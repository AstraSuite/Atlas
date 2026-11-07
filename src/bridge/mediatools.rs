//! MediaTools: ffmpeg and ImageMagick conversions for the Media Tools menu.

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
        include!("cxx-qt-lib/qstringlist.h");
        type QStringList = cxx_qt_lib::QStringList;
    }

    #[qenum(MediaTools)]
    enum Kind {
        Image,
        Video,
        Audio,
        Unknown,
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        #[qproperty(bool, busy, READ, NOTIFY = busy_changed)]
        #[qproperty(QString, status_text, cxx_name = "statusText", READ, NOTIFY = status_text_changed)]
        #[qproperty(bool, ffmpeg_available, cxx_name = "ffmpegAvailable", READ = ffmpeg_available, CONSTANT)]
        #[qproperty(bool, image_magick_available, cxx_name = "imageMagickAvailable", READ = image_magick_available, CONSTANT)]
        type MediaTools = super::MediaToolsRust;

        #[qsignal]
        #[cxx_name = "busyChanged"]
        fn busy_changed(self: Pin<&mut MediaTools>);
        #[qsignal]
        #[cxx_name = "statusTextChanged"]
        fn status_text_changed(self: Pin<&mut MediaTools>);

        #[cxx_name = "ffmpegAvailable"]
        fn ffmpeg_available(self: &MediaTools) -> bool;
        #[cxx_name = "imageMagickAvailable"]
        fn image_magick_available(self: &MediaTools) -> bool;

        #[qinvokable]
        #[cxx_name = "clipVideo"]
        fn clip_video(self: Pin<&mut MediaTools>, source: &QString, start_seconds: f64, end_seconds: f64);
        #[qinvokable]
        #[cxx_name = "convertMedia"]
        fn convert_media(self: Pin<&mut MediaTools>, source: &QString, format: &QString);
        #[qinvokable]
        #[cxx_name = "rotateMedia"]
        fn rotate_media(self: Pin<&mut MediaTools>, source: &QString, degrees: i32);
        #[qinvokable]
        #[cxx_name = "flipMedia"]
        fn flip_media(self: Pin<&mut MediaTools>, source: &QString, horizontal: bool);
        #[qinvokable]
        #[cxx_name = "circleCrop"]
        fn circle_crop(self: Pin<&mut MediaTools>, source: &QString);
        #[qinvokable]
        #[cxx_name = "setAspectRatio"]
        fn set_aspect_ratio(self: Pin<&mut MediaTools>, source: &QString, ratio_w: i32, ratio_h: i32, crop: bool);
        #[qinvokable]
        #[cxx_name = "kindFor"]
        fn kind_for(self: &MediaTools, source: &QString) -> i32;
        #[qinvokable]
        #[cxx_name = "formatsFor"]
        fn formats_for(self: Pin<&mut MediaTools>, source: &QString) -> QStringList;
        #[qinvokable]
        #[cxx_name = "durationFor"]
        fn duration_for(self: &MediaTools, source: &QString) -> QString;
    }

    impl cxx_qt::Threading for MediaTools {}
}

use crate::bridge::native::{self, mime, qs, qsl};
use crate::bridge::registry;
use crate::core::{desktop, paths};
use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::{QString, QStringList};
use qobject::MediaTools;
use std::collections::HashMap;
use std::pin::Pin;
use std::sync::OnceLock;

#[derive(Clone, Copy, PartialEq)]
enum Kind {
    Image = 0,
    Video = 1,
    Audio = 2,
    Unknown = 3,
}

const IMAGE_FORMATS: &[&str] = &["png", "jpg", "webp", "avif", "bmp", "tiff", "gif"];

fn kind_for(source: &str) -> Kind {
    if source.is_empty() || !paths::exists(source) {
        return Kind::Unknown;
    }
    let mime = mime::for_file(source);
    if mime.starts_with("image/") {
        Kind::Image
    } else if mime.starts_with("video/") {
        Kind::Video
    } else if mime.starts_with("audio/") {
        Kind::Audio
    } else {
        Kind::Unknown
    }
}

