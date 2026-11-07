//! DriveManager: drives and partitions from lsblk, mounted through udisksctl.

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!(<QtCore/QAbstractListModel>);
        type QAbstractListModel;

        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
        include!("cxx-qt-lib/qstringlist.h");
        type QStringList = cxx_qt_lib::QStringList;
        include!("cxx-qt-lib/qmodelindex.h");
        type QModelIndex = cxx_qt_lib::QModelIndex;
        include!("cxx-qt-lib/qvariant.h");
        type QVariant = cxx_qt_lib::QVariant;
        include!("cxx-qt-lib/qhash.h");
        type QHash_i32_QByteArray = cxx_qt_lib::QHash<cxx_qt_lib::QHashPair_i32_QByteArray>;
        include!("cxx-qt-lib/qlist.h");
        type QList_QVariant = cxx_qt_lib::QList<cxx_qt_lib::QVariant>;
    }

    extern "RustQt" {
        #[qobject]
        #[base = QAbstractListModel]
        #[qml_element]
        #[qml_singleton]
        #[qproperty(i32, count, READ = count, NOTIFY = count_changed)]
        #[qproperty(bool, show_hidden_devices, cxx_name = "showHiddenDevices", READ, WRITE = set_show_hidden_devices, NOTIFY = show_hidden_devices_changed)]
        type DriveManager = super::DriveManagerRust;

        #[qsignal]
        #[cxx_name = "countChanged"]
        fn count_changed(self: Pin<&mut DriveManager>);
        #[qsignal]
        #[cxx_name = "showHiddenDevicesChanged"]
        fn show_hidden_devices_changed(self: Pin<&mut DriveManager>);
        #[qsignal]
        #[cxx_name = "deviceMounted"]
        fn device_mounted(self: Pin<&mut DriveManager>, mount_point: &QString, tab_index: i32);
        #[qsignal]
        #[cxx_name = "deviceUnmounted"]
        fn device_unmounted(self: Pin<&mut DriveManager>, device_path: &QString);
        #[qsignal]
        #[cxx_name = "operationFailed"]
        fn operation_failed(self: Pin<&mut DriveManager>, error: &QString);

        fn count(self: &DriveManager) -> i32;
        #[cxx_name = "setShowHiddenDevices"]
        fn set_show_hidden_devices(self: Pin<&mut DriveManager>, show: bool);

        #[qinvokable]
        fn refresh(self: Pin<&mut DriveManager>);
        #[qinvokable]
        #[cxx_name = "mountDevice"]
        fn mount_device(self: Pin<&mut DriveManager>, device_path: &QString, tab_index: i32);
        #[qinvokable]
        #[cxx_name = "mountDevice"]
        fn mount_device_default(self: Pin<&mut DriveManager>, device_path: &QString);
        #[qinvokable]
        #[cxx_name = "unmountDevice"]
        fn unmount_device(self: Pin<&mut DriveManager>, device_path: &QString);
        #[qinvokable]
        #[cxx_name = "ejectDevice"]
        fn eject_device(self: Pin<&mut DriveManager>, device_path: &QString);
        #[qinvokable]
        #[cxx_name = "hideDevice"]
        fn hide_device(self: Pin<&mut DriveManager>, device_path: &QString);
        #[qinvokable]
        #[cxx_name = "unhideDevice"]
        fn unhide_device(self: Pin<&mut DriveManager>, device_path: &QString);
        #[qinvokable]
        #[cxx_name = "toggleDeviceHidden"]
        fn toggle_device_hidden(self: Pin<&mut DriveManager>, device_path: &QString);
        #[qinvokable]
        #[cxx_name = "isDeviceHidden"]
        fn is_device_hidden(self: &DriveManager, device_path: &QString, name: &QString) -> bool;
        #[qinvokable]
        #[cxx_name = "isDeviceHidden"]
        fn is_device_hidden_default(self: &DriveManager, device_path: &QString) -> bool;
        #[qinvokable]
        #[cxx_name = "hiddenDevices"]
        fn hidden_devices(self: &DriveManager) -> QStringList;
        #[qinvokable]
        #[cxx_name = "setHiddenDevices"]
        fn set_hidden_devices(self: Pin<&mut DriveManager>, list: &QStringList);
        #[qinvokable]
        #[cxx_name = "allDevices"]
        fn all_devices(self: &DriveManager) -> QList_QVariant;
    }

    unsafe extern "RustQt" {
        #[inherit]
        #[cxx_name = "beginResetModel"]
        fn begin_reset_model(self: Pin<&mut DriveManager>);
        #[inherit]
        #[cxx_name = "endResetModel"]
        fn end_reset_model(self: Pin<&mut DriveManager>);

        #[cxx_override]
        fn data(self: &DriveManager, index: &QModelIndex, role: i32) -> QVariant;
        #[cxx_override]
        #[cxx_name = "roleNames"]
        fn role_names(self: &DriveManager) -> QHash_i32_QByteArray;
        #[cxx_override]
        #[cxx_name = "rowCount"]
        fn row_count(self: &DriveManager, parent: &QModelIndex) -> i32;
    }

    impl cxx_qt::Threading for DriveManager {}
    impl cxx_qt::Constructor<()> for DriveManager {}
}

