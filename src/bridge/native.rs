//! Bridge to native/qthelpers.h, plus Rust-side conveniences on top of it.

#[cxx_qt::bridge(namespace = "atlas::native")]
pub mod ffi {
    struct ClipboardState {
        files: QStringList,
        cut: bool,
        #[cxx_name = "imagePngBase64"]
        image_png_base64: QString,
    }

    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        include!("cxx-qt-lib/qstringlist.h");
        include!("cxx-qt-lib/qsize.h");
        include!("cxx-qt-lib/qqmlapplicationengine.h");
        include!("qthelpers.h");

        #[namespace = ""]
        type QString = cxx_qt_lib::QString;
        #[namespace = ""]
        type QStringList = cxx_qt_lib::QStringList;
        #[namespace = ""]
        type QSize = cxx_qt_lib::QSize;
        #[namespace = ""]
        type QQmlApplicationEngine = cxx_qt_lib::QQmlApplicationEngine;

        #[cxx_name = "preApplicationSetup"]
        fn pre_application_setup();
        #[cxx_name = "setupApplication"]
        fn setup_application(version: &QString);
        #[cxx_name = "installEngine"]
        fn install_engine(engine: Pin<&mut QQmlApplicationEngine>);
        #[cxx_name = "clearIconCache"]
        fn clear_icon_cache();
        #[cxx_name = "setTtyTokens"]
        fn set_tty_tokens(tty: bool, preferred_mono: &QString);

        #[cxx_name = "settingsContains"]
        fn settings_contains(scope: i32, key: &QString) -> bool;
        #[cxx_name = "settingsBool"]
        fn settings_bool(scope: i32, key: &QString, fallback: bool) -> bool;
        #[cxx_name = "settingsInt"]
        fn settings_int(scope: i32, key: &QString, fallback: i32) -> i32;
        #[cxx_name = "settingsDouble"]
        fn settings_double(scope: i32, key: &QString, fallback: f64) -> f64;
        #[cxx_name = "settingsString"]
        fn settings_string(scope: i32, key: &QString, fallback: &QString) -> QString;
        #[cxx_name = "settingsStringList"]
        fn settings_string_list(scope: i32, key: &QString) -> QStringList;
        #[cxx_name = "settingsSetBool"]
        fn settings_set_bool(key: &QString, value: bool);
        #[cxx_name = "settingsSetInt"]
        fn settings_set_int(key: &QString, value: i32);
        #[cxx_name = "settingsSetDouble"]
        fn settings_set_double(key: &QString, value: f64);
        #[cxx_name = "settingsSetString"]
        fn settings_set_string(key: &QString, value: &QString);
        #[cxx_name = "settingsSetStringList"]
        fn settings_set_string_list(key: &QString, value: &QStringList);
        #[cxx_name = "settingsRemove"]
        fn settings_remove(key: &QString);

        #[cxx_name = "mimeNameForFile"]
        fn mime_name_for_file(path: &QString) -> QString;
        #[cxx_name = "mimeComment"]
        fn mime_comment(name: &QString) -> QString;
        #[cxx_name = "mimeInherits"]
        fn mime_inherits(name: &QString, parent: &QString) -> bool;
        #[cxx_name = "mimeAliases"]
        fn mime_aliases(name: &QString) -> QStringList;

        #[cxx_name = "hasThemeIcon"]
        fn has_theme_icon(name: &QString) -> bool;
        #[cxx_name = "iconThemeSearchPaths"]
        fn icon_theme_search_paths() -> QStringList;

        #[cxx_name = "normalizeKeySequence"]
        fn normalize_key_sequence(sequence: &QString) -> QString;
        #[cxx_name = "keySequenceFromKey"]
        fn key_sequence_from_key(key: i32, modifiers: i32) -> QString;
        #[cxx_name = "isBareKeySequence"]
        fn is_bare_key_sequence(sequence: &QString) -> bool;

        #[cxx_name = "formatDateTime"]
        fn format_date_time(msecs: i64, format: i32, pattern: &QString) -> QString;
        #[cxx_name = "queryKeyboardModifiers"]
        fn query_keyboard_modifiers() -> i32;
        #[cxx_name = "imageSize"]
        fn image_size(path: &QString) -> QSize;

        #[cxx_name = "clipboardWatch"]
        fn clipboard_watch();
        #[cxx_name = "clipboardSetFiles"]
        fn clipboard_set_files(paths: &QStringList, cut: bool);
        #[cxx_name = "clipboardSetText"]
        fn clipboard_set_text(text: &QString);
        #[cxx_name = "clipboardRead"]
        fn clipboard_read() -> ClipboardState;

        #[cxx_name = "startNativeDrag"]
        fn start_native_drag(paths: &QStringList, card_width: i32, card_height: i32, icon_size: i32);
    }

    extern "Rust" {
        fn clipboard_changed();
        fn native_drag_finished();
    }
}

use cxx_qt_lib::{QList, QString, QStringList, QVariant};
use serde_json::Value;

fn clipboard_changed() {
    crate::bridge::fileoperations::on_clipboard_changed();
}

fn native_drag_finished() {
    crate::bridge::fileoperations::on_native_drag_finished();
}

// ---- Strings ----

pub fn qs(s: &str) -> QString {
    QString::from(s)
}

