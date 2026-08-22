#include "filesystemmodel.hpp"
#include "../core/fileutils.hpp"

#include <QCollator>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QImageReader>
#include <QMimeDatabase>
#include <QtConcurrent>
#include <algorithm>

namespace prism::models {

FileSystemModel::FileSystemModel(QObject* parent)
    : QAbstractListModel(parent) {
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, [this]() {
        scanDirectory(false);
    });
}


FileSystemModel::~FileSystemModel() {
    qDeleteAll(m_rawEntries);
    m_rawEntries.clear();
    m_filteredEntries.clear();
}

int FileSystemModel::rowCount(const QModelIndex& parent) const {
    if (parent.isValid())
        return 0;
    return static_cast<int>(m_filteredEntries.size());
}

QVariant FileSystemModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_filteredEntries.size())
        return {};

    auto* entry = m_filteredEntries.at(index.row());
    switch (role) {
    case EntryRole: return QVariant::fromValue(entry);
    case NameRole: return entry->name();
    case PathRole: return entry->path();
    case IsDirRole: return entry->isDir();
    case SizeRole: return entry->size();
    case SizeFormattedRole: return entry->formattedSize();
    case MimeTypeRole: return entry->mimeType();
    case MimeDescriptionRole: return entry->mimeDescription();
    case DateModifiedRole: return entry->lastModified();
    case DateModifiedFormattedRole: return entry->formattedDate();
    case PermissionsRole: return entry->permissions();
    case OwnerRole: return entry->owner();
    case IsImageRole: return entry->isImage();
    case IsHiddenRole: return entry->isHidden();
    case Qt::DisplayRole: return entry->name();
    default:
        return {};
    }
}

QHash<int, QByteArray> FileSystemModel::roleNames() const {
    return {
        { EntryRole, "modelData" },
        { NameRole, "name" },
        { PathRole, "path" },
        { IsDirRole, "isDir" },
        { SizeRole, "size" },
        { SizeFormattedRole, "sizeFormatted" },
        { MimeTypeRole, "mimeType" },
        { MimeDescriptionRole, "mimeDescription" },
        { DateModifiedRole, "dateModified" },
        { DateModifiedFormattedRole, "dateModifiedFormatted" },
        { PermissionsRole, "permissions" },
        { OwnerRole, "owner" },
        { IsImageRole, "isImage" },
        { IsHiddenRole, "isHidden" }
    };
}

void FileSystemModel::setPath(const QString& path) {
    QString expanded = prism::core::FileUtils::expandPath(path);
    if (m_path != expanded) {
        m_path = expanded;
        emit pathChanged();
        scanDirectory(true);
    }
}


void FileSystemModel::setFilterText(const QString& text) {
    if (m_filterText != text) {
        m_filterText = text;
        emit filterTextChanged();
        applyFilterAndSort();
    }
}

void FileSystemModel::setSearchQuery(const QString& query) {
    if (m_searchQuery != query) {
        m_searchQuery = query;
        emit searchQueryChanged();
        if (m_searchQuery.trimmed().isEmpty()) {
            m_isSearching = false;
            emit isSearchingChanged();
            scanDirectory();
        } else {
            m_isSearching = true;
            emit isSearchingChanged();
            performSearch(m_path, m_searchQuery.trimmed());
        }
    }
}

void FileSystemModel::setNameFilters(const QStringList& filters) {
    if (m_nameFilters != filters) {
        m_nameFilters = filters;
        emit nameFiltersChanged();
        applyFilterAndSort();
    }
}

void FileSystemModel::setShowHidden(bool show) {
    if (m_showHidden != show) {
        m_showHidden = show;
        emit showHiddenChanged();
        applyFilterAndSort();
    }
}

void FileSystemModel::setShowDirsFirst(bool dirsFirst) {
    if (m_showDirsFirst != dirsFirst) {
        m_showDirsFirst = dirsFirst;
        emit showDirsFirstChanged();
        applyFilterAndSort();
    }
}

void FileSystemModel::setSortField(SortField field) {
    if (m_sortField != field) {
        m_sortField = field;
        emit sortFieldChanged();
        applyFilterAndSort();
    }
}

