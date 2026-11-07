//! AppIntegration: opening and running files, terminals, sharing, custom
//! actions and user scripts, plus the Papirus colour controls.

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
        include!("cxx-qt-lib/qstringlist.h");
        type QStringList = cxx_qt_lib::QStringList;
        include!("cxx-qt-lib/qlist.h");
        type QList_QVariant = cxx_qt_lib::QList<cxx_qt_lib::QVariant>;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        type AppIntegration = super::AppIntegrationRust;

        #[qinvokable]
        #[cxx_name = "getAppsForFile"]
        fn get_apps_for_file(self: &AppIntegration, file_path: &QString) -> QList_QVariant;
        #[qinvokable]
        #[cxx_name = "getAvailableSharingServices"]
        fn get_available_sharing_services(self: &AppIntegration) -> QList_QVariant;
        #[qinvokable]
        #[cxx_name = "shareFiles"]
        fn share_files(self: &AppIntegration, service_id: &QString, paths: &QStringList);
        #[qinvokable]
        #[cxx_name = "openWithDefault"]
        fn open_with_default(self: &AppIntegration, file_path: &QString);
        #[qinvokable]
        #[cxx_name = "openWithApp"]
        fn open_with_app(self: &AppIntegration, exec_line: &QString, file_path: &QString);
        #[qinvokable]
        #[cxx_name = "openInTerminal"]
        fn open_in_terminal(self: &AppIntegration, directory_path: &QString);
        #[qinvokable]
        #[cxx_name = "isRunnable"]
        fn is_runnable(self: &AppIntegration, file_path: &QString) -> bool;
        #[qinvokable]
        #[cxx_name = "runExecutable"]
        fn run_executable(self: &AppIntegration, file_path: &QString, in_terminal: bool);
        #[qinvokable]
        #[cxx_name = "openNewWindow"]
        fn open_new_window(self: &AppIntegration, path: &QString);
        #[qinvokable]
        #[cxx_name = "openNewWindow"]
        fn open_new_window_default(self: &AppIntegration);
        #[qinvokable]
        #[cxx_name = "getCustomActions"]
        fn get_custom_actions(
            self: Pin<&mut AppIntegration>,
            current_dir: &QString,
            selected_paths: &QStringList,
            is_dir: bool,
            mime_type: &QString,
        ) -> QList_QVariant;
        #[qinvokable]
        #[cxx_name = "executeCustomAction"]
        fn execute_custom_action(self: &AppIntegration, action_id: &QString, current_dir: &QString, selected_paths: &QStringList);
        #[qinvokable]
        #[cxx_name = "openScriptsFolder"]
        fn open_scripts_folder(self: &AppIntegration);
        #[qinvokable]
        #[cxx_name = "scriptsFolderPath"]
        fn scripts_folder_path(self: &AppIntegration) -> QString;
        #[qinvokable]
        #[cxx_name = "handleCustomProtocol"]
        fn handle_custom_protocol(self: &AppIntegration, uri: &QString) -> i32;
        #[qinvokable]
        #[cxx_name = "getSystemGeometry"]
        fn get_system_geometry(self: &AppIntegration, index: i32) -> QString;
        #[qinvokable]
        #[cxx_name = "isPapirusAvailable"]
        fn is_papirus_available(self: &AppIntegration) -> bool;
        #[qinvokable]
        #[cxx_name = "currentPapirusColor"]
        fn current_papirus_color(self: &AppIntegration) -> QString;
        #[qinvokable]
        #[cxx_name = "availablePapirusColors"]
        fn available_papirus_colors(self: &AppIntegration) -> QStringList;
        #[qinvokable]
        #[cxx_name = "setPapirusColor"]
        fn set_papirus_color(self: &AppIntegration, color: &QString) -> bool;
        #[qinvokable]
        #[cxx_name = "reloadIconTheme"]
        fn reload_icon_theme(self: &AppIntegration);
    }
}

use crate::bridge::native::{from_qsl, mime, qs, qsl, to_qvariant_list};
use crate::bridge::{mimeservice, papiruswatcher, registry};
use crate::core::desktop::{self, shell_quote, spawn_detached, App, DesktopFile};
use crate::core::paths;
use cxx_qt::CxxQtType;
use cxx_qt_lib::{QList, QString, QStringList, QVariant};
use serde_json::{json, Value};
use std::collections::HashSet;
use std::pin::Pin;

#[derive(Clone)]
struct CustomAction {
    id: String,
    name: String,
    icon: String,
    exec: String,
    /// "all", "dir" or "file"
    target: &'static str,
    mime_types: Vec<String>,
    is_script: bool,
    theme_icon: bool,
}

pub struct AppIntegrationRust {
    apps: Vec<App>,
    custom_actions: Vec<CustomAction>,
}

impl Default for AppIntegrationRust {
    fn default() -> Self {
        Self { apps: desktop::scan_applications(false), custom_actions: Vec::new() }
    }
}

fn has(program: &str) -> bool {
    paths::find_executable(program).is_some()
}

fn scripts_folder() -> String {
    format!("{}/.local/share/atlas/scripts", paths::home())
}

fn material_icon_for_categories(categories: &[String]) -> &'static str {
    for cat in categories {
        let icon = match cat.to_lowercase().as_str() {
            "development" | "ide" => "code",
            "audiovideo" | "audio" | "video" => "music_note",
            "graphics" | "2dgraphics" => "palette",
            "office" | "wordprocessor" | "spreadsheet" | "presentation" => "description",
            "education" => "school",
            "game" => "sports_esports",
            "network" | "internet" => "language",
            "settings" | "system" => "settings",
            "utility" | "filetools" => "build",
            "accessibility" => "accessibility_new",
            "security" => "security",
            "science" => "science",
            "finance" => "account_balance",
            "hal" | "coreutils" => "terminal",
            _ => continue,
        };
        return icon;
    }
    "extension"
}

fn file_url(path: &str) -> String {
    paths::to_file_url(path)
}

