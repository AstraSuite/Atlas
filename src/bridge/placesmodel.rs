//! PlacesModel: the sidebar's places and bookmarks, shared with KDE
//! (user-places.xbel) and GTK (gtk-3.0/bookmarks).

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!(<QtCore/QAbstractListModel>);
        type QAbstractListModel;

        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
        include!("cxx-qt-lib/qstringlist.h");
        type QStringList = cxx_qt_lib::QStringList;
        include!("cxx-qt-lib/qmodelindex.h");
        type QModelIndex = cxx_qt_lib::QModelIndex;
        include!("cxx-qt-lib/qvariant.h");
        type QVariant = cxx_qt_lib::QVariant;
        include!("cxx-qt-lib/qhash.h");
        type QHash_i32_QByteArray = cxx_qt_lib::QHash<cxx_qt_lib::QHashPair_i32_QByteArray>;
        include!("cxx-qt-lib/qlist.h");
        type QList_i32 = cxx_qt_lib::QList<i32>;
        type QList_QVariant = cxx_qt_lib::QList<cxx_qt_lib::QVariant>;
    }

    extern "RustQt" {
        #[qobject]
        #[base = QAbstractListModel]
        #[qml_element]
        #[qml_singleton]
        #[qproperty(i32, count, READ = count, NOTIFY = count_changed)]
        type PlacesModel = super::PlacesModelRust;

        #[qsignal]
        #[cxx_name = "countChanged"]
        fn count_changed(self: Pin<&mut PlacesModel>);

        fn count(self: &PlacesModel) -> i32;

        #[qinvokable]
        fn refresh(self: Pin<&mut PlacesModel>);
        #[qinvokable]
        #[cxx_name = "addBookmark"]
        fn add_bookmark(self: Pin<&mut PlacesModel>, path: &QString, name: &QString, icon: &QString);
        #[qinvokable]
        #[cxx_name = "addBookmark"]
        fn add_bookmark_named(self: Pin<&mut PlacesModel>, path: &QString, name: &QString);
        #[qinvokable]
        #[cxx_name = "addBookmark"]
        fn add_bookmark_path(self: Pin<&mut PlacesModel>, path: &QString);
        #[qinvokable]
        #[cxx_name = "addCustomPlace"]
        fn add_custom_place(self: Pin<&mut PlacesModel>, name: &QString, path: &QString, icon: &QString);
        #[qinvokable]
        #[cxx_name = "addCustomPlace"]
        fn add_custom_place_default(self: Pin<&mut PlacesModel>, name: &QString, path: &QString);
        #[qinvokable]
        #[cxx_name = "movePlace"]
        fn move_place(self: Pin<&mut PlacesModel>, from_index: i32, to_index: i32);
        #[qinvokable]
        #[cxx_name = "removeBookmark"]
        fn remove_bookmark(self: Pin<&mut PlacesModel>, index: i32);
        #[qinvokable]
        #[cxx_name = "removePlace"]
        fn remove_place(self: Pin<&mut PlacesModel>, index: i32);
        #[qinvokable]
        #[cxx_name = "removeBookmarkByPath"]
        fn remove_bookmark_by_path(self: Pin<&mut PlacesModel>, path: &QString);
        #[qinvokable]
        #[cxx_name = "removePlaceByPath"]
        fn remove_place_by_path(self: Pin<&mut PlacesModel>, path: &QString);
        #[qinvokable]
        #[cxx_name = "updatePlace"]
        fn update_place(self: Pin<&mut PlacesModel>, index: i32, name: &QString, icon_name: &QString);
        #[qinvokable]
        #[cxx_name = "isBookmarked"]
        fn is_bookmarked(self: &PlacesModel, path: &QString) -> bool;
        #[qinvokable]
        #[cxx_name = "toggleBookmark"]
        fn toggle_bookmark(self: Pin<&mut PlacesModel>, path: &QString);
        #[qinvokable]
        #[cxx_name = "restoreDefaultPlaces"]
        fn restore_default_places(self: Pin<&mut PlacesModel>);
        #[qinvokable]
        #[cxx_name = "hidePlace"]
        fn hide_place(self: Pin<&mut PlacesModel>, path: &QString);
        #[qinvokable]
        #[cxx_name = "unhidePlace"]
        fn unhide_place(self: Pin<&mut PlacesModel>, path: &QString);
        #[qinvokable]
        #[cxx_name = "togglePlaceHidden"]
        fn toggle_place_hidden(self: Pin<&mut PlacesModel>, path: &QString);
        #[qinvokable]
        #[cxx_name = "isPlaceHidden"]
        fn is_place_hidden(self: &PlacesModel, path: &QString) -> bool;
        #[qinvokable]
        #[cxx_name = "hiddenPlaces"]
        fn hidden_places(self: &PlacesModel) -> QStringList;
        #[qinvokable]
        #[cxx_name = "setHiddenPlaces"]
        fn set_hidden_places(self: Pin<&mut PlacesModel>, list: &QStringList);
        #[qinvokable]
        #[cxx_name = "allPlaces"]
        fn all_places(self: &PlacesModel) -> QList_QVariant;
    }

    unsafe extern "RustQt" {
        #[inherit]
        #[cxx_name = "beginResetModel"]
        fn begin_reset_model(self: Pin<&mut PlacesModel>);
        #[inherit]
        #[cxx_name = "endResetModel"]
        fn end_reset_model(self: Pin<&mut PlacesModel>);
        #[inherit]
        #[cxx_name = "beginInsertRows"]
        fn begin_insert_rows(self: Pin<&mut PlacesModel>, parent: &QModelIndex, first: i32, last: i32);
        #[inherit]
        #[cxx_name = "endInsertRows"]
        fn end_insert_rows(self: Pin<&mut PlacesModel>);
        #[inherit]
        #[cxx_name = "beginRemoveRows"]
        fn begin_remove_rows(self: Pin<&mut PlacesModel>, parent: &QModelIndex, first: i32, last: i32);
        #[inherit]
        #[cxx_name = "endRemoveRows"]
        fn end_remove_rows(self: Pin<&mut PlacesModel>);
        #[inherit]
        #[cxx_name = "beginMoveRows"]
        fn begin_move_rows(
            self: Pin<&mut PlacesModel>,
            source_parent: &QModelIndex,
            source_first: i32,
            source_last: i32,
            destination_parent: &QModelIndex,
            destination_child: i32,
        ) -> bool;
        #[inherit]
        #[cxx_name = "endMoveRows"]
        fn end_move_rows(self: Pin<&mut PlacesModel>);
        #[inherit]
        fn index(self: &PlacesModel, row: i32, column: i32, parent: &QModelIndex) -> QModelIndex;
        #[inherit]
        #[qsignal]
        #[cxx_name = "dataChanged"]
        fn data_changed(self: Pin<&mut PlacesModel>, top_left: &QModelIndex, bottom_right: &QModelIndex, roles: &QList_i32);

        #[cxx_override]
        fn data(self: &PlacesModel, index: &QModelIndex, role: i32) -> QVariant;
        #[cxx_override]
        #[cxx_name = "roleNames"]
        fn role_names(self: &PlacesModel) -> QHash_i32_QByteArray;
        #[cxx_override]
        #[cxx_name = "rowCount"]
        fn row_count(self: &PlacesModel, parent: &QModelIndex) -> i32;
    }

    impl cxx_qt::Threading for PlacesModel {}
    impl cxx_qt::Constructor<()> for PlacesModel {}
}