void FileSystemModel::setSortOrder(Qt::SortOrder order) {
    if (m_sortOrder != order) {
        m_sortOrder = order;
        emit sortOrderChanged();
        applyFilterAndSort();
    }
}

FileSystemEntry* FileSystemModel::get(int index) const {
    if (index >= 0 && index < m_filteredEntries.size())
        return m_filteredEntries.at(index);
    return nullptr;
}

int FileSystemModel::indexOfPath(const QString& path) const {
    for (int i = 0; i < m_filteredEntries.size(); ++i) {
        if (m_filteredEntries.at(i)->path() == path)
            return i;
    }
    return -1;
}

void FileSystemModel::refresh() {
    scanDirectory();
}

static RawEntryData createRawDataFromInfo(const QFileInfo& fi, const QMimeDatabase& mimeDb) {
    RawEntryData d;
    d.name = fi.fileName();
    d.path = fi.absoluteFilePath();
    d.isDir = fi.isDir();
    d.isSymLink = fi.isSymLink();
    d.symLinkTarget = fi.symLinkTarget();
    d.size = fi.isDir() ? 0 : fi.size();
    d.formattedSize = fi.isDir() ? QString() : prism::core::FileUtils::formatSize(d.size);
    d.suffix = fi.suffix();
    d.isHidden = fi.isHidden() || d.name.startsWith('.');
    d.isWritable = fi.isWritable();
    d.isReadOnly = !d.isWritable;
    d.lastModified = fi.lastModified();
    d.formattedDate = d.lastModified.toString("yyyy-MM-dd hh:mm");
    d.owner = fi.owner();
    d.group = fi.group();

    auto perms = fi.permissions();
    QString pStr;
    pStr += (perms & QFile::ReadUser) ? 'r' : '-';
    pStr += (perms & QFile::WriteUser) ? 'w' : '-';
    pStr += (perms & QFile::ExeUser) ? 'x' : '-';
    pStr += (perms & QFile::ReadGroup) ? 'r' : '-';
    pStr += (perms & QFile::WriteGroup) ? 'w' : '-';
    pStr += (perms & QFile::ExeGroup) ? 'x' : '-';
    pStr += (perms & QFile::ReadOther) ? 'r' : '-';
    pStr += (perms & QFile::WriteOther) ? 'w' : '-';
    pStr += (perms & QFile::ExeOther) ? 'x' : '-';
    d.permissions = pStr;

    QMimeType mime = mimeDb.mimeTypeForFile(fi);
    d.mimeType = mime.name();
    d.mimeDescription = mime.comment();

    if (d.mimeType.startsWith("image/")) {
        d.isImage = true;
    } else if (d.mimeType.startsWith("audio/")) {
        d.isAudio = true;
    } else if (d.mimeType.startsWith("video/")) {
        d.isVideo = true;
    } else if (d.mimeType.startsWith("text/") || d.mimeType.contains("json") || d.mimeType.contains("xml")) {
        d.isText = true;
    }

    if (fi.absolutePath().contains("/.local/share/Trash/files") || fi.absolutePath().contains("/Trash/files")) {
        d.isTrashItem = true;
        QString infoPath = QDir::homePath() + "/.local/share/Trash/info/" + fi.fileName() + ".trashinfo";
        QFile infoFile(infoPath);
        if (infoFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            while (!infoFile.atEnd()) {
                QString line = QString::fromUtf8(infoFile.readLine()).trimmed();
                if (line.startsWith("Path=")) {
                    d.originalPath = line.mid(5);
                } else if (line.startsWith("DeletionDate=")) {
                    QString dStr = line.mid(13);
                    QDateTime dt = QDateTime::fromString(dStr, Qt::ISODate);
                    if (dt.isValid()) {
                        d.deletionTime = dt.toString("M/d/yy 'at' h:mm AP");
                    } else {
                        d.deletionTime = dStr;
                    }
                }
            }
        }
    }

    return d;
}