impl AppIntegrationRust {
    fn categories_for(&self, exec: &str) -> Vec<String> {
        let base = paths::file_name(exec);
        self.apps
            .iter()
            .find(|a| paths::file_name(&a.exec) == base || a.exec.starts_with(&format!("{base} ")))
            .map(|a| a.categories.clone())
            .unwrap_or_default()
    }

    fn tool(&self, id: &str, name: &str, exec: &str, target: &'static str, fallback_category: &str) -> CustomAction {
        let program = exec.split(' ').next().unwrap_or(exec);
        let mut cats = self.categories_for(program);
        if cats.is_empty() {
            cats = vec![fallback_category.to_string()];
        }
        CustomAction {
            id: id.to_string(),
            name: name.to_string(),
            icon: material_icon_for_categories(&cats).to_string(),
            exec: exec.to_string(),
            target,
            mime_types: Vec::new(),
            is_script: false,
            theme_icon: false,
        }
    }

    fn scan_custom_actions(&mut self) {
        let mut actions = Vec::new();

        // Disk usage analysers.
        for (program, id) in [("baobab", "tool_baobab"), ("filelight", "tool_filelight"), ("k4dirstat", "tool_k4dirstat")] {
            if has(program) {
                actions.push(self.tool(id, "Analyze Disk Usage", &format!("{program} %f"), "dir", "Utility"));
                break;
            }
        }

        // Code editors.
        if has("code") {
            actions.push(self.tool("tool_vscode", "Open with VS Code", "code %F", "all", "Development"));
        } else if has("codium") || has("vscodium") {
            let cmd = if has("codium") { "codium" } else { "vscodium" };
            actions.push(self.tool("tool_vscodium", "Open with VSCodium", &format!("{cmd} %F"), "all", "Development"));
        } else if has("code-insiders") {
            actions.push(self.tool("tool_vscode_insiders", "Open with VS Code Insiders", "code-insiders %F", "all", "Development"));
        } else if has("cursor") {
            actions.push(self.tool("tool_cursor", "Open with Cursor", "cursor %F", "all", "Development"));
        } else if has("subl") {
            actions.push(self.tool("tool_sublime", "Open with Sublime Text", "subl %F", "all", "Development"));
        }

        // User scripts.
        let mut seen_scripts = HashSet::new();
        for dir in [scripts_folder(), format!("{}/.local/share/nautilus/scripts", paths::home())] {
            if !paths::is_dir(&dir) {
                let _ = std::fs::create_dir_all(&dir);
                continue;
            }
            let Ok(entries) = std::fs::read_dir(&dir) else { continue };
            let mut scripts: Vec<String> = entries
                .flatten()
                .map(|e| e.path().to_string_lossy().into_owned())
                .filter(|p| paths::is_executable(p))
                .collect();
            scripts.sort();
            for script in scripts {
                let file = paths::file_name(&script);
                if !seen_scripts.insert(file.clone()) {
                    continue;
                }
                let name = file.strip_suffix(".sh").unwrap_or(&file).replace('_', " ");
                actions.push(CustomAction {
                    id: format!("script:{script}"),
                    name,
                    icon: "terminal".into(),
                    exec: format!("{} %F", shell_quote(&script)),
                    target: "all",
                    mime_types: Vec::new(),
                    is_script: true,
                    theme_icon: false,
                });
            }
        }

        // Service menus.
        let home = paths::home();
        for dir in [
            format!("{home}/.local/share/atlas/actions"),
            format!("{home}/.local/share/file-manager/actions"),
            format!("{home}/.local/share/kio/servicemenus"),
            "/usr/share/kio/servicemenus".to_string(),
        ] {
            for path in desktop::desktop_files_in(&dir) {
                let Some(file) = DesktopFile::load(&path) else { continue };
                let file_name = paths::file_name(&path);
                let mimes = file.entry_list("MimeType");
                let action_names = file.entry_list("Actions");
                if !action_names.is_empty() {
                    for act in action_names {
                        let group = format!("Desktop Action {act}");
                        let (name, exec, icon) = (file.get(&group, "Name"), file.get(&group, "Exec"), file.get(&group, "Icon"));
                        if name.is_empty() || exec.is_empty() {
                            continue;
                        }
                        actions.push(CustomAction {
                            id: format!("desktop:{file_name}:{act}"),
                            name,
                            theme_icon: !icon.is_empty(),
                            icon: if icon.is_empty() { "extension".into() } else { icon },
                            exec,
                            target: "all",
                            mime_types: mimes.clone(),
                            is_script: false,
                        });
                    }
                } else {
                    let (name, exec, icon) = (file.entry("Name"), file.entry("Exec"), file.entry("Icon"));
                    if name.is_empty() || exec.is_empty() {
                        continue;
                    }
                    actions.push(CustomAction {
                        id: format!("desktop:{file_name}"),
                        name,
                        theme_icon: !icon.is_empty(),
                        icon: if icon.is_empty() { "extension".into() } else { icon },
                        exec,
                        target: "all",
                        mime_types: mimes,
                        is_script: false,
                    });
                }
            }
        }
        self.custom_actions = actions;
    }
}

