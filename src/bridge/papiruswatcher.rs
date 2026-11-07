//! PapirusWatcher: reloads icons when the Papirus folder colour changes.

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
        include!("cxx-qt-lib/qstringlist.h");
        type QStringList = cxx_qt_lib::QStringList;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        #[qproperty(QString, current_color, cxx_name = "currentColor", READ = current_color, NOTIFY = color_changed)]
        #[qproperty(QStringList, available_colors, cxx_name = "availableColors", READ = available_colors, CONSTANT)]
        #[qproperty(bool, is_available, cxx_name = "isAvailable", READ = is_available, CONSTANT)]
        type PapirusWatcher = super::PapirusWatcherRust;

        #[qsignal]
        #[cxx_name = "colorChanged"]
        fn color_changed(self: Pin<&mut PapirusWatcher>, color: &QString);
        #[qsignal]
        #[cxx_name = "themeReloaded"]
        fn theme_reloaded(self: Pin<&mut PapirusWatcher>);

        #[cxx_name = "currentColor"]
        fn current_color(self: &PapirusWatcher) -> QString;
        #[cxx_name = "availableColors"]
        fn available_colors(self: &PapirusWatcher) -> QStringList;
        #[cxx_name = "isAvailable"]
        fn is_available(self: &PapirusWatcher) -> bool;

        #[qinvokable]
        fn reload(self: Pin<&mut PapirusWatcher>);
    }

    impl cxx_qt::Threading for PapirusWatcher {}
    impl cxx_qt::Constructor<()> for PapirusWatcher {}
}

use crate::bridge::native::{self, qs, qsl};
use crate::bridge::registry;
use crate::core::paths;
use crate::core::watcher::Watcher;
use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::{QString, QStringList};
use qobject::PapirusWatcher;
use std::pin::Pin;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;

pub const COLORS: &[&str] = &[
    "adwaita", "black", "blue", "bluegrey", "breeze", "brown", "carmine", "cyan", "darkcyan", "deeporange", "green",
    "grey", "indigo", "magenta", "nordic", "orange", "palebrown", "paleorange", "pink", "red", "teal", "violet",
    "white", "yaru", "yellow",
];

const PLACES_SIZES: &[&str] = &["16x16", "22x22", "24x24", "32x32", "48x48", "64x64", "scalable", "symbolic"];

fn icon_base_dirs() -> Vec<String> {
    let home = paths::home();
    let mut dirs = native::icon_theme_search_paths();
    dirs.extend([
        format!("{home}/.icons"),
        format!("{home}/.local/share/icons"),
        "/usr/local/share/icons".to_string(),
        "/usr/share/icons".to_string(),
    ]);
    dirs
}

fn read_keep_file(path: &str) -> String {
    let Ok(text) = std::fs::read_to_string(path) else { return String::new() };
    for line in text.lines().map(str::trim) {
        if let Some(c) = line.strip_prefix("color=") {
            return c.trim().to_string();
        }
        if let Some(c) = line.strip_prefix("folder_color=") {
            return c.trim().to_string();
        }
    }
    String::new()
}

/// The colour papirus-folders linked 48x48/places/folder.svg to.
fn detect_color_from_symlink() -> String {
    let re = regex::Regex::new(r"folder-([a-zA-Z0-9_-]+)\.svg").unwrap();
    for base in icon_base_dirs() {
        let svg = format!("{base}/Papirus/48x48/places/folder.svg");
        if let Ok(target) = std::fs::read_link(&svg) {
            if let Some(c) = re.captures(&target.to_string_lossy()) {
                return c[1].to_string();
            }
        }
    }
    String::new()
}

pub fn current_color() -> String {
    let keeps = [
        format!("{}/papirus-folders/keep", paths::config_home()),
        "/var/lib/papirus-folders/keep".to_string(),
        "/etc/papirus-folders/keep".to_string(),
    ];
    for keep in &keeps {
        let color = read_keep_file(keep);
        if !color.is_empty() {
            return color;
        }
    }
    let color = detect_color_from_symlink();
    if color.is_empty() { "default".to_string() } else { color }
}

pub fn is_available() -> bool {
    paths::find_executable("papirus-folders").is_some() || !detect_color_from_symlink().is_empty()
}

