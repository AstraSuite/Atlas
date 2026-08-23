#include "catboxuploader.hpp"
#include "fileoperations.hpp"
#include <QFile>
#include <QFileInfo>
#include <QMimeDatabase>
#include <QMimeType>
#include <QGuiApplication>
#include <QClipboard>
#include <QProcess>
#include <QStandardPaths>
#include <QDateTime>
#include <QRandomGenerator>
#include <QDebug>
#include <algorithm>

namespace prism::core {
namespace {

class MultipartFileDevice : public QIODevice {
public:
    MultipartFileDevice(QByteArray prologue, const QString& filePath, QByteArray epilogue, QObject* parent = nullptr)
        : QIODevice(parent)
        , m_prologue(std::move(prologue))
        , m_epilogue(std::move(epilogue))
        , m_file(filePath) {}

    bool open(OpenMode mode) override {
        if (!(mode & ReadOnly))
            return false;
        if (!m_file.open(QIODevice::ReadOnly))
            return false;
        m_fileSize = m_file.size();
        m_pos = 0;
        return QIODevice::open(mode | Unbuffered);
    }

    void close() override {
        m_file.close();
        QIODevice::close();
    }

    [[nodiscard]] bool isSequential() const override { return false; }
    [[nodiscard]] qint64 size() const override { return m_prologue.size() + m_fileSize + m_epilogue.size(); }
    [[nodiscard]] qint64 pos() const override { return m_pos; }
    [[nodiscard]] bool atEnd() const override { return m_pos >= size(); }

    bool seek(qint64 pos) override {
        if (pos < 0 || pos > size())
            return false;
        const qint64 filePart = pos - m_prologue.size();
        if (filePart >= 0 && filePart <= m_fileSize && !m_file.seek(filePart))
            return false;
        if (filePart < 0 && !m_file.seek(0))
            return false;
        m_pos = pos;
        return QIODevice::seek(pos);
    }

protected:
    qint64 readData(char* data, qint64 maxlen) override {
        if (maxlen <= 0 || m_pos >= size())
            return m_pos >= size() ? 0 : -1;

        qint64 written = 0;
        while (written < maxlen && m_pos < size()) {
            const qint64 want = maxlen - written;
            if (m_pos < m_prologue.size()) {
                const qint64 take = qMin(want, m_prologue.size() - m_pos);
                memcpy(data + written, m_prologue.constData() + m_pos, static_cast<size_t>(take));
                written += take;
                m_pos += take;
            } else if (m_pos < m_prologue.size() + m_fileSize) {
                const qint64 offset = m_pos - m_prologue.size();
                if (m_file.pos() != offset && !m_file.seek(offset))
                    return written > 0 ? written : -1;
                const qint64 take = qMin(want, m_fileSize - offset);
                const qint64 got = m_file.read(data + written, take);
                if (got < 0)
                    return written > 0 ? written : -1;
                if (got == 0)
                    break;
                written += got;
                m_pos += got;
            } else {
                const qint64 offset = m_pos - m_prologue.size() - m_fileSize;
                const qint64 take = qMin(want, m_epilogue.size() - offset);
                memcpy(data + written, m_epilogue.constData() + offset, static_cast<size_t>(take));
                written += take;
                m_pos += take;
            }
        }
        return written;
    }