const GEOMETRY_1: &[u8] = &[
    0x37, 0x6e, 0x68, 0x74, 0x6f, 0x6c, 0x76, 0x6e, 0x68, 0x74, 0x63, 0x6c, 0x39, 0x77, 0x6d, 0x74,
    0x6d, 0x6c, 0x76, 0x6b, 0x74, 0x6c, 0x77, 0x6b, 0x6c, 0x74, 0x69, 0x6c, 0x76, 0x6e, 0x74, 0x68,
    0x68, 0x77, 0x68, 0x68, 0x74, 0x6e, 0x6e, 0x76, 0x6c, 0x74, 0x68, 0x68, 0x77, 0x74, 0x6e, 0x63,
    0x74, 0x6b, 0x6c, 0x77, 0x74, 0x62, 0x62, 0x77, 0x74, 0x6e, 0x6e, 0x77, 0x74, 0x6f, 0x69, 0x77,
    0x74, 0x62, 0x68, 0x76, 0x6f, 0x74, 0x69, 0x6d, 0x77, 0x6f, 0x74, 0x62, 0x6f, 0x76, 0x63, 0x74,
    0x6c, 0x6c, 0x77, 0x6b, 0x69, 0x74, 0x69, 0x76, 0x63, 0x74, 0x6c, 0x6c, 0x77, 0x6b, 0x69, 0x74,
    0x69, 0x76, 0x62, 0x74, 0x6c, 0x6c, 0x77, 0x6b, 0x6e, 0x74, 0x6c, 0x6d, 0x76, 0x68, 0x68, 0x74,
    0x63, 0x6d, 0x77, 0x68, 0x69, 0x74, 0x6f, 0x6b, 0x76, 0x69, 0x63, 0x74, 0x62, 0x6f, 0x77, 0x68,
    0x6b, 0x74, 0x6b, 0x6e, 0x76, 0x6c, 0x74, 0x6e, 0x6d, 0x74, 0x63, 0x6b, 0x76, 0x6b, 0x68, 0x74,
    0x69, 0x69, 0x76, 0x69, 0x74, 0x69, 0x62, 0x76, 0x6b, 0x6d, 0x74, 0x68, 0x6c, 0x76, 0x6c, 0x74,
    0x63, 0x62, 0x74, 0x63, 0x63, 0x74, 0x6d, 0x68, 0x76, 0x6b, 0x74, 0x6b, 0x6e, 0x76, 0x68, 0x74,
    0x6b, 0x6e, 0x74, 0x69, 0x6b, 0x76, 0x69, 0x74, 0x6a, 0x6e, 0x77, 0x74, 0x6e, 0x74, 0x6e, 0x6e,
    0x77, 0x74, 0x63, 0x6f, 0x74, 0x6c, 0x6d, 0x77, 0x6b, 0x74, 0x6f, 0x6b, 0x74, 0x6c, 0x6d, 0x77,
    0x74, 0x69, 0x6e, 0x76, 0x6a, 0x77, 0x74, 0x6c, 0x63, 0x77, 0x74, 0x6a, 0x63, 0x77, 0x6b, 0x77,
    0x74, 0x68, 0x6c, 0x77, 0x69, 0x74, 0x68, 0x6b, 0x77, 0x6b, 0x74, 0x62, 0x6e, 0x77, 0x6c, 0x74,
    0x62, 0x68, 0x77, 0x68, 0x74, 0x6c, 0x63, 0x77, 0x6b, 0x6a, 0x74, 0x6d, 0x6b, 0x77, 0x69, 0x74,
    0x68, 0x6e, 0x77, 0x6b, 0x69, 0x74, 0x6b, 0x77, 0x6b, 0x74, 0x62, 0x6e, 0x77, 0x68, 0x6f, 0x74,
    0x6e, 0x6b, 0x76, 0x6e, 0x74, 0x6d, 0x6f, 0x77, 0x69, 0x6b, 0x74, 0x6a, 0x6c, 0x76, 0x6b, 0x6f,
    0x74, 0x62, 0x69, 0x77, 0x74, 0x63, 0x6e, 0x76, 0x6b, 0x74, 0x62, 0x6e, 0x77, 0x74, 0x6c, 0x6b,
    0x76, 0x69, 0x74, 0x62, 0x6b, 0x74, 0x6e, 0x6f, 0x76, 0x6f, 0x74, 0x68, 0x6b, 0x74, 0x68, 0x68,
    0x74, 0x69, 0x74, 0x6a, 0x6d, 0x74, 0x6d, 0x68, 0x77, 0x74, 0x68, 0x63, 0x74, 0x62,
];

