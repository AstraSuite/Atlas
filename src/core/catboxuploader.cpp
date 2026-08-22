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
#include <algorithm>

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
            m_uploadQueue.append(UploadItem{ path, Service::Catbox, QString() });
        }
    }

    if (!m_isUploading && !m_uploadQueue.isEmpty()) {
        processNextInQueue();
    }
}

void CatboxUploader::uploadToLitterbox(const QString& filePath, const QString& time) {
    if (filePath.isEmpty()) return;
    uploadFilesToLitterbox(QStringList{ filePath }, time);
}

void CatboxUploader::uploadFilesToLitterbox(const QStringList& filePaths, const QString& time) {
    QString validTime = time.isEmpty() ? QStringLiteral("24h") : time;
    for (const QString& rawPath : filePaths) {
        QString path = rawPath;
        if (path.startsWith(QLatin1String("file://"))) {
            path = QUrl(rawPath).toLocalFile();
        }
        if (!path.isEmpty() && QFileInfo::exists(path) && !QFileInfo(path).isDir()) {
            m_uploadQueue.append(UploadItem{ path, Service::Litterbox, validTime });
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
        m_currentService.clear();
        emit isUploadingChanged();
        emit uploadProgressChanged();
        emit currentFileNameChanged();
        emit currentServiceChanged();

        auto* foProgress = FileOperations::instance()->progress();
        if (foProgress && foProgress->running()) {
            foProgress->setRunning(false);
            foProgress->setProgress(0.0);
            foProgress->setStatusText(QStringLiteral("Upload cancelled"));
            foProgress->setCurrentItem(QString());
        }
    }
}

void CatboxUploader::processNextInQueue() {
    if (m_uploadQueue.isEmpty()) {
        m_isUploading = false;
        m_uploadProgress = 0.0;
        m_currentFileName.clear();
        m_currentService.clear();
        m_currentFileSize = 0;
        emit isUploadingChanged();
        emit uploadProgressChanged();
        emit currentFileNameChanged();
        emit currentServiceChanged();

        auto* foProgress = FileOperations::instance()->progress();
        if (foProgress) {
            foProgress->setRunning(false);
            foProgress->setProgress(0.0);
            foProgress->setStatusText(QString());
            foProgress->setCurrentItem(QString());
        }
        return;
    }

    m_currentItem = m_uploadQueue.takeFirst();
    QFileInfo fi(m_currentItem.filePath);
    if (!fi.exists() || fi.isDir()) {
        processNextInQueue();
        return;
    }

    m_currentFileName = fi.fileName();
    m_currentFileSize = fi.size();
    m_isUploading = true;
    m_uploadProgress = 0.0;

    QString serviceDisplayName = (m_currentItem.service == Service::Catbox)
        ? QStringLiteral("Catbox")
        : QStringLiteral("Litterbox (%1)").arg(m_currentItem.time);
    m_currentService = serviceDisplayName;

    emit isUploadingChanged();
    emit uploadProgressChanged();
    emit currentFileNameChanged();
    emit currentServiceChanged();
    emit uploadStarted(m_currentItem.filePath);

    auto* foProgress = FileOperations::instance()->progress();
    if (foProgress) {
        foProgress->setRunning(true);
        foProgress->setProgress(0.0);
        foProgress->setCurrentItem(m_currentFileName);
        foProgress->setStatusText(tr("Uploading %1 to %2...").arg(m_currentFileName, serviceDisplayName));
    }

    m_currentFile = new QFile(m_currentItem.filePath);
    if (!m_currentFile->open(QIODevice::ReadOnly)) {
        QString err = tr("Failed to open file for reading");
        delete m_currentFile;
        m_currentFile = nullptr;

        emit uploadFinished(false, err, m_currentItem.filePath);
        FileOperations::instance()->operationFinished(false, tr("%1 upload failed: %2").arg(serviceDisplayName, err));
        processNextInQueue();
        return;
    }

    m_currentMultiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    // Form parameter: reqtype = fileupload
    QHttpPart reqTypePart;
    reqTypePart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"reqtype\""));
    reqTypePart.setBody("fileupload");
    m_currentMultiPart->append(reqTypePart);

    // For Litterbox: time parameter
    if (m_currentItem.service == Service::Litterbox) {
        QHttpPart timePart;
        timePart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant("form-data; name=\"time\""));
        timePart.setBody(m_currentItem.time.toUtf8());
        m_currentMultiPart->append(timePart);
    }

    // Form parameter: fileToUpload = <file data>
    QHttpPart filePart;
    QMimeDatabase mimeDb;
    QMimeType mimeType = mimeDb.mimeTypeForFile(m_currentItem.filePath);
    QString mimeName = mimeType.isValid() ? mimeType.name() : QStringLiteral("application/octet-stream");

    filePart.setHeader(QNetworkRequest::ContentTypeHeader, QVariant(mimeName));
    filePart.setHeader(QNetworkRequest::ContentDispositionHeader,
                       QVariant(QString("form-data; name=\"fileToUpload\"; filename=\"%1\"").arg(m_currentFileName)));
    filePart.setBodyDevice(m_currentFile);
    m_currentFile->setParent(m_currentMultiPart);
    m_currentMultiPart->append(filePart);

    QUrl apiUrl = (m_currentItem.service == Service::Catbox)
        ? QUrl(QStringLiteral("https://catbox.moe/user/api.php"))
        : QUrl(QStringLiteral("https://litterbox.catbox.moe/resources/internals/api.php"));

    QNetworkRequest request(apiUrl);
    request.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("Prism-FileManager/1.0"));
    request.setTransferTimeout(120000);

    m_currentReply = m_nam->post(request, m_currentMultiPart);
    m_currentMultiPart->setParent(m_currentReply);

    connect(m_currentReply, &QNetworkReply::uploadProgress, this, &CatboxUploader::onUploadProgress);
    connect(m_currentReply, &QNetworkReply::finished, this, &CatboxUploader::onReplyFinished);
}

