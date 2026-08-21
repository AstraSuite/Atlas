#include "drivemanager.hpp"
#include "fileutils.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QStorageInfo>
#include <QSettings>
#include <QtConcurrent>

namespace prism::core {

DriveManager::DriveManager(QObject* parent)
    : QAbstractListModel(parent) {
    loadHiddenDevices();
    if (QFile::exists("/proc/mounts")) {
        m_mountWatcher.addPath("/proc/mounts");
        connect(&m_mountWatcher, &QFileSystemWatcher::fileChanged, this, &DriveManager::refresh);
    }
    refresh();
}

int DriveManager::rowCount(const QModelIndex& parent) const {
    if (parent.isValid()) return 0;
    return static_cast<int>(m_drives.size());
}

QVariant DriveManager::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_drives.size())
        return {};

    const auto& d = m_drives.at(index.row());
    switch (role) {
    case NameRole: return d.name;
    case DevicePathRole: return d.devicePath;
    case MountPointRole: return d.mountPoint;
    case SizeFormattedRole: return d.sizeFormatted;
    case FsTypeRole: return d.fsType;
    case ModelRole: return d.model;
    case IsMountedRole: return d.isMounted;
    case IsRemovableRole: return d.isRemovable;
    case BytesFreeRole: return d.bytesFree;
    case BytesTotalRole: return d.bytesTotal;
    case FreeSpaceFormattedRole: {
        if (d.bytesTotal > 0) {
            return QString("%1 free of %2").arg(FileUtils::formatSize(d.bytesFree), FileUtils::formatSize(d.bytesTotal));
        }
        return d.sizeFormatted;
    }
    case IsHiddenRole: return isDeviceHidden(d.devicePath, d.name);
    case Qt::DisplayRole: return d.name;
    default: return {};
    }
}

QHash<int, QByteArray> DriveManager::roleNames() const {
    return {
        { NameRole, "name" },
        { DevicePathRole, "devicePath" },
        { MountPointRole, "mountPoint" },
        { SizeFormattedRole, "sizeFormatted" },
        { FsTypeRole, "fsType" },
        { ModelRole, "model" },
        { IsMountedRole, "isMounted" },
        { IsRemovableRole, "isRemovable" },
        { BytesFreeRole, "bytesFree" },
        { BytesTotalRole, "bytesTotal" },
        { FreeSpaceFormattedRole, "freeSpaceFormatted" },
        { IsHiddenRole, "isHidden" }
    };
}

void DriveManager::loadHiddenDevices() {
    QSettings settings("prism", "prism");
    m_hiddenDevices = settings.value("devices/hiddenDevices").toStringList();
}

void DriveManager::saveHiddenDevices() {
    QSettings settings("prism", "prism");
    settings.setValue("devices/hiddenDevices", m_hiddenDevices);
}

void DriveManager::setShowHiddenDevices(bool show) {
    if (m_showHiddenDevices != show) {
        m_showHiddenDevices = show;
        applyDeviceFilters();
        emit showHiddenDevicesChanged();
    }
}

void DriveManager::hideDevice(const QString& devicePath) {
    if (!devicePath.isEmpty() && !m_hiddenDevices.contains(devicePath)) {
        m_hiddenDevices.append(devicePath);
        saveHiddenDevices();
        applyDeviceFilters();
    }
}

void DriveManager::unhideDevice(const QString& devicePath) {
    if (!devicePath.isEmpty() && m_hiddenDevices.contains(devicePath)) {
        m_hiddenDevices.removeAll(devicePath);
        saveHiddenDevices();
        applyDeviceFilters();
    }
}

void DriveManager::toggleDeviceHidden(const QString& devicePath) {
    if (isDeviceHidden(devicePath)) {
        unhideDevice(devicePath);
    } else {
        hideDevice(devicePath);
    }
}

bool DriveManager::isDeviceHidden(const QString& devicePath, const QString& name) const {
    if (m_hiddenDevices.contains(devicePath)) return true;
    if (!name.isEmpty() && m_hiddenDevices.contains(name)) return true;
    return false;
}

