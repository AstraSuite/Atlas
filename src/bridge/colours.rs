//! Colours: the Material 3 palette, following KiiteShell's generated scheme
//! (~/.local/state/kiite/user/generated/colors.json), else Caelestia's
//! (~/.local/state/caelestia/scheme.json), and the look: Material 3 or TTY,
//! the latter as KiiteShell draws it.

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qcolor.h");
        type QColor = cxx_qt_lib::QColor;

        include!("qobjectfactory.h");
        #[cxx_name = "atlasNewChild"]
        unsafe fn new_palette(parent: *mut Colours) -> *mut M3Palette;
    }

    extern "RustQt" {
        #[qobject]
        #[qproperty(QColor, m3background, cxx_name = "m3background", READ = m3background, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3on_background, cxx_name = "m3onBackground", READ = m3on_background, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3surface, cxx_name = "m3surface", READ = m3surface, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3surface_dim, cxx_name = "m3surfaceDim", READ = m3surface_dim, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3surface_bright, cxx_name = "m3surfaceBright", READ = m3surface_bright, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3surface_container_lowest, cxx_name = "m3surfaceContainerLowest", READ = m3surface_container_lowest, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3surface_container_low, cxx_name = "m3surfaceContainerLow", READ = m3surface_container_low, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3surface_container, cxx_name = "m3surfaceContainer", READ = m3surface_container, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3surface_container_high, cxx_name = "m3surfaceContainerHigh", READ = m3surface_container_high, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3surface_container_highest, cxx_name = "m3surfaceContainerHighest", READ = m3surface_container_highest, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3on_surface, cxx_name = "m3onSurface", READ = m3on_surface, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3surface_variant, cxx_name = "m3surfaceVariant", READ = m3surface_variant, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3on_surface_variant, cxx_name = "m3onSurfaceVariant", READ = m3on_surface_variant, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3inverse_surface, cxx_name = "m3inverseSurface", READ = m3inverse_surface, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3inverse_on_surface, cxx_name = "m3inverseOnSurface", READ = m3inverse_on_surface, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3outline, cxx_name = "m3outline", READ = m3outline, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3outline_variant, cxx_name = "m3outlineVariant", READ = m3outline_variant, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3shadow, cxx_name = "m3shadow", READ = m3shadow, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3scrim, cxx_name = "m3scrim", READ = m3scrim, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3surface_tint, cxx_name = "m3surfaceTint", READ = m3surface_tint, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3primary, cxx_name = "m3primary", READ = m3primary, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3on_primary, cxx_name = "m3onPrimary", READ = m3on_primary, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3primary_container, cxx_name = "m3primaryContainer", READ = m3primary_container, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3on_primary_container, cxx_name = "m3onPrimaryContainer", READ = m3on_primary_container, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3secondary, cxx_name = "m3secondary", READ = m3secondary, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3on_secondary, cxx_name = "m3onSecondary", READ = m3on_secondary, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3secondary_container, cxx_name = "m3secondaryContainer", READ = m3secondary_container, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3on_secondary_container, cxx_name = "m3onSecondaryContainer", READ = m3on_secondary_container, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3tertiary, cxx_name = "m3tertiary", READ = m3tertiary, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3on_tertiary, cxx_name = "m3onTertiary", READ = m3on_tertiary, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3tertiary_container, cxx_name = "m3tertiaryContainer", READ = m3tertiary_container, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3on_tertiary_container, cxx_name = "m3onTertiaryContainer", READ = m3on_tertiary_container, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3error, cxx_name = "m3error", READ = m3error, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3on_error, cxx_name = "m3onError", READ = m3on_error, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3error_container, cxx_name = "m3errorContainer", READ = m3error_container, NOTIFY = palette_changed)]
        #[qproperty(QColor, m3on_error_container, cxx_name = "m3onErrorContainer", READ = m3on_error_container, NOTIFY = palette_changed)]
        type M3Palette = super::M3PaletteRust;

        #[qsignal]
        #[cxx_name = "paletteChanged"]
        fn palette_changed(self: Pin<&mut M3Palette>);

        #[cxx_name = "m3background"]
        fn m3background(self: &M3Palette) -> QColor;
        #[cxx_name = "m3onBackground"]
        fn m3on_background(self: &M3Palette) -> QColor;
        #[cxx_name = "m3surface"]
        fn m3surface(self: &M3Palette) -> QColor;
        #[cxx_name = "m3surfaceDim"]
        fn m3surface_dim(self: &M3Palette) -> QColor;
        #[cxx_name = "m3surfaceBright"]
        fn m3surface_bright(self: &M3Palette) -> QColor;
        #[cxx_name = "m3surfaceContainerLowest"]
        fn m3surface_container_lowest(self: &M3Palette) -> QColor;
        #[cxx_name = "m3surfaceContainerLow"]
        fn m3surface_container_low(self: &M3Palette) -> QColor;
        #[cxx_name = "m3surfaceContainer"]
        fn m3surface_container(self: &M3Palette) -> QColor;
        #[cxx_name = "m3surfaceContainerHigh"]
        fn m3surface_container_high(self: &M3Palette) -> QColor;
        #[cxx_name = "m3surfaceContainerHighest"]
        fn m3surface_container_highest(self: &M3Palette) -> QColor;
        #[cxx_name = "m3onSurface"]
        fn m3on_surface(self: &M3Palette) -> QColor;
        #[cxx_name = "m3surfaceVariant"]
        fn m3surface_variant(self: &M3Palette) -> QColor;
        #[cxx_name = "m3onSurfaceVariant"]
        fn m3on_surface_variant(self: &M3Palette) -> QColor;
        #[cxx_name = "m3inverseSurface"]
        fn m3inverse_surface(self: &M3Palette) -> QColor;
        #[cxx_name = "m3inverseOnSurface"]
        fn m3inverse_on_surface(self: &M3Palette) -> QColor;
        #[cxx_name = "m3outline"]
        fn m3outline(self: &M3Palette) -> QColor;
        #[cxx_name = "m3outlineVariant"]
        fn m3outline_variant(self: &M3Palette) -> QColor;
        #[cxx_name = "m3shadow"]
        fn m3shadow(self: &M3Palette) -> QColor;
        #[cxx_name = "m3scrim"]
        fn m3scrim(self: &M3Palette) -> QColor;
        #[cxx_name = "m3surfaceTint"]
        fn m3surface_tint(self: &M3Palette) -> QColor;
        #[cxx_name = "m3primary"]
        fn m3primary(self: &M3Palette) -> QColor;
        #[cxx_name = "m3onPrimary"]
        fn m3on_primary(self: &M3Palette) -> QColor;
        #[cxx_name = "m3primaryContainer"]
        fn m3primary_container(self: &M3Palette) -> QColor;
        #[cxx_name = "m3onPrimaryContainer"]
        fn m3on_primary_container(self: &M3Palette) -> QColor;
        #[cxx_name = "m3secondary"]
        fn m3secondary(self: &M3Palette) -> QColor;
        #[cxx_name = "m3onSecondary"]
        fn m3on_secondary(self: &M3Palette) -> QColor;
        #[cxx_name = "m3secondaryContainer"]
        fn m3secondary_container(self: &M3Palette) -> QColor;
        #[cxx_name = "m3onSecondaryContainer"]
        fn m3on_secondary_container(self: &M3Palette) -> QColor;
        #[cxx_name = "m3tertiary"]
        fn m3tertiary(self: &M3Palette) -> QColor;
        #[cxx_name = "m3onTertiary"]
        fn m3on_tertiary(self: &M3Palette) -> QColor;
        #[cxx_name = "m3tertiaryContainer"]
        fn m3tertiary_container(self: &M3Palette) -> QColor;
        #[cxx_name = "m3onTertiaryContainer"]
        fn m3on_tertiary_container(self: &M3Palette) -> QColor;
        #[cxx_name = "m3error"]
        fn m3error(self: &M3Palette) -> QColor;
        #[cxx_name = "m3onError"]
        fn m3on_error(self: &M3Palette) -> QColor;
        #[cxx_name = "m3errorContainer"]
        fn m3error_container(self: &M3Palette) -> QColor;
        #[cxx_name = "m3onErrorContainer"]
        fn m3on_error_container(self: &M3Palette) -> QColor;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        #[qproperty(bool, light, READ = is_light, WRITE = set_light, NOTIFY = light_changed)]
        #[qproperty(*mut M3Palette, palette, READ = palette, CONSTANT)]
        #[qproperty(*mut M3Palette, t_palette, cxx_name = "tPalette", READ = t_palette, CONSTANT)]
        #[qproperty(i32, style, READ, WRITE = set_style, NOTIFY = style_changed)]
        #[qproperty(bool, tty, READ, NOTIFY = tty_changed)]
        #[qproperty(bool, kiite_available, cxx_name = "kiiteAvailable", READ = kiite_available, CONSTANT)]
        type Colours = super::ColoursRust;

        #[qsignal]
        #[cxx_name = "lightChanged"]
        fn light_changed(self: Pin<&mut Colours>);
        #[qsignal]
        #[cxx_name = "styleChanged"]
        fn style_changed(self: Pin<&mut Colours>);
        #[qsignal]
        #[cxx_name = "ttyChanged"]
        fn tty_changed(self: Pin<&mut Colours>);

        #[cxx_name = "isLight"]
        fn is_light(self: &Colours) -> bool;
        #[cxx_name = "setLight"]
        fn set_light(self: Pin<&mut Colours>, light: bool);
        fn palette(self: &Colours) -> *mut M3Palette;
        #[cxx_name = "tPalette"]
        fn t_palette(self: &Colours) -> *mut M3Palette;
        #[cxx_name = "setStyle"]
        fn set_style(self: Pin<&mut Colours>, style: i32);
        #[cxx_name = "kiiteAvailable"]
        fn kiite_available(self: &Colours) -> bool;

        #[qinvokable]
        fn reload(self: Pin<&mut Colours>);
    }

    impl cxx_qt::Threading for Colours {}
    impl cxx_qt::Constructor<()> for Colours {}
}