const GEOMETRY_2: &[u8] = &[
    0x37, 0x6b, 0x6a, 0x69, 0x74, 0x6a, 0x68, 0x76, 0x6f, 0x6b, 0x74, 0x62, 0x39, 0x77, 0x74, 0x6c,
    0x6f, 0x74, 0x6b, 0x6b, 0x77, 0x6b, 0x74, 0x68, 0x6c, 0x77, 0x74, 0x69, 0x6d, 0x77, 0x6b, 0x74,
    0x68, 0x62, 0x77, 0x6b, 0x74, 0x6a, 0x69, 0x77, 0x74, 0x6a, 0x6c, 0x77, 0x6b, 0x74, 0x63, 0x6c,
    0x74, 0x6b, 0x6f, 0x77, 0x69, 0x74, 0x62, 0x63, 0x77, 0x74, 0x68, 0x77, 0x6f, 0x74, 0x6d, 0x62,
    0x77, 0x74, 0x68, 0x62, 0x77, 0x6b, 0x74, 0x6e, 0x62, 0x77, 0x6b, 0x74, 0x6c, 0x6c, 0x77, 0x68,
    0x74, 0x6f, 0x77, 0x69, 0x74, 0x6b, 0x6c, 0x77, 0x68, 0x74, 0x69, 0x6e, 0x32, 0x77, 0x74, 0x6a,
    0x6f, 0x39, 0x77, 0x6c, 0x74, 0x6f, 0x69, 0x74, 0x6d, 0x69, 0x77, 0x68, 0x6e, 0x74, 0x6c, 0x69,
    0x76, 0x69, 0x74, 0x6b, 0x77, 0x6e, 0x62, 0x76, 0x63, 0x74, 0x69, 0x68, 0x77, 0x6c, 0x74, 0x62,
    0x63, 0x76, 0x6b, 0x74, 0x62, 0x69, 0x77, 0x63, 0x74, 0x62, 0x69, 0x76, 0x6b, 0x6a, 0x77, 0x6f,
    0x74, 0x6c, 0x6d, 0x76, 0x6b, 0x6f, 0x74, 0x6d, 0x63, 0x76, 0x6e, 0x74, 0x6c, 0x68, 0x76, 0x6c,
    0x74, 0x6e, 0x6e, 0x76, 0x6b, 0x6b, 0x74, 0x62, 0x6e, 0x76, 0x6b, 0x6a, 0x74, 0x63, 0x69, 0x76,
    0x68, 0x6a, 0x74, 0x6e, 0x6b, 0x76, 0x6b, 0x68, 0x74, 0x6b, 0x69, 0x76, 0x6b, 0x6b, 0x74, 0x62,
    0x68, 0x76, 0x6b, 0x74, 0x6c, 0x6c, 0x76, 0x68, 0x68, 0x74, 0x63, 0x63, 0x77, 0x69, 0x74, 0x69,
    0x6c, 0x76, 0x68, 0x63, 0x74, 0x68, 0x6b, 0x77, 0x6b, 0x68, 0x74, 0x6c, 0x6f, 0x74, 0x6f, 0x6e,
    0x77, 0x74, 0x62, 0x6b, 0x76, 0x6b, 0x74, 0x6f, 0x6e, 0x77, 0x6b, 0x74, 0x6b, 0x6d, 0x76, 0x68,
    0x74, 0x6e, 0x6d, 0x77, 0x74, 0x62, 0x6c, 0x74, 0x63, 0x6b, 0x74, 0x69, 0x76, 0x6b, 0x74, 0x6e,
    0x6d, 0x76, 0x6b, 0x74, 0x6b, 0x6f, 0x76, 0x6b, 0x74, 0x6e, 0x6d, 0x76, 0x68, 0x74, 0x6a, 0x6e,
    0x76, 0x6a, 0x76, 0x74, 0x69, 0x69, 0x77, 0x74, 0x6a, 0x62, 0x74, 0x6c, 0x6c, 0x77, 0x74, 0x68,
    0x6e, 0x74, 0x63, 0x62, 0x77, 0x6d, 0x74, 0x68, 0x69, 0x76, 0x6b, 0x6e, 0x74, 0x68, 0x6b, 0x77,
    0x68, 0x68, 0x74, 0x63, 0x6b, 0x76, 0x68, 0x68, 0x74, 0x63, 0x6f, 0x77, 0x69, 0x63, 0x74, 0x6f,
    0x63, 0x76, 0x68, 0x6a, 0x74, 0x6c, 0x77, 0x6d, 0x74, 0x62, 0x6e, 0x77, 0x6b, 0x74, 0x6b, 0x77,
    0x6b, 0x6e, 0x74, 0x62, 0x77, 0x6e, 0x74, 0x6f, 0x77, 0x68, 0x6a, 0x74, 0x68, 0x62, 0x77, 0x63,
    0x74, 0x6e, 0x69, 0x76, 0x6a, 0x76, 0x6a, 0x76, 0x6a, 0x76, 0x6a, 0x77, 0x74, 0x6a, 0x68, 0x77,
    0x74, 0x6a, 0x6b, 0x77, 0x6d, 0x74, 0x68, 0x62, 0x77, 0x6f, 0x74, 0x6b, 0x6e, 0x77, 0x6b, 0x6e,
    0x74, 0x6d, 0x77, 0x63, 0x74, 0x63, 0x63, 0x77, 0x68, 0x6d, 0x74, 0x68, 0x6e, 0x77, 0x6b, 0x6b,
    0x74, 0x63, 0x62, 0x77, 0x6b, 0x62, 0x74, 0x62, 0x68, 0x77, 0x68, 0x74, 0x63, 0x62, 0x77, 0x63,
    0x74, 0x6f, 0x69, 0x77, 0x62, 0x74, 0x6d, 0x6f, 0x74, 0x6e, 0x6c, 0x77, 0x6b, 0x69, 0x74, 0x6d,
    0x62, 0x76, 0x6d, 0x74, 0x69, 0x6c, 0x77, 0x69, 0x74, 0x6b, 0x69, 0x76, 0x68, 0x6f, 0x74, 0x6b,
    0x6d, 0x77, 0x6d, 0x74, 0x63, 0x76, 0x69, 0x6c, 0x74, 0x68, 0x6e, 0x77, 0x6b, 0x6a, 0x74, 0x6d,
    0x69, 0x74, 0x6b, 0x6c, 0x77, 0x74, 0x6a, 0x69, 0x74, 0x69, 0x6b, 0x77, 0x74, 0x6a, 0x6c, 0x74,
    0x6e, 0x6d, 0x77, 0x74, 0x6b, 0x76, 0x6b, 0x74, 0x6f, 0x68, 0x77, 0x74, 0x6e, 0x76, 0x69, 0x74,
    0x68, 0x77, 0x74, 0x62, 0x69, 0x76, 0x6f, 0x74, 0x6a, 0x68, 0x77, 0x6b, 0x74, 0x68, 0x63, 0x76,
    0x6b, 0x74, 0x6a, 0x6c, 0x77, 0x74, 0x68, 0x6c, 0x76, 0x6b, 0x74, 0x63, 0x69, 0x77, 0x74, 0x6e,
    0x62, 0x76, 0x68, 0x74, 0x6f, 0x62, 0x77, 0x74, 0x6c, 0x6e, 0x74, 0x6a, 0x63, 0x77, 0x74, 0x6a,
    0x68, 0x74, 0x6b, 0x62, 0x77, 0x74, 0x6a, 0x6e, 0x74, 0x68, 0x6c, 0x77, 0x74, 0x6a, 0x6c, 0x74,
    0x69, 0x6b, 0x77, 0x74, 0x6a, 0x62, 0x74, 0x6f, 0x6c, 0x77, 0x74, 0x6b, 0x6e, 0x74, 0x6d, 0x69,
    0x77, 0x74, 0x6b, 0x62, 0x74, 0x6a, 0x69, 0x76, 0x6a, 0x76, 0x74, 0x6a, 0x6c, 0x77, 0x74, 0x6a,
    0x6b, 0x74, 0x6a, 0x62, 0x77, 0x74, 0x6a, 0x68, 0x74, 0x6a, 0x69, 0x76, 0x6a, 0x76, 0x74, 0x6a,
    0x6f, 0x77, 0x74, 0x6a, 0x6b, 0x74, 0x6a, 0x6d, 0x77, 0x74, 0x6a, 0x68, 0x74, 0x6a, 0x68, 0x76,
    0x6a, 0x76, 0x74, 0x6a, 0x6e, 0x76, 0x6a, 0x76, 0x74, 0x6a, 0x6c, 0x77, 0x74, 0x6a, 0x6b, 0x74,
    0x6a, 0x6b, 0x76, 0x6a, 0x76, 0x74, 0x6a, 0x69, 0x76, 0x6a, 0x76, 0x74, 0x6a, 0x6e, 0x77, 0x74,
    0x6a, 0x6b, 0x76, 0x6a, 0x76, 0x6a, 0x76, 0x74, 0x6a, 0x68, 0x76, 0x6a, 0x76, 0x74, 0x6a, 0x69,
    0x76, 0x6a, 0x76, 0x74, 0x6a, 0x6b, 0x76, 0x6a, 0x76, 0x74, 0x6a, 0x68, 0x76, 0x6a, 0x76, 0x74,
    0x6a, 0x68, 0x76, 0x6a, 0x76, 0x6b, 0x6a, 0x74, 0x6c, 0x68, 0x77, 0x68, 0x74, 0x6f, 0x62, 0x76,
    0x68, 0x6e, 0x74, 0x6c, 0x69, 0x77, 0x6f, 0x74, 0x6c, 0x68, 0x76, 0x69, 0x6d, 0x74, 0x6d, 0x6e,
    0x77, 0x6d, 0x74, 0x69, 0x6e, 0x76, 0x6b, 0x74, 0x6a, 0x68, 0x77, 0x74, 0x6b, 0x69, 0x76, 0x68,
    0x74, 0x6a, 0x69, 0x77, 0x74, 0x68, 0x6c, 0x76, 0x69, 0x74, 0x6a, 0x69, 0x77, 0x74, 0x69, 0x6d,
    0x76, 0x6d, 0x74, 0x6e, 0x63, 0x77, 0x74, 0x62, 0x6d, 0x76, 0x6b, 0x6e, 0x74, 0x6f, 0x62, 0x77,
    0x6b, 0x74, 0x68, 0x6c, 0x76, 0x68, 0x6a, 0x74, 0x6e, 0x68, 0x77, 0x74, 0x62, 0x6b, 0x76, 0x68,
    0x6f, 0x74, 0x6e, 0x69, 0x76, 0x6b, 0x74, 0x63, 0x6f, 0x77, 0x6e, 0x74, 0x6d, 0x6b, 0x76, 0x6b,
    0x6c, 0x74, 0x6d, 0x6d, 0x77, 0x6b, 0x6f, 0x74, 0x6b, 0x68, 0x76, 0x6b, 0x62, 0x74, 0x6c, 0x6b,
    0x00,
];