void DriveManager::setHiddenDevices(const QStringList& list) {
    m_hiddenDevices = list;
    saveHiddenDevices();
    applyDeviceFilters();
}

QVariantList DriveManager::allDevices() const {
    QVariantList list;
    for (const auto& d : m_allDrives) {
        QVariantMap map;
        map["name"] = d.name;
        map["devicePath"] = d.devicePath;
        map["mountPoint"] = d.mountPoint;
        map["sizeFormatted"] = d.sizeFormatted;
        map["fsType"] = d.fsType;
        map["model"] = d.model;
        map["isMounted"] = d.isMounted;
        map["isRemovable"] = d.isRemovable;
        map["freeSpaceFormatted"] = (d.bytesTotal > 0)
            ? QString("%1 free of %2").arg(FileUtils::formatSize(d.bytesFree), FileUtils::formatSize(d.bytesTotal))
            : d.sizeFormatted;
        map["isHidden"] = isDeviceHidden(d.devicePath, d.name);
        list.append(map);
    }
    return list;
}

void DriveManager::applyDeviceFilters() {
    beginResetModel();
    m_drives.clear();
    for (const auto& d : m_allDrives) {
        if (m_showHiddenDevices || !isDeviceHidden(d.devicePath, d.name)) {
            m_drives.append(d);
        }
    }
    endResetModel();
    emit countChanged();
}

void DriveManager::refresh() {
    (void)QtConcurrent::run([this]() {
        QProcess proc;
        proc.start("lsblk", { "-J", "-o", "NAME,LABEL,MOUNTPOINTS,SIZE,TYPE,FSTYPE,RM,HOTPLUG,MODEL" });
        if (!proc.waitForFinished(3000)) return;

        QByteArray out = proc.readAllStandardOutput();
        QJsonDocument doc = QJsonDocument::fromJson(out);
        if (!doc.isObject()) return;

        QVector<DriveItem> foundDrives;
        QJsonArray blockdevices = doc.object()["blockdevices"].toArray();

        auto parseDevice = [&](auto self, const QJsonObject& obj, const QString& parentModel) -> void {
            QString name = obj["name"].toString();
            QString type = obj["type"].toString();
            QString fstype = obj["fstype"].toString();
            QString label = obj["label"].toString();
            QString size = obj["size"].toString();
            QString model = obj["model"].toString();
            if (model.isEmpty()) model = parentModel;
            bool rm = obj["rm"].toBool() || obj["hotplug"].toBool();

            QString mountPoint;
            if (obj["mountpoints"].isArray()) {
                QJsonArray mps = obj["mountpoints"].toArray();
                for (const auto& mpVal : mps) {
                    QString mp = mpVal.toString();
                    if (!mp.isEmpty()) {
                        mountPoint = mp;
                        break;
                    }
                }
            } else {
                mountPoint = obj["mountpoint"].toString();
            }

            QString devPath = "/dev/" + name;

            // Filter out swap and unmounted loop devices
            bool isLoopUnmounted = (type == "loop" && mountPoint.isEmpty());
            bool isSwap = (fstype == "swap");
            bool isValidFs = !fstype.isEmpty() && !isSwap && !isLoopUnmounted;

            if ((type == "part" || type == "disk" || (type == "loop" && !mountPoint.isEmpty())) && isValidFs) {
                QString displayName = label;
                if (displayName.isEmpty()) {
                    if (!model.isEmpty()) {
                        displayName = model.trimmed();
                    } else {
                        displayName = name;
                    }
                }

                qint64 freeBytes = 0;
                qint64 totalBytes = 0;
                if (!mountPoint.isEmpty()) {
                    QStorageInfo storage(mountPoint);
                    if (storage.isValid() && storage.isReady()) {
                        freeBytes = storage.bytesFree();
                        totalBytes = storage.bytesTotal();
                    }
                }

                foundDrives.append({
                    displayName,
                    devPath,
                    mountPoint,
                    size,
                    fstype,
                    model.trimmed(),
                    !mountPoint.isEmpty(),
                    rm,
                    freeBytes,
                    totalBytes
                });
            }

            if (obj["children"].isArray()) {
                QJsonArray children = obj["children"].toArray();
                for (const auto& child : children) {
                    self(self, child.toObject(), model);
                }
            }
        };

        for (const auto& dev : blockdevices) {
            parseDevice(parseDevice, dev.toObject(), "");
        }

        QMetaObject::invokeMethod(this, [this, foundDrives]() {
            m_allDrives = foundDrives;
            applyDeviceFilters();
        });
    });
}