use crate::bridge::native::{self, qs, settings};
use crate::core::paths;
use crate::core::watcher::Watcher;
use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::QColor;
use qobject::{Colours, M3Palette};
use serde_json::Value;
use std::pin::Pin;

const NAMES: [&str; 36] = ["m3background", "m3onBackground", "m3surface", "m3surfaceDim", "m3surfaceBright", "m3surfaceContainerLowest", "m3surfaceContainerLow", "m3surfaceContainer", "m3surfaceContainerHigh", "m3surfaceContainerHighest", "m3onSurface", "m3surfaceVariant", "m3onSurfaceVariant", "m3inverseSurface", "m3inverseOnSurface", "m3outline", "m3outlineVariant", "m3shadow", "m3scrim", "m3surfaceTint", "m3primary", "m3onPrimary", "m3primaryContainer", "m3onPrimaryContainer", "m3secondary", "m3onSecondary", "m3secondaryContainer", "m3onSecondaryContainer", "m3tertiary", "m3onTertiary", "m3tertiaryContainer", "m3onTertiaryContainer", "m3error", "m3onError", "m3errorContainer", "m3onErrorContainer"];
const DARK: [&str; 36] = ["#191114", "#efdfe2", "#191114", "#191114", "#403739", "#130c0e", "#22191c", "#261d20", "#31282a", "#3c3235", "#efdfe2", "#514347", "#d5c2c6", "#efdfe2", "#372e30", "#9e8c91", "#514347", "#000000", "#000000", "#ffb0ca", "#ffb0ca", "#541d34", "#6f334a", "#ffd9e3", "#e2bdc7", "#422932", "#5a3f48", "#ffd9e3", "#f0bc95", "#48290c", "#b58763", "#000000", "#ffb4ab", "#690005", "#93000a", "#ffdad6"];
const LIGHT: [&str; 36] = ["#fff8f8", "#22191c", "#fff8f8", "#e6dadc", "#fff8f8", "#ffffff", "#fcf1f3", "#f7ebed", "#f1e5e8", "#ebdfe2", "#22191c", "#f2dde2", "#514347", "#372e30", "#faeeef", "#837377", "#d5c2c6", "#000000", "#000000", "#8b4a62", "#8b4a62", "#ffffff", "#ffd9e3", "#39071f", "#745660", "#ffffff", "#ffd9e3", "#2b151d", "#7e5635", "#ffffff", "#ffdcc3", "#2f1500", "#ba1a1a", "#ffffff", "#ffdad6", "#410002"];