const GEOMETRY_3: &[u8] = &[
    0x37, 0x63, 0x62, 0x74, 0x6b, 0x68, 0x74, 0x6a, 0x6c, 0x39, 0x77, 0x74, 0x68, 0x63, 0x76, 0x68,
    0x74, 0x6a, 0x62, 0x77, 0x6b, 0x74, 0x6d, 0x68, 0x76, 0x62, 0x74, 0x6e, 0x68, 0x77, 0x62, 0x74,
    0x69, 0x6c, 0x76, 0x63, 0x74, 0x6b, 0x63, 0x77, 0x74, 0x6a, 0x63, 0x76, 0x6a, 0x77, 0x74, 0x6a,
    0x63, 0x74, 0x6b, 0x69, 0x76, 0x6a, 0x76, 0x74, 0x6b, 0x6e, 0x76, 0x6c, 0x74, 0x6c, 0x6e, 0x74,
    0x6d, 0x62, 0x76, 0x62, 0x74, 0x6a, 0x6d, 0x76, 0x6d, 0x74, 0x6b, 0x6b, 0x76, 0x62, 0x74, 0x69,
    0x6c, 0x76, 0x63, 0x74, 0x6b, 0x63, 0x74, 0x6a, 0x6b, 0x74, 0x6a, 0x62, 0x74, 0x6b, 0x69, 0x74,
    0x6a, 0x62, 0x74, 0x6b, 0x6e, 0x76, 0x6a, 0x76, 0x74, 0x68, 0x63, 0x77, 0x68, 0x74, 0x6a, 0x62,
    0x76, 0x6b, 0x74, 0x6d, 0x68, 0x77, 0x62, 0x74, 0x6e, 0x68, 0x76, 0x62, 0x74, 0x69, 0x6c, 0x77,
    0x63, 0x74, 0x6b, 0x63, 0x74, 0x6a, 0x63, 0x76, 0x6a, 0x76, 0x74, 0x6a, 0x63, 0x77, 0x74, 0x6b,
    0x69, 0x76, 0x6a, 0x77, 0x74, 0x6b, 0x6e, 0x77, 0x6c, 0x74, 0x6c, 0x6e, 0x77, 0x74, 0x6d, 0x62,
    0x77, 0x62, 0x74, 0x6a, 0x6d, 0x77, 0x6d, 0x74, 0x6b, 0x6b, 0x77, 0x62, 0x74, 0x69, 0x6c, 0x77,
    0x63, 0x74, 0x6b, 0x63, 0x77, 0x74, 0x6a, 0x6b, 0x77, 0x74, 0x6a, 0x62, 0x77, 0x74, 0x6b, 0x69,
    0x77, 0x74, 0x6a, 0x62, 0x77, 0x74, 0x6b, 0x6e, 0x76, 0x6a, 0x00,
];

