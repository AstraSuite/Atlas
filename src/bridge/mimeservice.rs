//! MimeService: default applications and Open With, through mimeapps.list.

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
        include!("cxx-qt-lib/qlist.h");
        type QList_QVariant = cxx_qt_lib::QList<cxx_qt_lib::QVariant>;
        include!("cxx-qt-lib/qmap.h");
        type QMap_QString_QVariant = cxx_qt_lib::QMap<cxx_qt_lib::QMapPair_QString_QVariant>;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        type MimeService = super::MimeServiceRust;

        #[qinvokable]
        #[cxx_name = "getApplicationsForFile"]
        fn get_applications_for_file(self: &MimeService, file_path: &QString) -> QList_QVariant;
        #[qinvokable]
        #[cxx_name = "getAllApplications"]
        fn get_all_applications(self: &MimeService) -> QList_QVariant;
        #[qinvokable]
        #[cxx_name = "getDefaultApp"]
        fn get_default_app(self: &MimeService, mime_type: &QString) -> QMap_QString_QVariant;
        #[qinvokable]
        #[cxx_name = "getDefaultAppForFile"]
        fn get_default_app_for_file(self: &MimeService, file_path: &QString) -> QMap_QString_QVariant;
        #[qinvokable]
        #[cxx_name = "openWith"]
        fn open_with(self: &MimeService, file_path: &QString, desktop_file_path: &QString);
        #[qinvokable]
        #[cxx_name = "setDefaultApp"]
        fn set_default_app(self: &MimeService, mime_type: &QString, desktop_file_name: &QString) -> bool;
    }
}

use crate::bridge::native::{mime, qs, to_qvariant_list, to_qvariant_map, QVariantMap};
use crate::core::desktop::{self, App};
use crate::core::paths;
use cxx_qt_lib::{QList, QString, QVariant};
use serde_json::{json, Value};
use std::collections::HashSet;

#[derive(Default)]
pub struct MimeServiceRust;

/// A plain-XDG mimeapps.list. It is not QSettings-compatible: QSettings
/// escapes spaces in group names and slashes in keys, producing a file
/// xdg-open ignores, so it is parsed and written by hand.
#[derive(Default)]
struct Mimeapps {
    keys: Vec<(String, Vec<(String, String)>)>,
}

impl Mimeapps {
    fn section(&self, section: &str) -> Option<&Vec<(String, String)>> {
        self.keys.iter().find(|(s, _)| s == section).map(|(_, k)| k)
    }

    fn section_mut(&mut self, section: &str) -> &mut Vec<(String, String)> {
        if !self.keys.iter().any(|(s, _)| s == section) {
            self.keys.push((section.to_string(), Vec::new()));
        }
        &mut self.keys.iter_mut().find(|(s, _)| s == section).unwrap().1
    }

    fn value(&self, section: &str, key: &str) -> String {
        self.section(section)
            .and_then(|keys| keys.iter().find(|(k, _)| k == key))
            .map(|(_, v)| v.clone())
            .unwrap_or_default()
    }

    fn contains(&self, section: &str, key: &str) -> bool {
        self.section(section).is_some_and(|keys| keys.iter().any(|(k, _)| k == key))
    }

    fn set(&mut self, section: &str, key: &str, value: String) {
        let keys = self.section_mut(section);
        match keys.iter_mut().find(|(k, _)| k == key) {
            Some(entry) => entry.1 = value,
            None => keys.push((key.to_string(), value)),
        }
    }

    fn unset(&mut self, section: &str, key: &str) {
        if let Some((_, keys)) = self.keys.iter_mut().find(|(s, _)| s == section) {
            keys.retain(|(k, _)| k != key);
        }
    }

    fn parse(path: &str) -> Option<Mimeapps> {
        let mut data = Mimeapps::default();
        if !paths::exists(path) {
            return Some(data);
        }
        let text = std::fs::read_to_string(path).ok()?;
        // Canonical sections first, then heal group/key names an older
        // QSettings-based writer mangled.
        for pass in 0..2 {
            let mut section = String::new();
            let mut mangled = false;
            for raw in text.lines() {
                let t = raw.trim();
                if t.starts_with('[') && t.ends_with(']') {
                    let name = t[1..t.len() - 1].trim();
                    mangled = name == "Added%20Associations" || name == "Default%20Applications";
                    if mangled != (pass == 1) {
                        section.clear();
                        continue;
                    }
                    section = if mangled { name.replace("%20", " ") } else { name.to_string() };
                    data.section_mut(&section);
                    continue;
                }
                if section.is_empty() || t.is_empty() || t.starts_with('#') || t.starts_with(';') {
                    continue;
                }
                let Some((key, value)) = t.split_once('=') else { continue };
                let (mut key, mut value) = (key.trim().to_string(), value.trim().to_string());
                if key.is_empty() {
                    continue;
                }
                if mangled {
                    key = key.replace('\\', "/");
                    if value.len() >= 2 && value.starts_with('"') && value.ends_with('"') {
                        value = value[1..value.len() - 1].to_string();
                    }
                    if data.contains(&section, &key) {
                        continue;
                    }
                }
                data.set(&section, &key, value);
            }
        }
        Some(data)
    }

