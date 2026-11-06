//! One directory listing row, built off the Qt thread.

use super::{fileutils, paths, trash};
use crate::bridge::native::mime;
use std::cmp::Ordering;
use std::collections::BTreeMap as HashMap;
use std::ffi::CString;
use std::os::unix::fs::MetadataExt;
use std::sync::Mutex;

#[derive(Clone, Debug, Default, PartialEq)]
pub struct RawEntry {
    pub name: String,
    pub path: String,
    pub is_dir: bool,
    pub is_sym_link: bool,
    pub sym_link_target: String,
    pub size: i64,
    pub formatted_size: String,
    pub mime_type: String,
    pub mime_description: String,
    pub last_modified: i64,
    pub formatted_date: String,
    pub permissions: String,
    pub owner: String,
    pub group: String,
    pub suffix: String,
    pub is_hidden: bool,
    pub is_read_only: bool,
    pub is_writable: bool,
    pub is_image: bool,
    pub is_audio: bool,
    pub is_video: bool,
    pub has_thumbnail: bool,
    pub is_text: bool,
    pub original_path: String,
    pub deletion_time: String,
    /// Milliseconds since the epoch, 0 when unknown.
    pub deletion_date: i64,
    pub is_trash_item: bool,
}

fn lookup_name(cache: &Mutex<HashMap<u32, String>>, id: u32, user: bool) -> String {
    if let Some(name) = cache.lock().unwrap().get(&id) {
        return name.clone();
    }
    let mut buf = vec![0 as libc::c_char; 4096];
    let name = unsafe {
        if user {
            let mut pwd: libc::passwd = std::mem::zeroed();
            let mut result = std::ptr::null_mut();
            if libc::getpwuid_r(id, &mut pwd, buf.as_mut_ptr(), buf.len(), &mut result) == 0 && !result.is_null() {
                std::ffi::CStr::from_ptr(pwd.pw_name).to_string_lossy().into_owned()
            } else {
                String::new()
            }
        } else {
            let mut grp: libc::group = std::mem::zeroed();
            let mut result = std::ptr::null_mut();
            if libc::getgrgid_r(id, &mut grp, buf.as_mut_ptr(), buf.len(), &mut result) == 0 && !result.is_null() {
                std::ffi::CStr::from_ptr(grp.gr_name).to_string_lossy().into_owned()
            } else {
                String::new()
            }
        }
    };
    cache.lock().unwrap().insert(id, name.clone());
    name
}

pub fn owner_name(uid: u32) -> String {
    static CACHE: Mutex<HashMap<u32, String>> = Mutex::new(HashMap::new());
    lookup_name(&CACHE, uid, true)
}

pub fn group_name(gid: u32) -> String {
    static CACHE: Mutex<HashMap<u32, String>> = Mutex::new(HashMap::new());
    lookup_name(&CACHE, gid, false)
}

/// "rwxr-xr--" from the mode bits.
pub fn permission_string(mode: u32) -> String {
    let bits = [0o400, 0o200, 0o100, 0o040, 0o020, 0o010, 0o004, 0o002, 0o001];
    let chars = ['r', 'w', 'x', 'r', 'w', 'x', 'r', 'w', 'x'];
    bits.iter().zip(chars).map(|(b, c)| if mode & b != 0 { c } else { '-' }).collect()
}

pub fn is_writable(path: &str) -> bool {
    CString::new(path).map(|c| unsafe { libc::access(c.as_ptr(), libc::W_OK) } == 0).unwrap_or(false)
}

/// `QFileInfo::symLinkTarget`: the absolute path a link points to.
pub fn sym_link_target(path: &str) -> String {
    match std::fs::read_link(path) {
        Ok(target) => {
            let target = target.to_string_lossy().into_owned();
            if target.starts_with('/') {
                paths::clean_path(&target)
            } else {
                paths::clean_path(&format!("{}/{target}", paths::parent(path)))
            }
        }
        Err(_) => String::new(),
    }
}

/// Parses a .trashinfo DeletionDate (local ISO time) to epoch milliseconds.
pub fn parse_deletion_date(text: &str) -> Option<i64> {
    let naive = chrono::NaiveDateTime::parse_from_str(text, "%Y-%m-%dT%H:%M:%S").ok()?;
    naive.and_local_timezone(chrono::Local).earliest().map(|dt| dt.timestamp_millis())
}

