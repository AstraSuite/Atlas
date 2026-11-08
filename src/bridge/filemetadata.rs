//! FileMetadata: everything the properties dialog and preview panel show
//! about one path. Created per use from QML.

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
        include!("cxx-qt-lib/qdatetime.h");
        type QDateTime = cxx_qt_lib::QDateTime;
        include!("cxx-qt-lib/qlist.h");
        type QList_QVariant = cxx_qt_lib::QList<cxx_qt_lib::QVariant>;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(QString, path, READ, WRITE = set_path, NOTIFY = path_changed)]
        #[qproperty(QString, name, READ, NOTIFY = metadata_changed)]
        #[qproperty(i64, size, READ, NOTIFY = metadata_changed)]
        #[qproperty(QString, formatted_size, cxx_name = "formattedSize", READ, NOTIFY = metadata_changed)]
        #[qproperty(bool, is_dir, cxx_name = "isDir", READ, NOTIFY = metadata_changed)]
        #[qproperty(bool, is_sym_link, cxx_name = "isSymLink", READ, NOTIFY = metadata_changed)]
        #[qproperty(QString, sym_link_target, cxx_name = "symLinkTarget", READ, NOTIFY = metadata_changed)]
        #[qproperty(bool, is_image, cxx_name = "isImage", READ, NOTIFY = metadata_changed)]
        #[qproperty(bool, is_video, cxx_name = "isVideo", READ, NOTIFY = metadata_changed)]
        #[qproperty(bool, is_audio, cxx_name = "isAudio", READ, NOTIFY = metadata_changed)]
        #[qproperty(QString, thumbnail_path, cxx_name = "thumbnailPath", READ, NOTIFY = metadata_changed)]
        #[qproperty(QString, mime_type, cxx_name = "mimeType", READ, NOTIFY = metadata_changed)]
        #[qproperty(QString, mime_description, cxx_name = "mimeDescription", READ, NOTIFY = metadata_changed)]
        #[qproperty(QString, permissions, READ, NOTIFY = metadata_changed)]
        #[qproperty(QString, owner, READ, NOTIFY = metadata_changed)]
        #[qproperty(QString, group, READ, NOTIFY = metadata_changed)]
        #[qproperty(QString, formatted_created, cxx_name = "formattedCreated", READ, NOTIFY = metadata_changed)]
        #[qproperty(QString, formatted_modified, cxx_name = "formattedModified", READ, NOTIFY = metadata_changed)]
        #[qproperty(QString, formatted_accessed, cxx_name = "formattedAccessed", READ, NOTIFY = metadata_changed)]
        #[qproperty(i32, item_count, cxx_name = "itemCount", READ, NOTIFY = metadata_changed)]
        #[qproperty(i32, image_width, cxx_name = "imageWidth", READ, NOTIFY = metadata_changed)]
        #[qproperty(i32, image_height, cxx_name = "imageHeight", READ, NOTIFY = metadata_changed)]
        #[qproperty(QString, image_dimensions, cxx_name = "imageDimensions", READ, NOTIFY = metadata_changed)]
        #[qproperty(QString, md5, READ, NOTIFY = checksums_changed)]
        #[qproperty(QString, sha1, READ, NOTIFY = checksums_changed)]
        #[qproperty(QString, sha256, READ, NOTIFY = checksums_changed)]
        #[qproperty(bool, checksums_loading, cxx_name = "checksumsLoading", READ, NOTIFY = checksums_changed)]
        #[qproperty(i32, octal_permissions, cxx_name = "octalPermissions", READ, NOTIFY = metadata_changed)]
        #[qproperty(QString, audio_title, cxx_name = "audioTitle", READ, NOTIFY = metadata_changed)]
        #[qproperty(QString, audio_artist, cxx_name = "audioArtist", READ, NOTIFY = metadata_changed)]
        #[qproperty(QString, audio_album, cxx_name = "audioAlbum", READ, NOTIFY = metadata_changed)]
        #[qproperty(QString, duration_formatted, cxx_name = "durationFormatted", READ, NOTIFY = metadata_changed)]
        #[qproperty(QDateTime, last_modified, cxx_name = "lastModified", READ = last_modified, NOTIFY = metadata_changed)]
        #[qproperty(i64, last_modified_ms, cxx_name = "lastModifiedMs", READ = last_modified_ms, NOTIFY = metadata_changed)]
        #[qproperty(bool, has_media_details, cxx_name = "hasMediaDetails", READ, NOTIFY = media_details_changed)]
        #[qproperty(QString, video_dimensions, cxx_name = "videoDimensions", READ, NOTIFY = media_details_changed)]
        #[qproperty(QString, video_codec_name, cxx_name = "videoCodecName", READ, NOTIFY = media_details_changed)]
        #[qproperty(QString, audio_codec_name, cxx_name = "audioCodecName", READ, NOTIFY = media_details_changed)]
        #[qproperty(QString, frame_rate, cxx_name = "frameRate", READ, NOTIFY = media_details_changed)]
        #[qproperty(QString, bit_rate, cxx_name = "bitRate", READ, NOTIFY = media_details_changed)]
        #[qproperty(QString, copyright, READ, NOTIFY = media_details_changed)]
        #[qproperty(QList_QVariant, media_details, cxx_name = "mediaDetails", READ = media_details, NOTIFY = media_details_changed)]
        type FileMetadata = super::FileMetadataRust;

        #[qsignal]
        #[cxx_name = "pathChanged"]
        fn path_changed(self: Pin<&mut FileMetadata>);
        #[qsignal]
        #[cxx_name = "metadataChanged"]
        fn metadata_changed(self: Pin<&mut FileMetadata>);
        #[qsignal]
        #[cxx_name = "checksumsChanged"]
        fn checksums_changed(self: Pin<&mut FileMetadata>);
        #[qsignal]
        #[cxx_name = "mediaDetailsChanged"]
        fn media_details_changed(self: Pin<&mut FileMetadata>);

        #[qinvokable]
        #[cxx_name = "setPath"]
        fn set_path(self: Pin<&mut FileMetadata>, path: QString);
        #[cxx_name = "lastModified"]
        fn last_modified(self: &FileMetadata) -> QDateTime;
        #[cxx_name = "lastModifiedMs"]
        fn last_modified_ms(self: &FileMetadata) -> i64;
        #[cxx_name = "mediaDetails"]
        fn media_details(self: &FileMetadata) -> QList_QVariant;

        #[qinvokable]
        fn reload(self: Pin<&mut FileMetadata>);
        #[qinvokable]
        #[cxx_name = "calculateChecksums"]
        fn calculate_checksums(self: Pin<&mut FileMetadata>);
        #[qinvokable]
        #[cxx_name = "applyPermissions"]
        fn apply_permissions(
            self: Pin<&mut FileMetadata>,
            user_read: i32,
            user_write: i32,
            user_exec: i32,
            group_read: i32,
            group_write: i32,
            group_exec: i32,
            other_read: i32,
            other_write: i32,
            other_exec: i32,
            recursive: bool,
        ) -> bool;
        #[qinvokable]
        #[cxx_name = "setComment"]
        fn set_comment(self: Pin<&mut FileMetadata>, comment: &QString) -> bool;
    }

    impl cxx_qt::Threading for FileMetadata {}
}

