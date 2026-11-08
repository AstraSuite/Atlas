//! Colours: the Material 3 palette, following Caelestia's generated scheme
//! (~/.local/state/caelestia/scheme.json) when there is one.

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
        #[qproperty(bool, light, READ, WRITE = set_light, NOTIFY = light_changed)]
        #[qproperty(*mut M3Palette, palette, READ = palette, CONSTANT)]
        #[qproperty(*mut M3Palette, t_palette, cxx_name = "tPalette", READ = t_palette, CONSTANT)]
        type Colours = super::ColoursRust;

        #[qsignal]
        #[cxx_name = "lightChanged"]
        fn light_changed(self: Pin<&mut Colours>);

        #[cxx_name = "setLight"]
        fn set_light(self: Pin<&mut Colours>, light: bool);
        fn palette(self: &Colours) -> *mut M3Palette;
        #[cxx_name = "tPalette"]
        fn t_palette(self: &Colours) -> *mut M3Palette;

        #[qinvokable]
        fn reload(self: Pin<&mut Colours>);
    }

    impl cxx_qt::Threading for Colours {}
    impl cxx_qt::Constructor<()> for Colours {}
}

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

/// "#rrggbb" or "#aarrggbb", as QColor parses them.
fn parse_hex(text: &str) -> Option<[u8; 4]> {
    let hex = text.strip_prefix('#')?;
    let byte = |i: usize| u8::from_str_radix(hex.get(i..i + 2)?, 16).ok();
    match hex.len() {
        6 => Some([byte(0)?, byte(2)?, byte(4)?, 255]),
        8 => Some([byte(2)?, byte(4)?, byte(6)?, byte(0)?]),
        _ => None,
    }
}

fn defaults(light: bool) -> [[u8; 4]; 36] {
    let source = if light { LIGHT } else { DARK };
    source.map(|c| parse_hex(c).unwrap())
}

pub struct M3PaletteRust {
    colors: [[u8; 4]; 36],
}

impl Default for M3PaletteRust {
    fn default() -> Self {
        Self { colors: defaults(false) }
    }
}

impl M3Palette {
    fn color(&self, index: usize) -> QColor {
        let [r, g, b, a] = self.colors[index];
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

    /// Applies "primary" -> "ffb0ca" style entries from a scheme file.
    fn apply(mut self: Pin<&mut Self>, colours: &serde_json::Map<String, Value>) {
        for (key, value) in colours {
            let Some(index) = NAMES.iter().position(|n| n[2..] == *key) else { continue };
            if let Some(color) = value.as_str().and_then(|v| parse_hex(&format!("#{v}"))) {
                self.as_mut().rust_mut().colors[index] = color;
            }
        }
        self.palette_changed();
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
    palette: *mut M3Palette,
    t_palette: *mut M3Palette,
    scheme_file: String,
    watcher: Option<Watcher>,
}

impl Default for ColoursRust {
    fn default() -> Self {
        Self {
            light: false,
            palette: std::ptr::null_mut(),
            t_palette: std::ptr::null_mut(),
            scheme_file: format!("{}/.local/state/caelestia/scheme.json", paths::home()),
            watcher: None,
        }
    }
}

fn pin<'a>(p: *mut M3Palette) -> Pin<&'a mut M3Palette> {
    unsafe { Pin::new_unchecked(&mut *p) }
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

        // A forced --light/--dark wins over the scheme file.
        if let Some(light) = crate::cli::options().force_light {
            self.as_mut().set_light(light);
            return;
        }

        let thread = self.qt_thread();
        let watcher = Watcher::new(move |_| {
            let thread = thread.clone();
            std::thread::spawn(move || {
                // Let the writer finish flushing before reading.
                std::thread::sleep(std::time::Duration::from_millis(20));
                let _ = thread.queue(|colours| colours.on_scheme_changed());
            });
        });
        if let Some(w) = &watcher {
            let state_dir = paths::parent(&self.scheme_file);
            if paths::is_dir(&state_dir) {
                w.add_path(&state_dir);
            }
            if paths::exists(&self.scheme_file) {
                w.add_path(&self.scheme_file);
            }
        }
        self.as_mut().rust_mut().watcher = watcher;
    }
}

impl Colours {
    fn palette(&self) -> *mut M3Palette {
        self.palette
    }

    fn t_palette(&self) -> *mut M3Palette {
        self.t_palette
    }

    fn set_light(mut self: Pin<&mut Self>, light: bool) {
        if self.light != light {
            self.as_mut().rust_mut().light = light;
            pin(self.palette).load_defaults(light);
            pin(self.t_palette).load_defaults(light);
            self.light_changed();
        }
    }

    fn on_scheme_changed(self: Pin<&mut Self>) {
        if let Some(w) = &self.watcher {
            if paths::exists(&self.scheme_file) && !w.is_watching(&self.scheme_file) {
                w.add_path(&self.scheme_file);
            }
        }
        self.reload();
    }

    fn reload(mut self: Pin<&mut Self>) {
        let Ok(text) = std::fs::read_to_string(&self.scheme_file) else { return };
        let Ok(Value::Object(root)) = serde_json::from_str::<Value>(&text) else { return };
        let light = root.get("mode").and_then(Value::as_str) == Some("light");
        if self.light != light {
            self.as_mut().rust_mut().light = light;
            self.as_mut().light_changed();
        }
        if let Some(Value::Object(colours)) = root.get("colours") {
            pin(self.palette).apply(colours);
            pin(self.t_palette).apply(colours);
        }
    }
}
