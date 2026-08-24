#include "papiruswatcher.hpp"
#include "appcontroller.hpp"
#include "iconprovider.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QIcon>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QTextStream>

namespace atlas::core {

PapirusWatcher::PapirusWatcher(QObject* parent)
    : QObject(parent) {
    m_debounceTimer.setSingleShot(true);
    m_debounceTimer.setInterval(600);

    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, &PapirusWatcher::onFileSystemChanged);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &PapirusWatcher::onFileSystemChanged);
    connect(&m_debounceTimer, &QTimer::timeout, this, &PapirusWatcher::onDebounceTimeout);

    scanAndWatch();
    m_lastColor = currentColor();
    m_lastSymlinkTarget = detectColorFromSymlink();
}

PapirusWatcher* PapirusWatcher::instance() {
    static auto* s_instance = new PapirusWatcher();
    return s_instance;
}

void PapirusWatcher::scanAndWatch() {
    // Monitor configuration directories and files
    QString userConfigDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + QStringLiteral("/papirus-folders");
    QString userConfigFile = userConfigDir + QStringLiteral("/keep");
    QString sysVarDir = QStringLiteral("/var/lib/papirus-folders");
    QString sysVarFile = sysVarDir + QStringLiteral("/keep");
    QString sysEtcDir = QStringLiteral("/etc/papirus-folders");
    QString sysEtcFile = sysEtcDir + QStringLiteral("/keep");

    addPathIfValid(userConfigDir, true);
    addPathIfValid(userConfigFile, false);
    addPathIfValid(sysVarDir, true);
    addPathIfValid(sysVarFile, false);
    addPathIfValid(sysEtcDir, true);
    addPathIfValid(sysEtcFile, false);

    // Discover Icon Theme directories
    QStringList iconBaseDirs = QIcon::themeSearchPaths();
    iconBaseDirs << (QDir::homePath() + QStringLiteral("/.icons"));
    iconBaseDirs << (QDir::homePath() + QStringLiteral("/.local/share/icons"));
    iconBaseDirs << QStringLiteral("/usr/local/share/icons");
    iconBaseDirs << QStringLiteral("/usr/share/icons");

    // Also parse XDG_DATA_DIRS
    const QString xdgDataDirs = qEnvironmentVariable("XDG_DATA_DIRS");
    for (const QString& d : xdgDataDirs.split(QChar(':'), Qt::SkipEmptyParts)) {
        iconBaseDirs << (d + QStringLiteral("/icons"));
    }
    iconBaseDirs.removeDuplicates();

    static const QStringList placesSizes = {
        QStringLiteral("16x16"),
        QStringLiteral("22x22"),
        QStringLiteral("24x24"),
        QStringLiteral("32x32"),
        QStringLiteral("48x48"),
        QStringLiteral("64x64"),
        QStringLiteral("scalable"),
        QStringLiteral("symbolic")
    };

    for (const QString& baseDirStr : iconBaseDirs) {
        QDir baseDir(baseDirStr);
        if (!baseDir.exists()) continue;

        const QStringList themeDirs = baseDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        for (const QString& themeName : themeDirs) {
            if (!themeName.contains(QStringLiteral("Papirus"), Qt::CaseInsensitive) &&
                !themeName.contains(QStringLiteral("ePapirus"), Qt::CaseInsensitive)) {
                continue;
            }

            QString themePath = baseDir.filePath(themeName);
            addPathIfValid(themePath, true);

            // Watch cache and index files if they exist
            addPathIfValid(themePath + QStringLiteral("/icon-theme.cache"), false);
            addPathIfValid(themePath + QStringLiteral("/index.theme"), false);

            // Watch places directories where papirus-folders modifies symlinks
            for (const QString& sz : placesSizes) {
                QString placesPath = themePath + QLatin1Char('/') + sz + QStringLiteral("/places");
                addPathIfValid(placesPath, true);
            }
        }
    }
}

void PapirusWatcher::addPathIfValid(const QString& path, bool isDir) {
    if (path.isEmpty()) return;

    QFileInfo info(path);
    if (!info.exists()) return;

    if (isDir && info.isDir()) {
        if (!m_watchedDirectories.contains(path)) {
            if (m_watcher.addPath(path)) {
                m_watchedDirectories.append(path);
            }
        }
    } else if (!isDir && info.isFile()) {
        if (!m_watchedFiles.contains(path)) {
            if (m_watcher.addPath(path)) {
                m_watchedFiles.append(path);
            }
        }
    }
}