use crate::bridge::native::{from_qsl, qs, qsl, settings, to_qvariant_list};
use crate::bridge::registry;
use crate::core::watcher::Watcher;
use crate::core::{fileutils, paths, recent};
use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::{QByteArray, QHash, QHashPair_i32_QByteArray, QList, QModelIndex, QString, QStringList, QVariant};
use qobject::PlacesModel;
use quick_xml::events::{BytesDecl, BytesEnd, BytesStart, BytesText, Event};
use quick_xml::{Reader, Writer};
use serde_json::{json, Value};
use std::collections::BTreeSet;
use std::pin::Pin;
use std::time::{Duration, Instant};

mod role {
    pub const NAME: i32 = 0x0101;
    pub const PATH: i32 = 0x0102;
    pub const ICON_NAME: i32 = 0x0103;
    pub const IS_DEVICE: i32 = 0x0104;
    pub const IS_REMOVABLE: i32 = 0x0105;
    pub const IS_TRASH: i32 = 0x0106;
    pub const IS_CUSTOM: i32 = 0x0107;
    pub const IS_NETWORK: i32 = 0x0108;
    pub const BYTES_FREE: i32 = 0x0109;
    pub const BYTES_TOTAL: i32 = 0x010a;
    pub const FREE_SPACE_FORMATTED: i32 = 0x010b;
}