    fn write(&self, path: &str) -> bool {
        let target = std::fs::canonicalize(path).map(|p| p.to_string_lossy().into_owned()).unwrap_or(path.to_string());
        let mut out = String::new();
        for (i, (section, keys)) in self.keys.iter().enumerate() {
            if i > 0 {
                out.push('\n');
            }
            out.push_str(&format!("[{section}]\n"));
            for (k, v) in keys {
                out.push_str(&format!("{k}={v}\n"));
            }
        }
        // Write a sibling and rename over, keeping the old permissions.
        let temp = format!("{target}.atlas-tmp");
        let perms = std::fs::metadata(&target).map(|m| m.permissions()).ok();
        if std::fs::write(&temp, out).is_err() {
            eprintln!("Atlas: cannot write {target}");
            return false;
        }
        if let Some(perms) = perms {
            let _ = std::fs::set_permissions(&temp, perms);
        }
        if std::fs::rename(&temp, &target).is_err() {
            let _ = std::fs::remove_file(&temp);
            eprintln!("Atlas: failed to commit {target}");
            return false;
        }
        true
    }
}

fn split(value: &str) -> Vec<String> {
    desktop::split_list(value)
}

fn supports_mime(app: &App, mime_name: &str, aliases: &[String]) -> bool {
    app.mime_types.iter().any(|m| m == mime_name) || aliases.first().is_some_and(|a| app.mime_types.contains(a))
}

pub fn default_app(mime_type: &str) -> Option<App> {
    if mime_type.is_empty() {
        return None;
    }
    let mut desktop_id = String::new();
    let mut removed: Vec<String> = Vec::new();
    if let Some(user) = Mimeapps::parse(&format!("{}/mimeapps.list", paths::config_home())) {
        desktop_id = user.value("Default Applications", mime_type);
        if desktop_id.is_empty() {
            desktop_id = split(&user.value("Added Associations", mime_type)).into_iter().next().unwrap_or_default();
        }
        removed = split(&user.value("Removed Associations", mime_type));
    }
    if desktop_id.is_empty() {
        for dir in ["/etc/xdg", "/usr/share/applications", "/usr/local/share/applications"] {
            let path = format!("{dir}/mimeapps.list");
            if !paths::exists(&path) {
                continue;
            }
            if let Some(system) = Mimeapps::parse(&path) {
                desktop_id = system.value("Default Applications", mime_type);
                if !desktop_id.is_empty() {
                    break;
                }
            }
        }
    }
    if desktop_id.is_empty() {
        if let Some((_, out, _)) = desktop::run_timeout("xdg-mime", &["query", "default", mime_type], 1000) {
            desktop_id = out.trim().to_string();
        }
    }
    if desktop_id.contains(';') {
        desktop_id = split(&desktop_id).into_iter().next().unwrap_or_default();
    }
    if removed.contains(&desktop_id) {
        desktop_id.clear();
    }
    if !desktop_id.is_empty() {
        for dir in desktop::application_dirs() {
            let full = format!("{dir}/{desktop_id}");
            if paths::exists(&full) {
                // A NoDisplay handler (e.g. swappy) is a valid default too.
                if let Some(app) = App::parse(&full, true) {
                    return Some(app);
                }
            }
        }
    }
    desktop::scan_applications(true).into_iter().find(|a| a.mime_types.iter().any(|m| m == mime_type))
}

/// Launches `file_path` with the application in `desktop_file_path`.
pub fn open_with(file_path: &str, desktop_file_path: &str) {
    // NoDisplay entries can be picked from Open With (e.g. swappy) too.
    let Some(app) = App::parse(desktop_file_path, true) else { return };
    let mut exec = app.exec.clone();
    for code in ["%f", "%F", "%u", "%U", "%d", "%D", "%n", "%N", "%i", "%c", "%k", "%v", "%m"] {
        exec = exec.replace(code, "");
    }
    let mut args = desktop::split_command(exec.trim());
    if args.is_empty() {
        return;
    }
    let program = args.remove(0);
    args.push(file_path.to_string());
    if app.terminal {
        // Terminal apps (e.g. micro) need a terminal emulator around them.
        let mut launch = vec!["-e".to_string(), program];
        launch.extend(args);
        desktop::spawn_detached(&desktop::resolve_terminal(), &launch, None);
        return;
    }
    desktop::spawn_detached(&program, &args, None);
}

