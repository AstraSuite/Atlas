#pragma once

#include <QAbstractListModel>
#include <QObject>
#include <QString>
#include <QVector>
#include <QQmlEngine>
#include <QJSEngine>
#include <qqmlintegration.h>

namespace prism::core {

struct PlaceItem {
    QString name;
    QString path;
    QString iconName;
    bool isDevice = false;
    bool isRemovable = false;
    bool isTrash = false;
    bool isCustom = false;
    qint64 bytesFree = 0;
    qint64 bytesTotal = 0;
};

class PlacesModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum PlaceRoles {
        NameRole = Qt::UserRole + 1,
        PathRole,
        IconNameRole,
        IsDeviceRole,
        IsRemovableRole,
        IsTrashRole,
        IsCustomRole,
        BytesFreeRole,
        BytesTotalRole,
        FreeSpaceFormattedRole
    };
    Q_ENUM(PlaceRoles)

    explicit PlacesModel(QObject* parent = nullptr);
    ~PlacesModel() override = default;

    static PlacesModel* instance();
    static PlacesModel* create(QQmlEngine* = nullptr, QJSEngine* = nullptr) {
        return instance();
    }

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return static_cast<int>(m_places.size()); }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void addBookmark(const QString& path, const QString& name = QString(), const QString& icon = QString());
    Q_INVOKABLE void addCustomPlace(const QString& name, const QString& path, const QString& icon = QString());
    Q_INVOKABLE void movePlace(int fromIndex, int toIndex);
    Q_INVOKABLE void removeBookmark(int index);
    Q_INVOKABLE void removePlace(int index) { removeBookmark(index); }
    Q_INVOKABLE void removeBookmarkByPath(const QString& path);
    Q_INVOKABLE void removePlaceByPath(const QString& path) { removeBookmarkByPath(path); }
    Q_INVOKABLE void updatePlace(int index, const QString& name, const QString& iconName);
    Q_INVOKABLE bool isBookmarked(const QString& path) const;
    Q_INVOKABLE void toggleBookmark(const QString& path);
    Q_INVOKABLE void restoreDefaultPlaces();
    Q_INVOKABLE void hidePlace(const QString& path);
    Q_INVOKABLE void unhidePlace(const QString& path);
    Q_INVOKABLE void togglePlaceHidden(const QString& path);
    Q_INVOKABLE bool isPlaceHidden(const QString& path) const;
    Q_INVOKABLE QStringList hiddenPlaces() const;
    Q_INVOKABLE void setHiddenPlaces(const QStringList& list);
    Q_INVOKABLE QVariantList allPlaces() const;


signals:
    void countChanged();

private:
    void loadHiddenPlaces();
    void saveHiddenPlaces();
    void loadStandardPlaces();
    void loadBookmarks();
    void saveBookmarks();

    QVector<PlaceItem> m_places;
    QSet<QString> m_hiddenPlaces;
    bool m_isSaving = false;
};

} // namespace prism::core

