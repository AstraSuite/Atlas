#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QHttpMultiPart>
#include <QFile>
#include <QQmlEngine>
#include <QJSEngine>
#include <qqmlintegration.h>

namespace prism::core {

class CatboxUploader : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool isUploading READ isUploading NOTIFY isUploadingChanged)
    Q_PROPERTY(qreal uploadProgress READ uploadProgress NOTIFY uploadProgressChanged)
    Q_PROPERTY(QString currentFileName READ currentFileName NOTIFY currentFileNameChanged)
    Q_PROPERTY(QString currentService READ currentService NOTIFY currentServiceChanged)
    Q_PROPERTY(QString lastUrl READ lastUrl NOTIFY lastUrlChanged)

public:
    enum class Service {
        Catbox,
        Litterbox
    };
    Q_ENUM(Service)

    struct UploadItem {
        QString filePath;
        Service service = Service::Catbox;
        QString time = QStringLiteral("24h");
    };

    explicit CatboxUploader(QObject* parent = nullptr);
    ~CatboxUploader() override;

    static CatboxUploader* instance();
    static CatboxUploader* create(QQmlEngine* = nullptr, QJSEngine* = nullptr) {
        return instance();
    }

    bool isUploading() const { return m_isUploading; }
    qreal uploadProgress() const { return m_uploadProgress; }
    QString currentFileName() const { return m_currentFileName; }
    QString currentService() const { return m_currentService; }
    QString lastUrl() const { return m_lastUrl; }

    Q_INVOKABLE void uploadFile(const QString& filePath);
    Q_INVOKABLE void uploadFiles(const QStringList& filePaths);
    Q_INVOKABLE void uploadToLitterbox(const QString& filePath, const QString& time = QStringLiteral("24h"));
    Q_INVOKABLE void uploadFilesToLitterbox(const QStringList& filePaths, const QString& time = QStringLiteral("24h"));
    Q_INVOKABLE void cancelUpload();

signals:
    void isUploadingChanged();
    void uploadProgressChanged();
    void currentFileNameChanged();
    void currentServiceChanged();
    void lastUrlChanged();
    void uploadStarted(const QString& filePath);
    void uploadProgressUpdated(qreal progress, const QString& statusText);
    void uploadFinished(bool success, const QString& resultUrlOrError, const QString& filePath);

private slots:
    void onUploadProgress(qint64 bytesSent, qint64 bytesTotal);
    void onReplyFinished();

private:
    void enqueue(const QStringList& filePaths, Service service, const QString& time);
    void clearSharedProgress(const QString& finalStatusText = QString());
    static QString serviceDisplayName(Service service, const QString& time);

    void processNextInQueue();

    QNetworkAccessManager* m_nam = nullptr;
    QNetworkReply* m_currentReply = nullptr;
    QHttpMultiPart* m_currentMultiPart = nullptr;
    QFile* m_currentFile = nullptr;

    QList<UploadItem> m_uploadQueue;
    UploadItem m_currentItem;
    QString m_currentFileName;
    QString m_currentService;
    QString m_lastUrl;
    qint64 m_currentFileSize = 0;
    bool m_isUploading = false;
    bool m_ownsSharedProgress = false;
    qreal m_uploadProgress = 0.0;
};

} // namespace prism::core