use crate::bridge::native::{self, mime, qs, to_qvariant_list};
use crate::core::entry::{group_name, owner_name, permission_string, sym_link_target};
use crate::core::{exif, fileutils, paths};
use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::{QDateTime, QList, QString, QTimeZone, QVariant};
use md5::Digest;
use qobject::FileMetadata;
use serde_json::{json, Value};
use std::io::Read;
use std::os::unix::fs::{MetadataExt, PermissionsExt};
use std::pin::Pin;

fn append_row(rows: &mut Vec<Value>, label: &str, value: &str) {
    if !value.trim().is_empty() {
        rows.push(json!({ "label": label, "value": value }));
    }
}

fn format_duration(ms: i64) -> String {
    if ms <= 0 {
        return String::new();
    }
    let total = ms / 1000;
    let (h, m, s) = (total / 3600, (total % 3600) / 60, total % 60);
    if h > 0 { format!("{h}:{m:02}:{s:02}") } else { format!("{m}:{s:02}") }
}

fn format_bit_rate(bps: i64) -> String {
    if bps <= 0 {
        String::new()
    } else if bps >= 1_000_000 {
        format!("{:.1} Mbps", bps as f64 / 1_000_000.0)
    } else if bps >= 1000 {
        format!("{:.0} kbps", bps as f64 / 1000.0)
    } else {
        format!("{bps} bps")
    }
}

