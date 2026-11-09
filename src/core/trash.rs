//! FreeDesktop trash locations: the home trash plus per-volume
//! `.Trash/$uid` and `.Trash-$uid` directories.

use super::paths::{self, clean_path, file_name, parent};
use super::storage;
use std::os::unix::fs::MetadataExt;

#[derive(Clone, Debug, Default)]
pub struct TrashLocation {
    pub files_dir: String,
    pub info_dir: String,
    pub top_dir: String,
}

impl TrashLocation {
    pub fn is_valid(&self) -> bool {
        !self.files_dir.is_empty()
    }

    fn new(base_dir: &str, top_dir: &str) -> Self {
        Self {
            files_dir: format!("{base_dir}/files"),
            info_dir: format!("{base_dir}/info"),
            top_dir: top_dir.to_string(),
        }
    }
}

pub fn home_trash_dir() -> String {
    format!("{}/Trash", paths::data_home())
}

pub fn home_trash_files_dir() -> String {
    format!("{}/files", home_trash_dir())
}

pub fn is_trash_root(path: &str) -> bool {
    !path.is_empty() && clean_path(path) == clean_path(&home_trash_files_dir())
}

const PSEUDO_FS: &[&str] = &[
    "proc", "sysfs", "devtmpfs", "cgroup2", "securityfs", "debugfs", "tracefs", "configfs", "pstore",
    "bpf", "efivarfs", "mqueue", "hugetlbfs", "fusectl", "binfmt_misc", "autofs", "ramfs", "squashfs",
    "overlay", "tmpfs",
];

/// Writable real volumes other than the one holding $HOME.
fn mount_points() -> Vec<String> {
    let home_root = storage::root_path(&paths::home());
    let mut roots: Vec<String> = Vec::new();
    for volume in storage::mounted_volumes() {
        if volume.read_only || volume.root.is_empty() || volume.root == home_root || roots.contains(&volume.root) {
            continue;
        }
        if PSEUDO_FS.contains(&volume.fs_type.as_str()) {
            continue;
        }
        roots.push(volume.root);
    }
    roots
}

fn is_sticky_directory(path: &str) -> bool {
    match std::fs::symlink_metadata(path) {
        Ok(m) => m.is_dir() && m.mode() & libc::S_ISVTX as u32 != 0,
        Err(_) => false,
    }
}

fn mkpaths(base: &str) -> bool {
    std::fs::create_dir_all(format!("{base}/files")).is_ok() && std::fs::create_dir_all(format!("{base}/info")).is_ok()
}

fn volume_trash(top_dir: &str, create: bool) -> TrashLocation {
    let uid = unsafe { libc::getuid() };
    let shared = format!("{top_dir}/.Trash");
    if is_sticky_directory(&shared) {
        let base = format!("{shared}/{uid}");
        if paths::is_dir(&base) || (create && mkpaths(&base)) {
            return TrashLocation::new(&base, top_dir);
        }
    }
    let personal = format!("{top_dir}/.Trash-{uid}");
    if paths::is_dir(&personal) || (create && mkpaths(&personal)) {
        return TrashLocation::new(&personal, top_dir);
    }
    TrashLocation::default()
}

pub fn all() -> Vec<TrashLocation> {
    let mut locations = vec![TrashLocation::new(&home_trash_dir(), "")];
    for root in mount_points() {
        let location = volume_trash(&root, false);
        if location.is_valid() {
            locations.push(location);
        }
    }
    locations
}

pub fn for_trashed_file(trashed_file_path: &str) -> TrashLocation {
    let files_dir = parent(trashed_file_path);
    if file_name(&files_dir) != "files" {
        return TrashLocation::default();
    }
    let base_dir = parent(&files_dir);
    if clean_path(&base_dir) == clean_path(&home_trash_dir()) {
        return TrashLocation::new(&base_dir, "");
    }
    let mut top_dir = parent(&base_dir);
    if file_name(&base_dir) == ".Trash" || file_name(&top_dir) == ".Trash" {
        top_dir = parent(&top_dir);
    }
    TrashLocation::new(&base_dir, &top_dir)
}

fn home_location(create: bool) -> TrashLocation {
    let home = TrashLocation::new(&home_trash_dir(), "");
    if create {
        let _ = std::fs::create_dir_all(&home.files_dir);
        let _ = std::fs::create_dir_all(&home.info_dir);
    }
    home
}

pub fn for_source_file(source_path: &str, create: bool) -> TrashLocation {
    let home_root = storage::root_path(&paths::home());
    let source_root = storage::root_path(&parent(source_path));
    if source_root.is_empty() || source_root == home_root || !mount_points().contains(&source_root) {
        return home_location(create);
    }
    let location = volume_trash(&source_root, create);
    if location.is_valid() {
        return location;
    }
    home_location(create)
}

/// Turns a .trashinfo `Path=` value into an absolute path. Volume trashes
/// store paths relative to the volume's top directory.
pub fn resolve_original_path(location: &TrashLocation, encoded_path: &str) -> String {
    let decoded = paths::decode(encoded_path);
    if decoded.is_empty() || decoded.starts_with('/') || location.top_dir.is_empty() {
        return decoded;
    }
    clean_path(&format!("{}/{decoded}", location.top_dir))
}

/// Parsed `[Trash Info]` of a .trashinfo file: (encoded Path, DeletionDate).
pub fn read_trash_info(info_path: &str) -> Option<(String, String)> {
    let text = std::fs::read_to_string(info_path).ok()?;
    let mut path = None;
    let mut date = String::new();
    for line in text.lines() {
        if let Some(v) = line.strip_prefix("Path=") {
            path = Some(v.trim().to_string());
        } else if let Some(v) = line.strip_prefix("DeletionDate=") {
            date = v.trim().to_string();
        }
    }
    path.map(|p| (p, date))
}
