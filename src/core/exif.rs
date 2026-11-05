//! EXIF metadata for the preview panel and properties dialog, read with
//! kamadak-exif. Writing the comment goes through the `exiv2` CLI, since
//! kamadak-exif cannot write.

use exif::{Exif, Field, In, Tag, Value};
use serde_json::{json, Value as Json};
use std::io::BufReader;

fn append_row(rows: &mut Vec<Json>, label: &str, value: &str) {
    if !value.split_whitespace().collect::<Vec<_>>().is_empty() {
        rows.push(json!({ "label": label, "value": value }));
    }
}

fn field<'a>(exif: &'a Exif, tag: Tag) -> Option<&'a Field> {
    exif.get_field(tag, In::PRIMARY)
}

fn text(exif: &Exif, tag: Tag) -> String {
    match field(exif, tag).map(|f| &f.value) {
        Some(Value::Ascii(parts)) => parts
            .iter()
            .map(|p| String::from_utf8_lossy(p).trim_end_matches('\0').to_string())
            .collect::<Vec<_>>()
            .join(" ")
            .trim()
            .to_string(),
        Some(_) => field(exif, tag).map(|f| f.display_value().to_string()).unwrap_or_default(),
        None => String::new(),
    }
}

fn first_f64(exif: &Exif, tag: Tag) -> f64 {
    match field(exif, tag).map(|f| &f.value) {
        Some(Value::Rational(v)) => v.first().map(|r| r.to_f64()).unwrap_or(0.0),
        Some(Value::SRational(v)) => v.first().map(|r| r.to_f64()).unwrap_or(0.0),
        Some(v) => v.get_uint(0).map(f64::from).unwrap_or(0.0),
        None => 0.0,
    }
}

fn first_uint(exif: &Exif, tag: Tag) -> Option<u32> {
    field(exif, tag).and_then(|f| f.value.get_uint(0))
}

/// [48/1, 8/1, 4506/100] + "N" -> "48.1459° N"
fn format_gps(exif: &Exif, coord: Tag, reference: Tag) -> String {
    let reference = text(exif, reference);
    let Some(Value::Rational(parts)) = field(exif, coord).map(|f| &f.value) else {
        return String::new();
    };
    if parts.len() != 3 || reference.is_empty() || parts.iter().any(|r| r.denom == 0) {
        return String::new();
    }
    let decimal = parts[0].to_f64() + parts[1].to_f64() / 60.0 + parts[2].to_f64() / 3600.0;
    format!("{decimal:.4}° {}", reference.chars().next().unwrap())
}

/// "1/250" -> "1/250 s"; ten seconds or more is shown whole.
fn format_exposure(exif: &Exif) -> String {
    let Some(Value::Rational(v)) = field(exif, Tag::ExposureTime).map(|f| &f.value) else {
        return String::new();
    };
    let Some(r) = v.first() else { return String::new() };
    if r.denom > 0 && r.to_f64() >= 10.0 {
        return format!("{:.0} s", r.to_f64());
    }
    if r.denom == 1 {
        format!("{} s", r.num)
    } else {
        format!("{}/{} s", r.num, r.denom)
    }
}

/// UserComment starts with an 8-byte character code ("ASCII\0\0\0", ...).
fn user_comment(exif: &Exif) -> String {
    let Some(Value::Undefined(bytes, _)) = field(exif, Tag::UserComment).map(|f| &f.value) else {
        return String::new();
    };
    if bytes.len() < 8 {
        return String::new();
    }
    let (code, body) = bytes.split_at(8);
    let comment = if code.starts_with(b"UNICODE") {
        let units: Vec<u16> = body.chunks_exact(2).map(|c| u16::from_be_bytes([c[0], c[1]])).collect();
        String::from_utf16_lossy(&units)
    } else {
        String::from_utf8_lossy(body).into_owned()
    };
    comment.trim_matches(['\0', ' ']).trim().to_string()
}

