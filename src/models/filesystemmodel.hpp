#pragma once

#include <QAbstractListModel>
#include <QDateTime>
#include <QFileSystemWatcher>
#include <QList>
#include <QString>
#include <QStringList>
#include <qqmlintegration.h>

namespace prism::models {

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
    bool isText = false;
    QString originalPath;
    QString deletionTime;
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
    Q_PROPERTY(bool isReadOnly READ isReadOnly CONSTANT)
    Q_PROPERTY(bool isWritable READ isWritable CONSTANT)
    Q_PROPERTY(bool isImage READ isImage CONSTANT)
    Q_PROPERTY(bool isAudio READ isAudio CONSTANT)
    Q_PROPERTY(bool isVideo READ isVideo CONSTANT)
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
    bool isReadOnly() const { return m_isReadOnly; }
    bool isWritable() const { return m_isWritable; }
    bool isImage() const { return m_isImage; }
    bool isAudio() const { return m_isAudio; }
    bool isVideo() const { return m_isVideo; }
    bool isText() const { return m_isText; }
    QString originalPath() const { return m_originalPath; }
    QString deletionTime() const { return m_deletionTime; }
    bool isTrashItem() const { return m_isTrashItem; }

    bool updateFromRaw(const RawEntryData& d);

    QString m_name;
    QString m_path;
    QString m_originalPath;
    QString m_deletionTime;
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
    bool m_isText = false;
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
    Q_PROPERTY(SortField sortField READ sortField WRITE setSortField NOTIFY sortFieldChanged)
    Q_PROPERTY(Qt::SortOrder sortOrder READ sortOrder WRITE setSortOrder NOTIFY sortOrderChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum SortField {
        SortByName,
        SortBySize,
        SortByDate,
        SortByType
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
        IsHiddenRole
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

    SortField sortField() const { return m_sortField; }
    void setSortField(SortField field);

    Qt::SortOrder sortOrder() const { return m_sortOrder; }
    void setSortOrder(Qt::SortOrder order);

    int count() const { return static_cast<int>(m_filteredEntries.size()); }

    Q_INVOKABLE prism::models::FileSystemEntry* get(int index) const;
    Q_INVOKABLE int indexOfPath(const QString& path) const;
    Q_INVOKABLE void refresh();

signals:
    void pathChanged();
    void filterTextChanged();
    void searchQueryChanged();
    void isSearchingChanged();
    void isLoadingChanged();
    void nameFiltersChanged();
    void showHiddenChanged();
    void showDirsFirstChanged();
    void sortFieldChanged();
    void sortOrderChanged();
    void countChanged();
    void fileModified(const QString& path);

private:
    void scanDirectory(bool isPathReset = false);
    void updateDirectoryGranular(const QList<RawEntryData>& rawData);
    void applyFilterAndSort();
    void performSearch(const QString& rootPath, const QString& query);
    QList<FileSystemEntry*> calculateFilteredAndSorted(const QList<FileSystemEntry*>& source);

    QString m_path;
    QString m_filterText;
    QString m_searchQuery;
    bool m_isSearching = false;
    bool m_isLoading = false;
    bool m_isPathReset = false;
    QStringList m_nameFilters;
    bool m_showHidden = false;
    bool m_showDirsFirst = true;
    SortField m_sortField = SortByName;
    Qt::SortOrder m_sortOrder = Qt::AscendingOrder;

    QList<FileSystemEntry*> m_rawEntries;
    QList<FileSystemEntry*> m_filteredEntries;
    QFileSystemWatcher m_watcher;
};

} // namespace prism::models