/// `preferences/uiStyle`: follow KiiteShell's look, or pick one.
const STYLE_FOLLOW_KIITE: i32 = 0;
const STYLE_TTY: i32 = 2;

type Rgba = [u8; 4];

/// "#rrggbb" or "#aarrggbb", as QColor parses them.
fn parse_hex(text: &str) -> Option<Rgba> {
    let hex = text.strip_prefix('#')?;
    let byte = |i: usize| u8::from_str_radix(hex.get(i..i + 2)?, 16).ok();
    match hex.len() {
        6 => Some([byte(0)?, byte(2)?, byte(4)?, 255]),
        8 => Some([byte(2)?, byte(4)?, byte(6)?, byte(0)?]),
        _ => None,
    }
}

fn defaults(light: bool) -> [Rgba; 36] {
    let source = if light { LIGHT } else { DARK };
    source.map(|c| parse_hex(c).unwrap())
}

/// TTY's neutrals, from KiiteShell's `look::ink`: tinted toward its default
/// accent like a terminal scheme.
mod ink {
    pub const GROUND: [u8; 4] = [0x0b, 0x0e, 0x0d, 255];
    pub const RAISED: [u8; 4] = [0x0f, 0x13, 0x12, 255];
    pub const ROW: [u8; 4] = [0x16, 0x21, 0x1f, 255];
    pub const TAB: [u8; 4] = [0x1f, 0x2a, 0x28, 255];
    pub const BORDER: [u8; 4] = [0x2f, 0x3a, 0x37, 255];
    pub const TEXT: [u8; 4] = [0xcf, 0xd8, 0xd5, 255];
    pub const BRIGHT: [u8; 4] = [0xe7, 0xee, 0xec, 255];
    pub const VARIANT: [u8; 4] = [0x9a, 0xa6, 0xa2, 255];
    pub const DIM: [u8; 4] = [0x7d, 0x8a, 0x86, 255];
    pub const ERROR: [u8; 4] = [0xe5, 0x83, 0x8a, 255];
    pub const BLACK: [u8; 4] = [0, 0, 0, 255];
}

