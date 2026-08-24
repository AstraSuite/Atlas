#include "trashlocations.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>
#include <QStorageInfo>
#include <QUrl>

#include <sys/stat.h>
#include <unistd.h>

namespace atlas::core {

QString TrashLocations::homeTrashDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/Trash");
}

QString TrashLocations::homeTrashFilesDir() {
    return homeTrashDir() + QStringLiteral("/files");
}

bool TrashLocations::isTrashRoot(const QString& path) {
    if (path.isEmpty())
        return false;
    return QDir::cleanPath(path) == QDir::cleanPath(homeTrashFilesDir());
}

QString TrashLocations::topDirFor(const QString& path) {
    const QStorageInfo storage(QFileInfo(path).absolutePath());
    return storage.isValid() ? storage.rootPath() : QString();
}

QStringList TrashLocations::mountPoints() {
    QStringList roots;
    const QString homeRoot = QStorageInfo(QDir::homePath()).rootPath();

    const auto volumes = QStorageInfo::mountedVolumes();
    for (const QStorageInfo& volume : volumes) {
        if (!volume.isValid() || !volume.isReady() || volume.isReadOnly())
            continue;

        const QString root = volume.rootPath();
        if (root.isEmpty() || root == homeRoot || roots.contains(root))
            continue;

        const QByteArray fsType = volume.fileSystemType();
        if (fsType == "proc" || fsType == "sysfs" || fsType == "devtmpfs" || fsType == "cgroup2"
            || fsType == "securityfs" || fsType == "debugfs" || fsType == "tracefs" || fsType == "configfs"
            || fsType == "pstore" || fsType == "bpf" || fsType == "efivarfs" || fsType == "mqueue"
            || fsType == "hugetlbfs" || fsType == "fusectl" || fsType == "binfmt_misc" || fsType == "autofs"
            || fsType == "ramfs" || fsType == "squashfs" || fsType == "overlay" || fsType == "tmpfs")
            continue;

        roots.append(root);
    }

    return roots;
}

static TrashLocation makeLocation(const QString& baseDir, const QString& topDir) {
    TrashLocation location;
    location.baseDir = baseDir;
    location.filesDir = baseDir + QStringLiteral("/files");
    location.infoDir = baseDir + QStringLiteral("/info");
    location.topDir = topDir;
    return location;
}

static bool isStickyDirectory(const QString& path) {
    struct stat info;
    if (lstat(QFile::encodeName(path).constData(), &info) != 0)
        return false;
    if (S_ISLNK(info.st_mode) || !S_ISDIR(info.st_mode))
        return false;
    return (info.st_mode & S_ISVTX) != 0;
}

static TrashLocation volumeTrash(const QString& topDir, bool create) {
    const QString uid = QString::number(::getuid());

    const QString shared = topDir + QStringLiteral("/.Trash");
    if (isStickyDirectory(shared)) {
        const QString base = shared + QLatin1Char('/') + uid;
        if (QDir(base).exists() || (create && QDir().mkpath(base + QStringLiteral("/files")) && QDir().mkpath(base + QStringLiteral("/info"))))
            return makeLocation(base, topDir);
    }

    const QString personal = topDir + QStringLiteral("/.Trash-") + uid;
    if (QDir(personal).exists())
        return makeLocation(personal, topDir);

    if (create && QDir().mkpath(personal + QStringLiteral("/files")) && QDir().mkpath(personal + QStringLiteral("/info")))
        return makeLocation(personal, topDir);

    return {};
}

QList<TrashLocation> TrashLocations::all() {
    QList<TrashLocation> locations;
    locations.append(makeLocation(homeTrashDir(), QString()));

    const QStringList roots = mountPoints();
    for (const QString& root : roots) {
        const TrashLocation location = volumeTrash(root, false);
        if (location.isValid())
            locations.append(location);
    }

    return locations;
}

TrashLocation TrashLocations::forTrashedFile(const QString& trashedFilePath) {
    const QString filesDir = QFileInfo(trashedFilePath).absolutePath();
    if (QFileInfo(filesDir).fileName() != QLatin1String("files"))
        return {};

    const QString baseDir = QFileInfo(filesDir).absolutePath();
    const QString homeBase = QDir::cleanPath(homeTrashDir());
    if (QDir::cleanPath(baseDir) == homeBase)
        return makeLocation(baseDir, QString());

    QString topDir = QFileInfo(baseDir).absolutePath();
    if (QFileInfo(baseDir).fileName() == QLatin1String(".Trash") || QFileInfo(topDir).fileName() == QLatin1String(".Trash"))
        topDir = QFileInfo(topDir).absolutePath();

    return makeLocation(baseDir, topDir);
}

TrashLocation TrashLocations::forSourceFile(const QString& sourcePath, bool create) {
    const QString homeRoot = QStorageInfo(QDir::homePath()).rootPath();
    const QString sourceRoot = topDirFor(sourcePath);

    if (sourceRoot.isEmpty() || sourceRoot == homeRoot || !mountPoints().contains(sourceRoot)) {
        const TrashLocation home = makeLocation(homeTrashDir(), QString());
        if (create) {
            QDir().mkpath(home.filesDir);
            QDir().mkpath(home.infoDir);
        }
        return home;
    }

    const TrashLocation location = volumeTrash(sourceRoot, create);
    if (location.isValid())
        return location;

    const TrashLocation home = makeLocation(homeTrashDir(), QString());
    if (create) {
        QDir().mkpath(home.filesDir);
        QDir().mkpath(home.infoDir);
    }
    return home;
}

QString TrashLocations::resolveOriginalPath(const TrashLocation& location, const QString& encodedPath) {
    const QString decoded = QUrl::fromPercentEncoding(encodedPath.toUtf8());
    if (decoded.isEmpty() || decoded.startsWith(QLatin1Char('/')))
        return decoded;
    if (location.topDir.isEmpty())
        return decoded;
    return QDir::cleanPath(location.topDir + QLatin1Char('/') + decoded);
}

} // namespace atlas::core