fn audio_codec_args(ext: &str) -> Vec<&'static str> {
    match ext {
        "webm" | "opus" => vec!["-c:a", "libopus", "-b:a", "128k"],
        "ogg" => vec!["-c:a", "libvorbis", "-q:a", "5"],
        "mp3" | "avi" => vec!["-c:a", "libmp3lame", "-q:a", "2"],
        "flac" => vec!["-c:a", "flac"],
        "wav" => vec!["-c:a", "pcm_s16le"],
        _ => vec!["-c:a", "aac", "-b:a", "192k"],
    }
}

fn video_codec_args(ext: &str) -> Vec<&'static str> {
    match ext {
        "webm" => vec!["-c:v", "libvpx-vp9", "-crf", "34", "-b:v", "0"],
        "avi" => vec!["-c:v", "mpeg4", "-q:v", "4"],
        _ => vec!["-c:v", "libx264", "-crf", "20", "-preset", "veryfast", "-pix_fmt", "yuv420p"],
    }
}

fn ffmpeg() -> String {
    paths::find_executable("ffmpeg").unwrap_or_default()
}

fn image_magick_binary() -> &'static str {
    static CACHED: OnceLock<String> = OnceLock::new();
    CACHED.get_or_init(|| paths::find_executable("magick").or_else(|| paths::find_executable("convert")).unwrap_or_default())
}

fn make_even(v: i32) -> i32 {
    if v % 2 == 0 { v } else { v - 1 }
}

/// `base (tag).ext` next to the source, numbered until it is free.
fn unique_output_path(source: &str, tag: &str, ext: &str) -> String {
    let dir = paths::parent(&paths::clean_path(source));
    let base = paths::complete_base_name(source);
    let mut candidate = if tag.is_empty() { format!("{base}.{ext}") } else { format!("{base} ({tag}).{ext}") };
    let mut counter = 2;
    while paths::exists(&format!("{dir}/{candidate}")) {
        candidate = if tag.is_empty() {
            format!("{base} {counter}.{ext}")
        } else {
            format!("{base} ({tag}) {counter}.{ext}")
        };
        counter += 1;
    }
    format!("{dir}/{candidate}")
}

fn video_dimensions(path: &str) -> Option<(i32, i32)> {
    let ffprobe = paths::find_executable("ffprobe")?;
    if path.is_empty() || !paths::exists(path) {
        return None;
    }
    let (_, out, _) = desktop::run_timeout(
        &ffprobe,
        &["-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height", "-of", "csv=s=x:p=0", path],
        5000,
    )?;
    let first = out.trim().split(',').next()?;
    let (w, h) = first.split_once('x')?;
    let (w, h) = (w.parse::<i32>().ok()?, h.parse::<i32>().ok()?);
    (w > 0 && h > 0).then_some((w, h))
}

fn add_task(success: bool, message: &str) {
    if let Some(ops) = registry::FILE_OPERATIONS.get() {
        ops.push_completed_task(success, message, "");
    }
}

#[derive(Default)]
pub struct MediaToolsRust {
    busy: bool,
    status_text: QString,
    im_handle_cache: HashMap<String, bool>,
}

impl MediaTools {
    fn ffmpeg_available(&self) -> bool {
        paths::find_executable("ffmpeg").is_some()
    }

    fn image_magick_available(&self) -> bool {
        !image_magick_binary().is_empty()
    }

    fn set_busy(mut self: Pin<&mut Self>, busy: bool) {
        if self.busy != busy {
            self.as_mut().rust_mut().busy = busy;
            self.busy_changed();
        }
    }

    fn set_status(mut self: Pin<&mut Self>, text: &str) {
        let text = qs(text);
        if self.status_text != text {
            self.as_mut().rust_mut().status_text = text;
            self.status_text_changed();
        }
    }

