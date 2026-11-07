//! ShortcutManager: the registry of user-rebindable global shortcuts.
//!
//! The actions (stable id, label, category, icon, default sequences) live
//! here; what each one does stays in qml/main.qml. Only overrides are saved,
//! as compact JSON under "shortcuts/bindings".

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
        include!("cxx-qt-lib/qstringlist.h");
        type QStringList = cxx_qt_lib::QStringList;
        include!("cxx-qt-lib/qlist.h");
        type QList_QVariant = cxx_qt_lib::QList<cxx_qt_lib::QVariant>;
        include!("cxx-qt-lib/qmap.h");
        type QMap_QString_QVariant = cxx_qt_lib::QMap<cxx_qt_lib::QMapPair_QString_QVariant>;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        #[qproperty(QMap_QString_QVariant, bindings, READ = bindings, NOTIFY = shortcuts_changed)]
        #[qproperty(QList_QVariant, shortcuts, READ = shortcuts, NOTIFY = shortcuts_changed)]
        #[qproperty(bool, recording, READ, WRITE = set_recording, NOTIFY = recording_changed)]
        type ShortcutManager = super::ShortcutManagerRust;

        #[qsignal]
        #[cxx_name = "shortcutsChanged"]
        fn shortcuts_changed(self: Pin<&mut ShortcutManager>);
        #[qsignal]
        #[cxx_name = "recordingChanged"]
        fn recording_changed(self: Pin<&mut ShortcutManager>);

        fn bindings(self: &ShortcutManager) -> QMap_QString_QVariant;
        fn shortcuts(self: &ShortcutManager) -> QList_QVariant;
        #[cxx_name = "setRecording"]
        fn set_recording(self: Pin<&mut ShortcutManager>, recording: bool);

        #[qinvokable]
        #[cxx_name = "sequencesFor"]
        fn sequences_for(self: &ShortcutManager, id: &QString) -> QStringList;
        #[qinvokable]
        #[cxx_name = "hasOverride"]
        fn has_override(self: &ShortcutManager, id: &QString) -> bool;
        #[qinvokable]
        #[cxx_name = "setSequences"]
        fn set_sequences(self: Pin<&mut ShortcutManager>, id: &QString, seqs: &QStringList) -> bool;
        #[qinvokable]
        #[cxx_name = "addSequence"]
        fn add_sequence(self: Pin<&mut ShortcutManager>, id: &QString, seq: &QString) -> bool;
        #[qinvokable]
        #[cxx_name = "removeSequence"]
        fn remove_sequence(self: Pin<&mut ShortcutManager>, id: &QString, seq: &QString) -> bool;
        #[qinvokable]
        #[cxx_name = "resetAction"]
        fn reset_action(self: Pin<&mut ShortcutManager>, id: &QString);
        #[qinvokable]
        #[cxx_name = "resetAll"]
        fn reset_all(self: Pin<&mut ShortcutManager>);
        #[qinvokable]
        fn conflicts(self: &ShortcutManager, id: &QString, seqs: &QStringList) -> QList_QVariant;
        #[qinvokable]
        fn reassign(self: Pin<&mut ShortcutManager>, id: &QString, seq: &QString) -> bool;
        #[qinvokable]
        #[cxx_name = "sequenceFromKey"]
        fn sequence_from_key(self: &ShortcutManager, key: i32, modifiers: i32) -> QString;
        #[qinvokable]
        #[cxx_name = "isAcceptable"]
        fn is_acceptable(self: &ShortcutManager, seq: &QString) -> bool;
        #[qinvokable]
        #[cxx_name = "isBareKey"]
        fn is_bare_key(self: &ShortcutManager, seq: &QString) -> bool;
    }
}

use crate::bridge::native::{self, from_qsl, qs, qsl, settings, to_qvariant_list, to_qvariant_map, QVariantMap};
use cxx_qt::CxxQtType;
use cxx_qt_lib::{QList, QString, QStringList, QVariant};
use qobject::ShortcutManager;
use serde_json::{json, Map, Value};
use std::collections::BTreeMap;
use std::pin::Pin;

struct Action {
    id: &'static str,
    label: &'static str,
    description: &'static str,
    category: &'static str,
    icon: &'static str,
    defaults: &'static [&'static str],
}

macro_rules! action {
    ($id:literal, $label:literal, $desc:literal, $cat:literal, $icon:literal, [$($seq:literal),*]) => {
        Action { id: $id, label: $label, description: $desc, category: $cat, icon: $icon, defaults: &[$($seq),*] }
    };
}

