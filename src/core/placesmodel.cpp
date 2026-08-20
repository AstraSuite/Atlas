#include "placesmodel.hpp"
#include "fileutils.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

namespace prism::core {

PlacesModel::PlacesModel(QObject* parent)
    : QAbstractListModel(parent) {
    refresh();
}

int PlacesModel::rowCount(const QModelIndex& parent) const {
    if (parent.isValid())
        return 0;
    return static_cast<int>(m_places.size());
}

QVariant PlacesModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_places.size())
        return {};

    const auto& p = m_places.at(index.row());
    switch (role) {
    case NameRole: return p.name;
    case PathRole: return p.path;
    case IconNameRole: return p.iconName;
    case IsDeviceRole: return p.isDevice;
    case IsRemovableRole: return p.isRemovable;
    case IsTrashRole: return p.isTrash;
    case IsCustomRole: return p.isCustom;
    case BytesFreeRole: return p.bytesFree;
    case BytesTotalRole: return p.bytesTotal;
    case FreeSpaceFormattedRole: {
        if (p.bytesTotal > 0) {
            return QString("%1 free of %2").arg(FileUtils::formatSize(p.bytesFree), FileUtils::formatSize(p.bytesTotal));
        }
        return QString();
    }
    default:
        return {};
    }
}

QHash<int, QByteArray> PlacesModel::roleNames() const {
    return {
        { NameRole, "name" },
        { PathRole, "path" },
        { IconNameRole, "iconName" },
        { IsDeviceRole, "isDevice" },
        { IsRemovableRole, "isRemovable" },
        { IsTrashRole, "isTrash" },
        { IsCustomRole, "isCustom" },
        { BytesFreeRole, "bytesFree" },
        { BytesTotalRole, "bytesTotal" },
        { FreeSpaceFormattedRole, "freeSpaceFormatted" }
    };
}

void PlacesModel::refresh() {
    beginResetModel();
    m_places.clear();
    loadStandardPlaces();
    loadBookmarks();
    loadStorageDevices();
    endResetModel();
}

void PlacesModel::loadStandardPlaces() {
    QString home = QDir::homePath();
    m_places.append({ tr("Home"), home, "home", false, false, false, false, 0, 0 });
    m_places.append({ tr("Downloads"), QStandardPaths::writableLocation(QStandardPaths::DownloadLocation), "file_download", false, false, false, false, 0, 0 });
    m_places.append({ tr("Documents"), QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation), "description", false, false, false, false, 0, 0 });
    m_places.append({ tr("Desktop"), QStandardPaths::writableLocation(QStandardPaths::DesktopLocation), "desktop_windows", false, false, false, false, 0, 0 });
    m_places.append({ tr("Pictures"), QStandardPaths::writableLocation(QStandardPaths::PicturesLocation), "image", false, false, false, false, 0, 0 });
    m_places.append({ tr("Music"), QStandardPaths::writableLocation(QStandardPaths::MusicLocation), "music_note", false, false, false, false, 0, 0 });
    m_places.append({ tr("Videos"), QStandardPaths::writableLocation(QStandardPaths::MoviesLocation), "video_library", false, false, false, false, 0, 0 });
    m_places.append({ tr("Trash"), home + "/.local/share/Trash/files", "delete", false, false, true, false, 0, 0 });
}

void PlacesModel::loadStorageDevices() {
    const auto volumes = QStorageInfo::mountedVolumes();
    for (const auto& vol : volumes) {
        if (!vol.isValid() || !vol.isReady() || vol.isReadOnly() && vol.rootPath() != "/")
            continue;

        QString rootPath = vol.rootPath();
        if (rootPath.startsWith("/sys") || rootPath.startsWith("/proc") || rootPath.startsWith("/dev") || rootPath.startsWith("/run/user"))
            continue;

        QString name = vol.name();
        if (name.isEmpty()) {
            if (rootPath == "/") {
                name = tr("Root File System");
            } else {
                name = QFileInfo(rootPath).fileName();
                if (name.isEmpty()) name = rootPath;
            }
        }

        bool isRemovable = rootPath.startsWith("/media") || rootPath.startsWith("/run/media") || rootPath.startsWith("/mnt");
        QString icon = isRemovable ? "usb" : (rootPath == "/" ? "storage" : "hard_drive");

        m_places.append({
            name,
            rootPath,
            icon,
            true,
            isRemovable,
            false,
            false,
            vol.bytesFree(),
            vol.bytesTotal()
        });
    }
}

void PlacesModel::loadBookmarks() {
    // 1. GTK bookmarks (~/.config/gtk-3.0/bookmarks)
    QString gtkBookmarksPath = QDir::homePath() + "/.config/gtk-3.0/bookmarks";
    QFile gtkFile(gtkBookmarksPath);
    if (gtkFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        while (!gtkFile.atEnd()) {
            QString line = QString::fromUtf8(gtkFile.readLine()).trimmed();
            if (line.isEmpty()) continue;
            QStringList parts = line.split(' ');
            QString uri = parts.value(0);
            QString name = parts.size() > 1 ? parts.mid(1).join(' ') : "";
            if (uri.startsWith("file://")) {
                QString path = QUrl(uri).toLocalFile();
                if (QDir(path).exists()) {
                    if (name.isEmpty()) name = QFileInfo(path).fileName();
                    m_places.append({ name, path, "bookmark", false, false, false, true, 0, 0 });
                }
            }
        }
    }

    // 2. Custom Prism places JSON
    QString customFile = QDir::homePath() + "/.config/caelestia/prism-places.json";
    QFile file(customFile);
    if (file.open(QIODevice::ReadOnly)) {
        auto doc = QJsonDocument::fromJson(file.readAll());
        if (doc.isArray()) {
            auto arr = doc.array();
            for (const auto& item : arr) {
                auto obj = item.toObject();
                QString path = obj["path"].toString();
                QString name = obj["name"].toString();
                if (!path.isEmpty() && QDir(path).exists()) {
                    if (name.isEmpty()) name = QFileInfo(path).fileName();
                    m_places.append({ name, path, "bookmark", false, false, false, true, 0, 0 });
                }
            }
        }
    }
}

void PlacesModel::saveBookmarks() {
    QJsonArray arr;
    for (const auto& p : m_places) {
        if (p.isCustom) {
            QJsonObject obj;
            obj["name"] = p.name;
            obj["path"] = p.path;
            arr.append(obj);
        }
    }
    QString configDir = QDir::homePath() + "/.config/caelestia";
    QDir().mkpath(configDir);
    QFile file(configDir + "/prism-places.json");
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(arr).toJson());
    }
}

void PlacesModel::addBookmark(const QString& path, const QString& name) {
    QString n = name.isEmpty() ? QFileInfo(path).fileName() : name;
    beginInsertRows(QModelIndex(), m_places.size(), m_places.size());
    m_places.append({ n, path, "bookmark", false, false, false, true, 0, 0 });
    endInsertRows();
    saveBookmarks();
}

void PlacesModel::removeBookmark(int index) {
    if (index < 0 || index >= m_places.size())
        return;
    if (!m_places[index].isCustom)
        return;

    beginRemoveRows(QModelIndex(), index, index);
    m_places.removeAt(index);
    endRemoveRows();
    saveBookmarks();
}

} // namespace prism::core