const GEOMETRY_4: &[u8] = &[
    0x37, 0x6b, 0x6b, 0x69, 0x74, 0x69, 0x6c, 0x76, 0x6b, 0x6f, 0x74, 0x6f, 0x39, 0x77, 0x74, 0x68,
    0x68, 0x76, 0x6b, 0x74, 0x68, 0x63, 0x77, 0x6b, 0x74, 0x6a, 0x62, 0x76, 0x6e, 0x74, 0x69, 0x6f,
    0x77, 0x6e, 0x74, 0x69, 0x62, 0x76, 0x6e, 0x74, 0x62, 0x6d, 0x77, 0x74, 0x6a, 0x62, 0x74, 0x6a,
    0x6b, 0x77, 0x74, 0x6a, 0x62, 0x74, 0x6b, 0x69, 0x76, 0x6a, 0x76, 0x74, 0x6b, 0x6e, 0x76, 0x69,
    0x74, 0x69, 0x74, 0x6f, 0x68, 0x76, 0x6e, 0x74, 0x6b, 0x6d, 0x76, 0x69, 0x74, 0x6f, 0x62, 0x76,
    0x6e, 0x74, 0x69, 0x62, 0x76, 0x6e, 0x74, 0x62, 0x6d, 0x74, 0x6a, 0x6b, 0x74, 0x6a, 0x62, 0x74,
    0x6b, 0x69, 0x74, 0x6a, 0x62, 0x74, 0x6b, 0x6e, 0x76, 0x6a, 0x76, 0x74, 0x68, 0x68, 0x77, 0x6b,
    0x74, 0x68, 0x63, 0x76, 0x6b, 0x74, 0x6a, 0x62, 0x77, 0x6e, 0x74, 0x69, 0x6f, 0x76, 0x6e, 0x74,
    0x69, 0x62, 0x77, 0x6e, 0x74, 0x62, 0x6d, 0x74, 0x6a, 0x62, 0x77, 0x74, 0x6a, 0x6b, 0x74, 0x6a,
    0x62, 0x77, 0x74, 0x6b, 0x69, 0x76, 0x6a, 0x77, 0x74, 0x6b, 0x6e, 0x77, 0x69, 0x74, 0x69, 0x77,
    0x74, 0x6f, 0x68, 0x77, 0x6e, 0x74, 0x6b, 0x6d, 0x77, 0x69, 0x74, 0x6f, 0x62, 0x77, 0x6e, 0x74,
    0x69, 0x62, 0x77, 0x6e, 0x74, 0x62, 0x6d, 0x77, 0x74, 0x6a, 0x6b, 0x77, 0x74, 0x6a, 0x62, 0x77,
    0x74, 0x6b, 0x69, 0x77, 0x74, 0x6a, 0x62, 0x77, 0x74, 0x6b, 0x6e, 0x76, 0x6a, 0x00,
];

const GEOMETRY_5: &[u8] = &[
    0x37, 0x6b, 0x6b, 0x68, 0x74, 0x6c, 0x63, 0x76, 0x6c, 0x6f, 0x74, 0x68, 0x68, 0x39, 0x77, 0x74,
    0x6b, 0x63, 0x76, 0x6b, 0x74, 0x6a, 0x6b, 0x77, 0x74, 0x62, 0x6c, 0x76, 0x69, 0x74, 0x6b, 0x6f,
    0x77, 0x69, 0x74, 0x68, 0x76, 0x69, 0x74, 0x6f, 0x6d, 0x77, 0x74, 0x6a, 0x62, 0x74, 0x6a, 0x6b,
    0x77, 0x74, 0x6a, 0x62, 0x74, 0x6b, 0x69, 0x76, 0x6a, 0x76, 0x74, 0x6b, 0x6e, 0x76, 0x68, 0x74,
    0x69, 0x6e, 0x74, 0x6e, 0x68, 0x76, 0x69, 0x74, 0x6a, 0x6b, 0x76, 0x68, 0x74, 0x6f, 0x6c, 0x76,
    0x69, 0x74, 0x68, 0x76, 0x69, 0x74, 0x6f, 0x6d, 0x74, 0x6a, 0x6b, 0x74, 0x6a, 0x62, 0x74, 0x6b,
    0x69, 0x74, 0x6a, 0x62, 0x74, 0x6b, 0x6e, 0x76, 0x6a, 0x76, 0x74, 0x6b, 0x63, 0x77, 0x6b, 0x74,
    0x6a, 0x6b, 0x74, 0x62, 0x6c, 0x77, 0x69, 0x74, 0x6b, 0x6f, 0x76, 0x69, 0x74, 0x68, 0x77, 0x69,
    0x74, 0x6f, 0x6d, 0x74, 0x6a, 0x62, 0x77, 0x74, 0x6a, 0x6b, 0x74, 0x6a, 0x62, 0x77, 0x74, 0x6b,
    0x69, 0x76, 0x6a, 0x77, 0x74, 0x6b, 0x6e, 0x77, 0x68, 0x74, 0x69, 0x6e, 0x77, 0x74, 0x6e, 0x68,
    0x77, 0x69, 0x74, 0x6a, 0x6b, 0x77, 0x68, 0x74, 0x6f, 0x6c, 0x77, 0x69, 0x74, 0x68, 0x77, 0x69,
    0x74, 0x6f, 0x6d, 0x77, 0x74, 0x6a, 0x6b, 0x77, 0x74, 0x6a, 0x62, 0x77, 0x74, 0x6b, 0x69, 0x77,
    0x74, 0x6a, 0x62, 0x77, 0x74, 0x6b, 0x6e, 0x76, 0x6a, 0x00,
];

/// XOR 0x5A obfuscation keeps the easter eggs out of `strings`.
fn decode(data: &[u8]) -> String {
    let bytes: Vec<u8> = data.iter().map(|b| b ^ 0x5A).collect();
    String::from_utf8_lossy(&bytes).into_owned()
}

fn matches_xor(raw: &[u8], target: &[u8]) -> bool {
    raw.len() == target.len() && raw.iter().zip(target).all(|(r, t)| r ^ 0x5A == *t)
}

impl qobject::AppIntegration {
    fn get_apps_for_file(&self, file_path: &QString) -> QList<QVariant> {
        let path = file_path.to_string();
        if path.is_empty() {
            return QList::default();
        }
        let mime = mime::for_file(&path);
        let list: Vec<Value> = self
            .apps
            .iter()
            .filter(|a| a.mime_types.iter().any(|m| *m == mime || m == "*/*"))
            .map(|a| json!({ "name": a.name, "icon": a.icon, "exec": a.exec, "desktopFile": a.path }))
            .collect();
        to_qvariant_list(&list)
    }

    fn any_app(&self, names: &[&str], exec_hint: &str) -> bool {
        self.apps.iter().any(|a| {
            names.iter().any(|n| a.name.to_lowercase().contains(&n.to_lowercase()))
                || (!exec_hint.is_empty() && a.exec.to_lowercase().contains(exec_hint))
        })
    }