fn format_frame_rate(fps: f64) -> String {
    if fps <= 0.0 {
        String::new()
    } else if fps.fract() == 0.0 {
        format!("{} fps", fps as i64)
    } else {
        format!("{fps:.2} fps")
    }
}

/// FreeDesktop thumbnail cache entry for a file, if one exists.
fn find_thumbnail(path: &str) -> String {
    if path.is_empty() {
        return String::new();
    }
    let hash = format!("{:x}", md5::Md5::digest(paths::to_file_url(path).as_bytes()));
    let home = paths::home();
    ["x-large", "large", "normal"]
        .iter()
        .map(|size| format!("{home}/.cache/thumbnails/{size}/{hash}.png"))
        .find(|p| paths::exists(p))
        .unwrap_or_default()
}

/// Friendly names for the codecs ffprobe reports, matching what QtMultimedia showed.
fn codec_display_name(codec: &str) -> String {
    match codec {
        "h264" => "H.264",
        "hevc" => "H.265",
        "av1" => "AV1",
        "vp8" => "VP8",
        "vp9" => "VP9",
        "mpeg4" => "MPEG-4 Video",
        "mpeg2video" => "MPEG-2 Video",
        "mpeg1video" => "MPEG-1 Video",
        "mjpeg" => "Motion JPEG",
        "theora" => "Theora",
        "wmv3" => "Windows Media Video",
        "aac" => "AAC",
        "mp3" => "MP3",
        "opus" => "Opus",
        "vorbis" => "Vorbis",
        "flac" => "FLAC",
        "alac" => "ALAC",
        "ac3" => "AC-3",
        "eac3" => "E-AC-3",
        "wmav2" => "Windows Media Audio",
        c if c.starts_with("pcm_") => "Linear PCM",
        c => return c.to_uppercase(),
    }
    .to_string()
}

#[derive(Default)]
struct MediaInfo {
    rows: Vec<Value>,
    video_dimensions: String,
    video_codec: String,
    audio_codec: String,
    frame_rate: String,
    bit_rate: String,
    copyright: String,
    duration: String,
    title: String,
    artist: String,
    album: String,
}

/// Container and stream details from ffprobe.
fn probe_media(path: &str) -> Option<MediaInfo> {
    let ffprobe = paths::find_executable("ffprobe")?;
    let (code, out, _) = crate::core::desktop::run_timeout(
        &ffprobe,
        &["-v", "error", "-print_format", "json", "-show_format", "-show_streams", path],
        10000,
    )?;
    if code != 0 {
        return None;
    }
    let doc: Value = serde_json::from_str(&out).ok()?;
    let format = doc.get("format").cloned().unwrap_or(Value::Null);
    let streams = doc.get("streams").and_then(Value::as_array).cloned().unwrap_or_default();
    let stream = |kind: &str| streams.iter().find(|s| s["codec_type"] == kind).cloned();
    let video = stream("video").filter(|s| s["disposition"]["attached_pic"] != 1);
    let audio = stream("audio");
    let tag = |key: &str| -> String {
        let find = |tags: &Value| {
            tags.as_object().and_then(|t| t.iter().find(|(k, _)| k.eq_ignore_ascii_case(key))).and_then(|(_, v)| v.as_str().map(String::from))
        };
        find(&format["tags"])
            .or_else(|| audio.as_ref().and_then(|a| find(&a["tags"])))
            .or_else(|| video.as_ref().and_then(|v| find(&v["tags"])))
            .unwrap_or_default()
    };
    let num = |v: &Value| v.as_str().and_then(|s| s.parse::<f64>().ok()).or_else(|| v.as_f64());

    let mut info = MediaInfo::default();
    if let Some(v) = &video {
        if let (Some(w), Some(h)) = (v["width"].as_i64(), v["height"].as_i64()) {
            info.video_dimensions = format!("{w} × {h}");
        }
        info.video_codec = v["codec_name"].as_str().map(codec_display_name).unwrap_or_default();
        if let Some((n, d)) = v["avg_frame_rate"].as_str().and_then(|r| r.split_once('/')) {
            let (n, d) = (n.parse::<f64>().unwrap_or(0.0), d.parse::<f64>().unwrap_or(0.0));
            if d > 0.0 {
                info.frame_rate = format_frame_rate(n / d);
            }
        }
    }
    if let Some(a) = &audio {
        info.audio_codec = a["codec_name"].as_str().map(codec_display_name).unwrap_or_default();
    }
    let video_rate = video.as_ref().and_then(|v| num(&v["bit_rate"])).unwrap_or(0.0) as i64;
    let audio_rate = audio.as_ref().and_then(|a| num(&a["bit_rate"])).or_else(|| num(&format["bit_rate"])).unwrap_or(0.0) as i64;
    info.bit_rate = format_bit_rate(if video_rate > 0 { video_rate } else { audio_rate });
    info.duration = format_duration((num(&format["duration"]).unwrap_or(0.0) * 1000.0) as i64);
    info.copyright = tag("copyright");
    info.title = tag("title");
    info.album = tag("album");
    for key in ["album_artist", "artist", "performer"] {
        let artist = tag(key);
        if !artist.is_empty() {
            info.artist = artist;
            break;
        }
    }

    let rows = &mut info.rows;
    append_row(rows, "Title", &info.title);
    append_row(rows, "Artist", &info.artist);
    append_row(rows, "Album", &info.album);
    append_row(rows, "Track", &tag("track"));
    append_row(rows, "Genre", &tag("genre"));
    append_row(rows, "Resolution", &info.video_dimensions);
    append_row(rows, "Duration", &info.duration);
    append_row(rows, "Container", format["format_long_name"].as_str().unwrap_or(""));
    append_row(rows, "Video Codec", &info.video_codec);
    append_row(rows, "Frame Rate", &info.frame_rate);
    if video_rate > 0 {
        append_row(rows, "Video Bit Rate", &format_bit_rate(video_rate));
    }
    append_row(rows, "Audio Codec", &info.audio_codec);
    if audio_rate > 0 {
        append_row(rows, "Audio Bit Rate", &format_bit_rate(audio_rate));
    }
    let recorded = tag("creation_time");
    let recorded = if recorded.is_empty() { tag("date") } else { recorded };
    if let Ok(dt) = chrono::DateTime::parse_from_rfc3339(&recorded) {
        append_row(rows, "Recorded", &fileutils::format_msecs(dt.timestamp_millis()));
    }
    let comment = tag("comment");
    append_row(rows, "Comment", &if comment.is_empty() { tag("description") } else { comment });
    append_row(rows, "Copyright", &info.copyright);
    Some(info)
}

