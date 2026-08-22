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
    Q_PROPERTY(QString lastUrl READ lastUrl NOTIFY lastUrlChanged)

public:
    explicit CatboxUploader(QObject* parent = nullptr);
    ~CatboxUploader() override;

    static CatboxUploader* instance();
    static CatboxUploader* create(QQmlEngine* = nullptr, QJSEngine* = nullptr) {
        return instance();
    }

    bool isUploading() const { return m_isUploading; }
    qreal uploadProgress() const { return m_uploadProgress; }
    QString currentFileName() const { return m_currentFileName; }
    QString lastUrl() const { return m_lastUrl; }

    Q_INVOKABLE void uploadFile(const QString& filePath);
    Q_INVOKABLE void uploadFiles(const QStringList& filePaths);
    Q_INVOKABLE void cancelUpload();

signals:
    void isUploadingChanged();
    void uploadProgressChanged();
    void currentFileNameChanged();
    void lastUrlChanged();
    void uploadStarted(const QString& filePath);
    void uploadProgressUpdated(qreal progress, const QString& statusText);
    void uploadFinished(bool success, const QString& resultUrlOrError, const QString& filePath);

private slots:
    void onUploadProgress(qint64 bytesSent, qint64 bytesTotal);
    void onReplyFinished();

private:
    void processNextInQueue();

    QNetworkAccessManager* m_nam = nullptr;
    QNetworkReply* m_currentReply = nullptr;
    QHttpMultiPart* m_currentMultiPart = nullptr;
    QFile* m_currentFile = nullptr;

    QStringList m_uploadQueue;
    QString m_currentFilePath;
    QString m_currentFileName;
    QString m_lastUrl;
    bool m_isUploading = false;
    qreal m_uploadProgress = 0.0;
};

} // namespace prism::core
