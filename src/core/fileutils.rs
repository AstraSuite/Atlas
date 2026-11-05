//! Path, size, date and icon helpers shared by every service.

use super::{paths, storage};
use crate::bridge::native::{self, mime, qs};
use serde_json::{json, Value};
use std::sync::atomic::{AtomicBool, AtomicI32, AtomicI64, Ordering};
use std::sync::RwLock;

// Preferences mirrored here by AppController so any thread can format.
static DATE_FORMAT: AtomicI32 = AtomicI32::new(1);
static THUMBS_ENABLED: AtomicBool = AtomicBool::new(true);
static THUMB_MAX_BYTES: AtomicI64 = AtomicI64::new(0);
static FOLDER_COUNT_MODE: AtomicI32 = AtomicI32::new(0);
static CUSTOM_DATE_FORMAT: RwLock<String> = RwLock::new(String::new());

const DEFAULT_PATTERN: &str = "yyyy-MM-dd hh:mm";

pub fn set_date_format(format: i32) {
    DATE_FORMAT.store(format, Ordering::Relaxed);
}

pub fn set_custom_date_format(pattern: &str) {
    let pattern = if pattern.trim().is_empty() { DEFAULT_PATTERN } else { pattern };
    *CUSTOM_DATE_FORMAT.write().unwrap() = pattern.to_string();
}

pub fn set_thumbnails_enabled(enabled: bool) {
    THUMBS_ENABLED.store(enabled, Ordering::Relaxed);
}

pub fn set_thumbnail_max_bytes(bytes: i64) {
    THUMB_MAX_BYTES.store(bytes, Ordering::Relaxed);
}

pub fn set_folder_count_mode(mode: i32) {
    FOLDER_COUNT_MODE.store(mode, Ordering::Relaxed);
}

/// Formats a timestamp per the date preference (or `format` when >= 0).
pub fn format_msecs_with(msecs: i64, format: i32) -> String {
    let format = if format < 0 { DATE_FORMAT.load(Ordering::Relaxed) } else { format };
    let pattern = CUSTOM_DATE_FORMAT.read().unwrap().clone();
    let pattern = if pattern.is_empty() { DEFAULT_PATTERN.to_string() } else { pattern };
    native::ffi::format_date_time(msecs, format, &qs(&pattern)).to_string()
}

pub fn format_msecs(msecs: i64) -> String {
    format_msecs_with(msecs, -1)
}

pub fn format_system_time(time: std::io::Result<std::time::SystemTime>) -> String {
    system_time_msecs(time).map(format_msecs).unwrap_or_default()
}

pub fn system_time_msecs(time: std::io::Result<std::time::SystemTime>) -> Option<i64> {
    let time = time.ok()?;
    Some(match time.duration_since(std::time::UNIX_EPOCH) {
        Ok(d) => d.as_millis() as i64,
        Err(e) => -(e.duration().as_millis() as i64),
    })
}

pub fn format_size(bytes: i64) -> String {
    const KB: f64 = 1024.0;
    let b = bytes as f64;
    if bytes < 1024 {
        format!("{bytes} B")
    } else if b < KB * KB {
        format!("{:.1} KB", b / KB)
    } else if b < KB * KB * KB {
        format!("{:.1} MB", b / (KB * KB))
    } else {
        format!("{:.1} GB", b / (KB * KB * KB))
    }
}

pub fn should_thumbnail(is_image: bool, is_video: bool, size: i64) -> bool {
    if (!is_image && !is_video) || !THUMBS_ENABLED.load(Ordering::Relaxed) {
        return false;
    }
    let limit = THUMB_MAX_BYTES.load(Ordering::Relaxed);
    limit <= 0 || size <= limit
}

/// "N items" for a folder, per the folder item count preference.
pub fn count_folder_items(path: &str) -> String {
    let mode = FOLDER_COUNT_MODE.load(Ordering::Relaxed);
    if mode == 0 {
        return String::new();
    }
    if mode == 1 {
        let device = storage::volume_for(path).map(|v| v.device).unwrap_or_default();
        if !device.starts_with('/') {
            return String::new();
        }
    }
    let Ok(entries) = std::fs::read_dir(path) else { return String::new() };
    match entries.count() {
        1 => "1 item".to_string(),
        n => format!("{n} items"),
    }
}

pub fn shorten_home(path: &str) -> String {
    let home = paths::home();
    match path.strip_prefix(&home) {
        Some(rest) => format!("~{rest}"),
        None => path.to_string(),
    }
}

pub fn free_space_for(path: &str) -> String {
    if path.is_empty() || path.contains("://") || path.starts_with("recent:") {
        return String::new();
    }
    storage::space(path).map(|(free, _)| format_size(free)).unwrap_or_default()
}