void DriveManager::mountDevice(const QString& devicePath, int tabIndex) {
    (void)QtConcurrent::run([this, devicePath, tabIndex]() {
        QProcess proc;
        proc.start("udisksctl", { "mount", "-b", devicePath });
        proc.waitForFinished(10000);

        QString out = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
        QString err = QString::fromUtf8(proc.readAllStandardError()).trimmed();

        QString mountPoint;
        if (out.contains(" at ")) {
            int atIdx = out.indexOf(" at ");
            mountPoint = out.mid(atIdx + 4).trimmed();
            if (mountPoint.endsWith('.')) mountPoint.chop(1);
        } else if (err.contains("already mounted at `")) {
            int atIdx = err.indexOf("already mounted at `");
            mountPoint = err.mid(atIdx + 20);
            int endQuote = mountPoint.indexOf('\'');
            if (endQuote != -1) mountPoint = mountPoint.left(endQuote);
        } else if (err.contains("already mounted at '")) {
            int atIdx = err.indexOf("already mounted at '");
            mountPoint = err.mid(atIdx + 20);
            int endQuote = mountPoint.indexOf('\'');
            if (endQuote != -1) mountPoint = mountPoint.left(endQuote);
        }

        if (mountPoint.isEmpty()) {
            QProcess checkProc;
            checkProc.start("lsblk", { "-no", "MOUNTPOINTS,MOUNTPOINT", devicePath });
            checkProc.waitForFinished(2000);
            QString lines = QString::fromUtf8(checkProc.readAllStandardOutput()).trimmed();
            for (const QString& line : lines.split('\n')) {
                QString trimmed = line.trimmed();
                if (!trimmed.isEmpty() && trimmed != "[SWAP]") {
                    mountPoint = trimmed;
                    break;
                }
            }
        }

        QMetaObject::invokeMethod(this, [this, devicePath, mountPoint, tabIndex, err]() {
            refresh();
            if (!mountPoint.isEmpty() && QDir(mountPoint).exists()) {
                emit deviceMounted(mountPoint, tabIndex);
            } else if (!err.isEmpty()) {
                emit operationFailed(err);
            }
        });
    });
}

void DriveManager::unmountDevice(const QString& devicePath) {
    (void)QtConcurrent::run([this, devicePath]() {
        QProcess proc;
        proc.start("udisksctl", { "unmount", "-b", devicePath });
        proc.waitForFinished(5000);

        QMetaObject::invokeMethod(this, [this, devicePath]() {
            refresh();
            emit deviceUnmounted(devicePath);
        });
    });
}

void DriveManager::ejectDevice(const QString& devicePath) {
    (void)QtConcurrent::run([this, devicePath]() {
        QProcess unmountProc;
        unmountProc.start("udisksctl", { "unmount", "-b", devicePath });
        unmountProc.waitForFinished(5000);

        QProcess proc;
        proc.start("udisksctl", { "power-off", "-b", devicePath });
        if (!proc.waitForFinished(5000) || proc.exitCode() != 0) {
            QProcess ejectProc;
            ejectProc.start("eject", { devicePath });
            ejectProc.waitForFinished(5000);
        }

        QMetaObject::invokeMethod(this, [this, devicePath]() {
            refresh();
            emit deviceUnmounted(devicePath);
        });
    });
}

} // namespace prism::core