bool FileSystemEntry::updateFromRaw(const RawEntryData& d) {
    bool changed = false;
    if (m_name != d.name) { m_name = d.name; changed = true; }
    if (m_path != d.path) { m_path = d.path; changed = true; }
    if (m_isDir != d.isDir) { m_isDir = d.isDir; changed = true; }
    if (m_isSymLink != d.isSymLink) { m_isSymLink = d.isSymLink; changed = true; }
    if (m_symLinkTarget != d.symLinkTarget) { m_symLinkTarget = d.symLinkTarget; changed = true; }
    if (m_size != d.size) { m_size = d.size; changed = true; }
    if (m_formattedSize != d.formattedSize) { m_formattedSize = d.formattedSize; changed = true; }
    if (m_suffix != d.suffix) { m_suffix = d.suffix; changed = true; }
    if (m_isHidden != d.isHidden) { m_isHidden = d.isHidden; changed = true; }
    if (m_isReadOnly != d.isReadOnly) { m_isReadOnly = d.isReadOnly; changed = true; }
    if (m_isWritable != d.isWritable) { m_isWritable = d.isWritable; changed = true; }
    if (m_lastModified != d.lastModified) { m_lastModified = d.lastModified; changed = true; }
    if (m_formattedDate != d.formattedDate) { m_formattedDate = d.formattedDate; changed = true; }
    if (m_owner != d.owner) { m_owner = d.owner; changed = true; }
    if (m_group != d.group) { m_group = d.group; changed = true; }
    if (m_permissions != d.permissions) { m_permissions = d.permissions; changed = true; }
    if (m_mimeType != d.mimeType) { m_mimeType = d.mimeType; changed = true; }
    if (m_mimeDescription != d.mimeDescription) { m_mimeDescription = d.mimeDescription; changed = true; }
    if (m_isImage != d.isImage) { m_isImage = d.isImage; changed = true; }
    if (m_isAudio != d.isAudio) { m_isAudio = d.isAudio; changed = true; }
    if (m_isVideo != d.isVideo) { m_isVideo = d.isVideo; changed = true; }
    if (m_isText != d.isText) { m_isText = d.isText; changed = true; }
    if (m_originalPath != d.originalPath) { m_originalPath = d.originalPath; changed = true; }
    if (m_deletionTime != d.deletionTime) { m_deletionTime = d.deletionTime; changed = true; }
    if (m_isTrashItem != d.isTrashItem) { m_isTrashItem = d.isTrashItem; changed = true; }
    return changed;
}

static FileSystemEntry* createEntryFromRawData(const RawEntryData& d, QObject* parent) {
    auto* entry = new FileSystemEntry(parent);
    entry->m_name = d.name;
    entry->m_path = d.path;
    entry->m_isDir = d.isDir;
    entry->m_isSymLink = d.isSymLink;
    entry->m_symLinkTarget = d.symLinkTarget;
    entry->m_size = d.size;
    entry->m_formattedSize = d.formattedSize;
    entry->m_suffix = d.suffix;
    entry->m_isHidden = d.isHidden;
    entry->m_isReadOnly = d.isReadOnly;
    entry->m_isWritable = d.isWritable;
    entry->m_lastModified = d.lastModified;
    entry->m_formattedDate = d.formattedDate;
    entry->m_owner = d.owner;
    entry->m_group = d.group;
    entry->m_permissions = d.permissions;
    entry->m_mimeType = d.mimeType;
    entry->m_mimeDescription = d.mimeDescription;
    entry->m_isImage = d.isImage;
    entry->m_isAudio = d.isAudio;
    entry->m_isVideo = d.isVideo;
    entry->m_isText = d.isText;
    entry->m_originalPath = d.originalPath;
    entry->m_deletionTime = d.deletionTime;
    entry->m_isTrashItem = d.isTrashItem;
    return entry;
}