pub fn icon_for_name(name: &str, fallback: &str) -> String {
    if native::has_theme_icon(name) {
        return format!("image://icon/{name}");
    }
    if !fallback.is_empty() && native::has_theme_icon(fallback) {
        return format!("image://icon/{fallback}");
    }
    format!("image://icon/{}", if fallback.is_empty() { name } else { fallback })
}

pub fn icon_for_file(name: &str, is_dir: bool, mime_type: &str) -> String {
    if is_dir {
        const SPECIAL: &[&str] = &["Desktop", "Documents", "Downloads", "Music", "Pictures", "Public", "Templates", "Videos"];
        if SPECIAL.contains(&name) {
            let icon = format!("folder-{}", name.to_lowercase());
            if native::has_theme_icon(&icon) {
                return format!("image://icon/{icon}");
            }
        }
        return "image://icon/inode-directory".to_string();
    }
    let lower = name.to_lowercase();
    if lower.ends_with(".bak") || name.ends_with('~') || lower.ends_with(".backup") || lower.ends_with(".old") {
        for icon in ["application-x-backup", "document-revert", "edit-undo", "text-x-generic"] {
            if native::has_theme_icon(icon) {
                return format!("image://icon/{icon}");
            }
        }
    }
    let mime_icon = mime_type.replace('/', "-");
    if native::has_theme_icon(&mime_icon) {
        return format!("image://icon/{mime_icon}");
    }
    if native::has_theme_icon(mime_type) {
        return format!("image://icon/{mime_type}");
    }
    "image://icon/application-x-zerosize".to_string()
}

pub fn mime_starts_with(path: &str, prefix: &str) -> bool {
    !path.is_empty() && mime::for_file(path).starts_with(prefix)
}

pub fn expand_path(input: &str, current_dir: &str) -> String {
    let mut p = input.trim().to_string();
    if p.is_empty() {
        return p;
    }
    let home = paths::home();

    if p == "~" || p == "~/" {
        p = home.clone();
    } else if let Some(rest) = p.strip_prefix("~/") {
        p = format!("{home}/{rest}");
    } else if let Some(rest) = p.strip_prefix('~') {
        let (first, tail) = match rest.find('/') {
            Some(i) => (&rest[..i], &rest[i..]),
            None => (rest, ""),
        };
        // ~user/... when that user's home exists, else a folder in ours.
        let other = format!("/home/{first}");
        p = if !first.is_empty() && paths::is_dir(&other) {
            format!("{other}{tail}")
        } else {
            format!("{home}/{first}{tail}")
        };
    }

    let env_re = regex::Regex::new(r"\$(?:([A-Za-z_][A-Za-z0-9_]*)|\{([A-Za-z_][A-Za-z0-9_]*)\})").unwrap();
    while let Some(caps) = env_re.captures(&p) {
        let whole = caps.get(0).unwrap();
        let name = caps.get(1).or_else(|| caps.get(2)).unwrap().as_str();
        let mut value = std::env::var(name).unwrap_or_default();
        if value.is_empty() && (name == "HOME" || name == "home") {
            value = home.clone();
        }
        p.replace_range(whole.range(), &value);
    }

    if !p.starts_with('/') && !current_dir.is_empty() {
        p = format!("{current_dir}/{p}");
    }
    let trailing = p.ends_with('/');
    p = paths::clean_path(&p);
    if trailing && !p.ends_with('/') && p != "/" {
        p.push('/');
    }
    p
}

fn icon_for_mime_glyph(mime: &str) -> &'static str {
    if mime.starts_with("image/") {
        "image"
    } else if mime.starts_with("video/") {
        "movie"
    } else if mime.starts_with("audio/") {
        "audiotrack"
    } else if mime.contains("compressed") || mime.contains("zip") || mime.contains("tar") || mime.contains("7z") {
        "archive"
    } else if mime.contains("pdf") {
        "picture_as_pdf"
    } else {
        "description"
    }
}

