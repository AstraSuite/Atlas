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
#include <QSettings>
#include <QTimer>

namespace prism::core {

static QString mapXbelIconToMaterial(const QString& iconName, const QString& path, bool isDir) {
    if (iconName.isEmpty()) return isDir ? "folder" : "bookmark";

    // If iconName has no hyphens, preserve it directly!
    if (!iconName.contains("-")) return iconName;

    QString n = iconName.toLower();
    if (n.contains("terminal")) return "terminal";
    if (n.contains("development") || n.contains("code")) return "code";
    if (n.contains("home")) return "home";
    if (n.contains("download")) return "file_download";
    if (n.contains("desktop")) return "desktop_windows";
    if (n.contains("document")) return "description";
    if (n.contains("music")) return "music_note";
    if (n.contains("picture") || n.contains("image") || n.contains("photo")) return "image";
    if (n.contains("video") || n.contains("movie")) return "video_library";
    if (n.contains("trash") || n.contains("delete")) return "delete";
    if (n.contains("game")) return "sports_esports";
    if (n.contains("star")) return "star";
    if (n.contains("favorite") || n.contains("heart")) return "favorite";
    if (n.contains("cloud")) return "cloud";
    if (n.contains("work") || n.contains("briefcase")) return "work";
    if (n.contains("lock")) return "lock";
    if (n.contains("tag") || n.contains("label")) return "sell";

    return isDir ? "folder" : "bookmark";
}

PlacesModel::PlacesModel(QObject* parent)
    : QAbstractListModel(parent) {
    
    loadHiddenPlaces();

    auto* watcher = new QFileSystemWatcher(this);
    QString xbelPath = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/user-places.xbel";
    QString gtkPath = QDir::homePath() + "/.config/gtk-3.0/bookmarks";
    
    if (QFile::exists(xbelPath)) watcher->addPath(xbelPath);
    if (QFile::exists(gtkPath)) watcher->addPath(gtkPath);
    
    connect(watcher, &QFileSystemWatcher::fileChanged, this, [this, watcher, xbelPath, gtkPath](const QString& path) {
        if (m_isSaving) return;
        // If file was replaced atomically, re-add to watcher
        if (!watcher->files().contains(path)) {
            if (QFile::exists(path)) watcher->addPath(path);
        }
        refresh();
    });
    
    refresh();
}

void PlacesModel::loadHiddenPlaces() {
    QSettings settings("prism", "prism");
    QStringList hidden = settings.value("places/hiddenPlaces").toStringList();
    m_hiddenPlaces = QSet<QString>(hidden.begin(), hidden.end());
}

void PlacesModel::saveHiddenPlaces() {
    QSettings settings("prism", "prism");
    settings.setValue("places/hiddenPlaces", QStringList(m_hiddenPlaces.begin(), m_hiddenPlaces.end()));
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
    
    // 1. Read standard XBEL places
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
                            if (m_hiddenPlaces.contains(localPath) || (currentHref.startsWith("trash:") && m_hiddenPlaces.contains("trash:"))) continue;

                            if (!localPath.isEmpty() && (QFile::exists(localPath) || currentHref.startsWith("trash:"))) {

                                if (currentTitle.isEmpty()) {
                                    currentTitle = QFileInfo(localPath).fileName();
                                    if (currentTitle.isEmpty()) currentTitle = localPath;
                                }

                                bool isTrash = currentHref.startsWith("trash:") || localPath.contains("Trash");
                                QString icon = mapXbelIconToMaterial(currentIcon, localPath, QFileInfo(localPath).isDir());

                                bool alreadyPresent = false;
                                for (const auto& p : m_places) {
                                    if (p.path == localPath || (p.isTrash && isTrash)) {
                                        alreadyPresent = true;
                                        break;
                                    }
                                }

                                if (!alreadyPresent) {
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
    if (!m_hiddenPlaces.contains(home))
        m_places.append({ tr("Home"), home, "home", false, false, false, false, 0, 0 });
    
    QString downloads = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    if (!m_hiddenPlaces.contains(downloads))
        m_places.append({ tr("Downloads"), downloads, "file_download", false, false, false, false, 0, 0 });
    
    QString documents = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    if (!m_hiddenPlaces.contains(documents))
        m_places.append({ tr("Documents"), documents, "description", false, false, false, false, 0, 0 });
    
    QString desktop = QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
    if (!m_hiddenPlaces.contains(desktop))
        m_places.append({ tr("Desktop"), desktop, "desktop_windows", false, false, false, false, 0, 0 });
    
    QString pictures = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    if (!m_hiddenPlaces.contains(pictures))
        m_places.append({ tr("Pictures"), pictures, "image", false, false, false, false, 0, 0 });
    
    QString music = QStandardPaths::writableLocation(QStandardPaths::MusicLocation);
    if (!m_hiddenPlaces.contains(music))
        m_places.append({ tr("Music"), music, "music_note", false, false, false, false, 0, 0 });
    
    QString videos = QStandardPaths::writableLocation(QStandardPaths::MoviesLocation);
    if (!m_hiddenPlaces.contains(videos))
        m_places.append({ tr("Videos"), videos, "video_library", false, false, false, false, 0, 0 });
    
    QString trash = home + "/.local/share/Trash/files";
    if (!m_hiddenPlaces.contains(trash) && !m_hiddenPlaces.contains("trash:"))
        m_places.append({ tr("Trash"), trash, "delete", false, false, true, false, 0, 0 });
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
                if (QDir(path).exists() && path != "/" && !m_hiddenPlaces.contains(path)) {
                    bool isTrash = path.contains("/Trash") || uri.startsWith("trash:");
                    bool alreadyPresent = false;
                    for (const auto& p : m_places) {
                        if (p.path == path || (p.isTrash && isTrash)) {
                            alreadyPresent = true;
                            break;
                        }
                    }
                    if (!alreadyPresent) {
                        if (name.isEmpty()) name = QFileInfo(path).fileName();
                        m_places.append({ name, path, isTrash ? "delete" : "bookmark", false, false, isTrash, true, 0, 0 });
                    }
                }
            }
        }
    }
}