#[derive(Default)]
pub struct PapirusWatcherRust {
    watcher: Option<Watcher>,
    last_color: String,
    last_symlink_target: String,
    debounce: Arc<AtomicU64>,
}

impl cxx_qt::Initialize for PapirusWatcher {
    fn initialize(mut self: Pin<&mut Self>) {
        registry::PAPIRUS_WATCHER.set(self.as_mut());
        // Coalesce change bursts: act 600ms after the last one.
        let thread = self.qt_thread();
        let debounce = self.debounce.clone();
        let watcher = Watcher::new(move |_| {
            let generation = debounce.fetch_add(1, Ordering::AcqRel) + 1;
            let thread = thread.clone();
            let debounce = debounce.clone();
            std::thread::spawn(move || {
                std::thread::sleep(std::time::Duration::from_millis(600));
                if debounce.load(Ordering::Acquire) == generation {
                    let _ = thread.queue(|w| w.on_debounce_timeout());
                }
            });
        });
        self.as_mut().rust_mut().watcher = watcher;
        self.as_mut().scan_and_watch();
        let mut rust = self.as_mut().rust_mut();
        rust.last_color = current_color();
        rust.last_symlink_target = detect_color_from_symlink();
    }
}

impl PapirusWatcher {
    fn add_path(&self, path: &str, is_dir: bool) {
        let Some(watcher) = &self.watcher else { return };
        let ok = if is_dir { paths::is_dir(path) } else { paths::is_file(path) };
        if ok && !watcher.is_watching(path) {
            watcher.add_path(path);
        }
    }

    fn scan_and_watch(self: Pin<&mut Self>) {
        let config = format!("{}/papirus-folders", paths::config_home());
        for dir in [config.as_str(), "/var/lib/papirus-folders", "/etc/papirus-folders"] {
            self.add_path(dir, true);
            self.add_path(&format!("{dir}/keep"), false);
        }

        let mut bases = icon_base_dirs();
        if let Ok(xdg) = std::env::var("XDG_DATA_DIRS") {
            bases.extend(xdg.split(':').filter(|d| !d.is_empty()).map(|d| format!("{d}/icons")));
        }
        let mut seen = Vec::new();
        for base in bases {
            if seen.contains(&base) {
                continue;
            }
            seen.push(base.clone());
            let Ok(entries) = std::fs::read_dir(&base) else { continue };
            for theme in entries.flatten().filter(|e| e.path().is_dir()) {
                let name = theme.file_name().to_string_lossy().to_lowercase();
                if !name.contains("papirus") {
                    continue;
                }
                let theme_path = theme.path().to_string_lossy().into_owned();
                self.add_path(&theme_path, true);
                self.add_path(&format!("{theme_path}/icon-theme.cache"), false);
                self.add_path(&format!("{theme_path}/index.theme"), false);
                // papirus-folders changes the symlinks in the places folders.
                for size in PLACES_SIZES {
                    self.add_path(&format!("{theme_path}/{size}/places"), true);
                }
            }
        }
    }

    fn on_debounce_timeout(mut self: Pin<&mut Self>) {
        // Watch again anything that was replaced or recreated.
        self.as_mut().scan_and_watch();
        let color = current_color();
        let symlink = detect_color_from_symlink();
        if color == self.last_color && symlink == self.last_symlink_target && !self.last_color.is_empty() {
            return;
        }
        {
            let mut rust = self.as_mut().rust_mut();
            rust.last_color = color.clone();
            rust.last_symlink_target = symlink;
        }
        self.notify(&color);
    }

    fn notify(mut self: Pin<&mut Self>, color: &str) {
        if let Some(app) = registry::APP_CONTROLLER.get() {
            app.trigger_icon_reload();
        }
        self.as_mut().color_changed(&qs(color));
        self.theme_reloaded();
    }

    pub fn reload(mut self: Pin<&mut Self>) {
        self.as_mut().scan_and_watch();
        let color = current_color();
        {
            let mut rust = self.as_mut().rust_mut();
            rust.last_color = color.clone();
            rust.last_symlink_target = detect_color_from_symlink();
        }
        self.notify(&color);
    }

    pub fn current_color(&self) -> QString {
        qs(&current_color())
    }

    pub fn available_colors(&self) -> QStringList {
        qsl(COLORS)
    }

    pub fn is_available(&self) -> bool {
        is_available()
    }
}