/// Order defines the grouping order in the settings UI.
const ACTIONS: &[Action] = &[
    action!("app.preferences", "Open Preferences", "Open the settings dialog", "Application", "settings", ["Ctrl+,", "Ctrl+."]),
    action!("app.fullscreen", "Toggle Full Screen", "Switch between full screen and windowed mode", "Application", "fullscreen", ["F11", "Shift+F11"]),
    action!("nav.back", "Go Back", "Navigate to the previously visited folder", "Navigation", "arrow_back", ["Alt+Left"]),
    action!("nav.forward", "Go Forward", "Navigate to the next visited folder", "Navigation", "arrow_forward", ["Alt+Right"]),
    action!("nav.parent", "Go to Parent Folder", "Navigate up one directory level", "Navigation", "arrow_upward", ["Alt+Up"]),
    action!("nav.home", "Go Home", "Navigate to the home directory", "Navigation", "home", ["Alt+Home"]),
    action!("nav.search", "Search", "Search for files across the current folder", "Navigation", "search", ["Ctrl+F", "F9", "Shift+F9"]),
    action!("nav.address", "Edit Location", "Type a path directly in the address bar", "Navigation", "edit_location", ["Ctrl+L", "Alt+D"]),
    action!("tabs.new", "New Tab", "Open a new tab", "Tabs", "tab", ["Ctrl+T"]),
    action!("tabs.close", "Close Tab / Pane", "Close the current tab or split pane", "Tabs", "tab_close", ["Ctrl+W"]),
    action!("tabs.next", "Next Tab", "Switch to the next tab", "Tabs", "chevron_right", ["Ctrl+Tab"]),
    action!("tabs.previous", "Previous Tab", "Switch to the previous tab", "Tabs", "chevron_left", ["Ctrl+Shift+Tab"]),
    action!("file.newFile", "New File", "Create an empty file in the current folder", "File Operations", "note_add", ["Ctrl+N"]),
    action!("file.newFolder", "New Folder", "Create a folder in the current folder", "File Operations", "create_new_folder", ["Ctrl+Shift+N", "F10", "Shift+F10"]),
    action!("file.rename", "Rename", "Rename the selected file or folder", "File Operations", "drive_file_rename_outline", ["F2", "Shift+F2"]),
    action!("file.trash", "Move to Trash", "Move the selection to the trash", "File Operations", "delete", ["Delete"]),
    action!("file.deletePermanent", "Delete Permanently", "Delete the selection without the trash", "File Operations", "delete_forever", ["Shift+Delete"]),
    action!("file.properties", "Properties", "Show properties of the selected item", "File Operations", "info", ["Alt+Return"]),
    action!("edit.copy", "Copy", "Copy the selection to the clipboard", "Editing", "content_copy", ["Ctrl+C"]),
    action!("edit.cut", "Cut", "Cut the selection to the clipboard", "Editing", "content_cut", ["Ctrl+X"]),
    action!("edit.paste", "Paste", "Paste clipboard contents into the current folder", "Editing", "content_paste", ["Ctrl+V"]),
    action!("edit.undo", "Undo", "Undo the last file operation", "Editing", "undo", ["Ctrl+Z"]),
    action!("edit.redo", "Redo", "Redo the last undone file operation", "Editing", "redo", ["Ctrl+Shift+Z", "Ctrl+Y"]),
    action!("edit.selectAll", "Select All", "Select every item in the current folder", "Selection", "select_all", ["Ctrl+A"]),
    action!("edit.clearSelection", "Clear Selection", "Deselect all items", "Selection", "deselect", ["Ctrl+Shift+A", "Ctrl+D"]),
    action!("edit.invertSelection", "Invert Selection", "Select everything that is not selected", "Selection", "flip", ["Ctrl+I"]),
    action!("edit.selectByPattern", "Select by Pattern", "Select items matching a wildcard pattern", "Selection", "filter_alt", ["Ctrl+S"]),
    action!("view.grid", "Grid View", "Display items as a grid of thumbnails", "View", "grid_view", ["Ctrl+1"]),
    action!("view.details", "Details View", "Display items as a details list", "View", "view_list", ["Ctrl+2"]),
    action!("view.compact", "Compact View", "Display items as a compact list", "View", "view_agenda", ["Ctrl+3"]),
    action!("view.toggleHidden", "Show Hidden Files", "Toggle visibility of hidden dotfiles", "View", "visibility", ["Ctrl+H", "Alt+."]),
    action!("view.split", "Toggle Split View", "Split or unsplit the current tab", "View", "vertical_split", ["F3", "Shift+F3"]),
    action!("view.refresh", "Refresh", "Reload the current folder listing", "View", "refresh", ["F5", "Shift+F5", "Ctrl+R"]),
    action!("view.previewPanel", "Toggle Preview Panel", "Show or hide the preview panel", "View", "preview", ["F1", "Shift+F1", "Alt+P"]),
    action!("view.previewMedia", "Preview Media", "Open the selected media file in the viewer", "View", "play_circle", ["Space"]),
    action!("view.zoomIn", "Zoom In", "Increase the icon size", "View", "zoom_in", ["Ctrl+=", "Ctrl++"]),
    action!("view.zoomOut", "Zoom Out", "Decrease the icon size", "View", "zoom_out", ["Ctrl+-"]),
    action!("view.zoomReset", "Reset Zoom", "Restore the default icon size", "View", "zoom_out_map", ["Ctrl+0"]),
    action!("tools.terminal", "Open in Terminal", "Launch a terminal in the current folder", "Tools", "terminal", ["F4", "Shift+F4", "Ctrl+Alt+T", "Ctrl+`"]),
];

