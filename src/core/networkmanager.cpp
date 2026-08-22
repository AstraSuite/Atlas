#include "networkmanager.hpp"
#include "placesmodel.hpp"
#include <QDir>
#include <QFileInfo>
#include <QUrl>
#include <QStandardPaths>
#include <QDebug>
#include <unistd.h>

namespace prism::core {

NetworkManager::NetworkManager(QObject* parent)
    : QObject(parent) {
}

NetworkManager* NetworkManager::instance() {
    static auto* s_instance = new NetworkManager();
    return s_instance;
}

void NetworkManager::connectSftp(const QString& host, int port, const QString& user, const QString& path, const QString& password, bool saveBookmark) {
    if (host.isEmpty()) {
        emit connectionFinished(false, QString(), tr("Host cannot be empty"));
        return;
    }

    int validPort = (port > 0) ? port : 22;
    QString remotePath = path.isEmpty() ? QStringLiteral("/") : path;
    if (!remotePath.startsWith(QLatin1Char('/'))) {
        remotePath.prepend(QLatin1Char('/'));
    }

    QString uri = QStringLiteral("sftp://");
    if (!user.isEmpty()) {
        uri += user + QLatin1Char('@');
    }
    uri += host;
    if (validPort != 22) {
        uri += QStringLiteral(":%1").arg(validPort);
    }
    uri += remotePath;

    connectUri(uri, password, saveBookmark);
}

void NetworkManager::connectUri(const QString& uri, const QString& password, bool saveBookmark) {
    if (uri.isEmpty()) {
        emit connectionFinished(false, QString(), tr("URI cannot be empty"));
        return;
    }

    QString normalizedUri = uri;
    if (!normalizedUri.contains(QLatin1String("://"))) {
        normalizedUri.prepend(QStringLiteral("sftp://"));
    }

    // Check if already mounted
    QString existingPath = resolveGvfsPath(normalizedUri);
    if (!existingPath.isEmpty() && QDir(existingPath).exists()) {
        m_lastMountedPath = existingPath;
        emit lastMountedPathChanged();
        emit connectionFinished(true, existingPath, QString());
        return;
    }

    if (m_isConnecting && m_currentProcess) {
        m_currentProcess->kill();
        m_currentProcess->deleteLater();
        m_currentProcess = nullptr;
    }

    m_isConnecting = true;
    m_lastError.clear();
    emit isConnectingChanged();
    emit lastErrorChanged();

    m_currentProcess = new QProcess(this);
    QStringList args;
    args << QStringLiteral("mount") << normalizedUri;

    connect(m_currentProcess, &QProcess::finished, this, [this, normalizedUri, saveBookmark](int exitCode, QProcess::ExitStatus exitStatus) {
        handleMountProcessFinished(exitCode, exitStatus, normalizedUri, saveBookmark);
    });

    m_currentProcess->start(QStringLiteral("gio"), args);
    if (!password.isEmpty()) {
        m_currentProcess->write(password.toUtf8() + "\n");
    }
}

void NetworkManager::handleMountProcessFinished(int exitCode, QProcess::ExitStatus exitStatus, const QString& uri, bool saveBookmark) {
    m_isConnecting = false;
    emit isConnectingChanged();

    QString stdOut;
    QString stdErr;
    if (m_currentProcess) {
        stdOut = QString::fromUtf8(m_currentProcess->readAllStandardOutput()).trimmed();
        stdErr = QString::fromUtf8(m_currentProcess->readAllStandardError()).trimmed();
        m_currentProcess->deleteLater();
        m_currentProcess = nullptr;
    }

    QString localPath = resolveGvfsPath(uri);

    if (exitCode == 0 || (!localPath.isEmpty() && QDir(localPath).exists())) {
        m_lastMountedPath = localPath.isEmpty() ? uri : localPath;
        m_lastError.clear();
        emit lastMountedPathChanged();
        emit lastErrorChanged();

        if (saveBookmark) {
            QUrl qUri(uri);
            QString title = qUri.host();
            if (title.isEmpty()) title = uri;
            if (!qUri.userName().isEmpty()) {
                title = QStringLiteral("%1@%2").arg(qUri.userName(), title);
            }
            PlacesModel::instance()->addBookmark(m_lastMountedPath, title, QStringLiteral("cloud"));
        }

        emit connectionFinished(true, m_lastMountedPath, QString());
    } else {
        m_lastError = stdErr.isEmpty() ? tr("Failed to connect to remote server") : stdErr;
        emit lastErrorChanged();
        emit connectionFinished(false, QString(), m_lastError);
    }
}

QString NetworkManager::resolveGvfsPath(const QString& uri) const {
    uid_t uid = getuid();
    QString gvfsDir = QStringLiteral("/run/user/%1/gvfs").arg(uid);
    QDir dir(gvfsDir);
    if (!dir.exists()) return QString();

    QUrl qUri(uri);
    QString scheme = qUri.scheme().toLower();
    QString host = qUri.host().toLower();
    QString user = qUri.userName().toLower();

    const auto entries = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const auto& fi : entries) {
        QString name = fi.fileName().toLower();
        if (name.startsWith(scheme)) {
            if (host.isEmpty() || name.contains(host)) {
                if (user.isEmpty() || name.contains(user)) {
                    return fi.absoluteFilePath();
                }
            }
        }
    }

    if (!entries.isEmpty() && host.isEmpty()) {
        return entries.first().absoluteFilePath();
    }

    return QString();
}

void NetworkManager::unmount(const QString& pathOrUri) {
    if (pathOrUri.isEmpty()) return;

    QProcess* proc = new QProcess(this);
    QStringList args;
    args << QStringLiteral("mount") << QStringLiteral("-u") << pathOrUri;

    connect(proc, &QProcess::finished, this, [this, proc, pathOrUri](int exitCode, QProcess::ExitStatus) {
        Q_UNUSED(exitCode)
        PlacesModel::instance()->removeBookmarkByPath(pathOrUri);
        emit unmounted(pathOrUri);
        proc->deleteLater();
    });

    proc->start(QStringLiteral("gio"), args);
}

QString NetworkManager::findLocalMountPath(const QString& uri) const {
    return resolveGvfsPath(uri);
}

QStringList NetworkManager::getActiveRemoteMounts() const {
    QStringList list;
    uid_t uid = getuid();
    QString gvfsDir = QStringLiteral("/run/user/%1/gvfs").arg(uid);
    QDir dir(gvfsDir);
    if (!dir.exists()) return list;

    const auto entries = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const auto& fi : entries) {
        list.append(fi.absoluteFilePath());
    }
    return list;
}

} // namespace prism::core
