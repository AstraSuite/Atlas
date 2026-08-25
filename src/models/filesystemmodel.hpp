#pragma once

#include <QAbstractListModel>
#include <QSet>
#include <QDateTime>
#include <QFileSystemWatcher>
#include <QList>
#include <QSharedPointer>
#include <QString>
#include <QStringList>
#include <atomic>
#include <qqmlintegration.h>

namespace atlas::models {

struct RawEntryData {
    QString name;
    QString path;
    bool isDir = false;
    bool isSymLink = false;
    QString symLinkTarget;
    qint64 size = 0;
    QString formattedSize;
    QString mimeType;
    QString mimeDescription;
    QDateTime lastModified;
    QString formattedDate;
    QString permissions;
    QString owner;
    QString group;
    QString suffix;
    bool isHidden = false;
    bool isReadOnly = false;
    bool isWritable = true;
    bool isImage = false;
    bool isAudio = false;
    bool isVideo = false;
    bool hasThumbnail = false;
    bool isText = false;
    QString originalPath;
    QString deletionTime;
    QDateTime deletionDateTime;
    bool isTrashItem = false;
};

class FileSystemEntry : public QObject {

    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString path READ path CONSTANT)
    Q_PROPERTY(bool isDir READ isDir CONSTANT)
    Q_PROPERTY(bool isSymLink READ isSymLink CONSTANT)
    Q_PROPERTY(QString symLinkTarget READ symLinkTarget CONSTANT)
    Q_PROPERTY(qint64 size READ size CONSTANT)
    Q_PROPERTY(QString formattedSize READ formattedSize CONSTANT)
    Q_PROPERTY(QString mimeType READ mimeType CONSTANT)
    Q_PROPERTY(QString mimeDescription READ mimeDescription CONSTANT)
    Q_PROPERTY(QDateTime lastModified READ lastModified CONSTANT)
    Q_PROPERTY(QString formattedDate READ formattedDate CONSTANT)
    Q_PROPERTY(QString permissions READ permissions CONSTANT)
    Q_PROPERTY(QString owner READ owner CONSTANT)
    Q_PROPERTY(QString group READ group CONSTANT)
    Q_PROPERTY(QString suffix READ suffix CONSTANT)
    Q_PROPERTY(bool isHidden READ isHidden CONSTANT)
    Q_PROPERTY(int depth READ depth NOTIFY treeChanged)
    Q_PROPERTY(bool expanded READ expanded NOTIFY treeChanged)
    Q_PROPERTY(bool isReadOnly READ isReadOnly CONSTANT)
    Q_PROPERTY(bool isWritable READ isWritable CONSTANT)
    Q_PROPERTY(bool isImage READ isImage CONSTANT)
    Q_PROPERTY(bool isAudio READ isAudio CONSTANT)
    Q_PROPERTY(bool isVideo READ isVideo CONSTANT)
    Q_PROPERTY(bool hasThumbnail READ hasThumbnail CONSTANT)
    Q_PROPERTY(bool isText READ isText CONSTANT)
    Q_PROPERTY(QString originalPath READ originalPath CONSTANT)
    Q_PROPERTY(QString deletionTime READ deletionTime CONSTANT)
    Q_PROPERTY(bool isTrashItem READ isTrashItem CONSTANT)

public:
    explicit FileSystemEntry(QObject* parent = nullptr) : QObject(parent) {}

    QString name() const { return m_name; }
    QString path() const { return m_path; }
    bool isDir() const { return m_isDir; }
    bool isSymLink() const { return m_isSymLink; }
    QString symLinkTarget() const { return m_symLinkTarget; }
    qint64 size() const { return m_size; }
    QString formattedSize() const { return m_formattedSize; }
    QString mimeType() const { return m_mimeType; }
    QString mimeDescription() const { return m_mimeDescription; }
    QDateTime lastModified() const { return m_lastModified; }
    QString formattedDate() const { return m_formattedDate; }
    QString permissions() const { return m_permissions; }
    QString owner() const { return m_owner; }
    QString group() const { return m_group; }
    QString suffix() const { return m_suffix; }
    bool isHidden() const { return m_isHidden; }
    int depth() const { return m_depth; }
    bool expanded() const { return m_expanded; }
    void setTreeState(int newDepth, bool isExpanded) {
        if (m_depth == newDepth && m_expanded == isExpanded)
            return;
        m_depth = newDepth;
        m_expanded = isExpanded;
        emit treeChanged();
    }

