#include "placesmodel.hpp"
#include "fileutils.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>
#include <QUrl>
#include <QXmlStreamReader>
#include <QXmlStreamWriter>
#include <QFileSystemWatcher>

namespace prism::core {

static QString mapXbelIconToMaterial(const QString& iconName, const QString& path, bool isDir) {
    QString n = iconName.toLower();
    if (n.contains("home")) return "home";
    if (n.contains("download")) return "file_download";
    if (n.contains("desktop")) return "desktop_windows";
    if (n.contains("document")) return "description";
    if (n.contains("music")) return "music_note";
    if (n.contains("picture") || n.contains("image") || n.contains("photo")) return "image";
    if (n.contains("video") || n.contains("movie")) return "video_library";
    if (n.contains("trash") || n.contains("delete")) return "delete";
    if (n.contains("game")) return "sports_esports";
    if (n.contains("development") || n.contains("code") || n.contains("project") || n.contains("terminal")) return "terminal";
    if (n.contains("star")) return "star";
    if (n.contains("favorite") || n.contains("heart")) return "favorite";
    if (n.contains("cloud")) return "cloud";
    if (n.contains("work") || n.contains("briefcase")) return "work";
    if (n.contains("lock")) return "lock";
    if (n.contains("tag") || n.contains("label")) return "sell";
    if (!iconName.isEmpty() && !iconName.contains("-")) return iconName; // Directly valid M3 icon name
    return isDir ? "folder" : "bookmark";
}

PlacesModel::PlacesModel(QObject* parent)
    : QAbstractListModel(parent) {
    
    auto* watcher = new QFileSystemWatcher(this);
    QString xbelPath = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/user-places.xbel";
    QString gtkPath = QDir::homePath() + "/.config/gtk-3.0/bookmarks";
    
    if (QFile::exists(xbelPath)) watcher->addPath(xbelPath);
    if (QFile::exists(gtkPath)) watcher->addPath(gtkPath);
    
    connect(watcher, &QFileSystemWatcher::fileChanged, this, &PlacesModel::refresh);
    
    refresh();
}

int PlacesModel::rowCount(const QModelIndex& parent) const {
    if (parent.isValid()) return 0;
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
    default: return {};
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
    
    // 1. Read standard XBEL places (KDE / Dolphin standard ~/.local/share/user-places.xbel)
    bool loadedXbel = false;
    QString xbelPath = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/user-places.xbel";
    if (QFile::exists(xbelPath)) {
        QFile file(xbelPath);
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QXmlStreamReader xml(&file);
            QString currentHref;
            QString currentTitle;
            QString currentIcon;
            bool isHidden = false;
            bool isSystem = false;

            while (!xml.atEnd() && !xml.hasError()) {
                auto token = xml.readNext();
                if (token == QXmlStreamReader::StartElement) {
                    auto tag = xml.name();
                    if (tag == QLatin1String("bookmark")) {
                        currentHref = xml.attributes().value("href").toString();
                        currentTitle.clear();
                        currentIcon.clear();
                        isHidden = false;
                        isSystem = false;
                    } else if (tag == QLatin1String("title")) {
                        currentTitle = xml.readElementText();
                    } else if (tag == QLatin1String("icon")) {
                        currentIcon = xml.attributes().value("name").toString();
                    } else if (tag == QLatin1String("isSystemItem")) {
                        isSystem = (xml.readElementText().trimmed().toLower() == "true");
                    } else if (tag == QLatin1String("IsHidden") || tag == QLatin1String("onlyInKDE")) {
                        if (xml.readElementText().trimmed().toLower() == "true") isHidden = true;
                    }
                } else if (token == QXmlStreamReader::EndElement) {
                    if (xml.name() == QLatin1String("bookmark")) {
                        if (!isHidden && !currentHref.isEmpty()) {
                            QString localPath;
                            if (currentHref.startsWith("file://")) {
                                localPath = QUrl(currentHref).toLocalFile();
                            } else if (currentHref.startsWith("trash:/")) {
                                localPath = QDir::homePath() + "/.local/share/Trash/files";
                            } else if (currentHref.startsWith("/")) {
                                localPath = currentHref;
                            }

                            if (localPath == "/" || localPath == "/root") continue;

                            if (!localPath.isEmpty() && (QFile::exists(localPath) || currentHref.startsWith("trash:"))) {
                                if (currentTitle.isEmpty()) {
                                    currentTitle = QFileInfo(localPath).fileName();
                                    if (currentTitle.isEmpty()) currentTitle = localPath;
                                }

                                bool isTrash = currentHref.startsWith("trash:") || localPath.contains("Trash");
                                QString icon = mapXbelIconToMaterial(currentIcon, localPath, QFileInfo(localPath).isDir());

                                m_places.append({
                                    currentTitle,
                                    localPath,
                                    icon,
                                    false,
                                    false,
                                    isTrash,
                                    !isSystem,
                                    0,
                                    0
                                });
                                loadedXbel = true;
                            }
                        }
                    }
                }
            }
        }
    }