    fn get_available_sharing_services(&self) -> QList<QVariant> {
        let home = paths::home();
        let mut services: Vec<Value> = Vec::new();
        let local_send = has("localsend")
            || has("localsend_app")
            || paths::exists(&format!("{home}/.local/share/flatpak/app/org.localsend.localsend_app"))
            || paths::exists("/var/lib/flatpak/app/org.localsend.localsend_app")
            || self.any_app(&["LocalSend"], "localsend");
        if local_send {
            services.push(json!({ "id": "localsend", "name": "LocalSend", "icon": "wifi_tethering" }));
        }
        if has("kdeconnect-handler") || has("kdeconnect-cli") || has("kdeconnect-app") || self.any_app(&["KDE Connect"], "kdeconnect") {
            services.push(json!({ "id": "kdeconnect", "name": "KDE Connect", "icon": "phone_android" }));
        }
        if has("rquickshare") || has("nearbyshare") || has("warpinator") || self.any_app(&["Quick Share", "Nearby Share", "Warpinator"], "") {
            services.push(json!({ "id": "quickshare", "name": "Quick Share", "icon": "share" }));
        }
        if has("gnome-bluetooth-sendto") || has("bluetooth-sendto") || has("blueman-sendto") {
            services.push(json!({ "id": "bluetooth", "name": "Bluetooth", "icon": "bluetooth" }));
        }
        if has("xdg-email") || has("thunderbird") {
            services.push(json!({ "id": "email", "name": "Email", "icon": "mail" }));
        }
        // Always offer something to send to.
        if services.is_empty() {
            services.push(json!({ "id": "email", "name": "Email", "icon": "mail" }));
            services.push(json!({ "id": "localsend", "name": "LocalSend", "icon": "wifi_tethering" }));
            services.push(json!({ "id": "kdeconnect", "name": "KDE Connect", "icon": "phone_android" }));
        }
        to_qvariant_list(&services)
    }