impl qobject::MimeService {
    fn get_all_applications(&self) -> QList<QVariant> {
        let apps: Vec<Value> = desktop::scan_applications(false).iter().map(App::to_json).collect();
        to_qvariant_list(&apps)
    }

    fn get_applications_for_file(&self, file_path: &QString) -> QList<QVariant> {
        let mime_name = mime::for_file(&file_path.to_string());
        let aliases = mime::aliases(&mime_name);
        let mut recommended = Vec::new();
        let mut others = Vec::new();
        let mut seen = HashSet::new();
        let mut add = |app: &App| {
            if !seen.insert(app.id.clone()) {
                return;
            }
            let matches = supports_mime(app, &mime_name, &aliases);
            let mut entry = app.to_json();
            entry["isRecommended"] = json!(matches);
            if matches {
                recommended.push(entry);
            } else {
                others.push(entry);
            }
        };
        for app in desktop::scan_applications(false) {
            add(&app);
        }
        // NoDisplay entries hide from launchers, but one declaring this file's
        // type is still a valid choice (swappy ships NoDisplay=true).
        for app in desktop::scan_applications(true) {
            if app.no_display && supports_mime(&app, &mime_name, &aliases) {
                add(&app);
            }
        }
        recommended.extend(others);
        to_qvariant_list(&recommended)
    }

    fn get_default_app(&self, mime_type: &QString) -> QVariantMap {
        default_app(&mime_type.to_string()).and_then(|a| to_qvariant_map(&a.to_json())).unwrap_or_default()
    }

    fn get_default_app_for_file(&self, file_path: &QString) -> QVariantMap {
        let path = file_path.to_string();
        if path.is_empty() {
            return QVariantMap::default();
        }
        self.get_default_app(&qs(&mime::for_file(&path)))
    }

    fn open_with(&self, file_path: &QString, desktop_file_path: &QString) {
        open_with(&file_path.to_string(), &desktop_file_path.to_string());
    }

    fn set_default_app(&self, mime_type: &QString, desktop_file_name: &QString) -> bool {
        let mime_type = mime_type.to_string();
        let desktop_file = desktop_file_name.to_string();
        if mime_type.is_empty() || desktop_file.is_empty() {
            return false;
        }
        let clean_id = paths::file_name(&desktop_file);

        // Register the default for every type in the same group the app
        // declares (all image/* for an image viewer), so one choice covers
        // each extension it supports.
        let mut mimes: Vec<String> = Vec::new();
        if let Some(app) = desktop::find_desktop_file(&desktop_file).and_then(|p| App::parse(&p, true)) {
            let group = mime_type.split('/').next().unwrap_or("");
            for m in app.mime_types {
                if m == "*/*" || m == "application/octet-stream" {
                    continue;
                }
                if m == mime_type || (!group.is_empty() && m.starts_with(&format!("{group}/"))) {
                    mimes.push(m);
                }
            }
        }
        if !mimes.contains(&mime_type) {
            mimes.insert(0, mime_type.clone());
        }
        let mut seen = HashSet::new();
        mimes.retain(|m| seen.insert(m.clone()));

        let config = paths::config_home();
        let _ = std::fs::create_dir_all(&config);
        let desktops = std::env::var("XDG_CURRENT_DESKTOP").unwrap_or_default().to_lowercase();
        for d in desktops.split(':').filter(|d| !d.is_empty()) {
            let shadow = format!("{config}/{d}-mimeapps.list");
            if std::fs::metadata(&shadow).is_ok_and(|m| m.len() > 0) {
                eprintln!("Atlas: per-desktop associations file shadows mimeapps.list: {shadow}");
                break;
            }
        }
        let path = format!("{config}/mimeapps.list");
        let Some(mut data) = Mimeapps::parse(&path) else {
            eprintln!("Atlas: cannot read {path}");
            return false;
        };
        for m in &mimes {
            let mut defaults = split(&data.value("Default Applications", m));
            defaults.retain(|d| *d != clean_id);
            defaults.insert(0, clean_id.clone());
            data.set("Default Applications", m, defaults.join(";"));

            let mut added = split(&data.value("Added Associations", m));
            added.retain(|d| *d != clean_id);
            added.insert(0, clean_id.clone());
            data.set("Added Associations", m, format!("{};", added.join(";")));

            let mut removed = split(&data.value("Removed Associations", m));
            let before = removed.len();
            removed.retain(|d| *d != clean_id);
            if removed.len() != before {
                if removed.is_empty() {
                    data.unset("Removed Associations", m);
                } else {
                    data.set("Removed Associations", m, format!("{};", removed.join(";")));
                }
            }
        }
        data.write(&path)
    }
}
