//! IconCatalog: searchable Material Symbols names for the icon picker.

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
        #[qproperty(i32, total_icons, cxx_name = "totalIcons", READ = total_icons, CONSTANT)]
        type IconCatalog = super::IconCatalogRust;

        #[cxx_name = "totalIcons"]
        fn total_icons(self: &IconCatalog) -> i32;

        #[qinvokable]
        fn search(self: &IconCatalog, query: &QString, limit: i32) -> QStringList;
        #[qinvokable]
        #[cxx_name = "getAllIcons"]
        fn get_all_icons(self: &IconCatalog) -> QStringList;
    }
}

use crate::bridge::native::qsl;
use cxx_qt_lib::{QString, QStringList};

const ICONS: &str = include_str!("../../assets/material_icons.txt");

fn icons() -> impl Iterator<Item = &'static str> {
    ICONS.lines().map(str::trim).filter(|l| !l.is_empty())
}

#[derive(Default)]
pub struct IconCatalogRust;

/// Exact match first, then prefix matches, then substring matches.
pub fn search(query: &str, limit: usize) -> Vec<&'static str> {
    let q = query.trim().to_lowercase();
    if q.is_empty() {
        let all = icons();
        return if limit > 0 { all.take(limit).collect() } else { all.collect() };
    }
    let (mut exact, mut prefix, mut substring) = (Vec::new(), Vec::new(), Vec::new());
    for icon in icons() {
        if icon == q {
            exact.push(icon);
        } else if icon.starts_with(&q) {
            prefix.push(icon);
        } else if icon.contains(&q) {
            substring.push(icon);
        }
        if limit > 0 && exact.len() + prefix.len() + substring.len() >= limit * 2 {
            break;
        }
    }
    let mut result = exact;
    result.extend(prefix);
    result.extend(substring);
    if limit > 0 {
        result.truncate(limit);
    }
    result
}

impl qobject::IconCatalog {
    fn total_icons(&self) -> i32 {
        icons().count() as i32
    }

    fn search(&self, query: &QString, limit: i32) -> QStringList {
        qsl(&search(&query.to_string(), limit.max(0) as usize))
    }

    fn get_all_icons(&self) -> QStringList {
        qsl(&icons().collect::<Vec<_>>())
    }
}