/// `c` laid over the TTY ground at `alpha`.
fn tint(c: Rgba, alpha: f32) -> Rgba {
    let g = ink::GROUND;
    let mix = |i: usize| (g[i] as f32 + (c[i] as f32 - g[i] as f32) * alpha).round() as u8;
    [mix(0), mix(1), mix(2), 255]
}

/// The scheme's palette as TTY shows it: its accents stay, its surfaces
/// flatten to one ground that borders, not tones, divide (KiiteShell's
/// `tty_palette`).
fn tty_color(name: &str, base: &[Rgba; 36]) -> Rgba {
    let get = |n: &str| base[NAMES.iter().position(|x| *x == n).unwrap()];
    let (primary, tertiary) = (get("m3primary"), get("m3tertiary"));
    match name {
        "m3primary" | "m3surfaceTint" | "m3onPrimaryContainer" | "m3onSecondaryContainer" => primary,
        "m3secondary" => get("m3secondary"),
        "m3tertiary" | "m3onTertiaryContainer" => tertiary,
        "m3onPrimary" | "m3onSecondary" | "m3onTertiary" | "m3onError" => ink::GROUND,
        "m3primaryContainer" => tint(primary, 0.18),
        "m3secondaryContainer" | "m3surfaceBright" => ink::TAB,
        "m3tertiaryContainer" => tint(tertiary, 0.18),
        "m3error" | "m3onErrorContainer" => ink::ERROR,
        "m3errorContainer" => tint(ink::ERROR, 0.2),
        "m3onBackground" | "m3onSurface" => ink::TEXT,
        "m3surfaceVariant" | "m3surfaceContainerHighest" => ink::ROW,
        "m3onSurfaceVariant" => ink::VARIANT,
        "m3outline" => ink::DIM,
        "m3outlineVariant" => ink::BORDER,
        "m3surfaceContainerHigh" | "m3inverseSurface" => ink::RAISED,
        "m3inverseOnSurface" => ink::BRIGHT,
        "m3shadow" | "m3scrim" => ink::BLACK,
        _ => ink::GROUND,
    }
}

/// "surface_container_high" -> "m3surfaceContainerHigh"
fn kiite_key_to_name(key: &str) -> String {
    let mut out = String::from("m3");
    let mut upper = false;
    for c in key.chars() {
        if c == '_' {
            upper = true;
        } else if upper {
            out.extend(c.to_uppercase());
            upper = false;
        } else {
            out.push(c);
        }
    }
    out
}