    /// Whether ImageMagick can read `source` (svg, pdf, heic, dds, ...),
    /// cached per extension.
    fn image_magick_handles(mut self: Pin<&mut Self>, source: &str) -> bool {
        if source.is_empty() || !paths::is_file(source) {
            return false;
        }
        let suffix = paths::suffix(source).to_lowercase();
        let key = if suffix.is_empty() { paths::clean_path(source) } else { format!(".{suffix}") };
        if let Some(handled) = self.im_handle_cache.get(&key) {
            return *handled;
        }
        let magick = image_magick_binary();
        let handled = if magick.is_empty() {
            false
        } else if magick.ends_with("magick") {
            desktop::run_timeout(magick, &["identify", "-ping", source], 3000).is_some_and(|r| r.0 == 0)
        } else {
            paths::find_executable("identify")
                .and_then(|identify| desktop::run_timeout(&identify, &["-ping", source], 3000))
                .is_some_and(|r| r.0 == 0)
        };
        self.as_mut().rust_mut().im_handle_cache.insert(key, handled);
        handled
    }

    fn run_process(mut self: Pin<&mut Self>, tool: String, description: String, args: Vec<String>, output: String) {
        if self.busy {
            return;
        }
        if tool.is_empty() {
            add_task(false, &format!("{description} failed - required tool not found"));
            return;
        }
        self.as_mut().set_busy(true);
        self.as_mut().set_status(&description);
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let refs: Vec<&str> = args.iter().map(String::as_str).collect();
            let (code, _, _) = desktop::run(&tool, &refs);
            let success = code == 0 && paths::exists(&output);
            let _ = thread.queue(move |mut tools| {
                tools.as_mut().set_busy(false);
                tools.set_status("");
                let message = if success {
                    format!("{description} - saved as {}", paths::file_name(&output))
                } else {
                    format!("{description} failed")
                };
                add_task(success, &message);
            });
        });
    }

    fn ffmpeg_job(self: Pin<&mut Self>, description: String, args: Vec<String>, output: String) {
        self.run_process(ffmpeg(), description, args, output);
    }

    fn clip_video(self: Pin<&mut Self>, source: &QString, start: f64, end: f64) {
        if start < 0.0 || end <= start {
            add_task(false, "Invalid clip range");
            return;
        }
        let source = source.to_string();
        let ext = paths::suffix(&source).to_lowercase();
        let output = unique_output_path(&source, "clipped", &paths::suffix(&source));
        let mut args: Vec<String> = vec![
            "-y".into(),
            "-ss".into(),
            format!("{start:.3}"),
            "-i".into(),
            source.clone(),
            "-t".into(),
            format!("{:.3}", end - start),
        ];
        if kind_for(&source) != Kind::Audio {
            args.extend(video_codec_args(&ext).into_iter().map(String::from));
        }
        args.extend(audio_codec_args(&ext).into_iter().map(String::from));
        args.push(output.clone());
        self.ffmpeg_job(format!("Clipping {}", paths::file_name(&source)), args, output);
    }

    fn convert_media(mut self: Pin<&mut Self>, source: &QString, format: &QString) {
        let source = source.to_string();
        let fmt = format.to_string().to_lowercase();
        let description = format!("Converting {} to {}", paths::file_name(&source), format);
        match kind_for(&source) {
            Kind::Video => {
                let output = unique_output_path(&source, "", &fmt);
                let mut args: Vec<String> = vec!["-y".into(), "-i".into(), source.clone()];
                if fmt == "gif" {
                    args.extend(["-an", "-vf", "fps=12,scale=480:-1:flags=lanczos"].map(String::from));
                } else {
                    args.extend(video_codec_args(&fmt).into_iter().map(String::from));
                    args.extend(audio_codec_args(&fmt).into_iter().map(String::from));
                }
                args.push(output.clone());
                self.ffmpeg_job(description, args, output);
            }
            Kind::Audio => {
                let output = unique_output_path(&source, "", &fmt);
                let mut args: Vec<String> = vec!["-y".into(), "-i".into(), source.clone(), "-vn".into()];
                args.extend(audio_codec_args(&fmt).into_iter().map(String::from));
                args.push(output.clone());
                self.ffmpeg_job(description, args, output);
            }
            _ => {
                // Images and anything else ImageMagick can read.
                if !self.as_mut().image_magick_handles(&source) {
                    add_task(false, "Unsupported file type for conversion");
                    return;
                }
                if image_magick_binary().is_empty() {
                    add_task(false, "ImageMagick not found - install it to convert images");
                    return;
                }
                let output = unique_output_path(&source, "", &fmt);
                let mut args: Vec<String> = vec![source.clone()];
                if fmt == "jpg" || fmt == "jpeg" {
                    // JPEG has no alpha channel: flatten transparency onto white.
                    args.extend(["-background", "white", "-alpha", "remove", "-quality", "92"].map(String::from));
                } else if fmt == "webp" {
                    args.extend(["-quality", "90"].map(String::from));
                }
                args.push(output.clone());
                self.run_process(image_magick_binary().to_string(), description, args, output);
            }
        }
    }

    fn output_ext(source: &str) -> String {
        let ext = paths::suffix(source).to_lowercase();
        if !ext.is_empty() {
            ext
        } else if kind_for(source) == Kind::Image {
            "png".into()
        } else {
            "mp4".into()
        }
    }

    fn rotate_media(self: Pin<&mut Self>, source: &QString, degrees: i32) {
        let filter = match degrees {
            90 => "transpose=1",
            270 | -90 => "transpose=2",
            180 => "transpose=1,transpose=1",
            _ => {
                add_task(false, "Unsupported rotation angle");
                return;
            }
        };
        let source = source.to_string();
        let ext = Self::output_ext(&source);
        let output = unique_output_path(&source, "rotated", &ext);
        let mut args: Vec<String> = vec!["-y".into(), "-i".into(), source.clone(), "-vf".into(), filter.into()];
        if kind_for(&source) != Kind::Image {
            args.extend(video_codec_args(&ext).into_iter().map(String::from));
            args.push("-an".into());
        }
        args.push(output.clone());
        self.ffmpeg_job(format!("Rotating {}", paths::file_name(&source)), args, output);
    }

    fn flip_media(self: Pin<&mut Self>, source: &QString, horizontal: bool) {
        let source = source.to_string();
        let ext = Self::output_ext(&source);
        let output = unique_output_path(&source, if horizontal { "flipped" } else { "mirrored" }, &ext);
        let mut args: Vec<String> = vec![
            "-y".into(),
            "-i".into(),
            source.clone(),
            "-vf".into(),
            if horizontal { "hflip" } else { "vflip" }.into(),
        ];
        if kind_for(&source) != Kind::Image {
            args.extend(video_codec_args(&ext).into_iter().map(String::from));
            args.extend(audio_codec_args(&ext).into_iter().map(String::from));
        }
        args.push(output.clone());
        let verb = if horizontal { "Flipping" } else { "Mirroring" };
        self.ffmpeg_job(format!("{verb} {}", paths::file_name(&source)), args, output);
    }

    fn circle_crop(self: Pin<&mut Self>, source: &QString) {
        let source = source.to_string();
        let output = unique_output_path(&source, "circle", "png");
        let args: Vec<String> = vec![
            "-y".into(),
            "-i".into(),
            source.clone(),
            "-vf".into(),
            "format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='255*lt(hypot(X-W/2\\,Y-H/2)\\,min(W,H)/2)'".into(),
            output.clone(),
        ];
        self.ffmpeg_job(format!("Circle cropping {}", paths::file_name(&source)), args, output);
    }

    fn set_aspect_ratio(self: Pin<&mut Self>, source: &QString, ratio_w: i32, ratio_h: i32, crop: bool) {
        if ratio_w <= 0 || ratio_h <= 0 {
            add_task(false, "Invalid aspect ratio");
            return;
        }
        let source = source.to_string();
        let is_image = kind_for(&source) == Kind::Image;
        let dims = if is_image {
            native::image_size(&source).or_else(|| video_dimensions(&source))
        } else {
            video_dimensions(&source)
        };
        let Some((iw, ih)) = dims else {
            add_task(false, "Could not determine media dimensions");
            return;
        };
        let (iw, ih) = (iw as f64, ih as f64);
        let ratio = ratio_w as f64 / ratio_h as f64;
        let (w, h) = if iw / ih > ratio {
            (make_even((ih * ratio) as i32), make_even(ih as i32))
        } else {
            (make_even(iw as i32), make_even((iw / ratio) as i32))
        };
        let filter = if crop {
            format!("crop={w}:{h}")
        } else {
            let pad = if is_image { "black@0.0" } else { "black" };
            format!("scale={w}:{h}:force_original_aspect_ratio=decrease,pad={w}:{h}:(ow-iw)/2:(oh-ih)/2:{pad}")
        };
        let mut ext = paths::suffix(&source).to_lowercase();
        if ext.is_empty() || !is_image {
            ext = if is_image { "png".into() } else { "mp4".into() };
        }
        let output = unique_output_path(&source, if crop { "cropped" } else { "padded" }, &ext);
        let mut args: Vec<String> = vec!["-y".into(), "-i".into(), source.clone(), "-vf".into(), filter];
        if !is_image {
            args.extend(video_codec_args(&ext).into_iter().map(String::from));
            args.extend(audio_codec_args(&ext).into_iter().map(String::from));
        }
        args.push(output.clone());
        self.ffmpeg_job(format!("Setting {} to {ratio_w}:{ratio_h}", paths::file_name(&source)), args, output);
    }

    fn kind_for(&self, source: &QString) -> i32 {
        kind_for(&source.to_string()) as i32
    }

    fn formats_for(self: Pin<&mut Self>, source: &QString) -> QStringList {
        let source = source.to_string();
        if source.is_empty() || !paths::exists(&source) {
            return QStringList::default();
        }
        let kind = kind_for(&source);
        // Don't offer targets whose converting backend is missing.
        if matches!(kind, Kind::Video | Kind::Audio) && !self.ffmpeg_available() {
            return QStringList::default();
        }
        if matches!(kind, Kind::Image | Kind::Unknown) && !self.image_magick_available() {
            return QStringList::default();
        }
        match kind {
            Kind::Image => qsl(IMAGE_FORMATS),
            Kind::Video => qsl(&["mp4", "webm", "mkv", "mov", "gif"]),
            Kind::Audio => qsl(&["mp3", "wav", "ogg", "flac", "m4a", "opus"]),
            Kind::Unknown => {
                if self.image_magick_handles(&source) {
                    qsl(IMAGE_FORMATS)
                } else {
                    QStringList::default()
                }
            }
        }
    }

    fn duration_for(&self, source: &QString) -> QString {
        let source = source.to_string();
        let Some(ffprobe) = paths::find_executable("ffprobe") else { return QString::default() };
        if source.is_empty() || !paths::exists(&source) {
            return QString::default();
        }
        let out = desktop::run_timeout(
            &ffprobe,
            &["-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", &source],
            5000,
        )
        .map(|r| r.1)
        .unwrap_or_default();
        let Ok(secs) = out.trim().parse::<f64>() else { return QString::default() };
        if secs <= 0.0 {
            return QString::default();
        }
        let total = secs.round() as i64;
        let (h, m, s) = (total / 3600, (total % 3600) / 60, total % 60);
        qs(&if h > 0 { format!("{h}:{m:02}:{s:02}") } else { format!("{m}:{s:02}") })
    }
}