fn find_action(id: &str) -> Option<&'static Action> {
    ACTIONS.iter().find(|a| a.id == id)
}

/// The portable QKeySequence text for `seq`, or "" when it isn't one.
fn normalize(seq: &str) -> String {
    native::ffi::normalize_key_sequence(&qs(seq)).to_string()
}

fn normalize_all<S: AsRef<str>>(seqs: &[S]) -> Vec<String> {
    let mut out: Vec<String> = Vec::new();
    for s in seqs {
        let n = normalize(s.as_ref());
        if !n.is_empty() && !out.contains(&n) {
            out.push(n);
        }
    }
    out
}

fn canonical_defaults(id: &str) -> Vec<String> {
    find_action(id).map(|a| normalize_all(a.defaults)).unwrap_or_default()
}

pub struct ShortcutManagerRust {
    overrides: BTreeMap<String, Vec<String>>,
    recording: bool,
}

impl Default for ShortcutManagerRust {
    fn default() -> Self {
        let mut overrides = BTreeMap::new();
        let saved: Map<String, Value> = serde_json::from_str::<Value>(&settings::string("shortcuts/bindings", ""))
            .ok()
            .and_then(|v| v.as_object().cloned())
            .unwrap_or_default();
        for (id, value) in saved {
            let Some(arr) = value.as_array() else { continue };
            if find_action(&id).is_none() {
                continue;
            }
            let seqs: Vec<String> = arr.iter().filter_map(|v| v.as_str().map(String::from)).collect();
            let list = normalize_all(&seqs);
            if !list.is_empty() {
                overrides.insert(id, list);
            }
        }
        Self { overrides, recording: false }
    }
}

impl ShortcutManager {
    fn effective(&self, id: &str) -> Vec<String> {
        self.overrides.get(id).cloned().unwrap_or_else(|| canonical_defaults(id))
    }

    fn bindings(&self) -> QVariantMap {
        let map: Map<String, Value> = ACTIONS.iter().map(|a| (a.id.to_string(), json!(self.effective(a.id)))).collect();
        to_qvariant_map(&Value::Object(map)).unwrap_or_default()
    }

    fn shortcuts(&self) -> QList<QVariant> {
        let list: Vec<Value> = ACTIONS
            .iter()
            .map(|a| {
                json!({
                    "id": a.id,
                    "label": a.label,
                    "description": a.description,
                    "category": a.category,
                    "icon": a.icon,
                    "sequences": self.effective(a.id),
                    "defaults": a.defaults,
                    "modified": self.overrides.contains_key(a.id),
                })
            })
            .collect();
        to_qvariant_list(&list)
    }

    fn set_recording(mut self: Pin<&mut Self>, recording: bool) {
        if self.recording != recording {
            self.as_mut().rust_mut().recording = recording;
            self.recording_changed();
        }
    }

    fn persist(&self) {
        if self.overrides.is_empty() {
            settings::remove("shortcuts/bindings");
        } else {
            let obj: Map<String, Value> = self.overrides.iter().map(|(k, v)| (k.clone(), json!(v))).collect();
            settings::set_string("shortcuts/bindings", &Value::Object(obj).to_string());
        }
    }

