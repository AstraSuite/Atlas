//! Desktop entry files, launching processes, and the user's terminal.

use super::paths;
use std::collections::{HashMap, HashSet};
use std::process::{Command, Stdio};

/// One parsed .desktop file: group name -> key -> value. Keys keep their
/// locale suffix (`Name[de]`); only the unlocalised key is looked up.
#[derive(Default)]
pub struct DesktopFile {
    groups: HashMap<String, HashMap<String, String>>,
}

impl DesktopFile {
    pub fn load(path: &str) -> Option<Self> {
        let text = std::fs::read_to_string(path).ok()?;
        let mut file = DesktopFile::default();
        let mut group = String::new();
        for line in text.lines() {
            let line = line.trim();
            if line.is_empty() || line.starts_with('#') {
                continue;
            }
            if line.starts_with('[') && line.ends_with(']') {
                group = line[1..line.len() - 1].trim().to_string();
                continue;
            }
            let Some((key, value)) = line.split_once('=') else { continue };
            // Later occurrences override earlier ones (desktop entry spec).
            file.groups
                .entry(group.clone())
                .or_default()
                .insert(key.trim().to_string(), value.trim().to_string());
        }
        Some(file)
    }

    pub fn get(&self, group: &str, key: &str) -> String {
        self.groups
            .iter()
            .find(|(g, _)| g.eq_ignore_ascii_case(group))
            .and_then(|(_, keys)| keys.iter().find(|(k, _)| k.eq_ignore_ascii_case(key)))
            .map(|(_, v)| v.clone())
            .unwrap_or_default()
    }

    pub fn entry(&self, key: &str) -> String {
        self.get("Desktop Entry", key)
    }

    pub fn entry_bool(&self, key: &str) -> bool {
        self.entry(key).eq_ignore_ascii_case("true")
    }

    pub fn entry_list(&self, key: &str) -> Vec<String> {
        split_list(&self.entry(key))
    }
}

pub fn split_list(value: &str) -> Vec<String> {
    value.split(';').map(str::trim).filter(|s| !s.is_empty()).map(String::from).collect()
}

pub fn application_dirs() -> Vec<String> {
    vec![
        format!("{}/.local/share/applications", paths::home()),
        "/usr/local/share/applications".to_string(),
        "/usr/share/applications".to_string(),
    ]
}

/// .desktop files in `dir`, sorted by name like QDir's default listing.
pub fn desktop_files_in(dir: &str) -> Vec<String> {
    let Ok(entries) = std::fs::read_dir(dir) else { return Vec::new() };
    let mut files: Vec<String> = entries
        .flatten()
        .filter(|e| e.path().is_file())
        .map(|e| e.path().to_string_lossy().into_owned())
        .filter(|p| p.ends_with(".desktop"))
        .collect();
    files.sort();
    files
}

/// An installed application, from a `Type=Application` desktop entry.
#[derive(Clone, Debug, Default)]
pub struct App {
    pub id: String,
    pub path: String,
    pub name: String,
    pub exec: String,
    pub icon: String,
    pub comment: String,
    pub mime_types: Vec<String>,
    pub categories: Vec<String>,
    pub no_display: bool,
    pub terminal: bool,
}

impl App {
    pub fn parse(path: &str, include_no_display: bool) -> Option<App> {
        let file = DesktopFile::load(path)?;
        let no_display = file.entry_bool("NoDisplay");
        if (no_display && !include_no_display) || file.entry_bool("Hidden") {
            return None;
        }
        // Type defaults to "Application" when absent.
        let kind = file.entry("Type");
        if !kind.is_empty() && !kind.eq_ignore_ascii_case("Application") {
            return None;
        }
        let name = file.entry("Name");
        let exec = file.entry("Exec");
        if name.is_empty() || exec.is_empty() {
            return None;
        }
        Some(App {
            id: paths::file_name(path),
            path: path.to_string(),
            name,
            exec,
            icon: file.entry("Icon"),
            comment: file.entry("Comment"),
            mime_types: file.entry_list("MimeType"),
            categories: file.entry_list("Categories"),
            no_display,
            terminal: file.entry_bool("Terminal"),
        })
    }

    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "id": self.id,
            "path": self.path,
            "name": self.name,
            "exec": self.exec,
            "icon": if self.icon.is_empty() { "application-x-executable" } else { &self.icon },
            "comment": self.comment,
            "mimeTypes": self.mime_types,
            "noDisplay": self.no_display,
            "terminal": self.terminal,
        })
    }
}

/// Every installed application; earlier directories shadow later ones.
pub fn scan_applications(include_no_display: bool) -> Vec<App> {
    let mut apps = Vec::new();
    let mut seen = HashSet::new();
    for dir in application_dirs() {
        for path in desktop_files_in(&dir) {
            let id = paths::file_name(&path);
            if seen.contains(&id) {
                continue;
            }
            if let Some(app) = App::parse(&path, include_no_display) {
                seen.insert(id);
                apps.push(app);
            }
        }
    }
    apps
}

