#pragma once

#include <QAbstractListModel>
#include <QString>
#include <QVector>
#include <QStorageInfo>
#include <qqmlintegration.h>

namespace prism::core {

struct PlaceEntry {
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

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void addBookmark(const QString& path, const QString& name = "");
    Q_INVOKABLE void removeBookmark(int index);

private:
    void loadStandardPlaces();
    void loadStorageDevices();
    void loadBookmarks();
    void saveBookmarks();

    QVector<PlaceEntry> m_places;
};

} // namespace prism::core