/// Ordered {label, value} rows; empty when the file has no readable EXIF.
pub fn read(file_path: &str) -> Vec<Json> {
    let mut rows = Vec::new();
    if file_path.is_empty() {
        return rows;
    }
    let Ok(file) = std::fs::File::open(file_path) else { return rows };
    let Ok(exif) = exif::Reader::new().read_from_container(&mut BufReader::new(file)) else {
        return rows;
    };
    if exif.fields().next().is_none() {
        return rows;
    }

    let taken = text(&exif, Tag::DateTimeOriginal);
    let taken = chrono::NaiveDateTime::parse_from_str(&taken, "%Y:%m:%d %H:%M:%S")
        .ok()
        .and_then(|dt| dt.and_local_timezone(chrono::Local).single())
        .map(|dt| super::fileutils::format_msecs(dt.timestamp_millis()))
        .unwrap_or_default();
    append_row(&mut rows, "Date Taken", &taken);

    let make = text(&exif, Tag::Make);
    let mut model = text(&exif, Tag::Model);
    if !make.is_empty() && model.to_lowercase().starts_with(&make.to_lowercase()) {
        model = model[make.len()..].trim().to_string();
    }
    let camera = format!("{make} {model}").split_whitespace().collect::<Vec<_>>().join(" ");
    append_row(&mut rows, "Camera", &camera);
    append_row(&mut rows, "Lens", &text(&exif, Tag::LensModel));

    append_row(&mut rows, "Exposure", &format_exposure(&exif));
    let f_number = first_f64(&exif, Tag::FNumber);
    if f_number > 0.0 {
        append_row(&mut rows, "Aperture", &format!("f/{f_number:.1}"));
    }
    let iso = [Tag::PhotographicSensitivity, Tag::ISOSpeed]
        .into_iter()
        .find_map(|t| first_uint(&exif, t))
        .map(|v| v.to_string())
        .unwrap_or_default();
    append_row(&mut rows, "ISO", &iso);
    let focal = first_f64(&exif, Tag::FocalLength);
    if focal > 0.0 {
        let shown = if focal.fract() == 0.0 { format!("{}", focal as i64) } else { format!("{focal:.1}") };
        append_row(&mut rows, "Focal Length", &format!("{shown} mm"));
    }
    if let Some(flash) = first_uint(&exif, Tag::Flash) {
        append_row(&mut rows, "Flash", if flash & 0x01 != 0 { "Fired" } else { "Did not fire" });
    }
    if let Some(wb) = first_uint(&exif, Tag::WhiteBalance) {
        append_row(&mut rows, "White Balance", if wb == 1 { "Manual" } else { "Auto" });
    }

    let latitude = format_gps(&exif, Tag::GPSLatitude, Tag::GPSLatitudeRef);
    let longitude = format_gps(&exif, Tag::GPSLongitude, Tag::GPSLongitudeRef);
    let gps = match (latitude.is_empty(), longitude.is_empty()) {
        (_, true) => latitude,
        (true, false) => longitude,
        (false, false) => format!("{latitude}, {longitude}"),
    };
    append_row(&mut rows, "GPS Coordinates", &gps);

    append_row(&mut rows, "Software", &text(&exif, Tag::Software));
    rows.push(json!({ "label": "Comment", "value": user_comment(&exif) }));
    append_row(&mut rows, "Description", &text(&exif, Tag::ImageDescription));
    append_row(&mut rows, "Copyright", &text(&exif, Tag::Copyright));
    rows
}

/// Sets (or, when blank, removes) the EXIF UserComment using `exiv2`.
pub fn write_comment(file_path: &str, comment: &str) -> bool {
    if file_path.is_empty() || super::paths::find_executable("exiv2").is_none() {
        return false;
    }
    let command = if comment.trim().is_empty() {
        "del Exif.Photo.UserComment".to_string()
    } else {
        format!("set Exif.Photo.UserComment charset=Ascii {comment}")
    };
    std::process::Command::new("exiv2")
        .arg("-M")
        .arg(command)
        .arg("mo")
        .arg(file_path)
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}