use crate::bridge::native::{from_qsl, qs, qsl, settings, to_qvariant_list};
use crate::core::{desktop, fileutils, paths, storage};
use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::{QByteArray, QHash, QHashPair_i32_QByteArray, QList, QModelIndex, QString, QStringList, QVariant};
use qobject::DriveManager;
use serde_json::{json, Value};
use std::pin::Pin;

mod role {
    pub const NAME: i32 = 0x0101;
    pub const DEVICE_PATH: i32 = 0x0102;
    pub const MOUNT_POINT: i32 = 0x0103;
    pub const SIZE_FORMATTED: i32 = 0x0104;
    pub const FS_TYPE: i32 = 0x0105;
    pub const MODEL: i32 = 0x0106;
    pub const IS_MOUNTED: i32 = 0x0107;
    pub const IS_REMOVABLE: i32 = 0x0108;
    pub const BYTES_FREE: i32 = 0x0109;
    pub const BYTES_TOTAL: i32 = 0x010a;
    pub const FREE_SPACE_FORMATTED: i32 = 0x010b;
    pub const IS_HIDDEN: i32 = 0x010c;
    pub const DISPLAY: i32 = 0;
}

#[derive(Clone, Default)]
struct DriveItem {
    name: String,
    device_path: String,
    mount_point: String,
    size_formatted: String,
    fs_type: String,
    model: String,
    // Stable identity for remembering hidden devices: /dev/sdX names can
    // swap between boots, filesystem and partition UUIDs do not.
    stable_id: String,
    is_mounted: bool,
    is_removable: bool,
    bytes_free: i64,
    bytes_total: i64,
}

impl DriveItem {
    fn free_space_formatted(&self) -> String {
        if self.bytes_total > 0 {
            format!("{} free of {}", fileutils::format_size(self.bytes_free), fileutils::format_size(self.bytes_total))
        } else {
            self.size_formatted.clone()
        }
    }
}

/// A filesystem can be mounted in several places at once (btrfs subvolumes,
/// bind mounts), in no stable order. Prefer "/", else the shortest path.
fn preferred_mount_point(points: &[String]) -> String {
    let mut best = String::new();
    for mp in points {
        if mp.is_empty() || mp == "[SWAP]" {
            continue;
        }
        if mp == "/" {
            return mp.clone();
        }
        if best.is_empty() || mp.len() < best.len() || (mp.len() == best.len() && *mp < best) {
            best = mp.clone();
        }
    }
    best
}

fn json_bool(v: &Value) -> bool {
    match v {
        Value::Bool(b) => *b,
        Value::String(s) => s == "1" || s.eq_ignore_ascii_case("true"),
        Value::Number(n) => n.as_i64() == Some(1),
        _ => false,
    }
}

fn json_str(v: &Value, key: &str) -> String {
    v.get(key).and_then(Value::as_str).unwrap_or("").to_string()
}