    /// Stores an override without emitting; matching the defaults clears it.
    fn apply_override(mut self: Pin<&mut Self>, id: &str, seqs: &[String]) {
        if find_action(id).is_none() {
            return;
        }
        let clean = normalize_all(seqs);
        if clean == canonical_defaults(id) {
            self.as_mut().rust_mut().overrides.remove(id);
        } else {
            self.as_mut().rust_mut().overrides.insert(id.to_string(), clean);
        }
        self.persist();
    }

    fn sequences_for(&self, id: &QString) -> QStringList {
        qsl(&self.effective(&id.to_string()))
    }

    fn has_override(&self, id: &QString) -> bool {
        self.overrides.contains_key(&id.to_string())
    }

    fn set_sequences(mut self: Pin<&mut Self>, id: &QString, seqs: &QStringList) -> bool {
        let id = id.to_string();
        if find_action(&id).is_none() {
            return false;
        }
        self.as_mut().apply_override(&id, &from_qsl(seqs));
        self.shortcuts_changed();
        true
    }

    fn add_sequence(mut self: Pin<&mut Self>, id: &QString, seq: &QString) -> bool {
        let id = id.to_string();
        let n = normalize(&seq.to_string());
        if n.is_empty() || find_action(&id).is_none() {
            return false;
        }
        let mut list = self.effective(&id);
        if list.contains(&n) {
            return false;
        }
        list.push(n);
        self.as_mut().apply_override(&id, &list);
        self.shortcuts_changed();
        true
    }

    fn remove_sequence(mut self: Pin<&mut Self>, id: &QString, seq: &QString) -> bool {
        let id = id.to_string();
        let n = normalize(&seq.to_string());
        if n.is_empty() || find_action(&id).is_none() {
            return false;
        }
        let mut list = self.effective(&id);
        let Some(pos) = list.iter().position(|s| *s == n) else { return false };
        list.remove(pos);
        self.as_mut().apply_override(&id, &list);
        self.shortcuts_changed();
        true
    }

    fn reset_action(mut self: Pin<&mut Self>, id: &QString) {
        if self.as_mut().rust_mut().overrides.remove(&id.to_string()).is_some() {
            self.persist();
            self.shortcuts_changed();
        }
    }

    fn reset_all(mut self: Pin<&mut Self>) {
        if self.overrides.is_empty() {
            return;
        }
        self.as_mut().rust_mut().overrides.clear();
        self.persist();
        self.shortcuts_changed();
    }

    fn conflicts(&self, id: &QString, seqs: &QStringList) -> QList<QVariant> {
        let id = id.to_string();
        let normalized = normalize_all(&from_qsl(seqs));
        if normalized.is_empty() {
            return QList::default();
        }
        let mut result: Vec<Value> = Vec::new();
        for a in ACTIONS.iter().filter(|a| a.id != id) {
            let effective = self.effective(a.id);
            let hit: Vec<&String> = normalized.iter().filter(|n| effective.contains(n)).collect();
            if !hit.is_empty() {
                result.push(json!({ "id": a.id, "label": a.label, "sequences": hit }));
            }
        }
        to_qvariant_list(&result)
    }

    fn reassign(mut self: Pin<&mut Self>, id: &QString, seq: &QString) -> bool {
        let id = id.to_string();
        let n = normalize(&seq.to_string());
        if n.is_empty() || find_action(&id).is_none() {
            return false;
        }
        let mut changed = false;
        for a in ACTIONS.iter().filter(|a| a.id != id) {
            let mut effective = self.effective(a.id);
            let before = effective.len();
            effective.retain(|s| *s != n);
            if effective.len() != before {
                self.as_mut().apply_override(a.id, &effective);
                changed = true;
            }
        }
        let mut list = self.effective(&id);
        if !list.contains(&n) {
            list.push(n);
            self.as_mut().apply_override(&id, &list);
            changed = true;
        }
        if changed {
            self.shortcuts_changed();
        }
        changed
    }

    fn sequence_from_key(&self, key: i32, modifiers: i32) -> QString {
        native::ffi::key_sequence_from_key(key, modifiers)
    }

    fn is_acceptable(&self, seq: &QString) -> bool {
        !normalize(&seq.to_string()).is_empty()
    }

    fn is_bare_key(&self, seq: &QString) -> bool {
        native::ffi::is_bare_key_sequence(seq)
    }
}