fn kiite_colors_file() -> String {
    format!("{}/.local/state/kiite/user/generated/colors.json", paths::home())
}

fn caelestia_scheme_file() -> String {
    format!("{}/.local/state/caelestia/scheme.json", paths::home())
}

fn kiite_config_file() -> String {
    format!("{}/kiite/config.json", paths::config_home())
}

/// KiiteShell's `appearance`: (whether its theme is "tty", its monospace face).
fn kiite_appearance() -> Option<(bool, String)> {
    let text = std::fs::read_to_string(kiite_config_file()).ok()?;
    let root: Value = serde_json::from_str(&text).ok()?;
    let appearance = root.get("appearance")?;
    let tty = appearance.get("theme").and_then(Value::as_str).is_some_and(|t| t.eq_ignore_ascii_case("tty"));
    let mono = appearance.pointer("/fonts/monospace").and_then(Value::as_str).unwrap_or("").to_string();
    Some((tty, mono))
}

/// A scheme: whether it is light, and its colours by palette name.
struct Scheme {
    light: bool,
    colours: Vec<(String, Rgba)>,
}

/// KiiteShell's generated palette: snake_case roles, no mode, so the mode is
/// read off the background.
fn read_kiite_scheme() -> Option<Scheme> {
    let text = std::fs::read_to_string(kiite_colors_file()).ok()?;
    let Value::Object(map) = serde_json::from_str::<Value>(&text).ok()? else { return None };
    let colours: Vec<(String, Rgba)> = map
        .iter()
        .filter_map(|(k, v)| Some((kiite_key_to_name(k), parse_hex(v.as_str()?)?)))
        .collect();
    let bg = colours.iter().find(|(n, _)| n == "m3background").map(|(_, c)| *c)?;
    let luma = 0.2126 * bg[0] as f32 + 0.7152 * bg[1] as f32 + 0.0722 * bg[2] as f32;
    Some(Scheme { light: luma > 127.0, colours })
}

/// Caelestia's scheme: `mode` and `colours` of camelCase roles without "#".
fn read_caelestia_scheme() -> Option<Scheme> {
    let text = std::fs::read_to_string(caelestia_scheme_file()).ok()?;
    let Value::Object(root) = serde_json::from_str::<Value>(&text).ok()? else { return None };
    let light = root.get("mode").and_then(Value::as_str) == Some("light");
    let colours = root
        .get("colours")
        .and_then(Value::as_object)
        .map(|c| {
            c.iter()
                .filter_map(|(k, v)| Some((format!("m3{k}"), parse_hex(&format!("#{}", v.as_str()?))?)))
                .collect()
        })
        .unwrap_or_default();
    Some(Scheme { light, colours })
}

pub struct M3PaletteRust {
    /// The scheme's own colours
    colors: [Rgba; 36],
    tty: bool,
}

impl Default for M3PaletteRust {
    fn default() -> Self {
        Self { colors: defaults(false), tty: false }
    }
}

impl M3Palette {
    fn color(&self, index: usize) -> QColor {
        let [r, g, b, a] = if self.tty { tty_color(NAMES[index], &self.colors) } else { self.colors[index] };
        if a == 255 {
            QColor::from_rgb(r as i32, g as i32, b as i32)
        } else {
            QColor::from_rgba_f(r as f32 / 255.0, g as f32 / 255.0, b as f32 / 255.0, a as f32 / 255.0)
        }
    }

    fn load_defaults(mut self: Pin<&mut Self>, light: bool) {
        self.as_mut().rust_mut().colors = defaults(light);
        self.palette_changed();
    }

    fn apply(mut self: Pin<&mut Self>, colours: &[(String, Rgba)]) {
        for (name, color) in colours {
            if let Some(index) = NAMES.iter().position(|n| n == name) {
                self.as_mut().rust_mut().colors[index] = *color;
            }
        }
        self.palette_changed();
    }

    fn set_tty(mut self: Pin<&mut Self>, tty: bool) {
        if self.tty != tty {
            self.as_mut().rust_mut().tty = tty;
            self.palette_changed();
        }
    }