fn parse_device(obj: &Value, parent_model: &str, out: &mut Vec<DriveItem>) {
    let name = json_str(obj, "name");
    let kind = json_str(obj, "type");
    let fstype = json_str(obj, "fstype");
    let label = json_str(obj, "label");
    let mut model = json_str(obj, "model");
    if model.is_empty() {
        model = parent_model.to_string();
    }
    let removable = obj.get("rm").is_some_and(json_bool) || obj.get("hotplug").is_some_and(json_bool);
    let uuid = json_str(obj, "uuid");
    let part_uuid = json_str(obj, "partuuid");
    let stable_id = if !uuid.is_empty() {
        format!("uuid:{uuid}")
    } else if !part_uuid.is_empty() {
        format!("partuuid:{part_uuid}")
    } else {
        String::new()
    };
    let mount_point = match obj.get("mountpoints").and_then(Value::as_array) {
        Some(points) => preferred_mount_point(
            &points.iter().map(|p| p.as_str().unwrap_or("").to_string()).collect::<Vec<_>>(),
        ),
        None => json_str(obj, "mountpoint"),
    };
    let loop_unmounted = kind == "loop" && mount_point.is_empty();
    let valid_fs = !fstype.is_empty() && fstype != "swap" && !loop_unmounted;
    if (kind == "part" || kind == "disk" || (kind == "loop" && !mount_point.is_empty())) && valid_fs {
        let display = if !label.is_empty() {
            label
        } else if !model.is_empty() {
            model.trim().to_string()
        } else {
            name.clone()
        };
        let (free, total) = if mount_point.is_empty() {
            (0, 0)
        } else {
            storage::space_free_total(&mount_point).unwrap_or((0, 0))
        };
        out.push(DriveItem {
            name: display,
            device_path: format!("/dev/{name}"),
            mount_point: mount_point.clone(),
            size_formatted: json_str(obj, "size"),
            fs_type: fstype,
            model: model.trim().to_string(),
            stable_id,
            is_mounted: !mount_point.is_empty(),
            is_removable: removable,
            bytes_free: free,
            bytes_total: total,
        });
    }
    if let Some(children) = obj.get("children").and_then(Value::as_array) {
        for child in children {
            parse_device(child, &model, out);
        }
    }
}

fn scan_drives() -> Option<Vec<DriveItem>> {
    let (_, out, _) = desktop::run_timeout(
        "lsblk",
        &["-J", "-o", "NAME,LABEL,MOUNTPOINTS,SIZE,TYPE,FSTYPE,RM,HOTPLUG,MODEL,UUID,PARTUUID"],
        3000,
    )?;
    let doc: Value = serde_json::from_str(&out).ok()?;
    let mut found = Vec::new();
    for dev in doc.get("blockdevices")?.as_array()? {
        parse_device(dev, "", &mut found);
    }
    Some(found)
}

/// The mount point udisksctl reports (or complains about), else lsblk's.
fn mount_with_udisks(device_path: &str) -> (String, String) {
    let (_, out, err) = desktop::run_timeout("udisksctl", &["mount", "-b", device_path], 10000).unwrap_or_default();
    let out = out.trim().to_string();
    let err = err.trim().to_string();
    let mut mount_point = String::new();
    if let Some(i) = out.find(" at ") {
        mount_point = out[i + 4..].trim().trim_end_matches('.').to_string();
    } else {
        for marker in ["already mounted at `", "already mounted at '"] {
            if let Some(i) = err.find(marker) {
                let rest = &err[i + marker.len()..];
                mount_point = rest.split('\'').next().unwrap_or(rest).to_string();
                break;
            }
        }
    }
    if mount_point.is_empty() {
        if let Some((_, out, _)) = desktop::run_timeout("lsblk", &["-no", "MOUNTPOINTS,MOUNTPOINT", device_path], 2000) {
            let lines: Vec<String> = out.lines().map(|l| l.trim().to_string()).collect();
            mount_point = preferred_mount_point(&lines);
        }
    }
    (mount_point, err)
}

pub struct DriveManagerRust {
    all_drives: Vec<DriveItem>,
    drives: Vec<DriveItem>,
    hidden_devices: Vec<String>,
    show_hidden_devices: bool,
}

impl Default for DriveManagerRust {
    fn default() -> Self {
        Self {
            all_drives: Vec::new(),
            drives: Vec::new(),
            hidden_devices: settings::string_list("devices/hiddenDevices"),
            show_hidden_devices: false,
        }
    }
}

impl cxx_qt::Initialize for DriveManager {
    fn initialize(self: Pin<&mut Self>) {
        let thread = self.qt_thread();
        storage::watch_mounts(move || {
            let _ = thread.queue(|drives| drives.refresh());
        });
        self.refresh();
    }
}

impl DriveManager {
    fn count(&self) -> i32 {
        self.drives.len() as i32
    }

    fn save_hidden(&self) {
        settings::set_string_list("devices/hiddenDevices", &self.hidden_devices);
    }