#[derive(Default)]
pub struct FileMetadataRust {
    path: QString,
    name: QString,
    size: i64,
    formatted_size: QString,
    is_dir: bool,
    is_sym_link: bool,
    sym_link_target: QString,
    is_image: bool,
    is_video: bool,
    is_audio: bool,
    thumbnail_path: QString,
    mime_type: QString,
    mime_description: QString,
    permissions: QString,
    owner: QString,
    group: QString,
    formatted_created: QString,
    formatted_modified: QString,
    formatted_accessed: QString,
    item_count: i32,
    image_width: i32,
    image_height: i32,
    image_dimensions: QString,
    md5: QString,
    sha1: QString,
    sha256: QString,
    checksums_loading: bool,
    octal_permissions: i32,
    audio_title: QString,
    audio_artist: QString,
    audio_album: QString,
    duration_formatted: QString,
    last_modified_msecs: Option<i64>,
    has_media_details: bool,
    video_dimensions: QString,
    video_codec_name: QString,
    audio_codec_name: QString,
    frame_rate: QString,
    bit_rate: QString,
    copyright: QString,
    media_rows: Vec<Value>,
    /// Bumped per reload so a slow media probe for an old path is dropped.
    probe_id: u64,
}

impl FileMetadata {
    fn set_path(mut self: Pin<&mut Self>, path: QString) {
        if self.path != path {
            self.as_mut().rust_mut().path = path;
            self.as_mut().path_changed();
            self.reload();
        }
    }

    fn last_modified(&self) -> QDateTime {
        match self.last_modified_msecs {
            Some(ms) => QDateTime::from_msecs_since_epoch(ms, &QTimeZone::utc()),
            None => QDateTime::default(),
        }
    }

    fn last_modified_ms(&self) -> i64 {
        self.last_modified_msecs.unwrap_or(0)
    }

    fn media_details(&self) -> QList<QVariant> {
        to_qvariant_list(&self.media_rows)
    }

    fn reset_media_details(mut self: Pin<&mut Self>) {
        let mut r = self.as_mut().rust_mut();
        r.has_media_details = false;
        r.video_dimensions = QString::default();
        r.video_codec_name = QString::default();
        r.audio_codec_name = QString::default();
        r.frame_rate = QString::default();
        r.bit_rate = QString::default();
        r.copyright = QString::default();
        r.duration_formatted = QString::default();
        r.audio_title = QString::default();
        r.audio_artist = QString::default();
        r.audio_album = QString::default();
        r.media_rows.clear();
        r.probe_id += 1;
    }

