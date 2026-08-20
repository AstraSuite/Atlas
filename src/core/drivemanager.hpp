#pragma once

#include <QAbstractListModel>
#include <QFileSystemWatcher>
#include <QObject>
#include <QProcess>
#include <QString>
#include <QVector>
#include <qqmlintegration.h>

namespace prism::core {

struct DriveItem {
    QString name;
    QString devicePath;
    QString mountPoint;
    QString sizeFormatted;
    QString fsType;
    QString model;
    bool isMounted = false;
    bool isRemovable = false;
    qint64 bytesFree = 0;
    qint64 bytesTotal = 0;
};

class DriveManager : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum DriveRoles {
        NameRole = Qt::UserRole + 1,
        DevicePathRole,
        MountPointRole,
        SizeFormattedRole,
        FsTypeRole,
        ModelRole,
        IsMountedRole,
        IsRemovableRole,
        BytesFreeRole,
        BytesTotalRole,
        FreeSpaceFormattedRole
    };
    Q_ENUM(DriveRoles)

    explicit DriveManager(QObject* parent = nullptr);
    ~DriveManager() override = default;

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return static_cast<int>(m_drives.size()); }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void mountDevice(const QString& devicePath, int tabIndex = 0);
    Q_INVOKABLE void unmountDevice(const QString& devicePath);

signals:
    void countChanged();
    void deviceMounted(const QString& mountPoint, int tabIndex);
    void deviceUnmounted(const QString& devicePath);
    void operationFailed(const QString& error);

private:
    void scanDrives();
    QVector<DriveItem> m_drives;
    QFileSystemWatcher m_mountWatcher;
};

} // namespace prism::core
