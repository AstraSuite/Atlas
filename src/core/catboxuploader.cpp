#include "catboxuploader.hpp"
#include "fileoperations.hpp"
#include <QFileInfo>
#include <QMimeDatabase>
#include <QMimeType>
#include <QGuiApplication>
#include <QClipboard>
#include <QProcess>
#include <QStandardPaths>
#include <QDebug>

namespace prism::core {

CatboxUploader::CatboxUploader(QObject* parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this)) {
}

CatboxUploader::~CatboxUploader() {
    cancelUpload();
}

CatboxUploader* CatboxUploader::instance() {
    static auto* s_instance = new CatboxUploader();
    return s_instance;
}

void CatboxUploader::uploadFile(const QString& filePath) {
    if (filePath.isEmpty()) return;
    uploadFiles(QStringList{ filePath });
}

void CatboxUploader::uploadFiles(const QStringList& filePaths) {
    for (const QString& rawPath : filePaths) {
        QString path = rawPath;
        if (path.startsWith(QLatin1String("file://"))) {
            path = QUrl(rawPath).toLocalFile();
        }
        if (!path.isEmpty() && QFileInfo::exists(path) && !QFileInfo(path).isDir()) {
            m_uploadQueue.append(path);
        }
    }

    if (!m_isUploading && !m_uploadQueue.isEmpty()) {
        processNextInQueue();
    }
}

void CatboxUploader::cancelUpload() {
    m_uploadQueue.clear();

    if (m_currentReply) {
        m_currentReply->abort();
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
        m_currentMultiPart = nullptr;
        m_currentFile = nullptr;
    } else {
        if (m_currentMultiPart) {
            m_currentMultiPart->deleteLater();
            m_currentMultiPart = nullptr;
            m_currentFile = nullptr;
        } else if (m_currentFile) {
            if (m_currentFile->isOpen()) m_currentFile->close();
            delete m_currentFile;
            m_currentFile = nullptr;
        }
    }

    if (m_isUploading) {
        m_isUploading = false;
        m_uploadProgress = 0.0;
        m_currentFileName.clear();
        emit isUploadingChanged();
        emit uploadProgressChanged();
        emit currentFileNameChanged();

        auto* foProgress = FileOperations::instance()->progress();
        if (foProgress && foProgress->running()) {
            foProgress->setRunning(false);
            foProgress->setStatusText(QStringLiteral("Upload cancelled"));
        }
    }
}

void CatboxUploader::processNextInQueue() {
    if (m_uploadQueue.isEmpty()) {
        m_isUploading = false;
        m_uploadProgress = 0.0;
        m_currentFileName.clear();
        emit isUploadingChanged();
        emit uploadProgressChanged();
        emit currentFileNameChanged();

        auto* foProgress = FileOperations::instance()->progress();
        if (foProgress && foProgress->running()) {
            foProgress->setRunning(false);
        }
        return;
    }

    m_currentFilePath = m_uploadQueue.takeFirst();
    QFileInfo fi(m_currentFilePath);
    if (!fi.exists() || fi.isDir()) {
        processNextInQueue();
        return;
    }

    m_currentFileName = fi.fileName();
    m_isUploading = true;
    m_uploadProgress = 0.0;
    emit isUploadingChanged();
    emit uploadProgressChanged();
    emit currentFileNameChanged();
    emit uploadStarted(m_currentFilePath);

    auto* foProgress = FileOperations::instance()->progress();
    if (foProgress) {
        foProgress->setRunning(true);
        foProgress->setProgress(0.0);
        foProgress->setCurrentItem(m_currentFileName);
        foProgress->setStatusText(tr("Uploading %1 to Catbox...").arg(m_currentFileName));
    }

    m_currentFile = new QFile(m_currentFilePath);
    if (!m_currentFile->open(QIODevice::ReadOnly)) {
        QString err = tr("Failed to open file for reading");
        delete m_currentFile;
        m_currentFile = nullptr;

        emit uploadFinished(false, err, m_currentFilePath);
        FileOperations::instance()->operationFinished(false, tr("Catbox upload failed: %1").arg(err));
        processNextInQueue();
        return;
    }

    m_currentMultiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    // Form parameter: reqtype = fileupload
    QHttpPart reqTypePart;
    reqTypePart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"reqtype\""));
    reqTypePart.setBody("fileupload");
    m_currentMultiPart->append(reqTypePart);

    // Form parameter: fileToUpload = <file data>
    QHttpPart filePart;
    QMimeDatabase mimeDb;
    QMimeType mimeType = mimeDb.mimeTypeForFile(m_currentFilePath);
    QString mimeName = mimeType.isValid() ? mimeType.name() : QStringLiteral("application/octet-stream");

    filePart.setHeader(QNetworkRequest::ContentTypeHeader, QVariant(mimeName));
    filePart.setHeader(QNetworkRequest::ContentDispositionHeader,
                       QVariant(QString("form-data; name=\"fileToUpload\"; filename=\"%1\"").arg(m_currentFileName)));
    filePart.setBodyDevice(m_currentFile);
    m_currentFile->setParent(m_currentMultiPart);
    m_currentMultiPart->append(filePart);

    QNetworkRequest request(QUrl(QStringLiteral("https://catbox.moe/user/api.php")));
    request.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("Prism-FileManager/1.0"));
    request.setTransferTimeout(60000);

    m_currentReply = m_nam->post(request, m_currentMultiPart);
    m_currentMultiPart->setParent(m_currentReply);

    connect(m_currentReply, &QNetworkReply::uploadProgress, this, &CatboxUploader::onUploadProgress);
    connect(m_currentReply, &QNetworkReply::finished, this, &CatboxUploader::onReplyFinished);
}