pub fn path_suggestions(input: &str, current_dir: &str) -> Vec<Value> {
    let trimmed = input.trim();
    let home = paths::home();
    let default_dir = if current_dir.is_empty() { home.clone() } else { current_dir.to_string() };

    let (display_prefix, search_dir, filter) = if trimmed.is_empty() {
        (String::new(), default_dir, String::new())
    } else if trimmed == "~" || trimmed == "~/" {
        ("~/".to_string(), home.clone(), String::new())
    } else if trimmed.starts_with("~/") {
        let last = trimmed.rfind('/').unwrap();
        let prefix = trimmed[..=last].to_string();
        let dir = expand_path(&prefix, current_dir);
        (prefix, dir, trimmed[last + 1..].to_string())
    } else if let Some(rest) = trimmed.strip_prefix('~') {
        ("~/".to_string(), home.clone(), rest.to_string())
    } else if let Some(last) = trimmed.rfind('/') {
        let prefix = trimmed[..=last].to_string();
        let dir = expand_path(&prefix, current_dir);
        (prefix, dir, trimmed[last + 1..].to_string())
    } else {
        (String::new(), default_dir, trimmed.to_string())
    };

    let Ok(entries) = std::fs::read_dir(&search_dir) else { return Vec::new() };
    let mut items: Vec<(bool, String, String)> = entries
        .flatten()
        .map(|e| {
            let full = e.path().to_string_lossy().into_owned();
            (paths::is_dir(&full), e.file_name().to_string_lossy().into_owned(), full)
        })
        .collect();
    // QDir::DirsFirst | QDir::Name | QDir::IgnoreCase
    items.sort_by(|a, b| b.0.cmp(&a.0).then_with(|| a.1.to_lowercase().cmp(&b.1.to_lowercase())));

    let filter_lower = filter.to_lowercase();
    let mut results = Vec::new();
    for (is_dir, name, full) in items {
        if results.len() >= 30 {
            break;
        }
        if !filter.is_empty() && !name.to_lowercase().starts_with(&filter_lower) {
            continue;
        }
        let slash = if is_dir { "/" } else { "" };
        let icon = if is_dir { "folder" } else { icon_for_mime_glyph(&mime::for_file(&full)) };
        results.push(json!({
            "name": format!("{name}{slash}"),
            "displayPath": format!("{display_prefix}{name}{slash}"),
            "fullPath": format!("{full}{slash}"),
            "isDir": is_dir,
            "icon": icon,
        }));
    }
    results
}

pub fn completed_path(input: &str, current_dir: &str) -> String {
    let suggestions = path_suggestions(input, current_dir);
    let display = |v: &Value| v["displayPath"].as_str().unwrap_or("").to_string();
    let Some(first) = suggestions.first().map(display) else {
        return input.to_string();
    };
    if suggestions.len() == 1 {
        return first;
    }
    let first_chars: Vec<char> = first.chars().collect();
    let mut common = first_chars.len();
    for s in suggestions.iter().skip(1).map(display) {
        let other: Vec<char> = s.chars().collect();
        let mut j = 0;
        while j < common && j < other.len() && first_chars[j].to_lowercase().eq(other[j].to_lowercase()) {
            j += 1;
        }
        common = j;
    }
    if common > input.chars().count() {
        return first_chars[..common].iter().collect();
    }
    first
}

pub fn templates() -> Vec<Value> {
    let dir = paths::templates();
    let Ok(entries) = std::fs::read_dir(&dir) else { return Vec::new() };
    let mut files: Vec<(String, String)> = entries
        .flatten()
        .filter(|e| e.path().is_file())
        .map(|e| (e.file_name().to_string_lossy().into_owned(), e.path().to_string_lossy().into_owned()))
        .collect();
    files.sort();
    files
        .into_iter()
        .take(50)
        .map(|(name, path)| {
            let mime = mime::for_file(&path);
            let glyph = if mime.starts_with("image/") {
                "image"
            } else if mime.starts_with("audio/") {
                "music_note"
            } else if mime.starts_with("video/") {
                "movie"
            } else if mime.contains("shellscript") || mime.contains("executable") {
                "terminal"
            } else if mime.contains("spreadsheet") || mime.contains("csv") {
                "table"
            } else if mime.contains("presentation") {
                "slideshow"
            } else if mime.contains("pdf") {
                "picture_as_pdf"
            } else {
                "description"
            };
            json!({ "name": name, "path": path, "icon": glyph })
        })
        .collect()
}

pub fn describe_paths(paths_in: &[String]) -> Vec<Value> {
    paths_in
        .iter()
        .filter_map(|path| {
            let meta = std::fs::metadata(path).ok()?;
            let modified = system_time_msecs(meta.modified()).unwrap_or(0);
            let abs = std::fs::canonicalize(path)
                .map(|p| p.to_string_lossy().into_owned())
                .unwrap_or_else(|_| path.clone());
            Some(json!({
                "path": paths::clean_path(&abs),
                "name": paths::file_name(path),
                "isDir": meta.is_dir(),
                "modified": modified,
                "created": system_time_msecs(meta.created()).unwrap_or(modified),
                "accessed": system_time_msecs(meta.accessed()).unwrap_or(modified),
            }))
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sizes() {
        assert_eq!(format_size(512), "512 B");
        assert_eq!(format_size(1536), "1.5 KB");
        assert_eq!(format_size(5 * 1024 * 1024), "5.0 MB");
    }

    #[test]
    fn expands() {
        std::env::set_var("ATLAS_TEST_DIR", "/tmp/x");
        assert_eq!(expand_path("$ATLAS_TEST_DIR/a/../b", ""), "/tmp/x/b");
        assert_eq!(expand_path("sub/", "/srv"), "/srv/sub/");
    }
}