impl RawEntry {
    pub fn from_path(path: &str) -> Option<RawEntry> {
        let link_meta = std::fs::symlink_metadata(path).ok()?;
        let is_sym_link = link_meta.file_type().is_symlink();
        // Like QFileInfo, describe what a symlink points to when it resolves.
        let meta = if is_sym_link { std::fs::metadata(path).unwrap_or(link_meta) } else { link_meta };
        let name = paths::file_name(path);
        let is_dir = meta.is_dir();
        let size = if is_dir { 0 } else { meta.len() as i64 };
        let last_modified = fileutils::system_time_msecs(meta.modified()).unwrap_or(0);
        let mime_type = mime::for_file(path);

        let mut d = RawEntry {
            name: name.clone(),
            path: path.to_string(),
            is_dir,
            is_sym_link,
            sym_link_target: if is_sym_link { sym_link_target(path) } else { String::new() },
            size,
            formatted_size: if is_dir { fileutils::count_folder_items(path) } else { fileutils::format_size(size) },
            mime_description: mime::comment(&mime_type),
            last_modified,
            formatted_date: fileutils::format_msecs(last_modified),
            permissions: permission_string(meta.mode()),
            owner: owner_name(meta.uid()),
            group: group_name(meta.gid()),
            suffix: paths::suffix(&name),
            is_hidden: name.starts_with('.'),
            is_writable: is_writable(path),
            original_path: paths::parent(path),
            ..Default::default()
        };
        d.is_read_only = !d.is_writable;
        if mime_type.starts_with("image/") {
            d.is_image = true;
        } else if mime_type.starts_with("audio/") {
            d.is_audio = true;
        } else if mime_type.starts_with("video/") {
            d.is_video = true;
        } else if mime_type.starts_with("text/") || mime_type.contains("json") || mime_type.contains("xml") {
            d.is_text = true;
        }
        d.mime_type = mime_type;
        d.has_thumbnail = fileutils::should_thumbnail(d.is_image, d.is_video, d.size);

        let location = trash::for_trashed_file(path);
        if location.is_valid() {
            d.is_trash_item = true;
            let info = format!("{}/{}.trashinfo", location.info_dir, name);
            if let Some((encoded, date)) = trash::read_trash_info(&info) {
                d.original_path = trash::resolve_original_path(&location, &encoded);
                match parse_deletion_date(&date) {
                    Some(ms) => {
                        d.deletion_time = fileutils::format_msecs(ms);
                        d.deletion_date = ms;
                    }
                    None => d.deletion_time = date,
                }
            }
        }
        Some(d)
    }
}

/// Every entry of `dir` except `.` and `..`, as absolute paths.
pub fn list_dir(dir: &str, include_hidden: bool) -> Vec<String> {
    let Ok(entries) = std::fs::read_dir(dir) else { return Vec::new() };
    let base = if dir.ends_with('/') { dir.to_string() } else { format!("{dir}/") };
    entries
        .flatten()
        .map(|e| e.file_name().to_string_lossy().into_owned())
        .filter(|n| include_hidden || !n.starts_with('.'))
        .map(|n| format!("{base}{n}"))
        .collect()
}

/// Case-insensitive comparison that orders digit runs by value, like
/// QCollator in numeric mode ("file2" before "file10").
pub fn natural_cmp(a: &str, b: &str) -> Ordering {
    let mut ai = a.chars().peekable();
    let mut bi = b.chars().peekable();
    loop {
        match (ai.peek().copied(), bi.peek().copied()) {
            (None, None) => return a.cmp(b),
            (None, Some(_)) => return Ordering::Less,
            (Some(_), None) => return Ordering::Greater,
            (Some(x), Some(y)) if x.is_ascii_digit() && y.is_ascii_digit() => {
                let mut na = String::new();
                while let Some(c) = ai.peek().copied().filter(char::is_ascii_digit) {
                    na.push(c);
                    ai.next();
                }
                let mut nb = String::new();
                while let Some(c) = bi.peek().copied().filter(char::is_ascii_digit) {
                    nb.push(c);
                    bi.next();
                }
                let ta = na.trim_start_matches('0');
                let tb = nb.trim_start_matches('0');
                let ord = ta.len().cmp(&tb.len()).then_with(|| ta.cmp(tb));
                if ord != Ordering::Equal {
                    return ord;
                }
            }
            (Some(x), Some(y)) => {
                let ord = x.to_lowercase().cmp(y.to_lowercase());
                if ord != Ordering::Equal {
                    return ord;
                }
                ai.next();
                bi.next();
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn natural_order() {
        assert_eq!(natural_cmp("file2", "file10"), Ordering::Less);
        assert_eq!(natural_cmp("Apple", "banana"), Ordering::Less);
        assert_eq!(natural_cmp("b", "A"), Ordering::Greater);
    }

    #[test]
    fn permissions() {
        assert_eq!(permission_string(0o754), "rwxr-xr--");
    }
}