    if (!loadedXbel || m_places.isEmpty()) {
        loadStandardPlaces();
    }

    loadBookmarks();

    endResetModel();
    emit countChanged();
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

void PlacesModel::loadBookmarks() {
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
                if (QDir(path).exists() && path != "/") {
                    bool alreadyPresent = false;
                    for (const auto& p : m_places) {
                        if (p.path == path) {
                            alreadyPresent = true;
                            break;
                        }
                    }
                    if (!alreadyPresent) {
                        if (name.isEmpty()) name = QFileInfo(path).fileName();
                        m_places.append({ name, path, "bookmark", false, false, false, true, 0, 0 });
                    }
                }
            }
        }
    }
}

void PlacesModel::saveBookmarks() {
    QString xbelPath = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/user-places.xbel";
    QFile file(xbelPath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QXmlStreamWriter xml(&file);
        xml.setAutoFormatting(true);
        xml.writeStartDocument("1.0");
        xml.writeDTD("<!DOCTYPE xbel>");
        xml.writeStartElement("xbel");
        xml.writeAttribute("xmlns:bookmark", "http://www.freedesktop.org/standards/desktop-bookmarks");
        xml.writeAttribute("xmlns:kdepriv", "http://www.kde.org/kdepriv");
        xml.writeAttribute("xmlns:mime", "http://www.freedesktop.org/standards/shared-mime-info");

        for (const auto& p : m_places) {
            xml.writeStartElement("bookmark");
            xml.writeAttribute("href", QUrl::fromLocalFile(p.path).toString());
            xml.writeTextElement("title", p.name);
            xml.writeStartElement("info");
            xml.writeStartElement("metadata");
            xml.writeAttribute("owner", "http://freedesktop.org");
            xml.writeStartElement("bookmark:icon");
            xml.writeAttribute("name", p.iconName);
            xml.writeEndElement(); // bookmark:icon
            xml.writeEndElement(); // metadata
            xml.writeStartElement("metadata");
            xml.writeAttribute("owner", "http://www.kde.org");
            xml.writeTextElement("isSystemItem", p.isCustom ? "false" : "true");
            xml.writeEndElement(); // metadata
            xml.writeEndElement(); // info
            xml.writeEndElement(); // bookmark
        }

        xml.writeEndElement(); // xbel
        xml.writeEndDocument();
    }
}

bool PlacesModel::isBookmarked(const QString& path) const {
    for (const auto& p : m_places) {
        if (p.path == path) return true;
    }
    return false;
}

void PlacesModel::addBookmark(const QString& path, const QString& name, const QString& icon) {
    if (path.isEmpty() || isBookmarked(path)) return;
    QString n = name.isEmpty() ? QFileInfo(path).fileName() : name;
    if (n.isEmpty()) n = path;
    QString ic = icon.isEmpty() ? "bookmark" : icon;

    beginInsertRows(QModelIndex(), m_places.size(), m_places.size());
    m_places.append({ n, path, ic, false, false, false, true, 0, 0 });
    endInsertRows();
    emit countChanged();
    saveBookmarks();
}

void PlacesModel::removeBookmark(int index) {
    if (index < 0 || index >= m_places.size()) return;
    beginRemoveRows(QModelIndex(), index, index);
    m_places.removeAt(index);
    endRemoveRows();
    emit countChanged();
    saveBookmarks();
}

void PlacesModel::removeBookmarkByPath(const QString& path) {
    for (int i = 0; i < m_places.size(); ++i) {
        if (m_places[i].path == path) {
            removeBookmark(i);
            return;
        }
    }
}

void PlacesModel::toggleBookmark(const QString& path) {
    if (isBookmarked(path)) {
        removeBookmarkByPath(path);
    } else {
        addBookmark(path);
    }
}

void PlacesModel::updatePlace(int index, const QString& name, const QString& iconName) {
    if (index < 0 || index >= m_places.size()) return;
    if (!name.isEmpty()) m_places[index].name = name;
    if (!iconName.isEmpty()) m_places[index].iconName = iconName;

    auto modelIdx = this->index(index, 0);
    emit dataChanged(modelIdx, modelIdx, { NameRole, IconNameRole });
    saveBookmarks();
}

} // namespace prism::core