    fn m3background(&self) -> QColor {
        self.color(0)
    }
    fn m3on_background(&self) -> QColor {
        self.color(1)
    }
    fn m3surface(&self) -> QColor {
        self.color(2)
    }
    fn m3surface_dim(&self) -> QColor {
        self.color(3)
    }
    fn m3surface_bright(&self) -> QColor {
        self.color(4)
    }
    fn m3surface_container_lowest(&self) -> QColor {
        self.color(5)
    }
    fn m3surface_container_low(&self) -> QColor {
        self.color(6)
    }
    fn m3surface_container(&self) -> QColor {
        self.color(7)
    }
    fn m3surface_container_high(&self) -> QColor {
        self.color(8)
    }
    fn m3surface_container_highest(&self) -> QColor {
        self.color(9)
    }
    fn m3on_surface(&self) -> QColor {
        self.color(10)
    }
    fn m3surface_variant(&self) -> QColor {
        self.color(11)
    }
    fn m3on_surface_variant(&self) -> QColor {
        self.color(12)
    }
    fn m3inverse_surface(&self) -> QColor {
        self.color(13)
    }
    fn m3inverse_on_surface(&self) -> QColor {
        self.color(14)
    }
    fn m3outline(&self) -> QColor {
        self.color(15)
    }
    fn m3outline_variant(&self) -> QColor {
        self.color(16)
    }
    fn m3shadow(&self) -> QColor {
        self.color(17)
    }
    fn m3scrim(&self) -> QColor {
        self.color(18)
    }
    fn m3surface_tint(&self) -> QColor {
        self.color(19)
    }
    fn m3primary(&self) -> QColor {
        self.color(20)
    }
    fn m3on_primary(&self) -> QColor {
        self.color(21)
    }
    fn m3primary_container(&self) -> QColor {
        self.color(22)
    }
    fn m3on_primary_container(&self) -> QColor {
        self.color(23)
    }
    fn m3secondary(&self) -> QColor {
        self.color(24)
    }
    fn m3on_secondary(&self) -> QColor {
        self.color(25)
    }
    fn m3secondary_container(&self) -> QColor {
        self.color(26)
    }
    fn m3on_secondary_container(&self) -> QColor {
        self.color(27)
    }
    fn m3tertiary(&self) -> QColor {
        self.color(28)
    }
    fn m3on_tertiary(&self) -> QColor {
        self.color(29)
    }
    fn m3tertiary_container(&self) -> QColor {
        self.color(30)
    }
    fn m3on_tertiary_container(&self) -> QColor {
        self.color(31)
    }
    fn m3error(&self) -> QColor {
        self.color(32)
    }
    fn m3on_error(&self) -> QColor {
        self.color(33)
    }
    fn m3error_container(&self) -> QColor {
        self.color(34)
    }
    fn m3on_error_container(&self) -> QColor {
        self.color(35)
    }
}

pub struct ColoursRust {
    light: bool,
    style: i32,
    tty: bool,
    palette: *mut M3Palette,
    t_palette: *mut M3Palette,
    watcher: Option<Watcher>,
}

impl Default for ColoursRust {
    fn default() -> Self {
        Self {
            light: false,
            style: settings::int("preferences/uiStyle", STYLE_FOLLOW_KIITE).clamp(0, 2),
            tty: false,
            palette: std::ptr::null_mut(),
            t_palette: std::ptr::null_mut(),
            watcher: None,
        }
    }
}

fn pin<'a>(p: *mut M3Palette) -> Pin<&'a mut M3Palette> {
    unsafe { Pin::new_unchecked(&mut *p) }
}

/// Files whose changes recolour or restyle Atlas while it runs.
fn watched_files() -> [String; 3] {
    [kiite_colors_file(), caelestia_scheme_file(), kiite_config_file()]
}