    fn set_show_hidden_devices(mut self: Pin<&mut Self>, show: bool) {
        if self.show_hidden_devices != show {
            self.as_mut().rust_mut().show_hidden_devices = show;
            self.as_mut().apply_filters();
            self.show_hidden_devices_changed();
        }
    }

    fn hide_key_for(&self, device_path: &str) -> String {
        self.all_drives
            .iter()
            .find(|d| d.device_path == device_path && !d.stable_id.is_empty())
            .map(|d| d.stable_id.clone())
            .unwrap_or_else(|| device_path.to_string())
    }

    fn hidden(&self, device_path: &str, name: &str) -> bool {
        let key = self.hide_key_for(device_path);
        self.hidden_devices.contains(&key)
            // A /dev path only counts when the device has no stable id.
            || (key == device_path && self.hidden_devices.iter().any(|h| h == device_path))
            || (!name.is_empty() && self.hidden_devices.iter().any(|h| h == name))
    }

    fn hide_device(mut self: Pin<&mut Self>, device_path: &QString) {
        let key = self.hide_key_for(&device_path.to_string());
        if !key.is_empty() && !self.hidden_devices.contains(&key) {
            self.as_mut().rust_mut().hidden_devices.push(key);
            self.save_hidden();
            self.apply_filters();
        }
    }

    fn unhide_device(mut self: Pin<&mut Self>, device_path: &QString) {
        let path = device_path.to_string();
        let key = self.hide_key_for(&path);
        let before = self.hidden_devices.len();
        // Older settings stored the /dev path, so drop that as well.
        self.as_mut().rust_mut().hidden_devices.retain(|h| *h != key && *h != path);
        if self.hidden_devices.len() != before {
            self.save_hidden();
            self.apply_filters();
        }
    }

    fn toggle_device_hidden(self: Pin<&mut Self>, device_path: &QString) {
        if self.hidden(&device_path.to_string(), "") {
            self.unhide_device(device_path);
        } else {
            self.hide_device(device_path);
        }
    }

    fn is_device_hidden(&self, device_path: &QString, name: &QString) -> bool {
        self.hidden(&device_path.to_string(), &name.to_string())
    }

    fn is_device_hidden_default(&self, device_path: &QString) -> bool {
        self.hidden(&device_path.to_string(), "")
    }

    fn hidden_devices(&self) -> QStringList {
        qsl(&self.hidden_devices)
    }

    fn set_hidden_devices(mut self: Pin<&mut Self>, list: &QStringList) {
        self.as_mut().rust_mut().hidden_devices = from_qsl(list);
        self.save_hidden();
        self.apply_filters();
    }

    /// Settings written before stable ids stored /dev paths; move each to the
    /// id of the device at that path now.
    fn migrate_hidden_device_paths(mut self: Pin<&mut Self>) {
        let migrated: Vec<String> = self
            .hidden_devices
            .iter()
            .map(|e| if e.starts_with("/dev/") { self.hide_key_for(e) } else { e.clone() })
            .collect();
        if migrated != self.hidden_devices {
            let mut deduped: Vec<String> = Vec::new();
            for m in migrated {
                if !deduped.contains(&m) {
                    deduped.push(m);
                }
            }
            self.as_mut().rust_mut().hidden_devices = deduped;
            self.save_hidden();
        }
    }

    fn all_devices(&self) -> QList<QVariant> {
        let list: Vec<Value> = self
            .all_drives
            .iter()
            .map(|d| {
                json!({
                    "name": d.name,
                    "devicePath": d.device_path,
                    "mountPoint": d.mount_point,
                    "sizeFormatted": d.size_formatted,
                    "fsType": d.fs_type,
                    "model": d.model,
                    "isMounted": d.is_mounted,
                    "isRemovable": d.is_removable,
                    "freeSpaceFormatted": d.free_space_formatted(),
                    "isHidden": self.hidden(&d.device_path, &d.name),
                })
            })
            .collect();
        to_qvariant_list(&list)
    }

    fn apply_filters(mut self: Pin<&mut Self>) {
        self.as_mut().begin_reset_model();
        let visible: Vec<DriveItem> = self
            .all_drives
            .iter()
            .filter(|d| self.show_hidden_devices || !self.hidden(&d.device_path, &d.name))
            .cloned()
            .collect();
        self.as_mut().rust_mut().drives = visible;
        self.as_mut().end_reset_model();
        self.count_changed();
    }