#[derive(Clone, Default)]
struct PlaceItem {
    name: String,
    path: String,
    icon_name: String,
    is_device: bool,
    is_removable: bool,
    is_trash: bool,
    is_custom: bool,
    is_network: bool,
    bytes_free: i64,
    bytes_total: i64,
}

impl PlaceItem {
    fn new(name: &str, path: &str, icon: &str, is_trash: bool, is_custom: bool, is_network: bool) -> Self {
        PlaceItem {
            name: name.to_string(),
            path: path.to_string(),
            icon_name: icon.to_string(),
            is_trash,
            is_custom,
            is_network,
            ..Default::default()
        }
    }
}

fn xbel_path() -> String {
    format!("{}/user-places.xbel", paths::data_home())
}

fn gtk_bookmarks_path() -> String {
    format!("{}/.config/gtk-3.0/bookmarks", paths::home())
}

fn trash_path() -> String {
    format!("{}/.local/share/Trash/files", paths::home())
}

fn map_xbel_icon(icon: &str, is_dir: bool) -> String {
    let fallback = if is_dir { "folder" } else { "bookmark" };
    if icon.is_empty() {
        return fallback.to_string();
    }
    // Names without hyphens are already Material Symbols names.
    if !icon.contains('-') {
        return icon.to_string();
    }
    let n = icon.to_lowercase();
    let mapped = [
        (&["terminal"][..], "terminal"),
        (&["development", "code"], "code"),
        (&["home"], "home"),
        (&["download"], "file_download"),
        (&["desktop"], "desktop_windows"),
        (&["document"], "description"),
        (&["music"], "music_note"),
        (&["picture", "image", "photo"], "image"),
        (&["video", "movie"], "video_library"),
        (&["trash", "delete"], "delete"),
        (&["game"], "sports_esports"),
        (&["star"], "star"),
        (&["favorite", "heart"], "favorite"),
        (&["cloud"], "cloud"),
        (&["work", "briefcase"], "work"),
        (&["lock"], "lock"),
        (&["tag", "label"], "sell"),
    ];
    mapped
        .iter()
        .find(|(keys, _)| keys.iter().any(|k| n.contains(k)))
        .map(|(_, v)| v.to_string())
        .unwrap_or_else(|| fallback.to_string())
}