void FileSystemModel::scanDirectory(bool isPathReset) {
    if (!m_watcher.directories().isEmpty())
        m_watcher.removePaths(m_watcher.directories());

    if (m_path.isEmpty() || !QDir(m_path).exists()) {
        if (m_isLoading) {
            m_isLoading = false;
            emit isLoadingChanged();
        }

        beginResetModel();
        qDeleteAll(m_rawEntries);
        m_rawEntries.clear();
        m_filteredEntries.clear();
        endResetModel();
        emit countChanged();
        return;
    }

    m_watcher.addPath(m_path);
    QString scanPath = m_path;

    if (isPathReset && !m_isLoading) {
        m_isLoading = true;
        emit isLoadingChanged();
    }

    (void)QtConcurrent::run([this, scanPath, isPathReset]() {
        QDir dir(scanPath);
        QFileInfoList list = dir.entryInfoList(QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System);
        QMimeDatabase mimeDb;

        QList<RawEntryData> rawData;
        rawData.reserve(list.size());
        for (const auto& fi : list) {
            rawData.append(createRawDataFromInfo(fi, mimeDb));
        }

        QMetaObject::invokeMethod(this, [this, rawData, scanPath, isPathReset]() {
            if (m_path != scanPath)
                return;

            if (m_isLoading) {
                m_isLoading = false;
                emit isLoadingChanged();
            }

            if (isPathReset || m_rawEntries.isEmpty()) {
                beginResetModel();
                qDeleteAll(m_rawEntries);
                m_rawEntries.clear();
                m_rawEntries.reserve(rawData.size());

                for (const auto& d : rawData) {
                    m_rawEntries.append(createEntryFromRawData(d, this));
                }

                m_filteredEntries = calculateFilteredAndSorted(m_rawEntries);
                endResetModel();
                emit countChanged();
            } else {
                updateDirectoryGranular(rawData);
            }
        });
    });
}

void FileSystemModel::updateDirectoryGranular(const QList<RawEntryData>& rawData) {
    QList<QString> modifiedPaths;
    QHash<QString, FileSystemEntry*> existingMap;
    for (auto* e : m_rawEntries) {
        existingMap.insert(e->path(), e);
    }

    QHash<QString, RawEntryData> newMap;
    for (const auto& d : rawData) {
        newMap.insert(d.path, d);
    }

    // Update existing entries or add new ones
    for (const auto& d : rawData) {
        auto it = existingMap.find(d.path);
        if (it != existingMap.end()) {
            FileSystemEntry* entry = it.value();
            if (entry->updateFromRaw(d)) {
                modifiedPaths.append(d.path);
            }
        } else {
            auto* newEntry = createEntryFromRawData(d, this);
            m_rawEntries.append(newEntry);
            modifiedPaths.append(d.path);
        }
    }

    // Remove deleted entries from raw list
    for (int i = static_cast<int>(m_rawEntries.size()) - 1; i >= 0; --i) {
        auto* e = m_rawEntries.at(i);
        if (!newMap.contains(e->path())) {
            m_rawEntries.removeAt(i);
            delete e;
        }
    }

    // Compute target filtered and sorted list
    QList<FileSystemEntry*> targetEntries = calculateFilteredAndSorted(m_rawEntries);

    // Granularly sync m_filteredEntries
    // Remove entries no longer in targetEntries
    for (int i = static_cast<int>(m_filteredEntries.size()) - 1; i >= 0; --i) {
        if (!targetEntries.contains(m_filteredEntries.at(i))) {
            beginRemoveRows(QModelIndex(), i, i);
            m_filteredEntries.removeAt(i);
            endRemoveRows();
        }
    }

    // Step B: Insert newly added entries
    for (int i = 0; i < targetEntries.size(); ++i) {
        auto* target = targetEntries.at(i);
        if (!m_filteredEntries.contains(target)) {
            int insertPos = std::min(i, static_cast<int>(m_filteredEntries.size()));
            beginInsertRows(QModelIndex(), insertPos, insertPos);
            m_filteredEntries.insert(insertPos, target);
            endInsertRows();
        }
    }

    // Step C: Move misplaced entries to match target sorted order
    for (int i = 0; i < targetEntries.size(); ++i) {
        auto* target = targetEntries.at(i);
        int currentPos = static_cast<int>(m_filteredEntries.indexOf(target));
        if (currentPos != -1 && currentPos != i) {
            int dest = (i > currentPos) ? i + 1 : i;
            if (beginMoveRows(QModelIndex(), currentPos, currentPos, QModelIndex(), dest)) {
                m_filteredEntries.move(currentPos, i);
                endMoveRows();
                if (!modifiedPaths.contains(target->path())) {
                    modifiedPaths.append(target->path());
                }
            }
        }
    }

    // Step D: Notify dataChanged & fileModified for modified items
    for (const auto& path : modifiedPaths) {
        int idx = indexOfPath(path);
        if (idx >= 0) {
            emit dataChanged(index(idx, 0), index(idx, 0));
            emit fileModified(path);
        }
    }

    emit countChanged();
}

