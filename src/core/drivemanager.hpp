#pragma once

#include <QAbstractListModel>
#include <QFileSystemWatcher>
#include <QObject>
#include <QProcess>
#include <QString>
#include <QVector>
#include <qqmlintegration.h>

namespace atlas::core {

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
    Q_PROPERTY(bool showHiddenDevices READ showHiddenDevices WRITE setShowHiddenDevices NOTIFY showHiddenDevicesChanged)

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
        FreeSpaceFormattedRole,
        IsHiddenRole
    };
    Q_ENUM(DriveRoles)

    explicit DriveManager(QObject* parent = nullptr);
    ~DriveManager() override = default;

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return static_cast<int>(m_drives.size()); }

    [[nodiscard]] bool showHiddenDevices() const { return m_showHiddenDevices; }
    void setShowHiddenDevices(bool show);

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void mountDevice(const QString& devicePath, int tabIndex = 0);
    Q_INVOKABLE void unmountDevice(const QString& devicePath);
    Q_INVOKABLE void ejectDevice(const QString& devicePath);

    Q_INVOKABLE void hideDevice(const QString& devicePath);
    Q_INVOKABLE void unhideDevice(const QString& devicePath);
    Q_INVOKABLE void toggleDeviceHidden(const QString& devicePath);
    Q_INVOKABLE bool isDeviceHidden(const QString& devicePath, const QString& name = QString()) const;
    Q_INVOKABLE QStringList hiddenDevices() const { return m_hiddenDevices; }
    Q_INVOKABLE void setHiddenDevices(const QStringList& list);
    Q_INVOKABLE QVariantList allDevices() const;

signals:
    void countChanged();
    void showHiddenDevicesChanged();
    void deviceMounted(const QString& mountPoint, int tabIndex);
    void deviceUnmounted(const QString& devicePath);
    void operationFailed(const QString& error);

private:
    void applyDeviceFilters();
    void loadHiddenDevices();
    void saveHiddenDevices();

    QVector<DriveItem> m_allDrives;
    QVector<DriveItem> m_drives;
    QStringList m_hiddenDevices;
    bool m_showHiddenDevices = false;
    QFileSystemWatcher m_mountWatcher;
};

} // namespace atlas::core