void PapirusWatcher::onFileSystemChanged(const QString& path) {
    Q_UNUSED(path);
    m_debounceTimer.start();
}

void PapirusWatcher::onDebounceTimeout() {
    // Re-verify watcher paths to reconnect any unlinked/recreated files
    scanAndWatch();

    QString newColor = currentColor();
    QString newSymlink = detectColorFromSymlink();

    // Only trigger if color or symlink target actually changed
    if (newColor == m_lastColor && newSymlink == m_lastSymlinkTarget && !m_lastColor.isEmpty()) {
        return;
    }

    m_lastColor = newColor;
    m_lastSymlinkTarget = newSymlink;

    // Invalidate caches and trigger icon update across UI
    AppController::instance()->triggerIconReload();

    emit colorChanged(newColor);
    emit themeReloaded();
}

void PapirusWatcher::reload() {
    scanAndWatch();
    m_lastColor = currentColor();
    m_lastSymlinkTarget = detectColorFromSymlink();
    AppController::instance()->triggerIconReload();
    emit colorChanged(m_lastColor);
    emit themeReloaded();
}

QString PapirusWatcher::readColorFromKeepFile(const QString& filePath) const {
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return QString();
    }

    QTextStream in(&file);
    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (line.startsWith(QLatin1String("color="))) {
            return line.mid(6).trimmed();
        }
        if (line.startsWith(QLatin1String("folder_color="))) {
            return line.mid(13).trimmed();
        }
    }
    return QString();
}

QString PapirusWatcher::detectColorFromSymlink() const {
    // Look for symlink target in 48x48 places folder.svg
    QStringList iconBaseDirs = QIcon::themeSearchPaths();
    iconBaseDirs << (QDir::homePath() + QStringLiteral("/.icons"));
    iconBaseDirs << (QDir::homePath() + QStringLiteral("/.local/share/icons"));
    iconBaseDirs << QStringLiteral("/usr/local/share/icons");
    iconBaseDirs << QStringLiteral("/usr/share/icons");

    for (const QString& base : iconBaseDirs) {
        QString folderSvg = base + QStringLiteral("/Papirus/48x48/places/folder.svg");
        QFileInfo info(folderSvg);
        if (info.exists() && info.isSymLink()) {
            QString target = info.symLinkTarget();
            // Expected target name: folder-<color>.svg or /path/to/folder-<color>.svg
            QRegularExpression re(QStringLiteral("folder-([a-zA-Z0-9_-]+)\\.svg"));
            QRegularExpressionMatch match = re.match(target);
            if (match.hasMatch()) {
                return match.captured(1);
            }
        }
    }
    return QString();
}

QString PapirusWatcher::currentColor() const {
    QString userKeep = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + QStringLiteral("/papirus-folders/keep");
    QString color = readColorFromKeepFile(userKeep);
    if (!color.isEmpty()) return color;

    color = readColorFromKeepFile(QStringLiteral("/var/lib/papirus-folders/keep"));
    if (!color.isEmpty()) return color;

    color = readColorFromKeepFile(QStringLiteral("/etc/papirus-folders/keep"));
    if (!color.isEmpty()) return color;

    color = detectColorFromSymlink();
    if (!color.isEmpty()) return color;

    return QStringLiteral("default");
}

QStringList PapirusWatcher::availableColors() const {
    return {
        QStringLiteral("adwaita"),
        QStringLiteral("black"),
        QStringLiteral("blue"),
        QStringLiteral("bluegrey"),
        QStringLiteral("breeze"),
        QStringLiteral("brown"),
        QStringLiteral("carmine"),
        QStringLiteral("cyan"),
        QStringLiteral("darkcyan"),
        QStringLiteral("deeporange"),
        QStringLiteral("green"),
        QStringLiteral("grey"),
        QStringLiteral("indigo"),
        QStringLiteral("magenta"),
        QStringLiteral("nordic"),
        QStringLiteral("orange"),
        QStringLiteral("palebrown"),
        QStringLiteral("paleorange"),
        QStringLiteral("pink"),
        QStringLiteral("red"),
        QStringLiteral("teal"),
        QStringLiteral("violet"),
        QStringLiteral("white"),
        QStringLiteral("yaru"),
        QStringLiteral("yellow")
    };
}

bool PapirusWatcher::isAvailable() const {
    if (!QStandardPaths::findExecutable(QStringLiteral("papirus-folders")).isEmpty()) {
        return true;
    }
    return !detectColorFromSymlink().isEmpty();
}

} // namespace atlas::core