    fn reload(mut self: Pin<&mut Self>) {
        let path = self.path.to_string();
        self.as_mut().reset_media_details();
        let link_meta = if path.is_empty() { None } else { std::fs::symlink_metadata(&path).ok() };
        let Some(link_meta) = link_meta else {
            let probe_id = self.probe_id;
            let checksums = (self.md5.clone(), self.sha1.clone(), self.sha256.clone(), self.checksums_loading);
            *self.as_mut().rust_mut() = FileMetadataRust { path: qs(&path), probe_id, ..Default::default() };
            let mut r = self.as_mut().rust_mut();
            (r.md5, r.sha1, r.sha256, r.checksums_loading) = checksums;
            r.octal_permissions = 0o755;
            self.as_mut().metadata_changed();
            self.media_details_changed();
            return;
        };
        let is_sym_link = link_meta.file_type().is_symlink();
        let meta = if is_sym_link { std::fs::metadata(&path).unwrap_or(link_meta) } else { link_meta };
        let mime_type = mime::for_file(&path);
        let is_image = mime_type.starts_with("image/");
        let is_video = mime_type.starts_with("video/");
        let is_audio = mime_type.starts_with("audio/");
        let modified = fileutils::system_time_msecs(meta.modified());
        {
            let mut r = self.as_mut().rust_mut();
            let name = paths::file_name(&path);
            r.name = qs(if name.is_empty() { &path } else { &name });
            r.is_dir = meta.is_dir();
            r.is_sym_link = is_sym_link;
            r.sym_link_target = qs(&if is_sym_link { sym_link_target(&path) } else { String::new() });
            if r.is_dir {
                r.item_count = std::fs::read_dir(&path).map(|e| e.count() as i32).unwrap_or(0);
                r.size = 0;
                r.formatted_size = QString::default();
            } else {
                r.item_count = 0;
                r.size = meta.len() as i64;
                r.formatted_size = qs(&fileutils::format_size(r.size));
            }
            r.mime_description = qs(&mime::comment(&mime_type));
            r.mime_type = qs(&mime_type);
            r.is_image = is_image;
            r.is_video = is_video;
            r.is_audio = is_audio;
            let cached = find_thumbnail(&path);
            r.thumbnail_path = qs(&if !cached.is_empty() {
                cached
            } else if is_image {
                path.clone()
            } else {
                String::new()
            });
            r.permissions = qs(&permission_string(meta.mode()));
            r.octal_permissions = (meta.mode() & 0o777) as i32;
            r.owner = qs(&owner_name(meta.uid()));
            r.group = qs(&group_name(meta.gid()));
            r.formatted_created = qs(&fileutils::format_system_time(meta.created()));
            r.formatted_modified = qs(&fileutils::format_system_time(meta.modified()));
            r.formatted_accessed = qs(&fileutils::format_system_time(meta.accessed()));
            r.last_modified_msecs = modified;
            r.image_width = 0;
            r.image_height = 0;
            r.image_dimensions = QString::default();
        }
        if is_image {
            if let Some((w, h)) = native::image_size(&path) {
                let mut r = self.as_mut().rust_mut();
                r.image_width = w;
                r.image_height = h;
                r.image_dimensions = qs(&format!("{w} × {h}"));
            }
            let rows = exif::read(&path);
            if !rows.is_empty() {
                let mut r = self.as_mut().rust_mut();
                r.media_rows = rows;
                r.has_media_details = true;
            }
        }
        if is_video || is_audio {
            self.as_mut().probe_media_metadata(path);
        }
        self.as_mut().metadata_changed();
        self.media_details_changed();
    }