/// Bookmarks from user-places.xbel: (href, title, icon, isSystem, isHidden).
fn read_xbel() -> Vec<(String, String, String, bool, bool)> {
    let Ok(text) = std::fs::read_to_string(xbel_path()) else { return Vec::new() };
    let mut reader = Reader::from_str(&text);
    let mut out = Vec::new();
    let (mut href, mut title, mut icon, mut system, mut hidden) = (String::new(), String::new(), String::new(), false, false);
    let mut in_bookmark = false;
    loop {
        match reader.read_event() {
            Ok(Event::Start(e)) => {
                let local = e.local_name();
                match local.as_ref() {
                    b"bookmark" => {
                        in_bookmark = true;
                        href = attr(&e, b"href").unwrap_or_default();
                        title.clear();
                        icon.clear();
                        system = false;
                        hidden = false;
                    }
                    b"title" if in_bookmark => {
                        title = reader.read_text(e.name()).map(|t| unescape(&t)).unwrap_or_default();
                    }
                    b"icon" => icon = attr(&e, b"name").unwrap_or_default(),
                    b"isSystemItem" => {
                        let t = reader.read_text(e.name()).map(|t| t.to_string()).unwrap_or_default();
                        system = t.trim().eq_ignore_ascii_case("true");
                    }
                    b"IsHidden" | b"onlyInKDE" => {
                        let t = reader.read_text(e.name()).map(|t| t.to_string()).unwrap_or_default();
                        if t.trim().eq_ignore_ascii_case("true") {
                            hidden = true;
                        }
                    }
                    _ => {}
                }
            }
            Ok(Event::Empty(e)) => {
                if e.local_name().as_ref() == b"icon" {
                    icon = attr(&e, b"name").unwrap_or_default();
                }
            }
            Ok(Event::End(e)) if e.local_name().as_ref() == b"bookmark" => {
                in_bookmark = false;
                out.push((href.clone(), title.clone(), icon.clone(), system, hidden));
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
    }
    out
}

fn attr(e: &BytesStart, name: &[u8]) -> Option<String> {
    e.attributes()
        .flatten()
        .find(|a| a.key.as_ref() == name)
        .and_then(|a| a.unescape_value().ok().map(|v| v.into_owned()))
}

fn unescape(text: &str) -> String {
    quick_xml::escape::unescape(text).map(|t| t.into_owned()).unwrap_or_else(|_| text.to_string())
}

pub struct PlacesModelRust {
    places: Vec<PlaceItem>,
    hidden: BTreeSet<String>,
    saving_until: Option<Instant>,
    watcher: Option<Watcher>,
}

impl Default for PlacesModelRust {
    fn default() -> Self {
        Self {
            places: Vec::new(),
            hidden: settings::string_list("places/hiddenPlaces").into_iter().collect(),
            saving_until: None,
            watcher: None,
        }
    }
}

impl cxx_qt::Initialize for PlacesModel {
    fn initialize(mut self: Pin<&mut Self>) {
        registry::PLACES_MODEL.set(self.as_mut());
        let thread = self.qt_thread();
        let watcher = Watcher::new(move |_| {
            let _ = thread.queue(|model| model.on_bookmarks_file_changed());
        });
        if let Some(w) = &watcher {
            for p in [xbel_path(), gtk_bookmarks_path()] {
                if paths::exists(&p) {
                    w.add_path(&p);
                }
            }
        }
        self.as_mut().rust_mut().watcher = watcher;
        self.refresh();
    }
}

impl PlacesModel {
    fn on_bookmarks_file_changed(self: Pin<&mut Self>) {
        if self.saving_until.is_some_and(|t| Instant::now() < t) {
            return;
        }
        // Files replaced atomically drop their watch; watch them again.
        if let Some(w) = &self.watcher {
            for p in [xbel_path(), gtk_bookmarks_path()] {
                if paths::exists(&p) && !w.is_watching(&p) {
                    w.add_path(&p);
                }
            }
        }
        self.refresh();
    }

    fn save_hidden(&self) {
        let list: Vec<String> = self.hidden.iter().cloned().collect();
        settings::set_string_list("places/hiddenPlaces", &list);
    }

    fn count(&self) -> i32 {
        self.places.len() as i32
    }

    fn has_place(&self, path: &str, is_trash: bool) -> bool {
        self.places.iter().any(|p| p.path == path || (p.is_trash && is_trash))
    }

    fn refresh(mut self: Pin<&mut Self>) {
        self.as_mut().begin_reset_model();
        let mut loaded_xbel = false;
        {
            let mut rust = self.as_mut().rust_mut();
            rust.places.clear();
            for (href, mut title, icon, system, hidden) in read_xbel() {
                if hidden || href.is_empty() {
                    continue;
                }
                let is_trash_href = href.starts_with("trash:");
                let local = if href.starts_with("file://") {
                    paths::from_file_url(&href)
                } else if href.starts_with("trash:/") {
                    trash_path()
                } else if href.starts_with('/') {
                    href.clone()
                } else {
                    String::new()
                };
                if local == "/" || local == "/root" {
                    continue;
                }
                if rust.hidden.contains(&local) || (is_trash_href && rust.hidden.contains("trash:")) {
                    continue;
                }
                if local.is_empty() || !(paths::exists(&local) || is_trash_href) {
                    continue;
                }
                if title.is_empty() {
                    title = paths::file_name(&local);
                    if title.is_empty() {
                        title = local.clone();
                    }
                }
                let is_trash = is_trash_href || local.contains("Trash");
                let icon = map_xbel_icon(&icon, paths::is_dir(&local));
                if !rust.places.iter().any(|p| p.path == local || (p.is_trash && is_trash)) {
                    rust.places.push(PlaceItem::new(&title, &local, &icon, is_trash, !system, false));
                    loaded_xbel = true;
                }
            }
        }
        if !loaded_xbel || self.places.is_empty() {
            self.as_mut().load_standard_places();
        }
        let recent_path = recent::virtual_path();
        if !self.hidden.contains(recent_path) {
            let item = PlaceItem::new("Recent", recent_path, "history", false, false, false);
            let mut rust = self.as_mut().rust_mut();
            match rust.places.iter().position(|p| p.is_trash) {
                Some(i) => rust.places.insert(i, item),
                None => rust.places.push(item),
            }
        }
        self.as_mut().load_bookmarks();
        self.as_mut().end_reset_model();
        self.count_changed();
    }

    fn standard_places() -> Vec<(&'static str, String, &'static str, bool)> {
        vec![
            ("Home", paths::home(), "home", false),
            ("Downloads", paths::downloads(), "file_download", false),
            ("Documents", paths::documents(), "description", false),
            ("Desktop", paths::desktop(), "desktop_windows", false),
            ("Pictures", paths::pictures(), "image", false),
            ("Music", paths::music(), "music_note", false),
            ("Videos", paths::videos(), "video_library", false),
            ("Trash", trash_path(), "delete", true),
        ]
    }

    fn load_standard_places(mut self: Pin<&mut Self>) {
        let mut rust = self.as_mut().rust_mut();
        for (name, path, icon, is_trash) in Self::standard_places() {
            if rust.hidden.contains(&path) || (is_trash && rust.hidden.contains("trash:")) {
                continue;
            }
            rust.places.push(PlaceItem::new(name, &path, icon, is_trash, false, false));
        }
    }

    fn load_bookmarks(mut self: Pin<&mut Self>) {
        if let Ok(text) = std::fs::read_to_string(gtk_bookmarks_path()) {
            for line in text.lines().map(str::trim).filter(|l| !l.is_empty()) {
                let (uri, name) = match line.split_once(' ') {
                    Some((u, n)) => (u, n.to_string()),
                    None => (line, String::new()),
                };
                if !uri.starts_with("file://") {
                    continue;
                }
                let path = paths::from_file_url(uri);
                if !paths::is_dir(&path) || path == "/" || self.hidden.contains(&path) {
                    continue;
                }
                let is_trash = path.contains("/Trash");
                if self.has_place(&path, is_trash) {
                    continue;
                }
                let name = if name.is_empty() { paths::file_name(&path) } else { name };
                let icon = if is_trash { "delete" } else { "bookmark" };
                self.as_mut().rust_mut().places.push(PlaceItem::new(&name, &path, icon, is_trash, true, false));
            }
        }

        // Active remote mounts (SFTP, SMB, FTP, WebDAV) under GVFS.
        let gvfs = format!("/run/user/{}/gvfs", unsafe { libc::getuid() });
        let Ok(entries) = std::fs::read_dir(&gvfs) else { return };
        let mut mounts: Vec<String> = entries
            .flatten()
            .filter(|e| e.path().is_dir())
            .map(|e| e.file_name().to_string_lossy().into_owned())
            .collect();
        mounts.sort();
        for name in mounts {
            let path = format!("{gvfs}/{name}");
            if self.hidden.contains(&path) || self.places.iter().any(|p| p.path == path) {
                continue;
            }
            let (icon, title) = if let Some(rest) = name.strip_prefix("sftp:") {
                ("dns", rest.to_string())
            } else if let Some(rest) = name.strip_prefix("smb-share:") {
                ("lan", rest.to_string())
            } else {
                ("cloud", name.clone())
            };
            self.as_mut().rust_mut().places.push(PlaceItem::new(&title, &path, icon, false, true, true));
        }
    }

    fn write_xbel(&self) -> std::io::Result<()> {
        let path = xbel_path();
        std::fs::create_dir_all(paths::parent(&path))?;
        let mut w = Writer::new_with_indent(Vec::new(), b' ', 4);
        w.write_event(Event::Decl(BytesDecl::new("1.0", Some("UTF-8"), None)))?;
        w.write_event(Event::DocType(BytesText::from_escaped("xbel")))?;
        let mut root = BytesStart::new("xbel");
        root.push_attribute(("xmlns:bookmark", "http://www.freedesktop.org/standards/desktop-bookmarks"));
        root.push_attribute(("xmlns:kdepriv", "http://www.kde.org/kdepriv"));
        root.push_attribute(("xmlns:mime", "http://www.freedesktop.org/standards/shared-mime-info"));
        w.write_event(Event::Start(root))?;
        for p in &self.places {
            let href = paths::to_file_url(&p.path);
            let mut bookmark = BytesStart::new("bookmark");
            bookmark.push_attribute(("href", href.as_str()));
            w.write_event(Event::Start(bookmark))?;
            w.create_element("title").write_text_content(BytesText::new(&p.name))?;
            w.write_event(Event::Start(BytesStart::new("info")))?;
            let mut meta = BytesStart::new("metadata");
            meta.push_attribute(("owner", "http://freedesktop.org"));
            w.write_event(Event::Start(meta))?;
            w.create_element("bookmark:icon").with_attribute(("name", p.icon_name.as_str())).write_empty()?;
            w.write_event(Event::End(BytesEnd::new("metadata")))?;
            let mut kde = BytesStart::new("metadata");
            kde.push_attribute(("owner", "http://www.kde.org"));
            w.write_event(Event::Start(kde))?;
            w.create_element("isSystemItem")
                .write_text_content(BytesText::new(if p.is_custom { "false" } else { "true" }))
                ?;
            w.write_event(Event::End(BytesEnd::new("metadata")))?;
            w.write_event(Event::End(BytesEnd::new("info")))?;
            w.write_event(Event::End(BytesEnd::new("bookmark")))?;
        }
        w.write_event(Event::End(BytesEnd::new("xbel")))?;
        let mut out = w.into_inner();
        out.push(b'\n');
        std::fs::write(path, out)
    }

    fn save_bookmarks(mut self: Pin<&mut Self>) {
        // Our own writes trigger the file watcher; ignore them for a moment.
        self.as_mut().rust_mut().saving_until = Some(Instant::now() + Duration::from_millis(300));
        let _ = self.write_xbel();

        let gtk = gtk_bookmarks_path();
        let _ = std::fs::create_dir_all(paths::parent(&gtk));
        let mut text = String::new();
        for p in self.places.iter().filter(|p| p.is_custom && !p.is_trash && !p.path.is_empty()) {
            let uri = paths::to_file_url(&p.path);
            if p.name.is_empty() || p.name == paths::file_name(&p.path) {
                text.push_str(&format!("{uri}\n"));
            } else {
                text.push_str(&format!("{uri} {}\n", p.name));
            }
        }
        let _ = std::fs::write(&gtk, text);
        self.save_hidden();
    }

    pub fn add_bookmark_impl(mut self: Pin<&mut Self>, path: &str, name: &str, icon: &str) {
        if path.is_empty() || self.places.iter().any(|p| p.path == path) {
            return;
        }
        self.as_mut().rust_mut().hidden.remove(path);
        self.save_hidden();
        let mut n = if name.is_empty() { paths::file_name(path) } else { name.to_string() };
        if n.is_empty() {
            n = path.to_string();
        }
        let icon = if icon.is_empty() { "bookmark" } else { icon };
        let is_net = matches!(icon, "cloud" | "dns" | "lan") || path.contains("/gvfs/");
        let row = self.places.len() as i32;
        self.as_mut().begin_insert_rows(&QModelIndex::default(), row, row);
        self.as_mut().rust_mut().places.push(PlaceItem::new(&n, path, icon, false, true, is_net));
        self.as_mut().end_insert_rows();
        self.as_mut().count_changed();
        self.save_bookmarks();
    }

    fn add_bookmark(self: Pin<&mut Self>, path: &QString, name: &QString, icon: &QString) {
        self.add_bookmark_impl(&path.to_string(), &name.to_string(), &icon.to_string());
    }
    fn add_bookmark_named(self: Pin<&mut Self>, path: &QString, name: &QString) {
        self.add_bookmark_impl(&path.to_string(), &name.to_string(), "");
    }
    fn add_bookmark_path(self: Pin<&mut Self>, path: &QString) {
        self.add_bookmark_impl(&path.to_string(), "", "");
    }
    fn add_custom_place(self: Pin<&mut Self>, name: &QString, path: &QString, icon: &QString) {
        self.add_bookmark_impl(&path.to_string(), &name.to_string(), &icon.to_string());
    }
    fn add_custom_place_default(self: Pin<&mut Self>, name: &QString, path: &QString) {
        self.add_bookmark_impl(&path.to_string(), &name.to_string(), "");
    }

    fn move_place(mut self: Pin<&mut Self>, from: i32, to: i32) {
        let len = self.places.len() as i32;
        if from < 0 || from >= len || to < 0 || to >= len || from == to {
            return;
        }
        let dest = if to > from { to + 1 } else { to };
        let root = QModelIndex::default();
        if !self.as_mut().begin_move_rows(&root, from, from, &root, dest) {
            return;
        }
        {
            let mut rust = self.as_mut().rust_mut();
            let item = rust.places.remove(from as usize);
            rust.places.insert(to as usize, item);
        }
        self.as_mut().end_move_rows();
        self.save_bookmarks();
    }

    fn remove_bookmark(mut self: Pin<&mut Self>, index: i32) {
        if index < 0 || index as usize >= self.places.len() {
            return;
        }
        let place = self.places[index as usize].clone();
        {
            let mut rust = self.as_mut().rust_mut();
            if !place.path.is_empty() {
                rust.hidden.insert(place.path.clone());
            }
            if place.is_trash {
                rust.hidden.insert("trash:".to_string());
            }
        }
        self.save_hidden();
        self.as_mut().begin_remove_rows(&QModelIndex::default(), index, index);
        self.as_mut().rust_mut().places.remove(index as usize);
        self.as_mut().end_remove_rows();
        self.as_mut().count_changed();
        self.save_bookmarks();
    }

    fn remove_place(self: Pin<&mut Self>, index: i32) {
        self.remove_bookmark(index);
    }

    pub fn remove_by_path(self: Pin<&mut Self>, path: &str) {
        if let Some(i) = self.places.iter().position(|p| p.path == path) {
            self.remove_bookmark(i as i32);
        }
    }

    fn remove_bookmark_by_path(self: Pin<&mut Self>, path: &QString) {
        self.remove_by_path(&path.to_string());
    }

    fn remove_place_by_path(self: Pin<&mut Self>, path: &QString) {
        self.remove_by_path(&path.to_string());
    }

    fn update_place(mut self: Pin<&mut Self>, index: i32, name: &QString, icon_name: &QString) {
        if index < 0 || index as usize >= self.places.len() {
            return;
        }
        {
            let mut rust = self.as_mut().rust_mut();
            let place = &mut rust.places[index as usize];
            if !name.is_empty() {
                place.name = name.to_string();
            }
            if !icon_name.is_empty() {
                place.icon_name = icon_name.to_string();
            }
        }
        let mi = self.index(index, 0, &QModelIndex::default());
        let mut roles = QList::<i32>::default();
        roles.append(role::NAME);
        roles.append(role::ICON_NAME);
        self.as_mut().data_changed(&mi, &mi, &roles);
        self.save_bookmarks();
    }

    fn is_bookmarked(&self, path: &QString) -> bool {
        let path = path.to_string();
        self.places.iter().any(|p| p.path == path)
    }

    fn toggle_bookmark(self: Pin<&mut Self>, path: &QString) {
        if self.is_bookmarked(path) {
            self.remove_by_path(&path.to_string());
        } else {
            self.add_bookmark_impl(&path.to_string(), "", "");
        }
    }

    fn restore_default_places(mut self: Pin<&mut Self>) {
        self.as_mut().rust_mut().hidden.clear();
        self.save_hidden();
        self.as_mut().refresh();
        self.save_bookmarks();
    }

    fn set_hidden(mut self: Pin<&mut Self>, path: &str, hidden: bool) {
        if path.is_empty() || self.hidden.contains(path) == hidden {
            return;
        }
        {
            let mut rust = self.as_mut().rust_mut();
            if hidden {
                rust.hidden.insert(path.to_string());
            } else {
                rust.hidden.remove(path);
            }
        }
        self.save_hidden();
        self.as_mut().refresh();
        self.save_bookmarks();
    }

    fn hide_place(self: Pin<&mut Self>, path: &QString) {
        self.set_hidden(&path.to_string(), true);
    }

    fn unhide_place(self: Pin<&mut Self>, path: &QString) {
        self.set_hidden(&path.to_string(), false);
    }

    fn toggle_place_hidden(self: Pin<&mut Self>, path: &QString) {
        let hidden = self.is_place_hidden(path);
        self.set_hidden(&path.to_string(), !hidden);
    }

    fn is_place_hidden(&self, path: &QString) -> bool {
        self.hidden.contains(&path.to_string())
    }

    fn hidden_places(&self) -> QStringList {
        let list: Vec<String> = self.hidden.iter().cloned().collect();
        qsl(&list)
    }

    fn set_hidden_places(mut self: Pin<&mut Self>, list: &QStringList) {
        self.as_mut().rust_mut().hidden = from_qsl(list).into_iter().collect();
        self.save_hidden();
        self.as_mut().refresh();
        self.save_bookmarks();
    }

    fn all_places(&self) -> QList<QVariant> {
        let mut list: Vec<Value> = Vec::new();
        for (name, path, icon, is_trash) in Self::standard_places() {
            if !path.is_empty() && (paths::exists(&path) || is_trash) {
                let hidden = self.hidden.contains(&path) || (is_trash && self.hidden.contains("trash:"));
                list.push(json!({
                    "name": name, "path": path, "iconName": icon,
                    "isCustom": false, "isTrash": is_trash, "isHidden": hidden,
                }));
            }
        }
        for p in self.places.iter().filter(|p| p.is_custom) {
            list.push(json!({
                "name": p.name, "path": p.path, "iconName": p.icon_name,
                "isCustom": true, "isTrash": p.is_trash, "isHidden": self.hidden.contains(&p.path),
            }));
        }
        to_qvariant_list(&list)
    }

    fn row_count(&self, parent: &QModelIndex) -> i32 {
        if parent.is_valid() { 0 } else { self.places.len() as i32 }
    }

    fn data(&self, index: &QModelIndex, role: i32) -> QVariant {
        let row = index.row();
        if !index.is_valid() || row < 0 || row as usize >= self.places.len() {
            return QVariant::default();
        }
        let p = &self.places[row as usize];
        match role {
            role::NAME => QVariant::from(&qs(&p.name)),
            role::PATH => QVariant::from(&qs(&p.path)),
            role::ICON_NAME => QVariant::from(&qs(&p.icon_name)),
            role::IS_DEVICE => QVariant::from(&p.is_device),
            role::IS_REMOVABLE => QVariant::from(&p.is_removable),
            role::IS_TRASH => QVariant::from(&p.is_trash),
            role::IS_CUSTOM => QVariant::from(&p.is_custom),
            role::IS_NETWORK => QVariant::from(&p.is_network),
            role::BYTES_FREE => QVariant::from(&p.bytes_free),
            role::BYTES_TOTAL => QVariant::from(&p.bytes_total),
            role::FREE_SPACE_FORMATTED => {
                let text = if p.bytes_total > 0 {
                    format!("{} free of {}", fileutils::format_size(p.bytes_free), fileutils::format_size(p.bytes_total))
                } else {
                    String::new()
                };
                QVariant::from(&qs(&text))
            }
            _ => QVariant::default(),
        }
    }

    fn role_names(&self) -> QHash<QHashPair_i32_QByteArray> {
        let mut roles = QHash::<QHashPair_i32_QByteArray>::default();
        for (r, name) in [
            (role::NAME, "name"),
            (role::PATH, "path"),
            (role::ICON_NAME, "iconName"),
            (role::IS_DEVICE, "isDevice"),
            (role::IS_REMOVABLE, "isRemovable"),
            (role::IS_TRASH, "isTrash"),
            (role::IS_CUSTOM, "isCustom"),
            (role::IS_NETWORK, "isNetwork"),
            (role::BYTES_FREE, "bytesFree"),
            (role::BYTES_TOTAL, "bytesTotal"),
            (role::FREE_SPACE_FORMATTED, "freeSpaceFormatted"),
        ] {
            roles.insert(r, QByteArray::from(name));
        }
        roles
    }
}