    bool isReadOnly() const { return m_isReadOnly; }
    bool isWritable() const { return m_isWritable; }
    bool isImage() const { return m_isImage; }
    bool isAudio() const { return m_isAudio; }
    bool isVideo() const { return m_isVideo; }
    bool hasThumbnail() const { return m_hasThumbnail; }
    bool isText() const { return m_isText; }
    QString originalPath() const { return m_originalPath; }
    QString deletionTime() const { return m_deletionTime; }
    QDateTime deletionDateTime() const { return m_deletionDateTime; }
    bool isTrashItem() const { return m_isTrashItem; }

    bool updateFromRaw(const RawEntryData& d);

    QString m_name;
    QString m_path;
    QString m_originalPath;
    QString m_deletionTime;
    QDateTime m_deletionDateTime;
    bool m_isTrashItem = false;
    bool m_isDir = false;
    bool m_isSymLink = false;
    QString m_symLinkTarget;
    qint64 m_size = 0;
    QString m_formattedSize;
    QString m_mimeType;
    QString m_mimeDescription;
    QDateTime m_lastModified;
    QString m_formattedDate;
    QString m_permissions;
    QString m_owner;
    QString m_group;
    QString m_suffix;
    bool m_isHidden = false;
    bool m_isReadOnly = false;
    bool m_isWritable = true;
    bool m_isImage = false;
    bool m_isAudio = false;
    bool m_isVideo = false;
    bool m_hasThumbnail = false;
    bool m_isText = false;
    int m_depth = 0;
    bool m_expanded = false;

signals:
    void treeChanged();
};

class FileSystemModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterTextChanged)
    Q_PROPERTY(QString searchQuery READ searchQuery WRITE setSearchQuery NOTIFY searchQueryChanged)
    Q_PROPERTY(bool isSearching READ isSearching NOTIFY isSearchingChanged)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
    Q_PROPERTY(QStringList nameFilters READ nameFilters WRITE setNameFilters NOTIFY nameFiltersChanged)
    Q_PROPERTY(bool showHidden READ showHidden WRITE setShowHidden NOTIFY showHiddenChanged)
    Q_PROPERTY(bool showDirsFirst READ showDirsFirst WRITE setShowDirsFirst NOTIFY showDirsFirstChanged)
    Q_PROPERTY(bool caseSensitiveSort READ caseSensitiveSort WRITE setCaseSensitiveSort NOTIFY caseSensitiveSortChanged)
    Q_PROPERTY(SortField sortField READ sortField WRITE setSortField NOTIFY sortFieldChanged)
    Q_PROPERTY(Qt::SortOrder sortOrder READ sortOrder WRITE setSortOrder NOTIFY sortOrderChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(QString directorySizeFormatted READ directorySizeFormatted NOTIFY directorySizeChanged)

public:
    enum SortField {
        SortByName,
        SortBySize,
        SortByDate,
        SortByType,
        SortByDeleted
    };
    Q_ENUM(SortField)

    enum Roles {
        EntryRole = Qt::UserRole + 1,
        NameRole,
        PathRole,
        IsDirRole,
        SizeRole,
        SizeFormattedRole,
        MimeTypeRole,
        MimeDescriptionRole,
        DateModifiedRole,
        DateModifiedFormattedRole,
        PermissionsRole,
        OwnerRole,
        IsImageRole,
        IsHiddenRole,
        DepthRole,
        ExpandedRole
    };
    Q_ENUM(Roles)

    explicit FileSystemModel(QObject* parent = nullptr);
    ~FileSystemModel() override;

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString path() const { return m_path; }
    void setPath(const QString& path);

    QString filterText() const { return m_filterText; }
    void setFilterText(const QString& text);

    QString searchQuery() const { return m_searchQuery; }
    void setSearchQuery(const QString& query);
    bool isSearching() const { return m_isSearching; }
    bool isLoading() const { return m_isLoading; }

    QStringList nameFilters() const { return m_nameFilters; }
    void setNameFilters(const QStringList& filters);

    bool showHidden() const { return m_showHidden; }
    void setShowHidden(bool show);

    bool showDirsFirst() const { return m_showDirsFirst; }
    void setShowDirsFirst(bool dirsFirst);

    bool caseSensitiveSort() const { return m_caseSensitiveSort; }
    void setCaseSensitiveSort(bool sensitive);

    SortField sortField() const { return m_sortField; }
    void setSortField(SortField field);

    Qt::SortOrder sortOrder() const { return m_sortOrder; }
    void setSortOrder(Qt::SortOrder order);

    int count() const { return static_cast<int>(m_filteredEntries.size()); }

    QString directorySizeFormatted() const { return m_directorySizeFormatted; }

    Q_INVOKABLE atlas::models::FileSystemEntry* get(int index) const;
    Q_INVOKABLE int indexOfPath(const QString& path) const;
    Q_INVOKABLE int findFirstIndexByPrefix(const QString& prefix, int startIndex = 0) const;
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void toggleExpanded(const QString& path);
    Q_INVOKABLE void collapseAll();
    Q_INVOKABLE bool isExpanded(const QString& path) const { return m_expandedPaths.contains(path); }
    [[nodiscard]] bool hasExpandedFolders() const { return !m_expandedPaths.isEmpty(); }

signals:
    void pathChanged();
    void filterTextChanged();
    void searchQueryChanged();
    void isSearchingChanged();
    void isLoadingChanged();
    void nameFiltersChanged();
    void showHiddenChanged();
    void showDirsFirstChanged();
    void caseSensitiveSortChanged();
    void sortFieldChanged();
    void sortOrderChanged();
    void countChanged();
    void directorySizeChanged();
    void fileModified(const QString& path);

private:
    void scanDirectory(bool isPathReset = false);
    void startDirectorySizeScan(const QString& path);
    void updateDirectoryGranular(const QList<RawEntryData>& rawData);
    void applyFilterAndSort();
    void performSearch(const QString& rootPath, const QString& query);
    QList<FileSystemEntry*> calculateFilteredAndSorted(const QList<FileSystemEntry*>& source);
    QList<FileSystemEntry*> filterAndSortOnly(const QList<FileSystemEntry*>& source) const;
    void appendWithChildren(FileSystemEntry* entry, int depth, QList<FileSystemEntry*>& out);
    QList<FileSystemEntry*> childrenOf(const QString& path);

    QString m_path;
    QString m_filterText;
    QString m_searchQuery;
    bool m_isSearching = false;
    bool m_isLoading = false;
    QSharedPointer<std::atomic<quint64>> m_scanGeneration = QSharedPointer<std::atomic<quint64>>::create(0);
    bool m_isPathReset = false;
    QStringList m_nameFilters;
    bool m_showHidden = false;
    bool m_showDirsFirst = true;
    bool m_caseSensitiveSort = false;
    SortField m_sortField = SortByName;
    Qt::SortOrder m_sortOrder = Qt::AscendingOrder;

    QList<FileSystemEntry*> m_rawEntries;
    QList<FileSystemEntry*> m_filteredEntries;
    QList<FileSystemEntry*> m_childEntries;
    QSet<QString> m_expandedPaths;
    QFileSystemWatcher m_watcher;
    QString m_directorySizeFormatted;
    quint64 m_sizeGeneration = 0;
};

} // namespace atlas::models

