//! Path helpers standing in for QDir, QStandardPaths and QUrl.

use percent_encoding::{percent_decode_str, utf8_percent_encode, AsciiSet, CONTROLS};
use std::path::Path;

pub fn home() -> String {
    std::env::var("HOME")
        .ok()
        .filter(|h| !h.is_empty())
        .unwrap_or_else(|| "/".to_string())
}

fn xdg_base(var: &str, fallback: &str) -> String {
    match std::env::var(var) {
        Ok(v) if v.starts_with('/') => v,
        _ => format!("{}/{fallback}", home()),
    }
}

/// `QStandardPaths::GenericDataLocation`.
pub fn data_home() -> String {
    xdg_base("XDG_DATA_HOME", ".local/share")
}

/// `QStandardPaths::GenericConfigLocation`.
pub fn config_home() -> String {
    xdg_base("XDG_CONFIG_HOME", ".config")
}

pub fn cache_home() -> String {
    xdg_base("XDG_CACHE_HOME", ".cache")
}

/// `QStandardPaths::CacheLocation` for the "astra-atlas"/"atlas" application.
pub fn app_cache_dir() -> String {
    format!("{}/astra-atlas/atlas", cache_home())
}

pub fn state_home() -> String {
    xdg_base("XDG_STATE_HOME", ".local/state")
}

/// Reads one `XDG_*_DIR` entry from user-dirs.dirs, like QStandardPaths does.
pub fn user_dir(key: &str, fallback: &str) -> String {
    let file = format!("{}/user-dirs.dirs", config_home());
    if let Ok(text) = std::fs::read_to_string(file) {
        for line in text.lines() {
            let line = line.trim();
            let Some(rest) = line.strip_prefix(key).and_then(|r| r.strip_prefix('=')) else {
                continue;
            };
            let value = rest.trim().trim_matches('"').replace("$HOME", &home());
            if value.starts_with('/') {
                return clean_path(&value);
            }
        }
    }
    format!("{}/{fallback}", home())
}

pub fn pictures() -> String {
    user_dir("XDG_PICTURES_DIR", "Pictures")
}
pub fn videos() -> String {
    user_dir("XDG_VIDEOS_DIR", "Videos")
}
pub fn documents() -> String {
    user_dir("XDG_DOCUMENTS_DIR", "Documents")
}
pub fn downloads() -> String {
    user_dir("XDG_DOWNLOAD_DIR", "Downloads")
}
pub fn music() -> String {
    user_dir("XDG_MUSIC_DIR", "Music")
}
pub fn desktop() -> String {
    user_dir("XDG_DESKTOP_DIR", "Desktop")
}
pub fn templates() -> String {
    user_dir("XDG_TEMPLATES_DIR", "Templates")
}

/// `QDir::cleanPath`: collapses separators, resolves `.` and `..`, and drops
/// the trailing slash.
pub fn clean_path(path: &str) -> String {
    if path.is_empty() {
        return String::new();
    }
    let absolute = path.starts_with('/');
    let mut parts: Vec<&str> = Vec::new();
    for part in path.split('/') {
        match part {
            "" | "." => {}
            ".." => {
                if parts.last().is_some_and(|p| *p != "..") {
                    parts.pop();
                } else if !absolute {
                    parts.push("..");
                }
            }
            p => parts.push(p),
        }
    }
    let joined = parts.join("/");
    if absolute {
        format!("/{joined}")
    } else if joined.is_empty() {
        ".".to_string()
    } else {
        joined
    }
}

/// `QFileInfo::fileName`.
pub fn file_name(path: &str) -> String {
    let trimmed = path.trim_end_matches('/');
    trimmed.rsplit('/').next().unwrap_or("").to_string()
}

/// `QFileInfo::absolutePath`: the parent directory.
pub fn parent(path: &str) -> String {
    let p = clean_path(path);
    match p.rfind('/') {
        Some(0) => "/".to_string(),
        Some(i) => p[..i].to_string(),
        None => ".".to_string(),
    }
}

/// `QFileInfo::suffix`: text after the last dot of the file name.
pub fn suffix(name: &str) -> String {
    let name = file_name(name);
    match name.rfind('.') {
        Some(i) if i > 0 || name.len() > 1 => name[i + 1..].to_string(),
        _ => String::new(),
    }
}