    fn probe_media_metadata(self: Pin<&mut Self>, path: String) {
        let probe_id = self.probe_id;
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let Some(info) = probe_media(&path) else { return };
            let _ = thread.queue(move |mut meta| {
                if meta.probe_id != probe_id || meta.path.to_string() != path {
                    return;
                }
                {
                    let mut r = meta.as_mut().rust_mut();
                    r.video_dimensions = qs(&info.video_dimensions);
                    r.duration_formatted = qs(&info.duration);
                    r.video_codec_name = qs(&info.video_codec);
                    r.audio_codec_name = qs(&info.audio_codec);
                    r.frame_rate = qs(&info.frame_rate);
                    r.bit_rate = qs(&info.bit_rate);
                    r.copyright = qs(&info.copyright);
                    r.audio_title = qs(&info.title);
                    r.audio_artist = qs(&info.artist);
                    r.audio_album = qs(&info.album);
                    r.has_media_details = !info.rows.is_empty();
                    r.media_rows = info.rows;
                }
                meta.as_mut().metadata_changed();
                meta.media_details_changed();
            });
        });
    }

    fn calculate_checksums(mut self: Pin<&mut Self>) {
        let path = self.path.to_string();
        if path.is_empty() || self.is_dir || !paths::exists(&path) {
            return;
        }
        self.as_mut().rust_mut().checksums_loading = true;
        self.as_mut().checksums_changed();
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let result = (|| -> std::io::Result<(String, String, String)> {
                let mut file = std::fs::File::open(&path)?;
                let mut md5 = md5::Md5::new();
                let mut sha1 = sha1::Sha1::new();
                let mut sha256 = sha2::Sha256::new();
                let mut buf = vec![0u8; 65536];
                loop {
                    let n = file.read(&mut buf)?;
                    if n == 0 {
                        break;
                    }
                    md5.update(&buf[..n]);
                    sha1.update(&buf[..n]);
                    sha256.update(&buf[..n]);
                }
                Ok((format!("{:x}", md5.finalize()), format!("{:x}", sha1.finalize()), format!("{:x}", sha256.finalize())))
            })();
            let _ = thread.queue(move |mut meta| {
                {
                    let mut r = meta.as_mut().rust_mut();
                    if let Ok((md5, sha1, sha256)) = result {
                        r.md5 = qs(&md5);
                        r.sha1 = qs(&sha1);
                        r.sha256 = qs(&sha256);
                    }
                    r.checksums_loading = false;
                }
                meta.checksums_changed();
            });
        });
    }

    #[allow(clippy::too_many_arguments)]
    fn apply_permissions(
        self: Pin<&mut Self>,
        user_read: i32,
        user_write: i32,
        user_exec: i32,
        group_read: i32,
        group_write: i32,
        group_exec: i32,
        other_read: i32,
        other_write: i32,
        other_exec: i32,
        recursive: bool,
    ) -> bool {
        let path = self.path.to_string();
        if path.is_empty() || !paths::exists(&path) {
            return false;
        }
        let bits = [
            (user_read, 0o400),
            (user_write, 0o200),
            (user_exec, 0o100),
            (group_read, 0o040),
            (group_write, 0o020),
            (group_exec, 0o010),
            (other_read, 0o004),
            (other_write, 0o002),
            (other_exec, 0o001),
        ];
        let mode: u32 = bits.iter().filter(|(on, _)| *on != 0).map(|(_, bit)| bit).sum();
        let set = |p: &str, mode: u32| std::fs::set_permissions(p, std::fs::Permissions::from_mode(mode)).is_ok();
        if !recursive {
            let ok = set(&path, mode);
            self.reload();
            return ok;
        }
        // Folders stay traversable wherever they are readable.
        let traversable = |mode: u32| {
            let mut m = mode;
            for (read, exec) in [(0o400, 0o100), (0o040, 0o010), (0o004, 0o001)] {
                if m & read != 0 {
                    m |= exec;
                }
            }
            m
        };
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            set(&path, traversable(mode));
            let mut pending = vec![path];
            while let Some(dir) = pending.pop() {
                let Ok(entries) = std::fs::read_dir(&dir) else { continue };
                for e in entries.flatten() {
                    let Ok(meta) = e.path().symlink_metadata() else { continue };
                    if meta.file_type().is_symlink() {
                        continue;
                    }
                    let p = e.path().to_string_lossy().into_owned();
                    if meta.is_dir() {
                        set(&p, traversable(mode));
                        pending.push(p);
                    } else {
                        set(&p, mode);
                    }
                }
            }
            let _ = thread.queue(|meta| meta.reload());
        });
        true
    }

    fn set_comment(self: Pin<&mut Self>, comment: &QString) -> bool {
        let path = self.path.to_string();
        if path.is_empty() || !self.is_image {
            return false;
        }
        let ok = exif::write_comment(&path, &comment.to_string());
        if ok {
            self.reload();
        }
        ok
    }
}
