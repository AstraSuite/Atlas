//! TTY draws a Nerd Font glyph for each Material symbol, as KiiteShell does.
//! The table is KiiteShell's (`name codepoint glyph`, the glyph a Nerd Fonts
//! v3 name kept for reading) with the symbols only Atlas uses added at the end.

use std::collections::HashMap;
use std::sync::OnceLock;

static NERD: OnceLock<HashMap<&'static str, char>> = OnceLock::new();

fn table() -> &'static HashMap<&'static str, char> {
    NERD.get_or_init(|| {
        include_str!("../../assets/nerd_symbols.codepoints")
            .lines()
            .filter_map(|line| {
                let mut parts = line.split(' ');
                let (name, hex) = (parts.next()?, parts.next()?);
                Some((name, char::from_u32(u32::from_str_radix(hex, 16).ok()?)?))
            })
            .collect()
    })
}

/// The Nerd Font glyph for the Material symbol `name`, if the table has one.
pub fn glyph(name: &str) -> Option<char> {
    table().get(name).copied()
}

/// The Nerd face to draw glyphs in, picked as KiiteShell picks it: the Mono
/// build of `preferred` (`X NF` → `X NFM`), then any Mono Nerd face, then any
/// Nerd face at all. Mono faces keep every glyph one cell wide.
pub fn pick_face(families: &[String], preferred: &[&str]) -> Option<String> {
    let known = |n: &str| families.iter().any(|m| m == n);
    let mono_of = |n: &str| {
        n.strip_suffix(" NF")
            .map(|base| format!("{base} NFM"))
            .or_else(|| n.strip_suffix(" Nerd Font").map(|base| format!("{base} Nerd Font Mono")))
    };
    for p in preferred.iter().filter(|p| !p.is_empty()) {
        if let Some(mono) = mono_of(p).filter(|m| known(m)) {
            return Some(mono);
        }
        if (p.ends_with(" NFM") || p.ends_with("Nerd Font Mono")) && known(p) {
            return Some(p.to_string());
        }
    }
    let any = |pred: &dyn Fn(&str) -> bool| families.iter().find(|n| pred(n)).cloned();
    Some("Symbols Nerd Font Mono".to_string())
        .filter(|w| known(w))
        .or_else(|| any(&|n| n.ends_with(" NFM") || n.ends_with("Nerd Font Mono")))
        .or_else(|| Some("Symbols Nerd Font".to_string()).filter(|w| known(w)))
        .or_else(|| any(&|n| n.contains("Nerd Font") || n.ends_with(" NF")))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn maps_material_names() {
        assert_eq!(glyph("folder"), Some('\u{f07b}'));
        assert_eq!(glyph("zoom_in"), Some('\u{f034b}'));
        assert_eq!(glyph("no_such_symbol"), None);
    }

    #[test]
    fn prefers_mono_of_configured_face() {
        let fams: Vec<String> = ["JetBrains Mono NF", "JetBrains Mono NFM", "Hack Nerd Font"].iter().map(|s| s.to_string()).collect();
        assert_eq!(pick_face(&fams, &["JetBrains Mono NF"]).as_deref(), Some("JetBrains Mono NFM"));
        assert_eq!(pick_face(&fams, &["Iosevka"]).as_deref(), Some("JetBrains Mono NFM"));
        let plain: Vec<String> = vec!["Hack Nerd Font".into()];
        assert_eq!(pick_face(&plain, &[]).as_deref(), Some("Hack Nerd Font"));
        assert_eq!(pick_face(&[], &[]), None);
    }
}