/// `QFileInfo::completeBaseName`: the name without its last suffix.
pub fn complete_base_name(name: &str) -> String {
    let name = file_name(name);
    match name.rfind('.') {
        Some(i) => name[..i].to_string(),
        None => name,
    }
}

/// `QFileInfo::baseName`: the name up to its first dot.
pub fn base_name(name: &str) -> String {
    let name = file_name(name);
    match name.find('.') {
        Some(i) => name[..i].to_string(),
        None => name,
    }
}

pub fn exists(path: &str) -> bool {
    !path.is_empty() && Path::new(path).symlink_metadata().is_ok()
}

pub fn is_dir(path: &str) -> bool {
    Path::new(path).is_dir()
}

pub fn is_file(path: &str) -> bool {
    Path::new(path).is_file()
}

const PATH_SET: &AsciiSet = &CONTROLS
    .add(b' ')
    .add(b'"')
    .add(b'#')
    .add(b'%')
    .add(b'<')
    .add(b'>')
    .add(b'?')
    .add(b'[')
    .add(b'\\')
    .add(b']')
    .add(b'^')
    .add(b'`')
    .add(b'{')
    .add(b'|')
    .add(b'}');

/// Percent-encodes a path for a `file://` URL or a .trashinfo `Path=`.
pub fn encode_path(path: &str) -> String {
    utf8_percent_encode(path, PATH_SET).to_string()
}

pub fn decode(text: &str) -> String {
    percent_decode_str(text).decode_utf8_lossy().into_owned()
}

/// `QUrl::fromLocalFile(path).toString()`.
pub fn to_file_url(path: &str) -> String {
    format!("file://{}", encode_path(path))
}

/// `QUrl(url).toLocalFile()`; returns the input unchanged if it is not a file URL.
pub fn from_file_url(url: &str) -> String {
    match url.strip_prefix("file://") {
        Some(rest) => {
            // file://host/path: drop a host part if present.
            let rest = if rest.starts_with('/') { rest } else { rest.find('/').map(|i| &rest[i..]).unwrap_or("") };
            decode(rest.split(['?', '#']).next().unwrap_or(""))
        }
        None => url.to_string(),
    }
}

/// Whether `name` (a program name or path) can be found and executed.
pub fn find_executable(name: &str) -> Option<String> {
    if name.contains('/') {
        return is_executable(name).then(|| name.to_string());
    }
    let paths = std::env::var("PATH").unwrap_or_else(|_| "/usr/local/bin:/usr/bin:/bin".into());
    paths
        .split(':')
        .filter(|d| !d.is_empty())
        .map(|d| format!("{d}/{name}"))
        .find(|p| is_executable(p))
}

pub fn is_executable(path: &str) -> bool {
    use std::os::unix::fs::PermissionsExt;
    std::fs::metadata(path)
        .map(|m| m.is_file() && m.permissions().mode() & 0o111 != 0)
        .unwrap_or(false)
}

/// Returns `dir/name` if free, else `dir/base (n).ext` with the first free n.
pub fn unique_path(dir: &str, name: &str) -> String {
    let candidate = format!("{dir}/{name}");
    if !exists(&candidate) {
        return candidate;
    }
    let base = complete_base_name(name);
    let ext = suffix(name);
    for n in 1.. {
        let next = if ext.is_empty() || base.is_empty() {
            format!("{dir}/{name} ({n})")
        } else {
            format!("{dir}/{base} ({n}).{ext}")
        };
        if !exists(&next) {
            return next;
        }
    }
    unreachable!()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn clean_path_matches_qdir() {
        assert_eq!(clean_path("/a//b/./c/../d/"), "/a/b/d");
        assert_eq!(clean_path("/.."), "/");
        assert_eq!(clean_path("a/../.."), "..");
        assert_eq!(clean_path("/"), "/");
    }

    #[test]
    fn names() {
        assert_eq!(suffix("/x/archive.tar.gz"), "gz");
        assert_eq!(complete_base_name("archive.tar.gz"), "archive.tar");
        assert_eq!(base_name("archive.tar.gz"), "archive");
        assert_eq!(suffix(".bashrc"), "bashrc");
        assert_eq!(parent("/a/b"), "/a");
        assert_eq!(parent("/a"), "/");
    }

    #[test]
    fn file_urls() {
        assert_eq!(to_file_url("/tmp/a b"), "file:///tmp/a%20b");
        assert_eq!(from_file_url("file:///tmp/a%20b"), "/tmp/a b");
    }
}