    qint64 writeData(const char*, qint64) override { return -1; }

private:
    QByteArray m_prologue;
    QByteArray m_epilogue;
    QFile m_file;
    qint64 m_fileSize = 0;
    qint64 m_pos = 0;
};

} // namespace

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

QString CatboxUploader::serviceDisplayName(Service service, const QString& time) {
    return service == Service::Catbox
        ? QStringLiteral("Catbox")
        : QStringLiteral("Litterbox (%1)").arg(time.isEmpty() ? QStringLiteral("24h") : time);
}

void CatboxUploader::beginSharedProgress(const QString& statusText) {
    m_ownsSharedProgress = true;

    auto* foProgress = FileOperations::instance()->progress();
    if (foProgress) {
        foProgress->setRunning(true);
        foProgress->setStatusText(statusText);
    }
}

void CatboxUploader::clearSharedProgress(const QString& finalStatusText) {
    if (!m_ownsSharedProgress)
        return;

    m_ownsSharedProgress = false;

    auto* foProgress = FileOperations::instance()->progress();
    if (foProgress) {
        foProgress->setRunning(false);
        foProgress->setProgress(0.0);
        foProgress->setStatusText(finalStatusText);
        foProgress->setCurrentItem(QString());
    }
}

void CatboxUploader::enqueue(const QStringList& filePaths, Service service, const QString& time) {
    const QString serviceName = serviceDisplayName(service, time);
    const QString validTime = time.isEmpty() ? QStringLiteral("24h") : time;

    int accepted = 0;
    for (const QString& rawPath : filePaths) {
        QString path = rawPath;
        if (path.startsWith(QLatin1String("file://")))
            path = QUrl(rawPath).toLocalFile();
        if (path.isEmpty())
            continue;

        const QFileInfo fi(path);
        if (!fi.exists() || fi.isDir()) {
            FileOperations::instance()->addCompletedTask(
                false, tr("Skipped %1: only existing files can be uploaded to %2").arg(fi.fileName().isEmpty() ? path : fi.fileName(), serviceName), QString());
            continue;
        }

        m_uploadQueue.append(UploadItem{ path, service, validTime });
        ++accepted;
    }

    if (accepted == 0) {
        FileOperations::instance()->operationFinished(false, tr("Nothing to upload to %1").arg(serviceName));
        return;
    }

    if (m_isUploading && !m_currentReply)
        m_isUploading = false;

    beginSharedProgress(tr("Preparing to upload to %1...").arg(serviceName));

    if (!m_isUploading)
        processNextInQueue();
}

void CatboxUploader::uploadFiles(const QStringList& filePaths) {
    enqueue(filePaths, Service::Catbox, QString());
}

void CatboxUploader::uploadToLitterbox(const QString& filePath, const QString& time) {
    if (filePath.isEmpty()) return;
    uploadFilesToLitterbox(QStringList{ filePath }, time);
}

void CatboxUploader::uploadFilesToLitterbox(const QStringList& filePaths, const QString& time) {
    enqueue(filePaths, Service::Litterbox, time);
}

void CatboxUploader::cancelUpload() {
    m_uploadQueue.clear();

    if (QNetworkReply* reply = m_currentReply) {
        m_currentReply = nullptr;
        reply->disconnect(this);
        reply->abort();
        reply->deleteLater();
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
    }

    clearSharedProgress(tr("Upload cancelled"));
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

        clearSharedProgress();
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

    const QString serviceName = serviceDisplayName(m_currentItem.service, m_currentItem.time);
    m_currentService = serviceName;

    emit isUploadingChanged();
    emit uploadProgressChanged();
    emit currentFileNameChanged();
    emit currentServiceChanged();
    emit uploadStarted(m_currentItem.filePath);

    m_ownsSharedProgress = true;

    auto* foProgress = FileOperations::instance()->progress();
    if (foProgress) {
        foProgress->setRunning(true);
        foProgress->setProgress(0.0);
        foProgress->setCurrentItem(m_currentFileName);
        foProgress->setStatusText(tr("Uploading %1 to %2...").arg(m_currentFileName, serviceName));
    }

    QString boundary = QStringLiteral("----PrismBoundary%1%2")
        .arg(QDateTime::currentMSecsSinceEpoch())
        .arg(QRandomGenerator::global()->generate());

    QMimeDatabase mimeDb;
    QMimeType mimeType = mimeDb.mimeTypeForFile(m_currentItem.filePath);
    QString mimeName = mimeType.isValid() ? mimeType.name() : QStringLiteral("application/octet-stream");

    QByteArray prologue;
    prologue.append("--" + boundary.toUtf8() + "\r\n");
    prologue.append("Content-Disposition: form-data; name=\"reqtype\"\r\n\r\n");
    prologue.append("fileupload\r\n");

    if (m_currentItem.service == Service::Litterbox) {
        prologue.append("--" + boundary.toUtf8() + "\r\n");
        prologue.append("Content-Disposition: form-data; name=\"time\"\r\n\r\n");
        prologue.append(m_currentItem.time.toUtf8() + "\r\n");
    }

    prologue.append("--" + boundary.toUtf8() + "\r\n");
    prologue.append("Content-Disposition: form-data; name=\"fileToUpload\"; filename=\"" + m_currentFileName.toUtf8() + "\"\r\n");
    prologue.append("Content-Type: " + mimeName.toUtf8() + "\r\n\r\n");

    QByteArray epilogue;
    epilogue.append("\r\n--" + boundary.toUtf8() + "--\r\n");

    auto* body = new MultipartFileDevice(prologue, m_currentItem.filePath, epilogue);
    if (!body->open(QIODevice::ReadOnly)) {
        delete body;
        QString err = tr("Failed to open file for reading");
        emit uploadFinished(false, err, m_currentItem.filePath);
        FileOperations::instance()->operationFinished(false, tr("%1 upload failed: %2").arg(serviceName, err));
        processNextInQueue();
        return;
    }

    QUrl apiUrl = (m_currentItem.service == Service::Catbox)
        ? QUrl(QStringLiteral("https://catbox.moe/user/api.php"))
        : QUrl(QStringLiteral("https://litterbox.catbox.moe/resources/internals/api.php"));

    QNetworkRequest request(apiUrl);
    request.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("Mozilla/5.0 Prism/1.0"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QString("multipart/form-data; boundary=%1").arg(boundary).toUtf8());
    request.setHeader(QNetworkRequest::ContentLengthHeader, body->size());
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, true);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setTransferTimeout(120000);

    QSslConfiguration sslConf = QSslConfiguration::defaultConfiguration();
    sslConf.setProtocol(QSsl::SecureProtocols);
    request.setSslConfiguration(sslConf);

    m_currentReply = m_nam->post(request, body);
    body->setParent(m_currentReply);
    connect(m_currentReply, &QNetworkReply::uploadProgress, this, &CatboxUploader::onUploadProgress);
    connect(m_currentReply, &QNetworkReply::finished, this, &CatboxUploader::onReplyFinished);
    connect(m_currentReply, &QNetworkReply::sslErrors, this, [this](const QList<QSslError>& errors) {
        qWarning() << "CatboxUploader SSL notices:" << errors;
        if (m_currentReply) {
            m_currentReply->ignoreSslErrors();
        }
    });
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
            const QString queued = m_uploadQueue.isEmpty()
                ? QString()
                : (m_uploadQueue.size() == 1
                       ? tr(", 1 more queued")
                       : tr(", %1 more queued").arg(m_uploadQueue.size()));
            foProgress->setStatusText(m_uploadProgress >= 1.0
                    ? tr("Waiting for %1 to process %2...").arg(m_currentService, m_currentFileName) + queued
                    : tr("Uploading %1 to %2 (%3%)")
                          .arg(m_currentFileName, m_currentService)
                          .arg(static_cast<int>(m_uploadProgress * 100)) + queued);
        }
    }
}

void CatboxUploader::onReplyFinished() {
    QNetworkReply* reply = m_currentReply ? m_currentReply : qobject_cast<QNetworkReply*>(sender());
    if (!reply)
        return;
    m_currentReply = nullptr;

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