void PlacesModel::saveBookmarks() {
    m_isSaving = true;

    // 1. Write XBEL Bookmarks
    QString xbelPath = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/user-places.xbel";
    QFileInfo xbelInfo(xbelPath);
    QDir().mkpath(xbelInfo.absolutePath());

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

    // 2. Write GTK-3.0 / GTK-4 Bookmarks
    QString gtkBookmarksPath = QDir::homePath() + "/.config/gtk-3.0/bookmarks";
    QFileInfo gtkInfo(gtkBookmarksPath);
    QDir().mkpath(gtkInfo.absolutePath());

    QFile gtkFile(gtkBookmarksPath);
    if (gtkFile.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        for (const auto& p : m_places) {
            if (p.isCustom && !p.isTrash && !p.path.isEmpty()) {
                QString uri = QUrl::fromLocalFile(p.path).toString();
                QString fileName = QFileInfo(p.path).fileName();
                if (p.name.isEmpty() || p.name == fileName) {
                    gtkFile.write((uri + "\n").toUtf8());
                } else {
                    gtkFile.write((uri + " " + p.name + "\n").toUtf8());
                }
            }
        }
        gtkFile.close();
    }

    saveHiddenPlaces();

    QTimer::singleShot(300, this, [this]() {
        m_isSaving = false;
    });
}

bool PlacesModel::isBookmarked(const QString& path) const {
    for (const auto& p : m_places) {
        if (p.path == path) return true;
    }
    return false;
}

void PlacesModel::addBookmark(const QString& path, const QString& name, const QString& icon) {
    if (path.isEmpty() || isBookmarked(path)) return;
    m_hiddenPlaces.remove(path);
    saveHiddenPlaces();

    QString n = name.isEmpty() ? QFileInfo(path).fileName() : name;
    if (n.isEmpty()) n = path;
    QString ic = icon.isEmpty() ? "bookmark" : icon;

    beginInsertRows(QModelIndex(), m_places.size(), m_places.size());
    m_places.append({ n, path, ic, false, false, false, true, 0, 0 });
    endInsertRows();
    emit countChanged();
    saveBookmarks();
}

void PlacesModel::addCustomPlace(const QString& name, const QString& path, const QString& icon) {
    addBookmark(path, name, icon);
}

void PlacesModel::movePlace(int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= m_places.size() || toIndex < 0 || toIndex >= m_places.size() || fromIndex == toIndex)
        return;

    int dest = toIndex > fromIndex ? toIndex + 1 : toIndex;
    if (!beginMoveRows(QModelIndex(), fromIndex, fromIndex, QModelIndex(), dest))
        return;

    m_places.move(fromIndex, toIndex);
    endMoveRows();
    saveBookmarks();
}