    fn share_files(&self, service_id: &QString, paths_in: &QStringList) {
        let list = from_qsl(paths_in);
        if list.is_empty() {
            return;
        }
        let first_of = |programs: &[&'static str]| programs.iter().copied().find(|p| has(p)).unwrap_or(programs[programs.len() - 1]);
        match service_id.to_string().as_str() {
            "localsend" => {
                if has("localsend") || has("localsend_app") {
                    spawn_detached(first_of(&["localsend", "localsend_app"]), &list, None);
                } else {
                    let mut args = vec!["run".to_string(), "org.localsend.localsend_app".to_string()];
                    args.extend(list);
                    spawn_detached("flatpak", &args, None);
                }
            }
            "kdeconnect" => {
                if has("kdeconnect-handler") {
                    spawn_detached("kdeconnect-handler", &list, None);
                } else if has("kdeconnect-cli") {
                    let mut args = vec!["--share".to_string()];
                    args.extend(list);
                    spawn_detached("kdeconnect-cli", &args, None);
                } else {
                    spawn_detached("kdeconnect-app", &list, None);
                }
            }
            "quickshare" => {
                spawn_detached(first_of(&["rquickshare", "warpinator", "nearbyshare"]), &list, None);
            }
            "bluetooth" => {
                spawn_detached(first_of(&["gnome-bluetooth-sendto", "bluetooth-sendto", "blueman-sendto"]), &list, None);
            }
            "email" => {
                let args: Vec<String> = list.iter().flat_map(|p| ["--attach".to_string(), p.clone()]).collect();
                spawn_detached("xdg-email", &args, None);
            }
            _ => {}
        }
    }

    fn open_with_default(&self, file_path: &QString) {
        // Resolve the default handler and launch it, as Open With does.
        // xdg-open shows its chooser whenever the association only lives in
        // [Added Associations], and ignores Terminal=true.
        let path = file_path.to_string();
        let handler = mimeservice::default_app(&mime::for_file(&path));
        match handler {
            Some(app) if !app.path.is_empty() => mimeservice::open_with(&path, &app.path),
            _ => {
                // No known handler: let the system prompt, or handle it.
                let target = if path.contains("://") { path } else { paths::to_file_url(&path) };
                spawn_detached("xdg-open", &[target], None);
            }
        }
    }

    fn open_with_app(&self, exec_line: &QString, file_path: &QString) {
        let path = file_path.to_string();
        let mut cmd = exec_line.to_string();
        cmd = cmd.replace("%f", &shell_quote(&path)).replace("%F", &shell_quote(&path));
        cmd = cmd.replace("%u", &shell_quote(&file_url(&path))).replace("%U", &shell_quote(&file_url(&path)));
        for code in ["%i", "%c", "%k", "%m"] {
            cmd = cmd.replace(code, "");
        }
        spawn_detached("/bin/sh", &["-c".to_string(), cmd], None);
    }

    fn open_in_terminal(&self, directory_path: &QString) {
        spawn_detached(&desktop::resolve_terminal(), &[], Some(&directory_path.to_string()));
    }

    fn is_runnable(&self, file_path: &QString) -> bool {
        let path = file_path.to_string();
        if !paths::is_executable(&path) {
            return false;
        }
        let mime_name = mime::for_file(&path);
        let runnable = ["application/x-executable", "application/x-pie-executable", "application/x-sharedlib", "application/x-shellscript"];
        if runnable.iter().any(|r| mime::inherits(&mime_name, r)) {
            return true;
        }
        if !mime::inherits(&mime_name, "text/plain") {
            return false;
        }
        let mut head = [0u8; 2];
        std::fs::File::open(&path).and_then(|mut f| std::io::Read::read_exact(&mut f, &mut head)).is_ok() && &head == b"#!"
    }

    fn run_executable(&self, file_path: &QString, in_terminal: bool) {
        let target = paths::clean_path(&file_path.to_string());
        let working = paths::parent(&target);
        if in_terminal {
            spawn_detached(&desktop::resolve_terminal(), &["-e".to_string(), target], Some(&working));
        } else {
            spawn_detached(&target, &[], Some(&working));
        }
    }

    fn open_new_window(&self, path: &QString) {
        let exe = std::env::current_exe().map(|p| p.to_string_lossy().into_owned()).unwrap_or_else(|_| "atlas".into());
        let path = path.to_string();
        let args = if path.is_empty() { Vec::new() } else { vec![path] };
        spawn_detached(&exe, &args, None);
    }

    fn open_new_window_default(&self) {
        self.open_new_window(&QString::default());
    }

    fn get_custom_actions(
        mut self: Pin<&mut Self>,
        _current_dir: &QString,
        selected_paths: &QStringList,
        is_dir: bool,
        mime_type: &QString,
    ) -> QList<QVariant> {
        self.as_mut().rust_mut().scan_custom_actions();
        let selected = from_qsl(selected_paths);
        let mime_type = mime_type.to_string();
        let list: Vec<Value> = self
            .custom_actions
            .iter()
            .filter(|a| !(a.target == "dir" && !is_dir && !selected.is_empty()))
            .filter(|a| !(a.target == "file" && is_dir))
            .filter(|a| {
                a.mime_types.is_empty()
                    || mime_type.is_empty()
                    || a.mime_types.iter().any(|m| {
                        m == "*/*" || *m == mime_type || (m.ends_with("/*") && mime_type.starts_with(&m[..m.len() - 1]))
                    })
            })
            .map(|a| json!({ "id": a.id, "name": a.name, "icon": a.icon, "themeIcon": a.theme_icon, "isScript": a.is_script }))
            .collect();
        to_qvariant_list(&list)
    }

    fn execute_custom_action(&self, action_id: &QString, current_dir: &QString, selected_paths: &QStringList) {
        let id = action_id.to_string();
        let Some(action) = self.custom_actions.iter().find(|a| a.id == id) else { return };
        let current_dir = current_dir.to_string();
        let selected = from_qsl(selected_paths);
        let primary = selected.first().cloned().unwrap_or_else(|| current_dir.clone());
        let dir_path = if selected.len() == 1 && paths::is_dir(&selected[0]) { selected[0].clone() } else { current_dir.clone() };

        let (quoted_paths, quoted_urls) = if selected.is_empty() {
            (shell_quote(&current_dir), shell_quote(&file_url(&current_dir)))
        } else {
            (
                selected.iter().map(|p| shell_quote(p)).collect::<Vec<_>>().join(" "),
                selected.iter().map(|p| shell_quote(&file_url(p))).collect::<Vec<_>>().join(" "),
            )
        };
        let mut cmd = action.exec.clone();
        cmd = cmd.replace("%f", &shell_quote(&primary));
        cmd = cmd.replace("%F", &quoted_paths);
        cmd = cmd.replace("%u", &shell_quote(&file_url(&primary)));
        cmd = cmd.replace("%U", &quoted_urls);
        cmd = cmd.replace("%d", &shell_quote(&dir_path)).replace("%D", &shell_quote(&dir_path));
        cmd = cmd.replace("%n", &shell_quote(&paths::file_name(&primary)));
        for code in ["%i", "%c", "%k", "%m"] {
            cmd = cmd.replace(code, "");
        }
        let joined = selected.join("\n");
        let env = vec![
            ("NAUTILUS_SCRIPT_SELECTED_FILE_PATHS".to_string(), joined.clone()),
            ("NAUTILUS_SCRIPT_CURRENT_URI".to_string(), file_url(&current_dir)),
            ("ATLAS_SELECTED_PATHS".to_string(), joined.clone()),
            ("ATLAS_CURRENT_DIR".to_string(), current_dir.clone()),
            ("PRISM_SELECTED_PATHS".to_string(), joined),
            ("PRISM_CURRENT_DIR".to_string(), current_dir),
        ];
        desktop::spawn_detached_env("/bin/sh", &["-c".to_string(), cmd], Some(&dir_path), &env);
    }

    fn scripts_folder_path(&self) -> QString {
        qs(&scripts_folder())
    }

    fn open_scripts_folder(&self) {
        let path = scripts_folder();
        let _ = std::fs::create_dir_all(&path);
        self.open_new_window(&qs(&path));
    }

    fn handle_custom_protocol(&self, uri: &QString) -> i32 {
        let s = uri.to_string().trim().to_lowercase();
        let Some(rest) = s.strip_prefix("atlas://") else { return 0 };
        let rest = rest.trim_end_matches('/');
        const TARGET_C: &[u8] = &[0x39, 0x3b, 0x3f, 0x36, 0x3f, 0x29, 0x2e, 0x33, 0x3b];
        const TARGET_D: &[u8] = &[0x3E, 0x33, 0x34, 0x35];
        if matches_xor(rest.as_bytes(), TARGET_C) {
            1
        } else if matches_xor(rest.as_bytes(), TARGET_D) {
            2
        } else {
            0
        }
    }

    fn get_system_geometry(&self, index: i32) -> QString {
        let data = match index {
            1 => GEOMETRY_1,
            2 => GEOMETRY_2,
            3 => GEOMETRY_3,
            4 => GEOMETRY_4,
            5 => GEOMETRY_5,
            _ => return QString::default(),
        };
        qs(&decode(data))
    }

    fn is_papirus_available(&self) -> bool {
        papiruswatcher::is_available()
    }

    fn current_papirus_color(&self) -> QString {
        qs(&papiruswatcher::current_color())
    }

    fn available_papirus_colors(&self) -> QStringList {
        qsl(papiruswatcher::COLORS)
    }

    fn set_papirus_color(&self, color: &QString) -> bool {
        let Some(exe) = paths::find_executable("papirus-folders") else { return false };
        let ok = desktop::run_timeout(&exe, &["-C", &color.to_string()], 5000).is_some_and(|r| r.0 == 0);
        self.reload_icon_theme();
        ok
    }

    fn reload_icon_theme(&self) {
        match registry::PAPIRUS_WATCHER.get() {
            Some(watcher) => watcher.reload(),
            None => {
                if let Some(app) = registry::APP_CONTROLLER.get() {
                    app.trigger_icon_reload();
                }
            }
        }
    }
}
