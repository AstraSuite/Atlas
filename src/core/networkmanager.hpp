#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QProcess>
#include <QQmlEngine>
#include <QJSEngine>
#include <qqmlintegration.h>

namespace prism::core {

class NetworkManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool isConnecting READ isConnecting NOTIFY isConnectingChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(QString lastMountedPath READ lastMountedPath NOTIFY lastMountedPathChanged)
    Q_PROPERTY(QStringList supportedSchemes READ supportedSchemes CONSTANT)

public:
    explicit NetworkManager(QObject* parent = nullptr);
    ~NetworkManager() override = default;

    static NetworkManager* instance();
    static NetworkManager* create(QQmlEngine* = nullptr, QJSEngine* = nullptr) {
        return instance();
    }

    bool isConnecting() const { return m_isConnecting; }
    QString lastError() const { return m_lastError; }
    QString lastMountedPath() const { return m_lastMountedPath; }

    Q_INVOKABLE void connectSftp(const QString& host, int port = 22, const QString& user = QString(), const QString& path = QStringLiteral("/"), const QString& password = QString(), bool saveBookmark = true);
    Q_INVOKABLE void connectServer(const QString& scheme, const QString& host, int port = 0, const QString& user = QString(), const QString& path = QStringLiteral("/"), const QString& password = QString(), bool saveBookmark = true);
    Q_INVOKABLE static int defaultPort(const QString& scheme);
    [[nodiscard]] static QStringList supportedSchemes();
    Q_INVOKABLE void connectUri(const QString& uri, const QString& password = QString(), bool saveBookmark = true);
    Q_INVOKABLE void unmount(const QString& pathOrUri);
    Q_INVOKABLE QString findLocalMountPath(const QString& uri) const;
    Q_INVOKABLE QStringList getActiveRemoteMounts() const;

signals:
    void isConnectingChanged();
    void lastErrorChanged();
    void lastMountedPathChanged();
    void connectionFinished(bool success, const QString& localPath, const QString& errorMessage);
    void unmounted(const QString& path);

private:
    void handleMountProcessFinished(int exitCode, QProcess::ExitStatus exitStatus, const QString& uri, bool saveBookmark);
    QString resolveGvfsPath(const QString& uri) const;

    bool m_isConnecting = false;
    QString m_lastError;
    QString m_lastMountedPath;
    QProcess* m_currentProcess = nullptr;
};

} // namespace prism::core