    fn refresh(self: Pin<&mut Self>) {
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let Some(found) = scan_drives() else { return };
            let _ = thread.queue(move |mut drives| {
                drives.as_mut().rust_mut().all_drives = found;
                drives.as_mut().migrate_hidden_device_paths();
                drives.apply_filters();
            });
        });
    }

    fn mount_device(self: Pin<&mut Self>, device_path: &QString, tab_index: i32) {
        let device = device_path.to_string();
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let (mount_point, err) = mount_with_udisks(&device);
            let _ = thread.queue(move |mut drives| {
                drives.as_mut().refresh();
                if !mount_point.is_empty() && paths::is_dir(&mount_point) {
                    drives.device_mounted(&qs(&mount_point), tab_index);
                } else if !err.is_empty() {
                    drives.operation_failed(&qs(&err));
                }
            });
        });
    }

    fn mount_device_default(self: Pin<&mut Self>, device_path: &QString) {
        self.mount_device(device_path, 0);
    }

    fn unmount_device(self: Pin<&mut Self>, device_path: &QString) {
        let device = device_path.to_string();
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let _ = desktop::run_timeout("udisksctl", &["unmount", "-b", &device], 5000);
            let _ = thread.queue(move |mut drives| {
                drives.as_mut().refresh();
                drives.device_unmounted(&qs(&device));
            });
        });
    }

    fn eject_device(self: Pin<&mut Self>, device_path: &QString) {
        let device = device_path.to_string();
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let _ = desktop::run_timeout("udisksctl", &["unmount", "-b", &device], 5000);
            let powered_off = desktop::run_timeout("udisksctl", &["power-off", "-b", &device], 5000).is_some_and(|r| r.0 == 0);
            if !powered_off {
                let _ = desktop::run_timeout("eject", &[&device], 5000);
            }
            let _ = thread.queue(move |mut drives| {
                drives.as_mut().refresh();
                drives.device_unmounted(&qs(&device));
            });
        });
    }

    fn row_count(&self, parent: &QModelIndex) -> i32 {
        if parent.is_valid() { 0 } else { self.drives.len() as i32 }
    }

    fn data(&self, index: &QModelIndex, role: i32) -> QVariant {
        let row = index.row();
        if !index.is_valid() || row < 0 || row as usize >= self.drives.len() {
            return QVariant::default();
        }
        let d = &self.drives[row as usize];
        match role {
            role::NAME | role::DISPLAY => QVariant::from(&qs(&d.name)),
            role::DEVICE_PATH => QVariant::from(&qs(&d.device_path)),
            role::MOUNT_POINT => QVariant::from(&qs(&d.mount_point)),
            role::SIZE_FORMATTED => QVariant::from(&qs(&d.size_formatted)),
            role::FS_TYPE => QVariant::from(&qs(&d.fs_type)),
            role::MODEL => QVariant::from(&qs(&d.model)),
            role::IS_MOUNTED => QVariant::from(&d.is_mounted),
            role::IS_REMOVABLE => QVariant::from(&d.is_removable),
            role::BYTES_FREE => QVariant::from(&d.bytes_free),
            role::BYTES_TOTAL => QVariant::from(&d.bytes_total),
            role::FREE_SPACE_FORMATTED => QVariant::from(&qs(&d.free_space_formatted())),
            role::IS_HIDDEN => QVariant::from(&self.hidden(&d.device_path, &d.name)),
            _ => QVariant::default(),
        }
    }

    fn role_names(&self) -> QHash<QHashPair_i32_QByteArray> {
        let mut roles = QHash::<QHashPair_i32_QByteArray>::default();
        for (r, name) in [
            (role::NAME, "name"),
            (role::DEVICE_PATH, "devicePath"),
            (role::MOUNT_POINT, "mountPoint"),
            (role::SIZE_FORMATTED, "sizeFormatted"),
            (role::FS_TYPE, "fsType"),
            (role::MODEL, "model"),
            (role::IS_MOUNTED, "isMounted"),
            (role::IS_REMOVABLE, "isRemovable"),
            (role::BYTES_FREE, "bytesFree"),
            (role::BYTES_TOTAL, "bytesTotal"),
            (role::FREE_SPACE_FORMATTED, "freeSpaceFormatted"),
            (role::IS_HIDDEN, "isHidden"),
        ] {
            roles.insert(r, QByteArray::from(name));
        }
        roles
    }
}
