//! FileUtils: the QML face of core::fileutils.

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
        include!("cxx-qt-lib/qstringlist.h");
        type QStringList = cxx_qt_lib::QStringList;
        include!("cxx-qt-lib/qurl.h");
        type QUrl = cxx_qt_lib::QUrl;
        include!("cxx-qt-lib/qdatetime.h");
        type QDateTime = cxx_qt_lib::QDateTime;
        include!("cxx-qt-lib/qlist.h");
        type QList_QVariant = cxx_qt_lib::QList<cxx_qt_lib::QVariant>;
    }

    #[qenum(FileUtils)]
    enum DateFormat {
        SystemLocale,
        Iso,
        LongLocale,
        Custom,
    }

    #[qenum(FileUtils)]
    enum FolderCount {
        FolderCountNever,
        FolderCountLocalOnly,
        FolderCountAlways,
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        #[qproperty(QString, home, READ = home, CONSTANT)]
        #[qproperty(QString, pictures, READ = pictures, CONSTANT)]
        #[qproperty(QString, videos, READ = videos, CONSTANT)]
        #[qproperty(QString, documents, READ = documents, CONSTANT)]
        #[qproperty(QString, downloads, READ = downloads, CONSTANT)]
        #[qproperty(QString, music, READ = music, CONSTANT)]
        #[qproperty(QString, desktop, READ = desktop, CONSTANT)]
        type FileUtils = super::FileUtilsRust;

        fn home(self: &FileUtils) -> QString;
        fn pictures(self: &FileUtils) -> QString;
        fn videos(self: &FileUtils) -> QString;
        fn documents(self: &FileUtils) -> QString;
        fn downloads(self: &FileUtils) -> QString;
        fn music(self: &FileUtils) -> QString;
        fn desktop(self: &FileUtils) -> QString;

        #[qinvokable]
        #[cxx_name = "formatSize"]
        fn format_size(self: &FileUtils, bytes: i64) -> QString;
        #[qinvokable]
        #[cxx_name = "formatDateTime"]
        fn format_date_time(self: &FileUtils, dt: &QDateTime, format: i32) -> QString;
        #[qinvokable]
        #[cxx_name = "formatDateTime"]
        fn format_date_time_default(self: &FileUtils, dt: &QDateTime) -> QString;
        #[qinvokable]
        #[cxx_name = "shouldThumbnail"]
        fn should_thumbnail(self: &FileUtils, is_image: bool, is_video: bool, size: i64) -> bool;
        #[qinvokable]
        #[cxx_name = "shortenHome"]
        fn shorten_home(self: &FileUtils, path: &QString) -> QString;
        #[qinvokable]
        #[cxx_name = "toLocalFile"]
        fn to_local_file(self: &FileUtils, url: &QUrl) -> QString;
        #[qinvokable]
        #[cxx_name = "baseName"]
        fn base_name(self: &FileUtils, path: &QString) -> QString;
        #[qinvokable]
        #[cxx_name = "describePaths"]
        fn describe_paths(self: &FileUtils, paths: &QStringList) -> QList_QVariant;
        #[qinvokable]
        #[cxx_name = "freeSpaceFor"]
        fn free_space_for(self: &FileUtils, path: &QString) -> QString;
        #[qinvokable]
        fn templates(self: &FileUtils) -> QList_QVariant;
        #[qinvokable]
        #[cxx_name = "isImage"]
        fn is_image(self: &FileUtils, path: &QString) -> bool;
        #[qinvokable]
        #[cxx_name = "isVideo"]
        fn is_video(self: &FileUtils, path: &QString) -> bool;
        #[qinvokable]
        #[cxx_name = "isAudio"]
        fn is_audio(self: &FileUtils, path: &QString) -> bool;
        #[qinvokable]
        #[cxx_name = "iconForName"]
        fn icon_for_name(self: &FileUtils, name: &QString, fallback: &QString) -> QString;
        #[qinvokable]
        #[cxx_name = "iconForName"]
        fn icon_for_name_default(self: &FileUtils, name: &QString) -> QString;
        #[qinvokable]
        #[cxx_name = "iconForFile"]
        fn icon_for_file(self: &FileUtils, name: &QString, is_dir: bool, mime_type: &QString) -> QString;
        #[qinvokable]
        #[cxx_name = "mimeTypeForFile"]
        fn mime_type_for_file(self: &FileUtils, path: &QString) -> QString;
        #[qinvokable]
        #[cxx_name = "expandPath"]
        fn expand_path(self: &FileUtils, input: &QString, current_dir: &QString) -> QString;
        #[qinvokable]
        #[cxx_name = "expandPath"]
        fn expand_path_default(self: &FileUtils, input: &QString) -> QString;
        #[qinvokable]
        #[cxx_name = "getPathSuggestions"]
        fn get_path_suggestions(self: &FileUtils, input: &QString, current_dir: &QString) -> QList_QVariant;
        #[qinvokable]
        #[cxx_name = "getCompletedPath"]
        fn get_completed_path(self: &FileUtils, input: &QString, current_dir: &QString) -> QString;
        #[qinvokable]
        #[cxx_name = "queryKeyboardModifiers"]
        fn query_keyboard_modifiers(self: &FileUtils) -> i32;
    }
}