pub fn qsl<S: AsRef<str>>(items: &[S]) -> QStringList {
    let mut list = QList::<QString>::default();
    for item in items {
        list.append(QString::from(item.as_ref()));
    }
    QStringList::from(&list)
}

pub fn from_qsl(list: &QStringList) -> Vec<String> {
    let list: QList<QString> = QList::from(list);
    list.iter().map(|s| s.to_string()).collect()
}

// ---- JSON -> QVariant ----

/// Converts JSON into the QVariant QML expects: objects become QVariantMap,
/// arrays QVariantList, integers qint64 and other numbers double.
pub fn to_qvariant(value: &Value) -> QVariant {
    match value {
        Value::Null => QVariant::default(),
        Value::Bool(b) => QVariant::from(b),
        Value::Number(n) => match n.as_i64() {
            Some(i) if i >= i32::MIN as i64 && i <= i32::MAX as i64 => QVariant::from(&(i as i32)),
            Some(i) => QVariant::from(&i),
            None => QVariant::from(&n.as_f64().unwrap_or(0.0)),
        },
        Value::String(s) => QVariant::from(&QString::from(s.as_str())),
        Value::Array(items) => QVariant::from(&to_qvariant_list(items)),
        Value::Object(_) => QVariant::from(&to_qvariant_map(value).unwrap_or_default()),
    }
}

pub type QVariantMap = cxx_qt_lib::QMap<cxx_qt_lib::QMapPair_QString_QVariant>;

pub fn to_qvariant_list(items: &[Value]) -> QList<QVariant> {
    let mut list = QList::<QVariant>::default();
    list.reserve(items.len() as isize);
    for item in items {
        list.append(to_qvariant(item));
    }
    list
}

pub fn to_qvariant_map(value: &Value) -> Option<QVariantMap> {
    let Value::Object(map) = value else { return None };
    let mut out = QVariantMap::default();
    for (k, v) in map {
        out.insert(QString::from(k.as_str()), to_qvariant(v));
    }
    Some(out)
}

// ---- Settings ----

pub mod settings {
    use super::{ffi, qs, qsl, from_qsl};

    pub fn contains(key: &str) -> bool {
        ffi::settings_contains(0, &qs(key))
    }

    /// Reads a bool, falling back to the two legacy Prism stores in turn.
    pub fn bool_with_legacy(key: &str, fallback: bool) -> bool {
        let legacy2 = ffi::settings_bool(2, &qs(key), fallback);
        let legacy1 = ffi::settings_bool(1, &qs(key), legacy2);
        ffi::settings_bool(0, &qs(key), legacy1)
    }

    pub fn bool(key: &str, fallback: bool) -> bool {
        ffi::settings_bool(0, &qs(key), fallback)
    }
    pub fn int(key: &str, fallback: i32) -> i32 {
        ffi::settings_int(0, &qs(key), fallback)
    }
    pub fn double(key: &str, fallback: f64) -> f64 {
        ffi::settings_double(0, &qs(key), fallback)
    }
    pub fn string(key: &str, fallback: &str) -> String {
        ffi::settings_string(0, &qs(key), &qs(fallback)).to_string()
    }
    pub fn string_list(key: &str) -> Vec<String> {
        from_qsl(&ffi::settings_string_list(0, &qs(key)))
    }
    pub fn legacy_string(scope: i32, key: &str) -> String {
        ffi::settings_string(scope, &qs(key), &qs("")).to_string()
    }
    pub fn legacy_contains(scope: i32, key: &str) -> bool {
        ffi::settings_contains(scope, &qs(key))
    }

    pub fn set_bool(key: &str, value: bool) {
        ffi::settings_set_bool(&qs(key), value)
    }
    pub fn set_int(key: &str, value: i32) {
        ffi::settings_set_int(&qs(key), value)
    }
    pub fn set_double(key: &str, value: f64) {
        ffi::settings_set_double(&qs(key), value)
    }
    pub fn set_string(key: &str, value: &str) {
        ffi::settings_set_string(&qs(key), &qs(value))
    }
    pub fn set_string_list(key: &str, value: &[String]) {
        ffi::settings_set_string_list(&qs(key), &qsl(value))
    }
    pub fn remove(key: &str) {
        ffi::settings_remove(&qs(key))
    }
}

// ---- MIME ----

pub mod mime {
    use super::{ffi, from_qsl, qs};

    /// Detects by name and, when needed, by content.
    pub fn for_file(path: &str) -> String {
        ffi::mime_name_for_file(&qs(path)).to_string()
    }
    pub fn comment(name: &str) -> String {
        ffi::mime_comment(&qs(name)).to_string()
    }
    pub fn inherits(name: &str, parent: &str) -> bool {
        ffi::mime_inherits(&qs(name), &qs(parent))
    }
    pub fn aliases(name: &str) -> Vec<String> {
        from_qsl(&ffi::mime_aliases(&qs(name)))
    }
}

pub fn has_theme_icon(name: &str) -> bool {
    !name.is_empty() && ffi::has_theme_icon(&qs(name))
}

pub fn icon_theme_search_paths() -> Vec<String> {
    from_qsl(&ffi::icon_theme_search_paths())
}

pub fn image_size(path: &str) -> Option<(i32, i32)> {
    let size = ffi::image_size(&qs(path));
    (size.width() > 0 && size.height() > 0).then(|| (size.width(), size.height()))
}