void CatboxUploader::onUploadProgress(qint64 bytesSent, qint64 bytesTotal) {
    qint64 total = bytesTotal;
    if (total <= 0 && m_currentFileSize > 0) {
        total = m_currentFileSize;
    }

    if (total > 0) {
        m_uploadProgress = std::clamp(static_cast<qreal>(bytesSent) / static_cast<qreal>(total), 0.0, 1.0);
        emit uploadProgressChanged();
        emit uploadProgressUpdated(m_uploadProgress, tr("Uploading %1 (%2%)").arg(m_currentFileName).arg(static_cast<int>(m_uploadProgress * 100)));

        auto* foProgress = FileOperations::instance()->progress();
        if (foProgress && foProgress->running()) {
            foProgress->setProgress(m_uploadProgress);
            foProgress->setStatusText(tr("Uploading %1 to %2 (%3%)")
                                          .arg(m_currentFileName, m_currentService)
                                          .arg(static_cast<int>(m_uploadProgress * 100)));
        }
    }
}

void CatboxUploader::onReplyFinished() {
    if (!m_currentReply) return;

    QNetworkReply* reply = m_currentReply;
    m_currentReply = nullptr;
    m_currentMultiPart = nullptr;
    m_currentFile = nullptr;

    QString currentFilePath = m_currentItem.filePath;
    QString currentFileName = m_currentFileName;
    QString serviceName = m_currentService;

    bool success = false;
    QString resultText;
    int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

    if (reply->error() == QNetworkReply::NoError && (statusCode == 200 || statusCode == 201)) {
        resultText = QString::fromUtf8(reply->readAll()).trimmed();
        if (resultText.startsWith(QLatin1String("http://")) || resultText.startsWith(QLatin1String("https://"))) {
            success = true;
            m_lastUrl = resultText;
            emit lastUrlChanged();

            // Automatically copy the returned URL to system clipboard
            if (auto* clipboard = QGuiApplication::clipboard()) {
                clipboard->setText(resultText);
            }

            emit uploadFinished(true, resultText, currentFilePath);
            FileOperations::instance()->addCompletedTask(true, tr("Uploaded %1 to %2").arg(currentFileName, serviceName), resultText);
            FileOperations::instance()->operationFinished(true, tr("Uploaded %1 to %2: %3").arg(currentFileName, serviceName, resultText));
        } else {
            success = false;
            emit uploadFinished(false, resultText, currentFilePath);
            FileOperations::instance()->addCompletedTask(false, tr("%1 upload failed for %2: %3").arg(serviceName, currentFileName, resultText), QString());
            FileOperations::instance()->operationFinished(false, tr("%1 upload failed for %2: %3").arg(serviceName, currentFileName, resultText));
        }
    } else {
        success = false;
        resultText = reply->errorString();
        emit uploadFinished(false, resultText, currentFilePath);
        FileOperations::instance()->addCompletedTask(false, tr("%1 upload error for %2: %3").arg(serviceName, currentFileName, resultText), QString());
        FileOperations::instance()->operationFinished(false, tr("%1 upload error for %2: %3").arg(serviceName, currentFileName, resultText));
    }

    reply->deleteLater();
    processNextInQueue();
}

} // namespace prism::core
