//! The blocking work behind FileOperations, run on worker threads.

use super::{paths, trash};
use super::desktop::shell_quote;
use std::fs;
use std::io::{Read, Write};
use std::os::unix::fs::symlink;
use std::sync::atomic::{AtomicBool, Ordering};

pub fn entry_exists(path: &str) -> bool {
    fs::symlink_metadata(path).is_ok()
}

fn canonical(path: &str) -> String {
    fs::canonicalize(path).map(|p| p.to_string_lossy().into_owned()).unwrap_or_default()
}

pub fn calculate_total_size(paths_in: &[String]) -> i64 {
    let mut total = 0;
    let mut pending: Vec<String> = paths_in.to_vec();
    while let Some(p) = pending.pop() {
        let Ok(meta) = fs::metadata(&p) else { continue };
        if meta.is_dir() {
            if let Ok(entries) = fs::read_dir(&p) {
                pending.extend(entries.flatten().map(|e| e.path().to_string_lossy().into_owned()));
            }
        } else {
            total += meta.len() as i64;
        }
    }
    total
}

/// Copy progress shared with the caller: bytes done so far, of `total`.
pub struct Progress<'a> {
    pub processed: i64,
    pub total: i64,
    pub report: &'a mut dyn FnMut(f64, &str),
}

/// Copies a file, folder or symlink. Files are written to a `.atlas-partial`
/// sibling first so a cancelled or failed copy never leaves a truncated file.
pub fn copy_recursively(src: &str, dest: &str, cancel: &AtomicBool, progress: &mut Progress) -> bool {
    if cancel.load(Ordering::Relaxed) {
        return false;
    }
    let src_canonical = canonical(src);
    if !src_canonical.is_empty() && src_canonical == canonical(dest) {
        return false;
    }
    let Ok(link_meta) = fs::symlink_metadata(src) else { return false };

    if link_meta.file_type().is_symlink() {
        let Ok(target) = fs::read_link(src) else { return false };
        if entry_exists(dest) {
            let _ = fs::remove_file(dest);
        }
        return symlink(target, dest).is_ok();
    }

    if link_meta.is_dir() {
        let _ = fs::create_dir_all(dest);
        let Ok(entries) = fs::read_dir(src) else { return false };
        for e in entries.flatten() {
            if cancel.load(Ordering::Relaxed) {
                return false;
            }
            let name = e.file_name().to_string_lossy().into_owned();
            let child_src = e.path().to_string_lossy().into_owned();
            if !copy_recursively(&child_src, &format!("{dest}/{name}"), cancel, progress) {
                return false;
            }
        }
        return true;
    }

    let partial = format!("{dest}.atlas-partial");
    let abandon = |partial: &str| {
        let _ = fs::remove_file(partial);
        false
    };
    let Ok(mut input) = fs::File::open(src) else { return false };
    let _ = fs::remove_file(&partial);
    let Ok(mut output) = fs::File::create(&partial) else { return false };
    let mut buf = vec![0u8; 64 * 1024];
    let mut last_report = std::time::Instant::now() - std::time::Duration::from_secs(1);
    loop {
        if cancel.load(Ordering::Relaxed) {
            drop(output);
            return abandon(&partial);
        }
        let read = match input.read(&mut buf) {
            Ok(0) => break,
            Ok(n) => n,
            Err(e) if e.kind() == std::io::ErrorKind::Interrupted => continue,
            Err(_) => {
                drop(output);
                return abandon(&partial);
            }
        };
        if output.write_all(&buf[..read]).is_err() {
            drop(output);
            return abandon(&partial);
        }
        progress.processed += read as i64;
        if progress.total > 0 && last_report.elapsed().as_millis() >= 50 {
            last_report = std::time::Instant::now();
            (progress.report)(progress.processed as f64 / progress.total as f64, src);
        }
    }
    if output.flush().is_err() {
        drop(output);
        return abandon(&partial);
    }
    drop(output);
    let _ = fs::set_permissions(&partial, link_meta.permissions());
    if entry_exists(dest) && fs::remove_file(dest).is_err() {
        return abandon(&partial);
    }
    if fs::rename(&partial, dest).is_err() {
        return abandon(&partial);
    }
    true
}

pub fn remove_recursively(path: &str) -> bool {
    match fs::symlink_metadata(path) {
        Ok(m) if m.is_dir() => fs::remove_dir_all(path).is_ok(),
        Ok(_) => fs::remove_file(path).is_ok(),
        Err(_) => false,
    }
}

