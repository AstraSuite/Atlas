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
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &FileSystemModel::scanDirectory);
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
    if (m_path != path) {
        m_path = path;
        emit pathChanged();
        scanDirectory();
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

static FileSystemEntry* createEntryFromInfo(const QFileInfo& fi, const QMimeDatabase& mimeDb, QObject* parent) {
    auto* entry = new FileSystemEntry(parent);
    entry->m_name = fi.fileName();
    entry->m_path = fi.absoluteFilePath();
    entry->m_isDir = fi.isDir();
    entry->m_isSymLink = fi.isSymLink();
    entry->m_symLinkTarget = fi.symLinkTarget();
    entry->m_size = fi.isDir() ? 0 : fi.size();
    entry->m_formattedSize = fi.isDir() ? QString() : prism::core::FileUtils::formatSize(entry->m_size);
    entry->m_suffix = fi.suffix();
    entry->m_isHidden = fi.isHidden() || entry->m_name.startsWith('.');
    entry->m_lastModified = fi.lastModified();
    entry->m_formattedDate = entry->m_lastModified.toString("yyyy-MM-dd hh:mm");
    entry->m_owner = fi.owner();
    entry->m_group = fi.group();

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
    entry->m_permissions = pStr;

    QMimeType mime = mimeDb.mimeTypeForFile(fi);
    entry->m_mimeType = mime.name();
    entry->m_mimeDescription = mime.comment();

    if (entry->m_mimeType.startsWith("image/")) {
        entry->m_isImage = true;
    } else if (entry->m_mimeType.startsWith("audio/")) {
        entry->m_isAudio = true;
    } else if (entry->m_mimeType.startsWith("video/")) {
        entry->m_isVideo = true;
    } else if (entry->m_mimeType.startsWith("text/") || entry->m_mimeType.contains("json") || entry->m_mimeType.contains("xml")) {
        entry->m_isText = true;
    }

    return entry;
}

void FileSystemModel::scanDirectory() {
    if (!m_watcher.directories().isEmpty())
        m_watcher.removePaths(m_watcher.directories());

    if (m_path.isEmpty() || !QDir(m_path).exists()) {
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

    (void)QtConcurrent::run([this, scanPath]() {
        QDir dir(scanPath);
        QFileInfoList list = dir.entryInfoList(QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System);
        QMimeDatabase mimeDb;

        QList<FileSystemEntry*> entries;
        entries.reserve(list.size());
        for (const auto& fi : list) {
            entries.append(createEntryFromInfo(fi, mimeDb, nullptr));
        }

        QMetaObject::invokeMethod(this, [this, entries, scanPath]() {
            if (m_path != scanPath) {
                qDeleteAll(entries);
                return;
            }

            beginResetModel();
            qDeleteAll(m_rawEntries);
            m_rawEntries = entries;
            for (auto* e : m_rawEntries) e->setParent(this);
            endResetModel();

            applyFilterAndSort();
        });
    });
}

void FileSystemModel::performSearch(const QString& rootPath, const QString& query) {
    (void)QtConcurrent::run([this, rootPath, query]() {
        QDirIterator it(rootPath, QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden, QDirIterator::Subdirectories);
        QMimeDatabase mimeDb;
        QList<FileSystemEntry*> foundEntries;

        QString lowerQuery = query.toLower();
        int maxResults = 500;

        while (it.hasNext() && foundEntries.size() < maxResults) {
            it.next();
            QFileInfo fi = it.fileInfo();
            if (fi.fileName().toLower().contains(lowerQuery)) {
                foundEntries.append(createEntryFromInfo(fi, mimeDb, nullptr));
            }
        }

        QMetaObject::invokeMethod(this, [this, foundEntries, query]() {
            if (m_searchQuery != query) {
                qDeleteAll(foundEntries);
                return;
            }

            beginResetModel();
            qDeleteAll(m_rawEntries);
            m_rawEntries = foundEntries;
            for (auto* e : m_rawEntries) e->setParent(this);
            endResetModel();

            applyFilterAndSort();
        });
    });
}

void FileSystemModel::applyFilterAndSort() {
    beginResetModel();
    m_filteredEntries.clear();

    QString lowerFilter = m_filterText.toLower();

    for (auto* e : m_rawEntries) {
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

        m_filteredEntries.append(e);
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

    std::sort(m_filteredEntries.begin(), m_filteredEntries.end(), comparator);

    endResetModel();
    emit countChanged();
}

} // namespace prism::models