impl cxx_qt::Initialize for Colours {
    fn initialize(mut self: Pin<&mut Self>) {
        let me = unsafe { self.as_mut().get_unchecked_mut() as *mut Colours };
        {
            let mut r = self.as_mut().rust_mut();
            r.palette = unsafe { qobject::new_palette(me) };
            r.t_palette = unsafe { qobject::new_palette(me) };
        }
        self.as_mut().reload();
        self.as_mut().apply_style();

        // A forced --light/--dark lasts until the scheme next changes.
        if let Some(light) = crate::cli::options().force_light {
            self.as_mut().set_light(light);
        }

        let thread = self.qt_thread();
        let watcher = Watcher::new(move |_| {
            let thread = thread.clone();
            std::thread::spawn(move || {
                // Let the writer finish flushing before reading.
                std::thread::sleep(std::time::Duration::from_millis(20));
                let _ = thread.queue(|colours| colours.on_files_changed());
            });
        });
        self.as_mut().rust_mut().watcher = watcher;
        self.watch_files();
    }
}

impl Colours {
    /// Watches each file and its folder: the files are often replaced
    /// rather than edited, which ends a watch on the file itself.
    fn watch_files(&self) {
        let Some(w) = &self.watcher else { return };
        for file in watched_files() {
            let dir = paths::parent(&file);
            if paths::is_dir(&dir) && !w.is_watching(&dir) {
                w.add_path(&dir);
            }
            if paths::exists(&file) && !w.is_watching(&file) {
                w.add_path(&file);
            }
        }
    }

    fn on_files_changed(mut self: Pin<&mut Self>) {
        self.watch_files();
        self.as_mut().reload();
        self.apply_style();
    }

    fn palette(&self) -> *mut M3Palette {
        self.palette
    }

    fn t_palette(&self) -> *mut M3Palette {
        self.t_palette
    }

    /// TTY is dark only.
    fn is_light(&self) -> bool {
        self.light && !self.tty
    }

    fn kiite_available(&self) -> bool {
        paths::exists(&kiite_config_file())
    }

    fn set_light(mut self: Pin<&mut Self>, light: bool) {
        if self.light != light {
            self.as_mut().rust_mut().light = light;
            pin(self.palette).load_defaults(light);
            pin(self.t_palette).load_defaults(light);
            self.light_changed();
        }
    }

    fn set_style(mut self: Pin<&mut Self>, style: i32) {
        let style = style.clamp(0, 2);
        if self.style != style {
            self.as_mut().rust_mut().style = style;
            settings::set_int("preferences/uiStyle", style);
            self.as_mut().style_changed();
            self.apply_style();
        }
    }

    /// Works out whether TTY is on (--tty, the style preference, or
    /// KiiteShell's own theme) and switches the palettes and tokens over.
    fn apply_style(mut self: Pin<&mut Self>) {
        let kiite = kiite_appearance();
        let tty = crate::cli::options().force_tty
            || match self.style {
                STYLE_FOLLOW_KIITE => kiite.as_ref().is_some_and(|(tty, _)| *tty),
                s => s == STYLE_TTY,
            };
        if self.tty == tty {
            return;
        }
        let mono = kiite.map(|(_, mono)| mono).unwrap_or_default();
        native::ffi::set_tty_tokens(tty, &qs(&mono));
        self.as_mut().rust_mut().tty = tty;
        pin(self.palette).set_tty(tty);
        pin(self.t_palette).set_tty(tty);
        self.as_mut().tty_changed();
        self.light_changed();
    }

    /// Loads KiiteShell's scheme, else Caelestia's.
    fn reload(mut self: Pin<&mut Self>) {
        let Some(scheme) = read_kiite_scheme().or_else(read_caelestia_scheme) else { return };
        if self.light != scheme.light {
            self.as_mut().rust_mut().light = scheme.light;
            self.as_mut().light_changed();
        }
        pin(self.palette).apply(&scheme.colours);
        pin(self.t_palette).apply(&scheme.colours);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn kiite_keys_map_to_palette_names() {
        assert_eq!(kiite_key_to_name("surface_container_high"), "m3surfaceContainerHigh");
        assert_eq!(kiite_key_to_name("on_primary"), "m3onPrimary");
        assert!(NAMES.contains(&kiite_key_to_name("inverse_on_surface").as_str()));
    }

    #[test]
    fn tty_keeps_accents_and_flattens_surfaces() {
        let base = defaults(false);
        let primary = base[NAMES.iter().position(|n| *n == "m3primary").unwrap()];
        assert_eq!(tty_color("m3primary", &base), primary);
        assert_eq!(tty_color("m3surfaceContainer", &base), ink::GROUND);
        assert_eq!(tty_color("m3onPrimary", &base), ink::GROUND);
    }
}
