//! Mounted volumes, standing in for QStorageInfo.

use std::ffi::CString;

#[derive(Clone, Debug, Default)]
pub struct Volume {
    pub root: String,
    pub device: String,
    pub fs_type: String,
    pub read_only: bool,
}

/// Undoes the octal escapes (`\040` for a space) used in /proc mount tables.
fn unescape(field: &str) -> String {
    let bytes = field.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'\\' && i + 4 <= bytes.len() {
            if let Ok(v) = u8::from_str_radix(&field[i + 1..i + 4], 8) {
                out.push(v);
                i += 4;
                continue;
            }
        }
        out.push(bytes[i]);
        i += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}

/// Every mounted volume, in mount order.
pub fn mounted_volumes() -> Vec<Volume> {
    let Ok(text) = std::fs::read_to_string("/proc/self/mountinfo") else {
        return Vec::new();
    };
    let mut volumes = Vec::new();
    for line in text.lines() {
        // id parent major:minor root mountpoint options [optional...] - fstype source superopts
        let Some((left, right)) = line.split_once(" - ") else { continue };
        let left: Vec<&str> = left.split(' ').collect();
        let right: Vec<&str> = right.split(' ').collect();
        if left.len() < 6 || right.len() < 2 {
            continue;
        }
        let options = left[5];
        volumes.push(Volume {
            root: unescape(left[4]),
            device: unescape(right[1]),
            fs_type: right[0].to_string(),
            read_only: options.split(',').any(|o| o == "ro"),
        });
    }
    volumes
}

/// The volume holding `path`: the mount point that is its longest prefix.
pub fn volume_for(path: &str) -> Option<Volume> {
    let path = super::paths::clean_path(path);
    let resolved = std::fs::canonicalize(&path)
        .map(|p| p.to_string_lossy().into_owned())
        .unwrap_or(path);
    mounted_volumes()
        .into_iter()
        .filter(|v| {
            v.root == "/" || resolved == v.root || resolved.starts_with(&format!("{}/", v.root))
        })
        .max_by_key(|v| v.root.len())
}

/// `QStorageInfo(path).rootPath()`.
pub fn root_path(path: &str) -> String {
    volume_for(path).map(|v| v.root).unwrap_or_default()
}

/// (bytes available to us, total bytes) for the filesystem holding `path`.
pub fn space(path: &str) -> Option<(i64, i64)> {
    let c = CString::new(path).ok()?;
    let mut st: libc::statvfs = unsafe { std::mem::zeroed() };
    if unsafe { libc::statvfs(c.as_ptr(), &mut st) } != 0 {
        return None;
    }
    let frsize = st.f_frsize as i64;
    Some((st.f_bavail as i64 * frsize, st.f_blocks as i64 * frsize))
}

#[cfg(test)]
mod tests {
    #[test]
    fn unescapes_spaces() {
        assert_eq!(super::unescape("/run/media/My\\040Disk"), "/run/media/My Disk");
        assert_eq!(super::unescape("/plain"), "/plain");
    }
}