void PlacesModel::removeBookmark(int index) {
    if (index < 0 || index >= m_places.size()) return;
    QString path = m_places[index].path;
    bool isTrash = m_places[index].isTrash;

    if (!path.isEmpty()) {
        m_hiddenPlaces.insert(path);
    }
    if (isTrash) {
        m_hiddenPlaces.insert("trash:");
    }
    saveHiddenPlaces();

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

void PlacesModel::restoreDefaultPlaces() {
    m_hiddenPlaces.clear();
    saveHiddenPlaces();
    refresh();
    saveBookmarks();
}

void PlacesModel::updatePlace(int index, const QString& name, const QString& iconName) {
    if (index < 0 || index >= m_places.size()) return;
    if (!name.isEmpty()) m_places[index].name = name;
    if (!iconName.isEmpty()) m_places[index].iconName = iconName;

    auto modelIdx = this->index(index, 0);
    emit dataChanged(modelIdx, modelIdx, { NameRole, IconNameRole });
    saveBookmarks();
}

void PlacesModel::hidePlace(const QString& path) {

    if (!path.isEmpty() && !m_hiddenPlaces.contains(path)) {
        m_hiddenPlaces.insert(path);
        saveHiddenPlaces();
        refresh();
        saveBookmarks();
    }
}

void PlacesModel::unhidePlace(const QString& path) {
    if (!path.isEmpty() && m_hiddenPlaces.contains(path)) {
        m_hiddenPlaces.remove(path);
        saveHiddenPlaces();
        refresh();
        saveBookmarks();
    }
}

void PlacesModel::togglePlaceHidden(const QString& path) {
    if (isPlaceHidden(path)) {
        unhidePlace(path);
    } else {
        hidePlace(path);
    }
}

bool PlacesModel::isPlaceHidden(const QString& path) const {
    return m_hiddenPlaces.contains(path);
}

QStringList PlacesModel::hiddenPlaces() const {
    return QStringList(m_hiddenPlaces.begin(), m_hiddenPlaces.end());
}

void PlacesModel::setHiddenPlaces(const QStringList& list) {
    m_hiddenPlaces = QSet<QString>(list.begin(), list.end());
    saveHiddenPlaces();
    refresh();
    saveBookmarks();
}

QVariantList PlacesModel::allPlaces() const {
    QVariantList list;
    QString home = QDir::homePath();
    struct StdPlace { QString name; QString path; QString icon; bool isTrash; };
    QList<StdPlace> stdPlaces = {
        { tr("Home"), home, "home", false },
        { tr("Downloads"), QStandardPaths::writableLocation(QStandardPaths::DownloadLocation), "file_download", false },
        { tr("Documents"), QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation), "description", false },
        { tr("Desktop"), QStandardPaths::writableLocation(QStandardPaths::DesktopLocation), "desktop_windows", false },
        { tr("Pictures"), QStandardPaths::writableLocation(QStandardPaths::PicturesLocation), "image", false },
        { tr("Music"), QStandardPaths::writableLocation(QStandardPaths::MusicLocation), "music_note", false },
        { tr("Videos"), QStandardPaths::writableLocation(QStandardPaths::MoviesLocation), "video_library", false },
        { tr("Trash"), home + "/.local/share/Trash/files", "delete", true }
    };

    for (const auto& sp : stdPlaces) {
        if (!sp.path.isEmpty() && (QFile::exists(sp.path) || sp.isTrash)) {
            QVariantMap map;
            map["name"] = sp.name;
            map["path"] = sp.path;
            map["iconName"] = sp.icon;
            map["isCustom"] = false;
            map["isTrash"] = sp.isTrash;
            map["isHidden"] = m_hiddenPlaces.contains(sp.path) || (sp.isTrash && m_hiddenPlaces.contains("trash:"));
            list.append(map);
        }
    }

    for (const auto& p : m_places) {
        if (p.isCustom) {
            QVariantMap map;
            map["name"] = p.name;
            map["path"] = p.path;
            map["iconName"] = p.iconName;
            map["isCustom"] = true;
            map["isTrash"] = p.isTrash;
            map["isHidden"] = m_hiddenPlaces.contains(p.path);
            list.append(map);
        }
    }
    return list;
}

} // namespace prism::core