void CatboxUploader::onUploadProgress(qint64 bytesSent, qint64 bytesTotal) {
    if (bytesTotal > 0) {
        m_uploadProgress = static_cast<qreal>(bytesSent) / static_cast<qreal>(bytesTotal);
        emit uploadProgressChanged();
        emit uploadProgressUpdated(m_uploadProgress, tr("Uploading %1 (%2%)").arg(m_currentFileName).arg(static_cast<int>(m_uploadProgress * 100)));

        auto* foProgress = FileOperations::instance()->progress();
        if (foProgress && foProgress->running()) {
            foProgress->setProgress(m_uploadProgress);
            foProgress->setStatusText(tr("Uploading %1 to Catbox (%2%)").arg(m_currentFileName).arg(static_cast<int>(m_uploadProgress * 100)));
        }
    }
}

void CatboxUploader::onReplyFinished() {
    if (!m_currentReply) return;

    QNetworkReply* reply = m_currentReply;
    m_currentReply = nullptr;
    m_currentMultiPart = nullptr;
    m_currentFile = nullptr;

    bool success = false;
    QString resultText;
    int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

    if (reply->error() == QNetworkReply::NoError && statusCode == 200) {
        resultText = QString::fromUtf8(reply->readAll()).trimmed();
        if (resultText.startsWith(QLatin1String("http://")) || resultText.startsWith(QLatin1String("https://"))) {
            success = true;
            m_lastUrl = resultText;
            emit lastUrlChanged();

            // Automatically copy the returned URL to system clipboard
            if (auto* clipboard = QGuiApplication::clipboard()) {
                clipboard->setText(resultText);
            }

            emit uploadFinished(true, resultText, m_currentFilePath);
            FileOperations::instance()->addCompletedTask(true, tr("Uploaded %1 to Catbox").arg(m_currentFileName), resultText);
            FileOperations::instance()->operationFinished(true, tr("Uploaded %1 to Catbox: %2").arg(m_currentFileName, resultText));
        } else {
            success = false;
            emit uploadFinished(false, resultText, m_currentFilePath);
            FileOperations::instance()->addCompletedTask(false, tr("Catbox upload failed for %1: %2").arg(m_currentFileName, resultText), QString());
            FileOperations::instance()->operationFinished(false, tr("Catbox upload failed for %1: %2").arg(m_currentFileName, resultText));
        }
    } else {
        success = false;
        resultText = reply->errorString();
        emit uploadFinished(false, resultText, m_currentFilePath);
        FileOperations::instance()->addCompletedTask(false, tr("Catbox upload error for %1: %2").arg(m_currentFileName, resultText), QString());
        FileOperations::instance()->operationFinished(false, tr("Catbox upload error for %1: %2").arg(m_currentFileName, resultText));
    }

    reply->deleteLater();
    processNextInQueue();
}

} // namespace prism::core