pub fn find_desktop_file(desktop_id: &str) -> Option<String> {
    if paths::exists(desktop_id) {
        return Some(desktop_id.to_string());
    }
    application_dirs()
        .into_iter()
        .map(|d| format!("{d}/{desktop_id}"))
        .find(|p| paths::exists(p))
}

/// The user's terminal emulator: $TERMINAL, else the first one installed.
pub fn resolve_terminal() -> String {
    if let Ok(term) = std::env::var("TERMINAL") {
        if !term.is_empty() {
            return term;
        }
    }
    const CANDIDATES: &[&str] =
        &["foot", "kitty", "alacritty", "ghostty", "wezterm", "konsole", "gnome-terminal", "xterm"];
    CANDIDATES
        .iter()
        .find(|c| paths::find_executable(c).is_some())
        .unwrap_or(&"xterm")
        .to_string()
}

pub fn shell_quote(value: &str) -> String {
    format!("'{}'", value.replace('\'', "'\\''"))
}

/// `QProcess::splitCommand`: splits on spaces, honouring double quotes
/// (with `""` as a literal quote inside them).
pub fn split_command(command: &str) -> Vec<String> {
    let mut args = Vec::new();
    let mut tmp = String::new();
    let mut quote_count = 0;
    let mut in_quote = false;
    for c in command.chars() {
        if c == '"' {
            quote_count += 1;
            if quote_count == 3 {
                quote_count = 0;
                tmp.push(c);
            }
            continue;
        }
        if quote_count > 0 {
            if quote_count == 1 {
                in_quote = !in_quote;
            }
            quote_count = 0;
        }
        if !in_quote && c.is_whitespace() {
            if !tmp.is_empty() {
                args.push(std::mem::take(&mut tmp));
            }
        } else {
            tmp.push(c);
        }
    }
    if !tmp.is_empty() {
        args.push(tmp);
    }
    args
}

/// Starts a process that outlives us, reaping it in the background so it
/// never lingers as a zombie.
pub fn spawn_detached(program: &str, args: &[String], working_dir: Option<&str>) -> bool {
    spawn_detached_env(program, args, working_dir, &[])
}

pub fn spawn_detached_env(program: &str, args: &[String], working_dir: Option<&str>, env: &[(String, String)]) -> bool {
    let mut cmd = Command::new(program);
    cmd.args(args).stdin(Stdio::null()).stdout(Stdio::null()).stderr(Stdio::null());
    if let Some(dir) = working_dir.filter(|d| !d.is_empty()) {
        cmd.current_dir(dir);
    }
    for (k, v) in env {
        cmd.env(k, v);
    }
    // Own session, so closing Atlas (or its terminal) doesn't take it down.
    unsafe {
        use std::os::unix::process::CommandExt;
        cmd.pre_exec(|| {
            libc::setsid();
            Ok(())
        });
    }
    match cmd.spawn() {
        Ok(mut child) => {
            std::thread::spawn(move || {
                let _ = child.wait();
            });
            true
        }
        Err(_) => false,
    }
}

/// Runs a program to completion, returning (exit code, stdout, stderr).
/// A missing program reports exit code -1.
pub fn run(program: &str, args: &[&str]) -> (i32, String, String) {
    match Command::new(program).args(args).stdin(Stdio::null()).output() {
        Ok(out) => (
            out.status.code().unwrap_or(-1),
            String::from_utf8_lossy(&out.stdout).into_owned(),
            String::from_utf8_lossy(&out.stderr).into_owned(),
        ),
        Err(e) => (-1, String::new(), e.to_string()),
    }
}

/// Like `run`, but gives up after `timeout_ms` (killing the child).
pub fn run_timeout(program: &str, args: &[&str], timeout_ms: u64) -> Option<(i32, String, String)> {
    use std::io::Read;
    let mut child = Command::new(program)
        .args(args)
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .ok()?;
    let mut stdout = child.stdout.take()?;
    let mut stderr = child.stderr.take()?;
    let out_thread = std::thread::spawn(move || {
        let mut s = Vec::new();
        let _ = stdout.read_to_end(&mut s);
        s
    });
    let err_thread = std::thread::spawn(move || {
        let mut s = Vec::new();
        let _ = stderr.read_to_end(&mut s);
        s
    });
    let deadline = std::time::Instant::now() + std::time::Duration::from_millis(timeout_ms);
    let status = loop {
        match child.try_wait() {
            Ok(Some(status)) => break status,
            Ok(None) if std::time::Instant::now() < deadline => {
                std::thread::sleep(std::time::Duration::from_millis(10))
            }
            _ => {
                let _ = child.kill();
                let _ = child.wait();
                return None;
            }
        }
    };
    let out = out_thread.join().unwrap_or_default();
    let err = err_thread.join().unwrap_or_default();
    Some((
        status.code().unwrap_or(-1),
        String::from_utf8_lossy(&out).into_owned(),
        String::from_utf8_lossy(&err).into_owned(),
    ))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn splits_like_qprocess() {
        assert_eq!(split_command(r#"a "b c" d"#), vec!["a", "b c", "d"]);
        assert_eq!(split_command(r#"a """"#), vec!["a", "\""]);
        assert_eq!(split_command("  "), Vec::<String>::new());
    }
}