/// Runs the user's transfer command (%F = quoted sources, %d = quoted
/// destination folder) and waits for it.
pub fn run_custom_transfer(command: &str, sources: &[String], destination_dir: &str) -> bool {
    if command.trim().is_empty() || sources.is_empty() {
        return false;
    }
    let quoted: Vec<String> = sources.iter().map(|s| shell_quote(s)).collect();
    let cmd = command.replace("%F", &quoted.join(" ")).replace("%d", &shell_quote(destination_dir));
    let output = std::process::Command::new("/bin/sh")
        .arg("-c")
        .arg(&cmd)
        .current_dir(destination_dir)
        .stdin(std::process::Stdio::null())
        .output();
    match output {
        Ok(o) if o.status.success() => true,
        Ok(o) => {
            eprintln!("atlas.fileops: Custom transfer command failed: {cmd} {}", String::from_utf8_lossy(&o.stderr));
            false
        }
        Err(_) => false,
    }
}

pub fn run_rsync(sources: &[String], destination_dir: &str, remove_source: bool) -> bool {
    let mut args: Vec<String> = vec!["-avh".into()];
    if remove_source {
        args.push("--remove-source-files".into());
    }
    args.extend(["--progress".into(), "--checksum".into()]);
    args.extend(sources.iter().cloned());
    args.push(format!("{destination_dir}/"));
    std::process::Command::new("rsync")
        .args(&args)
        .stdin(std::process::Stdio::null())
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .is_ok_and(|s| s.success())
}

const TRASH_PATH_SET: &percent_encoding::AsciiSet = &percent_encoding::NON_ALPHANUMERIC
    .remove(b'-')
    .remove(b'.')
    .remove(b'_')
    .remove(b'~')
    .remove(b'/');

/// Moves one item to the trash of its volume. Returns its .trashinfo path.
pub fn trash_one(path: &str) -> Option<String> {
    let abs = paths::clean_path(&if path.starts_with('/') {
        path.to_string()
    } else {
        format!("{}/{path}", std::env::current_dir().ok()?.to_string_lossy())
    });
    let location = trash::for_source_file(&abs, true);
    if !location.is_valid() {
        return None;
    }
    let file_name = paths::file_name(&abs);
    let mut dest = format!("{}/{file_name}", location.files_dir);
    let mut info = format!("{}/{file_name}.trashinfo", location.info_dir);
    let mut counter = 1;
    while entry_exists(&dest) || entry_exists(&info) {
        let unique = format!("{file_name}.{counter}");
        counter += 1;
        dest = format!("{}/{unique}", location.files_dir);
        info = format!("{}/{unique}.trashinfo", location.info_dir);
    }

    let mut original = abs.clone();
    if !location.top_dir.is_empty() {
        let prefix = format!("{}/", paths::clean_path(&location.top_dir));
        if let Some(rest) = original.strip_prefix(&prefix) {
            original = rest.to_string();
        }
    }
    let encoded = percent_encoding::utf8_percent_encode(&original, TRASH_PATH_SET).to_string();
    let date = chrono::Local::now().format("%Y-%m-%dT%H:%M:%S");
    let _ = fs::write(&info, format!("[Trash Info]\nPath={encoded}\nDeletionDate={date}\n"));

    if fs::rename(&abs, &dest).is_err() {
        // Another filesystem: copy, then remove the original.
        let cancel = AtomicBool::new(false);
        let mut noop = |_: f64, _: &str| {};
        let total = fs::metadata(&abs).map(|m| m.len() as i64).unwrap_or(0);
        let mut progress = Progress { processed: 0, total, report: &mut noop };
        if copy_recursively(&abs, &dest, &cancel, &mut progress) {
            remove_recursively(&abs);
        } else {
            let _ = fs::remove_file(&info);
            return None;
        }
    }
    Some(info)
}

/// Restores a trashed item (given by its path in files/ or its .trashinfo).
/// Returns the restored file name.
pub fn restore_from_trash(target_path: &str) -> Option<String> {
    let trashed = if target_path.ends_with(".trashinfo") {
        let base = paths::parent(&paths::parent(target_path));
        format!("{base}/files/{}", paths::complete_base_name(target_path))
    } else {
        target_path.to_string()
    };
    let location = trash::for_trashed_file(&trashed);
    if !location.is_valid() {
        return None;
    }
    let info = format!("{}/{}.trashinfo", location.info_dir, paths::file_name(&trashed));
    let (encoded, _) = trash::read_trash_info(&info)?;
    let original = trash::resolve_original_path(&location, &encoded);
    if original.is_empty() {
        return None;
    }
    let _ = fs::create_dir_all(paths::parent(&original));
    if fs::rename(&trashed, &original).is_ok() {
        let _ = fs::remove_file(&info);
        return Some(paths::file_name(&original));
    }
    None
}