void FileSystemModel::performSearch(const QString& rootPath, const QString& query) {
    (void)QtConcurrent::run([this, rootPath, query]() {
        QDirIterator it(rootPath, QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden, QDirIterator::Subdirectories);
        QMimeDatabase mimeDb;
        QList<RawEntryData> foundRawData;

        QString lowerQuery = query.toLower();
        int maxResults = 500;

        while (it.hasNext() && foundRawData.size() < maxResults) {
            it.next();
            QFileInfo fi = it.fileInfo();
            if (fi.fileName().toLower().contains(lowerQuery)) {
                foundRawData.append(createRawDataFromInfo(fi, mimeDb));
            }
        }

        QMetaObject::invokeMethod(this, [this, foundRawData, query]() {
            if (m_searchQuery != query)
                return;

            beginResetModel();
            qDeleteAll(m_rawEntries);
            m_rawEntries.clear();
            m_rawEntries.reserve(foundRawData.size());

            for (const auto& d : foundRawData) {
                m_rawEntries.append(createEntryFromRawData(d, this));
            }

            m_filteredEntries = calculateFilteredAndSorted(m_rawEntries);
            endResetModel();
            emit countChanged();
        });
    });
}

QList<FileSystemEntry*> FileSystemModel::calculateFilteredAndSorted(const QList<FileSystemEntry*>& source) {
    QList<FileSystemEntry*> result;
    QString lowerFilter = m_filterText.toLower();

    for (auto* e : source) {
        if (!m_showHidden && e->isHidden())
            continue;

        if (!lowerFilter.isEmpty() && !e->name().toLower().contains(lowerFilter))
            continue;

        if (!m_nameFilters.isEmpty() && !m_nameFilters.contains("*") && !e->isDir()) {
            bool matches = false;
            for (const QString& f : m_nameFilters) {
                if (f == "*" || f == "*.*" || f.toLower() == e->suffix().toLower()) {
                    matches = true;
                    break;
                }
            }
            if (!matches)
                continue;
        }

        result.append(e);
    }

    QCollator collator;
    collator.setCaseSensitivity(Qt::CaseInsensitive);
    collator.setNumericMode(true);

    auto comparator = [&](FileSystemEntry* a, FileSystemEntry* b) -> bool {
        if (m_showDirsFirst && a->isDir() != b->isDir()) {
            return a->isDir();
        }

        int res = 0;
        switch (m_sortField) {
        case SortByName:
            res = collator.compare(a->name(), b->name());
            break;
        case SortBySize:
            if (a->size() < b->size()) res = -1;
            else if (a->size() > b->size()) res = 1;
            else res = collator.compare(a->name(), b->name());
            break;
        case SortByDate:
            if (a->lastModified() < b->lastModified()) res = -1;
            else if (a->lastModified() > b->lastModified()) res = 1;
            else res = collator.compare(a->name(), b->name());
            break;
        case SortByType:
            res = collator.compare(a->mimeDescription(), b->mimeDescription());
            if (res == 0) res = collator.compare(a->name(), b->name());
            break;
        }

        return (m_sortOrder == Qt::AscendingOrder) ? (res < 0) : (res > 0);
    };

    std::sort(result.begin(), result.end(), comparator);
    return result;
}

void FileSystemModel::applyFilterAndSort() {
    beginResetModel();
    m_filteredEntries = calculateFilteredAndSorted(m_rawEntries);
    endResetModel();
    emit countChanged();
}

} // namespace prism::models

