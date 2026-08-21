#include "fileutils.hpp"
#include <QDir>
#include <QFileInfo>
#include <QMimeDatabase>
#include <QStandardPaths>
#include <QIcon>

namespace prism::core {

FileUtils::FileUtils(QObject* parent) : QObject(parent) {}

QString FileUtils::home() const {
    return QDir::homePath();
}

QString FileUtils::pictures() const {
    return QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
}

QString FileUtils::videos() const {
    return QStandardPaths::writableLocation(QStandardPaths::MoviesLocation);
}

QString FileUtils::documents() const {
    return QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
}

QString FileUtils::downloads() const {
    return QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
}

QString FileUtils::music() const {
    return QStandardPaths::writableLocation(QStandardPaths::MusicLocation);
}

QString FileUtils::desktop() const {
    return QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
}

QString FileUtils::formatSize(qint64 bytes) {
    if (bytes < 1024)
        return QString("%1 B").arg(bytes);
    if (bytes < 1024 * 1024)
        return QString("%1 KB").arg(QString::number(bytes / 1024.0, 'f', 1));
    if (bytes < 1024 * 1024 * 1024)
        return QString("%1 MB").arg(QString::number(bytes / (1024.0 * 1024.0), 'f', 1));
    return QString("%1 GB").arg(QString::number(bytes / (1024.0 * 1024.0 * 1024.0), 'f', 1));
}

QString FileUtils::shortenHome(const QString& path) {
    QString h = QDir::homePath();
    if (path.startsWith(h)) {
        return QString("~") + path.mid(h.length());
    }
    return path;
}

QString FileUtils::toLocalFile(const QUrl& url) {
    return url.isLocalFile() ? url.toLocalFile() : url.toString();
}

QString FileUtils::baseName(const QString& path) {
    if (path.isEmpty()) return QString();
    return QFileInfo(path).fileName();
}

bool FileUtils::isImage(const QString& path) {
    if (path.isEmpty()) return false;
    static const QMimeDatabase db;
    QMimeType mime = db.mimeTypeForFile(path);
    return mime.name().startsWith(QLatin1String("image/"));
}

bool FileUtils::isVideo(const QString& path) {
    if (path.isEmpty()) return false;
    static const QMimeDatabase db;
    QMimeType mime = db.mimeTypeForFile(path);
    return mime.name().startsWith(QLatin1String("video/"));
}

bool FileUtils::isAudio(const QString& path) {
    if (path.isEmpty()) return false;
    static const QMimeDatabase db;
    QMimeType mime = db.mimeTypeForFile(path);
    return mime.name().startsWith(QLatin1String("audio/"));
}

QString FileUtils::iconForName(const QString& name, const QString& fallback) {
    if (QIcon::hasThemeIcon(name)) {
        return QString("image://icon/") + name;
    }
    if (!fallback.isEmpty() && QIcon::hasThemeIcon(fallback)) {
        return QString("image://icon/") + fallback;
    }
    return QString("image://icon/") + (fallback.isEmpty() ? name : fallback);
}

QString FileUtils::iconForFile(const QString& name, bool isDir, const QString& mimeType) {
    if (isDir) {
        static const QStringList specialDirs = { "Desktop", "Documents", "Downloads", "Music", "Pictures", "Public", "Templates", "Videos" };
        if (specialDirs.contains(name)) {
            QString iconName = QString("folder-%1").arg(name.toLower());
            if (QIcon::hasThemeIcon(iconName))
                return QString("image://icon/") + iconName;
        }
        return QString("image://icon/inode-directory");
    }

    if (name.endsWith(".bak", Qt::CaseInsensitive) || name.endsWith("~") ||
        name.endsWith(".backup", Qt::CaseInsensitive) || name.endsWith(".old", Qt::CaseInsensitive)) {
        if (QIcon::hasThemeIcon("application-x-backup")) {
            return QString("image://icon/application-x-backup");
        }
        if (QIcon::hasThemeIcon("document-revert")) {
            return QString("image://icon/document-revert");
        }
        if (QIcon::hasThemeIcon("edit-undo")) {
            return QString("image://icon/edit-undo");
        }
        if (QIcon::hasThemeIcon("text-x-generic")) {
            return QString("image://icon/text-x-generic");
        }
    }

    QString mimeIcon = mimeType;
    mimeIcon.replace('/', '-');
    if (QIcon::hasThemeIcon(mimeIcon)) {
        return QString("image://icon/") + mimeIcon;
    }
    if (QIcon::hasThemeIcon(mimeType)) {
        return QString("image://icon/") + mimeType;
    }
    return QString("image://icon/application-x-zerosize");
}

QString FileUtils::mimeTypeForFile(const QString& path) {
    if (path.isEmpty()) return QString();
    static const QMimeDatabase db;
    return db.mimeTypeForFile(path).name();
}

} // namespace prism::core