pub fn empty_trash() -> bool {
    let mut all_success = true;
    let mut clear = |dir: &str| {
        let Ok(entries) = fs::read_dir(dir) else { return };
        for e in entries.flatten() {
            if !remove_recursively(&e.path().to_string_lossy()) {
                all_success = false;
            }
        }
    };
    for location in trash::all() {
        clear(&location.files_dir);
        clear(&location.info_dir);
    }
    let _ = fs::create_dir_all(trash::home_trash_files_dir());
    let _ = fs::create_dir_all(format!("{}/info", trash::home_trash_dir()));
    all_success
}

fn run_ok(program: &str, args: &[&str], working_dir: Option<&str>) -> bool {
    let mut cmd = std::process::Command::new(program);
    cmd.args(args).stdin(std::process::Stdio::null()).stdout(std::process::Stdio::null()).stderr(std::process::Stdio::null());
    if let Some(dir) = working_dir {
        cmd.current_dir(dir);
    }
    cmd.status().is_ok_and(|s| s.success())
}

pub fn extract_archive(archive: &str, dest: &str) -> bool {
    let _ = fs::create_dir_all(dest);
    let name = paths::file_name(archive).to_lowercase();
    let tar = |flag: &[&str]| {
        let mut args: Vec<&str> = flag.to_vec();
        args.extend([archive, "-C", dest]);
        run_ok("tar", &args, None)
    };
    if name.ends_with(".zip") {
        run_ok("unzip", &["-o", archive, "-d", dest], None)
    } else if name.ends_with(".tar.gz") || name.ends_with(".tgz") {
        tar(&["-xzf"])
    } else if name.ends_with(".tar.xz") || name.ends_with(".txz") {
        tar(&["-xJf"])
    } else if name.ends_with(".tar.zst") {
        tar(&["--zstd", "-xf"])
    } else if name.ends_with(".tar.bz2") || name.ends_with(".tbz2") {
        tar(&["-xjf"])
    } else if name.ends_with(".tar") {
        tar(&["-xf"])
    } else if name.ends_with(".7z") || name.ends_with(".rar") {
        run_ok("7z", &["x", "-y", &format!("-o{dest}"), archive], None)
    } else {
        false
    }
}

pub fn create_archive(sources: &[String], destination: &str, format: &str) -> bool {
    let fmt = format.to_lowercase();
    let lower = destination.to_lowercase();
    let names: Vec<&str> = sources.iter().map(|s| s.rsplit('/').next().unwrap_or(s)).collect();
    let workdir = sources.first().map(|s| paths::parent(s));
    let with_names = |prefix: &[&'static str]| -> Vec<String> {
        let mut args: Vec<String> = prefix.iter().map(|s| s.to_string()).collect();
        args.push(destination.to_string());
        args.extend(names.iter().map(|n| n.to_string()));
        args
    };
    let run = |program: &str, args: Vec<String>, dir: Option<&str>| {
        let refs: Vec<&str> = args.iter().map(String::as_str).collect();
        run_ok(program, &refs, dir)
    };
    if fmt == "zip" || lower.ends_with(".zip") {
        run("zip", with_names(&["-r"]), workdir.as_deref())
    } else if fmt == "tar.gz" || fmt == "tgz" || lower.ends_with(".tar.gz") {
        run("tar", with_names(&["-czf"]), workdir.as_deref())
    } else if fmt == "tar.zst" || lower.ends_with(".tar.zst") {
        run("tar", with_names(&["--zstd", "-cf"]), workdir.as_deref())
    } else if fmt == "7z" || lower.ends_with(".7z") {
        let mut args = vec!["a".to_string(), destination.to_string()];
        args.extend(sources.iter().cloned());
        run("7z", args, None)
    } else {
        false
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn trash_and_restore_round_trip() {
        let root = std::env::temp_dir().join(format!("atlas-trash-test-{}", std::process::id()));
        let _ = fs::remove_dir_all(&root);
        let data = root.join("data");
        let work = root.join("work");
        fs::create_dir_all(&work).unwrap();
        std::env::set_var("XDG_DATA_HOME", &data);
        let file = work.join("a file.txt");
        fs::write(&file, "x").unwrap();
        let dir = work.join("docs");
        fs::create_dir_all(dir.join("inner")).unwrap();

        let info_file = trash_one(file.to_str().unwrap()).expect("trash file");
        let info_dir = trash_one(dir.to_str().unwrap()).expect("trash dir");
        assert!(!file.exists() && !dir.exists());
        let info_text = fs::read_to_string(&info_file).unwrap();
        assert!(info_text.contains("Path=") && info_text.contains("a%20file.txt"), "{info_text}");

        assert_eq!(restore_from_trash(&info_file).as_deref(), Some("a file.txt"));
        assert_eq!(restore_from_trash(&info_dir).as_deref(), Some("docs"));
        assert!(file.exists() && dir.join("inner").exists());
        let _ = fs::remove_dir_all(&root);
    }
}
