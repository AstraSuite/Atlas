//! Recent files, read from the shared `recently-used.xbel`.

use super::paths;
use quick_xml::events::Event;
use quick_xml::{Reader, Writer};

fn store_path() -> String {
    format!("{}/recently-used.xbel", paths::data_home())
}

pub fn virtual_path() -> &'static str {
    "recent:///"
}

pub fn is_recent_path(path: &str) -> bool {
    path.starts_with("recent:")
}

fn attr(e: &quick_xml::events::BytesStart, name: &[u8]) -> Option<String> {
    e.attributes()
        .flatten()
        .find(|a| a.key.as_ref() == name)
        .and_then(|a| a.unescape_value().ok().map(|v| v.into_owned()))
}

/// Existing local files, most recently visited first.
pub fn paths(limit: usize) -> Vec<String> {
    let Ok(text) = std::fs::read_to_string(store_path()) else {
        return Vec::new();
    };
    let mut reader = Reader::from_str(&text);
    let mut entries: Vec<(String, String)> = Vec::new();
    loop {
        match reader.read_event() {
            Ok(Event::Start(e)) | Ok(Event::Empty(e)) if e.name().as_ref() == b"bookmark" => {
                let Some(href) = attr(&e, b"href") else { continue };
                if !href.starts_with("file://") {
                    continue;
                }
                let local = paths::from_file_url(&href);
                if local.is_empty() || !paths::exists(&local) {
                    continue;
                }
                let visited = attr(&e, b"visited").unwrap_or_default();
                entries.push((local, visited));
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
    }
    // ISO 8601 timestamps in one zone sort correctly as text.
    entries.sort_by(|a, b| b.1.cmp(&a.1));
    let mut result: Vec<String> = Vec::new();
    for (path, _) in entries {
        if result.len() >= limit {
            break;
        }
        if !result.contains(&path) {
            result.push(path);
        }
    }
    result
}

/// Drops `file_path`'s bookmark from the store.
pub fn forget(file_path: &str) {
    let store = store_path();
    let Ok(text) = std::fs::read_to_string(&store) else { return };
    let target = paths::to_file_url(file_path);

    let mut reader = Reader::from_str(&text);
    let mut writer = Writer::new_with_indent(Vec::new(), b' ', 2);
    let mut skip_depth: i32 = -1;
    loop {
        let event = match reader.read_event() {
            Ok(Event::Eof) => break,
            Ok(e) => e,
            Err(_) => return,
        };
        if skip_depth < 0 {
            match &event {
                Event::Start(e) if e.name().as_ref() == b"bookmark" && attr(e, b"href").as_deref() == Some(&target) => {
                    skip_depth = 0;
                    continue;
                }
                Event::Empty(e) if e.name().as_ref() == b"bookmark" && attr(e, b"href").as_deref() == Some(&target) => {
                    continue;
                }
                _ => {}
            }
        } else {
            match &event {
                Event::Start(_) => skip_depth += 1,
                Event::End(_) => {
                    if skip_depth == 0 {
                        skip_depth = -1;
                        continue;
                    }
                    skip_depth -= 1;
                }
                _ => {}
            }
            continue;
        }
        if let Event::Text(t) = &event {
            if t.iter().all(|b| b.is_ascii_whitespace()) {
                continue;
            }
        }
        if writer.write_event(event).is_err() {
            return;
        }
    }
    let output = writer.into_inner();
    if !output.is_empty() {
        let _ = std::fs::write(&store, output);
    }
}