use crate::bridge::native::{self, mime, qs, to_qvariant_list};
use crate::core::fileutils::*;
use crate::core::paths;
use cxx_qt_lib::{QDateTime, QList, QString, QStringList, QUrl, QVariant};

#[derive(Default)]
pub struct FileUtilsRust;

impl qobject::FileUtils {
    fn home(&self) -> QString {
        qs(&paths::home())
    }
    fn pictures(&self) -> QString {
        qs(&paths::pictures())
    }
    fn videos(&self) -> QString {
        qs(&paths::videos())
    }
    fn documents(&self) -> QString {
        qs(&paths::documents())
    }
    fn downloads(&self) -> QString {
        qs(&paths::downloads())
    }
    fn music(&self) -> QString {
        qs(&paths::music())
    }
    fn desktop(&self) -> QString {
        qs(&paths::desktop())
    }

    fn format_size(&self, bytes: i64) -> QString {
        qs(&format_size(bytes))
    }
    fn format_date_time(&self, dt: &QDateTime, format: i32) -> QString {
        if !dt.is_valid() {
            return QString::default();
        }
        qs(&format_msecs_with(dt.to_msecs_since_epoch(), format))
    }
    fn format_date_time_default(&self, dt: &QDateTime) -> QString {
        self.format_date_time(dt, -1)
    }
    fn should_thumbnail(&self, is_image: bool, is_video: bool, size: i64) -> bool {
        should_thumbnail(is_image, is_video, size)
    }
    fn shorten_home(&self, path: &QString) -> QString {
        qs(&shorten_home(&path.to_string()))
    }
    fn to_local_file(&self, url: &QUrl) -> QString {
        let text = url.to_string();
        qs(&paths::from_file_url(&text))
    }
    fn base_name(&self, path: &QString) -> QString {
        let path = path.to_string();
        if path.is_empty() {
            return QString::default();
        }
        qs(&paths::file_name(&path))
    }
    fn describe_paths(&self, paths_in: &QStringList) -> QList<QVariant> {
        to_qvariant_list(&describe_paths(&native::from_qsl(paths_in)))
    }
    fn free_space_for(&self, path: &QString) -> QString {
        qs(&free_space_for(&path.to_string()))
    }
    fn templates(&self) -> QList<QVariant> {
        to_qvariant_list(&templates())
    }
    fn is_image(&self, path: &QString) -> bool {
        mime_starts_with(&path.to_string(), "image/")
    }
    fn is_video(&self, path: &QString) -> bool {
        mime_starts_with(&path.to_string(), "video/")
    }
    fn is_audio(&self, path: &QString) -> bool {
        mime_starts_with(&path.to_string(), "audio/")
    }
    fn icon_for_name(&self, name: &QString, fallback: &QString) -> QString {
        qs(&icon_for_name(&name.to_string(), &fallback.to_string()))
    }
    fn icon_for_name_default(&self, name: &QString) -> QString {
        qs(&icon_for_name(&name.to_string(), ""))
    }
    fn icon_for_file(&self, name: &QString, is_dir: bool, mime_type: &QString) -> QString {
        qs(&icon_for_file(&name.to_string(), is_dir, &mime_type.to_string()))
    }
    fn mime_type_for_file(&self, path: &QString) -> QString {
        qs(&mime::for_file(&path.to_string()))
    }
    fn expand_path(&self, input: &QString, current_dir: &QString) -> QString {
        qs(&expand_path(&input.to_string(), &current_dir.to_string()))
    }
    fn expand_path_default(&self, input: &QString) -> QString {
        qs(&expand_path(&input.to_string(), ""))
    }
    fn get_path_suggestions(&self, input: &QString, current_dir: &QString) -> QList<QVariant> {
        to_qvariant_list(&path_suggestions(&input.to_string(), &current_dir.to_string()))
    }
    fn get_completed_path(&self, input: &QString, current_dir: &QString) -> QString {
        qs(&completed_path(&input.to_string(), &current_dir.to_string()))
    }
    fn query_keyboard_modifiers(&self) -> i32 {
        native::ffi::query_keyboard_modifiers()
    }
}

