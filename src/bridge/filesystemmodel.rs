//! FileSystemModel: one directory listing (or search results, the trash,
//! or recent files) for a pane, with FileSystemEntry objects as rows.

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!(<QtCore/QAbstractListModel>);
        type QAbstractListModel;

        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
        include!("cxx-qt-lib/qstringlist.h");
        type QStringList = cxx_qt_lib::QStringList;
        include!("cxx-qt-lib/qdatetime.h");
        type QDateTime = cxx_qt_lib::QDateTime;
        include!("cxx-qt-lib/qmodelindex.h");
        type QModelIndex = cxx_qt_lib::QModelIndex;
        include!("cxx-qt-lib/qvariant.h");
        type QVariant = cxx_qt_lib::QVariant;
        include!("cxx-qt-lib/qhash.h");
        type QHash_i32_QByteArray = cxx_qt_lib::QHash<cxx_qt_lib::QHashPair_i32_QByteArray>;
        include!("cxx-qt-lib/qlist.h");
        type QList_i32 = cxx_qt_lib::QList<i32>;

        include!("qobjectfactory.h");
        #[cxx_name = "atlasNewChild"]
        unsafe fn new_entry(parent: *mut FileSystemModel) -> *mut FileSystemEntry;
        #[cxx_name = "atlasDeleteLater"]
        unsafe fn delete_entry(entry: *mut FileSystemEntry);
    }

    #[qenum(FileSystemModel)]
    enum SortField {
        SortByName,
        SortBySize,
        SortByDate,
        SortByType,
        SortByDeleted,
    }

    extern "RustQt" {
        #[qobject]
        #[qproperty(QString, name, cxx_name = "name", READ = get_name, CONSTANT)]
        #[qproperty(QString, path, cxx_name = "path", READ = get_path, CONSTANT)]
        #[qproperty(bool, is_dir, cxx_name = "isDir", READ = get_is_dir, CONSTANT)]
        #[qproperty(bool, is_sym_link, cxx_name = "isSymLink", READ = get_is_sym_link, CONSTANT)]
        #[qproperty(QString, sym_link_target, cxx_name = "symLinkTarget", READ = get_sym_link_target, CONSTANT)]
        #[qproperty(i64, size, cxx_name = "size", READ = get_size, CONSTANT)]
        #[qproperty(QString, formatted_size, cxx_name = "formattedSize", READ = get_formatted_size, CONSTANT)]
        #[qproperty(QString, mime_type, cxx_name = "mimeType", READ = get_mime_type, CONSTANT)]
        #[qproperty(QString, mime_description, cxx_name = "mimeDescription", READ = get_mime_description, CONSTANT)]
        #[qproperty(QDateTime, last_modified, cxx_name = "lastModified", READ = get_last_modified, CONSTANT)]
        #[qproperty(QString, formatted_date, cxx_name = "formattedDate", READ = get_formatted_date, CONSTANT)]
        #[qproperty(QString, permissions, cxx_name = "permissions", READ = get_permissions, CONSTANT)]
        #[qproperty(QString, owner, cxx_name = "owner", READ = get_owner, CONSTANT)]
        #[qproperty(QString, group, cxx_name = "group", READ = get_group, CONSTANT)]
        #[qproperty(QString, suffix, cxx_name = "suffix", READ = get_suffix, CONSTANT)]
        #[qproperty(bool, is_hidden, cxx_name = "isHidden", READ = get_is_hidden, CONSTANT)]
        #[qproperty(bool, is_read_only, cxx_name = "isReadOnly", READ = get_is_read_only, CONSTANT)]
        #[qproperty(bool, is_writable, cxx_name = "isWritable", READ = get_is_writable, CONSTANT)]
        #[qproperty(bool, is_image, cxx_name = "isImage", READ = get_is_image, CONSTANT)]
        #[qproperty(bool, is_audio, cxx_name = "isAudio", READ = get_is_audio, CONSTANT)]
        #[qproperty(bool, is_video, cxx_name = "isVideo", READ = get_is_video, CONSTANT)]
        #[qproperty(bool, has_thumbnail, cxx_name = "hasThumbnail", READ = get_has_thumbnail, CONSTANT)]
        #[qproperty(bool, is_text, cxx_name = "isText", READ = get_is_text, CONSTANT)]
        #[qproperty(QString, original_path, cxx_name = "originalPath", READ = get_original_path, CONSTANT)]
        #[qproperty(QString, deletion_time, cxx_name = "deletionTime", READ = get_deletion_time, CONSTANT)]
        #[qproperty(bool, is_trash_item, cxx_name = "isTrashItem", READ = get_is_trash_item, CONSTANT)]
        #[qproperty(i32, depth, READ, NOTIFY = tree_changed)]
        #[qproperty(bool, expanded, READ, NOTIFY = tree_changed)]
        type FileSystemEntry = super::FileSystemEntryRust;

        #[qsignal]
        #[cxx_name = "treeChanged"]
        fn tree_changed(self: Pin<&mut FileSystemEntry>);

        #[cxx_name = "name"]
        fn get_name(self: &FileSystemEntry) -> QString;
        #[cxx_name = "path"]
        fn get_path(self: &FileSystemEntry) -> QString;
        #[cxx_name = "isDir"]
        fn get_is_dir(self: &FileSystemEntry) -> bool;
        #[cxx_name = "isSymLink"]
        fn get_is_sym_link(self: &FileSystemEntry) -> bool;
        #[cxx_name = "symLinkTarget"]
        fn get_sym_link_target(self: &FileSystemEntry) -> QString;
        #[cxx_name = "size"]
        fn get_size(self: &FileSystemEntry) -> i64;
        #[cxx_name = "formattedSize"]
        fn get_formatted_size(self: &FileSystemEntry) -> QString;
        #[cxx_name = "mimeType"]
        fn get_mime_type(self: &FileSystemEntry) -> QString;
        #[cxx_name = "mimeDescription"]
        fn get_mime_description(self: &FileSystemEntry) -> QString;
        #[cxx_name = "lastModified"]
        fn get_last_modified(self: &FileSystemEntry) -> QDateTime;
        #[cxx_name = "formattedDate"]
        fn get_formatted_date(self: &FileSystemEntry) -> QString;
        #[cxx_name = "permissions"]
        fn get_permissions(self: &FileSystemEntry) -> QString;
        #[cxx_name = "owner"]
        fn get_owner(self: &FileSystemEntry) -> QString;
        #[cxx_name = "group"]
        fn get_group(self: &FileSystemEntry) -> QString;
        #[cxx_name = "suffix"]
        fn get_suffix(self: &FileSystemEntry) -> QString;
        #[cxx_name = "isHidden"]
        fn get_is_hidden(self: &FileSystemEntry) -> bool;
        #[cxx_name = "isReadOnly"]
        fn get_is_read_only(self: &FileSystemEntry) -> bool;
        #[cxx_name = "isWritable"]
        fn get_is_writable(self: &FileSystemEntry) -> bool;
        #[cxx_name = "isImage"]
        fn get_is_image(self: &FileSystemEntry) -> bool;
        #[cxx_name = "isAudio"]
        fn get_is_audio(self: &FileSystemEntry) -> bool;
        #[cxx_name = "isVideo"]
        fn get_is_video(self: &FileSystemEntry) -> bool;
        #[cxx_name = "hasThumbnail"]
        fn get_has_thumbnail(self: &FileSystemEntry) -> bool;
        #[cxx_name = "isText"]
        fn get_is_text(self: &FileSystemEntry) -> bool;
        #[cxx_name = "originalPath"]
        fn get_original_path(self: &FileSystemEntry) -> QString;
        #[cxx_name = "deletionTime"]
        fn get_deletion_time(self: &FileSystemEntry) -> QString;
        #[cxx_name = "isTrashItem"]
        fn get_is_trash_item(self: &FileSystemEntry) -> bool;
    }

    extern "RustQt" {
        #[qobject]
        #[base = QAbstractListModel]
        #[qml_element]
        #[qproperty(QString, path, READ, WRITE = set_path, NOTIFY = path_changed)]
        #[qproperty(QString, filter_text, cxx_name = "filterText", READ, WRITE = set_filter_text, NOTIFY = filter_text_changed)]
        #[qproperty(QString, search_query, cxx_name = "searchQuery", READ, WRITE = set_search_query, NOTIFY = search_query_changed)]
        #[qproperty(bool, is_searching, cxx_name = "isSearching", READ, NOTIFY = is_searching_changed)]
        #[qproperty(bool, is_loading, cxx_name = "isLoading", READ, NOTIFY = is_loading_changed)]
        #[qproperty(QStringList, name_filters, cxx_name = "nameFilters", READ = name_filters, WRITE = set_name_filters, NOTIFY = name_filters_changed)]
        #[qproperty(bool, show_hidden, cxx_name = "showHidden", READ, WRITE = set_show_hidden, NOTIFY = show_hidden_changed)]
        #[qproperty(bool, show_dirs_first, cxx_name = "showDirsFirst", READ, WRITE = set_show_dirs_first, NOTIFY = show_dirs_first_changed)]
        #[qproperty(bool, case_sensitive_sort, cxx_name = "caseSensitiveSort", READ, WRITE = set_case_sensitive_sort, NOTIFY = case_sensitive_sort_changed)]
        #[qproperty(i32, sort_field, cxx_name = "sortField", READ, WRITE = set_sort_field, NOTIFY = sort_field_changed)]
        #[qproperty(i32, sort_order, cxx_name = "sortOrder", READ, WRITE = set_sort_order, NOTIFY = sort_order_changed)]
        #[qproperty(i32, count, READ = count, NOTIFY = count_changed)]
        #[qproperty(QString, directory_size_formatted, cxx_name = "directorySizeFormatted", READ, NOTIFY = directory_size_changed)]
        type FileSystemModel = super::FileSystemModelRust;

        #[qsignal]
        #[cxx_name = "pathChanged"]
        fn path_changed(self: Pin<&mut FileSystemModel>);
        #[qsignal]
        #[cxx_name = "filterTextChanged"]
        fn filter_text_changed(self: Pin<&mut FileSystemModel>);
        #[qsignal]
        #[cxx_name = "searchQueryChanged"]
        fn search_query_changed(self: Pin<&mut FileSystemModel>);
        #[qsignal]
        #[cxx_name = "isSearchingChanged"]
        fn is_searching_changed(self: Pin<&mut FileSystemModel>);
        #[qsignal]
        #[cxx_name = "isLoadingChanged"]
        fn is_loading_changed(self: Pin<&mut FileSystemModel>);
        #[qsignal]
        #[cxx_name = "nameFiltersChanged"]
        fn name_filters_changed(self: Pin<&mut FileSystemModel>);
        #[qsignal]
        #[cxx_name = "showHiddenChanged"]
        fn show_hidden_changed(self: Pin<&mut FileSystemModel>);
        #[qsignal]
        #[cxx_name = "showDirsFirstChanged"]
        fn show_dirs_first_changed(self: Pin<&mut FileSystemModel>);
        #[qsignal]
        #[cxx_name = "caseSensitiveSortChanged"]
        fn case_sensitive_sort_changed(self: Pin<&mut FileSystemModel>);
        #[qsignal]
        #[cxx_name = "sortFieldChanged"]
        fn sort_field_changed(self: Pin<&mut FileSystemModel>);
        #[qsignal]
        #[cxx_name = "sortOrderChanged"]
        fn sort_order_changed(self: Pin<&mut FileSystemModel>);
        #[qsignal]
        #[cxx_name = "countChanged"]
        fn count_changed(self: Pin<&mut FileSystemModel>);
        #[qsignal]
        #[cxx_name = "directorySizeChanged"]
        fn directory_size_changed(self: Pin<&mut FileSystemModel>);
        #[qsignal]
        #[cxx_name = "fileModified"]
        fn file_modified(self: Pin<&mut FileSystemModel>, path: &QString);

        #[cxx_name = "setPath"]
        fn set_path(self: Pin<&mut FileSystemModel>, path: QString);
        #[cxx_name = "setFilterText"]
        fn set_filter_text(self: Pin<&mut FileSystemModel>, text: QString);
        #[cxx_name = "setSearchQuery"]
        fn set_search_query(self: Pin<&mut FileSystemModel>, query: QString);
        #[cxx_name = "nameFilters"]
        fn name_filters(self: &FileSystemModel) -> QStringList;
        #[cxx_name = "setNameFilters"]
        fn set_name_filters(self: Pin<&mut FileSystemModel>, filters: QStringList);
        #[cxx_name = "setShowHidden"]
        fn set_show_hidden(self: Pin<&mut FileSystemModel>, show: bool);
        #[cxx_name = "setShowDirsFirst"]
        fn set_show_dirs_first(self: Pin<&mut FileSystemModel>, dirs_first: bool);
        #[cxx_name = "setCaseSensitiveSort"]
        fn set_case_sensitive_sort(self: Pin<&mut FileSystemModel>, sensitive: bool);
        #[cxx_name = "setSortField"]
        fn set_sort_field(self: Pin<&mut FileSystemModel>, field: i32);
        #[cxx_name = "setSortOrder"]
        fn set_sort_order(self: Pin<&mut FileSystemModel>, order: i32);
        fn count(self: &FileSystemModel) -> i32;

        #[qinvokable]
        fn get(self: &FileSystemModel, index: i32) -> *mut FileSystemEntry;
        #[qinvokable]
        #[cxx_name = "indexOfPath"]
        fn index_of_path(self: &FileSystemModel, path: &QString) -> i32;
        #[qinvokable]
        #[cxx_name = "findFirstIndexByPrefix"]
        fn find_first_index_by_prefix(self: &FileSystemModel, prefix: &QString, start_index: i32) -> i32;
        #[qinvokable]
        #[cxx_name = "findFirstIndexByPrefix"]
        fn find_first_index_by_prefix_default(self: &FileSystemModel, prefix: &QString) -> i32;
        #[qinvokable]
        fn refresh(self: Pin<&mut FileSystemModel>);
        #[qinvokable]
        #[cxx_name = "toggleExpanded"]
        fn toggle_expanded(self: Pin<&mut FileSystemModel>, path: &QString);
        #[qinvokable]
        #[cxx_name = "collapseAll"]
        fn collapse_all(self: Pin<&mut FileSystemModel>);
        #[qinvokable]
        #[cxx_name = "isExpanded"]
        fn is_expanded(self: &FileSystemModel, path: &QString) -> bool;
    }

    unsafe extern "RustQt" {
        #[inherit]
        #[cxx_name = "beginResetModel"]
        fn begin_reset_model(self: Pin<&mut FileSystemModel>);
        #[inherit]
        #[cxx_name = "endResetModel"]
        fn end_reset_model(self: Pin<&mut FileSystemModel>);
        #[inherit]
        #[cxx_name = "beginInsertRows"]
        fn begin_insert_rows(self: Pin<&mut FileSystemModel>, parent: &QModelIndex, first: i32, last: i32);
        #[inherit]
        #[cxx_name = "endInsertRows"]
        fn end_insert_rows(self: Pin<&mut FileSystemModel>);
        #[inherit]
        #[cxx_name = "beginRemoveRows"]
        fn begin_remove_rows(self: Pin<&mut FileSystemModel>, parent: &QModelIndex, first: i32, last: i32);
        #[inherit]
        #[cxx_name = "endRemoveRows"]
        fn end_remove_rows(self: Pin<&mut FileSystemModel>);
        #[inherit]
        #[cxx_name = "beginMoveRows"]
        fn begin_move_rows(
            self: Pin<&mut FileSystemModel>,
            source_parent: &QModelIndex,
            source_first: i32,
            source_last: i32,
            destination_parent: &QModelIndex,
            destination_child: i32,
        ) -> bool;
        #[inherit]
        #[cxx_name = "endMoveRows"]
        fn end_move_rows(self: Pin<&mut FileSystemModel>);
        #[inherit]
        fn index(self: &FileSystemModel, row: i32, column: i32, parent: &QModelIndex) -> QModelIndex;
        #[inherit]
        #[qsignal]
        #[cxx_name = "dataChanged"]
        fn data_changed(self: Pin<&mut FileSystemModel>, top_left: &QModelIndex, bottom_right: &QModelIndex, roles: &QList_i32);

        #[cxx_override]
        fn data(self: &FileSystemModel, index: &QModelIndex, role: i32) -> QVariant;
        #[cxx_override]
        #[cxx_name = "roleNames"]
        fn role_names(self: &FileSystemModel) -> QHash_i32_QByteArray;
        #[cxx_override]
        #[cxx_name = "rowCount"]
        fn row_count(self: &FileSystemModel, parent: &QModelIndex) -> i32;
    }

    impl cxx_qt::Threading for FileSystemModel {}
    impl cxx_qt::Constructor<()> for FileSystemModel {}
}

use crate::bridge::native::{from_qsl, qs, qsl};
use crate::core::entry::{self, natural_cmp, RawEntry};
use crate::core::watcher::Watcher;
use crate::core::{fileutils, recent, trash};
use cxx_qt::casting::Upcast;
use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::{
    QByteArray, QDateTime, QHash, QHashPair_i32_QByteArray, QList, QModelIndex, QObjectMutPtr, QString, QStringList,
    QTimeZone, QVariant,
};
use qobject::{FileSystemEntry, FileSystemModel};
use std::cmp::Ordering;
use std::collections::{HashMap, HashSet};
use std::pin::Pin;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering as AtomicOrdering};
use std::sync::Arc;

#[derive(Default)]
pub struct FileSystemEntryRust {
    raw: RawEntry,
    depth: i32,
    expanded: bool,
}

impl FileSystemEntry {
    fn get_name(&self) -> QString {
        qs(&self.raw.name)
    }
    fn get_path(&self) -> QString {
        qs(&self.raw.path)
    }
    fn get_is_dir(&self) -> bool {
        self.raw.is_dir
    }
    fn get_is_sym_link(&self) -> bool {
        self.raw.is_sym_link
    }
    fn get_sym_link_target(&self) -> QString {
        qs(&self.raw.sym_link_target)
    }
    fn get_size(&self) -> i64 {
        self.raw.size
    }
    fn get_formatted_size(&self) -> QString {
        qs(&self.raw.formatted_size)
    }
    fn get_mime_type(&self) -> QString {
        qs(&self.raw.mime_type)
    }
    fn get_mime_description(&self) -> QString {
        qs(&self.raw.mime_description)
    }
    fn get_last_modified(&self) -> QDateTime {
        QDateTime::from_msecs_since_epoch(self.raw.last_modified, &QTimeZone::utc())
    }
    fn get_formatted_date(&self) -> QString {
        qs(&self.raw.formatted_date)
    }
    fn get_permissions(&self) -> QString {
        qs(&self.raw.permissions)
    }
    fn get_owner(&self) -> QString {
        qs(&self.raw.owner)
    }
    fn get_group(&self) -> QString {
        qs(&self.raw.group)
    }
    fn get_suffix(&self) -> QString {
        qs(&self.raw.suffix)
    }
    fn get_is_hidden(&self) -> bool {
        self.raw.is_hidden
    }
    fn get_is_read_only(&self) -> bool {
        self.raw.is_read_only
    }
    fn get_is_writable(&self) -> bool {
        self.raw.is_writable
    }
    fn get_is_image(&self) -> bool {
        self.raw.is_image
    }
    fn get_is_audio(&self) -> bool {
        self.raw.is_audio
    }
    fn get_is_video(&self) -> bool {
        self.raw.is_video
    }
    fn get_has_thumbnail(&self) -> bool {
        self.raw.has_thumbnail
    }
    fn get_is_text(&self) -> bool {
        self.raw.is_text
    }
    fn get_original_path(&self) -> QString {
        qs(&self.raw.original_path)
    }
    fn get_deletion_time(&self) -> QString {
        qs(&self.raw.deletion_time)
    }
    fn get_is_trash_item(&self) -> bool {
        self.raw.is_trash_item
    }

    fn set_tree_state(mut self: Pin<&mut Self>, depth: i32, expanded: bool) {
        if self.depth == depth && self.expanded == expanded {
            return;
        }
        let mut rust = self.as_mut().rust_mut();
        rust.depth = depth;
        rust.expanded = expanded;
        self.tree_changed();
    }
}

/// Model roles, from Qt::UserRole + 1.
mod role {
    pub const ENTRY: i32 = 0x0101;
    pub const NAME: i32 = 0x0102;
    pub const PATH: i32 = 0x0103;
    pub const IS_DIR: i32 = 0x0104;
    pub const SIZE: i32 = 0x0105;
    pub const SIZE_FORMATTED: i32 = 0x0106;
    pub const MIME_TYPE: i32 = 0x0107;
    pub const MIME_DESCRIPTION: i32 = 0x0108;
    pub const DATE_MODIFIED: i32 = 0x0109;
    pub const DATE_MODIFIED_FORMATTED: i32 = 0x010a;
    pub const PERMISSIONS: i32 = 0x010b;
    pub const OWNER: i32 = 0x010c;
    pub const IS_IMAGE: i32 = 0x010d;
    pub const IS_HIDDEN: i32 = 0x010e;
    pub const DEPTH: i32 = 0x010f;
    pub const EXPANDED: i32 = 0x0110;
    pub const DISPLAY: i32 = 0; // Qt::DisplayRole
}

type EntryPtr = *mut FileSystemEntry;

fn entry<'a>(ptr: EntryPtr) -> &'a FileSystemEntry {
    unsafe { &*ptr }
}

fn entry_mut<'a>(ptr: EntryPtr) -> Pin<&'a mut FileSystemEntry> {
    unsafe { Pin::new_unchecked(&mut *ptr) }
}

pub struct FileSystemModelRust {
    path: QString,
    filter_text: QString,
    search_query: QString,
    is_searching: bool,
    is_loading: bool,
    name_filters: Vec<String>,
    show_hidden: bool,
    show_dirs_first: bool,
    case_sensitive_sort: bool,
    sort_field: i32,
    sort_order: i32,
    directory_size_formatted: QString,

    raw_entries: Vec<EntryPtr>,
    filtered_entries: Vec<EntryPtr>,
    child_entries: Vec<EntryPtr>,
    expanded_paths: HashSet<String>,
    scan_generation: Arc<AtomicU64>,
    size_generation: Arc<AtomicU64>,
    watcher: Option<Watcher>,
}

impl Default for FileSystemModelRust {
    fn default() -> Self {
        Self {
            path: QString::default(),
            filter_text: QString::default(),
            search_query: QString::default(),
            is_searching: false,
            is_loading: false,
            name_filters: Vec::new(),
            show_hidden: false,
            show_dirs_first: true,
            case_sensitive_sort: false,
            sort_field: 0,
            sort_order: 0,
            directory_size_formatted: QString::default(),
            raw_entries: Vec::new(),
            filtered_entries: Vec::new(),
            child_entries: Vec::new(),
            expanded_paths: HashSet::new(),
            scan_generation: Arc::new(AtomicU64::new(0)),
            size_generation: Arc::new(AtomicU64::new(0)),
            watcher: None,
        }
    }
}

impl cxx_qt::Initialize for FileSystemModel {
    fn initialize(mut self: Pin<&mut Self>) {
        // Coalesce bursts of change events (a file being written) into one
        // rescan shortly after they settle.
        let thread = self.qt_thread();
        let pending = Arc::new(AtomicBool::new(false));
        let watcher = Watcher::new(move |_| {
            if pending.swap(true, AtomicOrdering::AcqRel) {
                return;
            }
            let thread = thread.clone();
            let pending = pending.clone();
            std::thread::spawn(move || {
                std::thread::sleep(std::time::Duration::from_millis(120));
                pending.store(false, AtomicOrdering::Release);
                let _ = thread.queue(|model| model.scan_directory(false));
            });
        });
        self.as_mut().rust_mut().watcher = watcher;
    }
}

impl FileSystemModel {
    fn self_ptr(self: Pin<&mut Self>) -> *mut FileSystemModel {
        unsafe { self.get_unchecked_mut() as *mut FileSystemModel }
    }

    fn create_entry(self: Pin<&mut Self>, raw: RawEntry) -> EntryPtr {
        let ptr = unsafe { qobject::new_entry(self.self_ptr()) };
        entry_mut(ptr).rust_mut().raw = raw;
        ptr
    }

    fn delete_entries(entries: Vec<EntryPtr>) {
        for e in entries {
            unsafe { qobject::delete_entry(e) };
        }
    }

    fn set_loading(mut self: Pin<&mut Self>, loading: bool) {
        if self.is_loading != loading {
            self.as_mut().rust_mut().is_loading = loading;
            self.is_loading_changed();
        }
    }

    // ---- Properties ----

    fn set_path(mut self: Pin<&mut Self>, path: QString) {
        let expanded = qs(&fileutils::expand_path(&path.to_string(), ""));
        if self.path != expanded {
            self.as_mut().rust_mut().path = expanded;
            self.as_mut().path_changed();
            self.scan_directory(true);
        }
    }

    fn set_filter_text(mut self: Pin<&mut Self>, text: QString) {
        if self.filter_text != text {
            self.as_mut().rust_mut().filter_text = text;
            self.as_mut().filter_text_changed();
            self.apply_filter_and_sort();
        }
    }

    fn set_search_query(mut self: Pin<&mut Self>, query: QString) {
        if self.search_query == query {
            return;
        }
        self.as_mut().rust_mut().search_query = query;
        self.as_mut().search_query_changed();
        let trimmed = self.search_query.to_string().trim().to_string();
        if trimmed.is_empty() {
            self.as_mut().rust_mut().is_searching = false;
            self.as_mut().is_searching_changed();
            self.scan_directory(false);
        } else {
            self.as_mut().rust_mut().is_searching = true;
            self.as_mut().is_searching_changed();
            let root = self.path.to_string();
            self.perform_search(root, trimmed);
        }
    }

    fn name_filters(&self) -> QStringList {
        qsl(&self.name_filters)
    }

    fn set_name_filters(mut self: Pin<&mut Self>, filters: QStringList) {
        let filters = from_qsl(&filters);
        if self.name_filters != filters {
            self.as_mut().rust_mut().name_filters = filters;
            self.as_mut().name_filters_changed();
            self.apply_filter_and_sort();
        }
    }

    fn set_show_hidden(mut self: Pin<&mut Self>, show: bool) {
        if self.show_hidden != show {
            self.as_mut().rust_mut().show_hidden = show;
            self.as_mut().show_hidden_changed();
            self.apply_filter_and_sort();
        }
    }

    fn set_show_dirs_first(mut self: Pin<&mut Self>, dirs_first: bool) {
        if self.show_dirs_first != dirs_first {
            self.as_mut().rust_mut().show_dirs_first = dirs_first;
            self.as_mut().show_dirs_first_changed();
            self.apply_filter_and_sort();
        }
    }

    fn set_case_sensitive_sort(mut self: Pin<&mut Self>, sensitive: bool) {
        if self.case_sensitive_sort != sensitive {
            self.as_mut().rust_mut().case_sensitive_sort = sensitive;
            self.as_mut().case_sensitive_sort_changed();
            self.apply_filter_and_sort();
        }
    }

    fn set_sort_field(mut self: Pin<&mut Self>, field: i32) {
        if self.sort_field != field {
            self.as_mut().rust_mut().sort_field = field;
            self.as_mut().sort_field_changed();
            self.apply_filter_and_sort();
        }
    }

    fn set_sort_order(mut self: Pin<&mut Self>, order: i32) {
        if self.sort_order != order {
            self.as_mut().rust_mut().sort_order = order;
            self.as_mut().sort_order_changed();
            self.apply_filter_and_sort();
        }
    }

    fn count(&self) -> i32 {
        self.filtered_entries.len() as i32
    }

    // ---- Invokables ----

    fn get(&self, index: i32) -> *mut FileSystemEntry {
        usize::try_from(index)
            .ok()
            .and_then(|i| self.filtered_entries.get(i).copied())
            .unwrap_or(std::ptr::null_mut())
    }

    fn index_of(&self, path: &str) -> i32 {
        self.filtered_entries.iter().position(|e| entry(*e).raw.path == path).map(|i| i as i32).unwrap_or(-1)
    }

    fn index_of_path(&self, path: &QString) -> i32 {
        self.index_of(&path.to_string())
    }

    fn find_first_index_by_prefix(&self, prefix: &QString, start_index: i32) -> i32 {
        let prefix = prefix.to_string().to_lowercase();
        let size = self.filtered_entries.len();
        if prefix.is_empty() || size == 0 {
            return -1;
        }
        let start = usize::try_from(start_index).ok().filter(|s| *s < size).unwrap_or(0);
        (start..size)
            .chain(0..start)
            .find(|i| entry(self.filtered_entries[*i]).raw.name.to_lowercase().starts_with(&prefix))
            .map(|i| i as i32)
            .unwrap_or(-1)
    }

    fn find_first_index_by_prefix_default(&self, prefix: &QString) -> i32 {
        self.find_first_index_by_prefix(prefix, 0)
    }

    fn refresh(self: Pin<&mut Self>) {
        self.scan_directory(false);
    }

    fn toggle_expanded(mut self: Pin<&mut Self>, path: &QString) {
        let path = path.to_string();
        if path.is_empty() {
            return;
        }
        {
            let mut rust = self.as_mut().rust_mut();
            if rust.expanded_paths.contains(&path) {
                let prefix = format!("{path}/");
                rust.expanded_paths.retain(|open| *open != path && !open.starts_with(&prefix));
            } else {
                rust.expanded_paths.insert(path);
            }
        }
        self.apply_filter_and_sort();
    }

    fn collapse_all(mut self: Pin<&mut Self>) {
        if self.expanded_paths.is_empty() {
            return;
        }
        self.as_mut().rust_mut().expanded_paths.clear();
        self.apply_filter_and_sort();
    }

    fn is_expanded(&self, path: &QString) -> bool {
        self.expanded_paths.contains(&path.to_string())
    }

    // ---- Scanning ----

    fn reset_rows(mut self: Pin<&mut Self>, raw: Vec<RawEntry>) {
        self.as_mut().begin_reset_model();
        let old = std::mem::take(&mut self.as_mut().rust_mut().raw_entries);
        Self::delete_entries(old);
        let created: Vec<EntryPtr> = raw.into_iter().map(|d| self.as_mut().create_entry(d)).collect();
        self.as_mut().rust_mut().raw_entries = created.clone();
        let filtered = self.as_mut().calculate_filtered_and_sorted(&created);
        self.as_mut().rust_mut().filtered_entries = filtered;
        self.as_mut().end_reset_model();
        self.count_changed();
    }

    fn scan_directory(mut self: Pin<&mut Self>, is_path_reset: bool) {
        let generation = self.scan_generation.fetch_add(1, AtomicOrdering::Relaxed) + 1;
        if let Some(watcher) = &self.watcher {
            watcher.clear();
        }
        let path = self.path.to_string();
        let is_recent = recent::is_recent_path(&path);
        if path.is_empty() || (!is_recent && !std::path::Path::new(&path).is_dir()) {
            self.as_mut().set_loading(false);
            self.as_mut().start_directory_size_scan(String::new());
            self.reset_rows(Vec::new());
            return;
        }

        let is_trash = trash::is_trash_root(&path);
        if let Some(watcher) = &self.watcher {
            if is_trash {
                for location in trash::all() {
                    if std::path::Path::new(&location.files_dir).is_dir() {
                        watcher.add_path(&location.files_dir);
                    }
                }
            } else if !is_recent {
                watcher.add_path(&path);
            }
        }
        self.as_mut().start_directory_size_scan(path.clone());
        if is_path_reset {
            self.as_mut().set_loading(true);
        }

        let token = self.scan_generation.clone();
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let list: Vec<String> = if is_recent {
                recent::paths(200)
            } else if is_trash {
                trash::all().iter().flat_map(|l| entry::list_dir(&l.files_dir, true)).collect()
            } else {
                entry::list_dir(&path, true)
            };
            let mut raw = Vec::with_capacity(list.len());
            for p in &list {
                if token.load(AtomicOrdering::Relaxed) != generation {
                    return;
                }
                if let Some(d) = RawEntry::from_path(p) {
                    raw.push(d);
                }
            }
            let _ = thread.queue(move |mut model| {
                if model.scan_generation.load(AtomicOrdering::Relaxed) != generation {
                    return;
                }
                model.as_mut().set_loading(false);
                if is_path_reset || model.raw_entries.is_empty() {
                    model.reset_rows(raw);
                } else {
                    model.update_directory_granular(raw);
                }
            });
        });
    }

    fn start_directory_size_scan(mut self: Pin<&mut Self>, path: String) {
        let generation = self.size_generation.fetch_add(1, AtomicOrdering::Relaxed) + 1;
        if path.is_empty() || path.contains("://") || recent::is_recent_path(&path) || trash::is_trash_root(&path) {
            if !self.directory_size_formatted.is_empty() {
                self.as_mut().rust_mut().directory_size_formatted = QString::default();
                self.directory_size_changed();
            }
            return;
        }
        let token = self.size_generation.clone();
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let mut total: i64 = 0;
            let mut pending = vec![path];
            while let Some(dir) = pending.pop() {
                if token.load(AtomicOrdering::Relaxed) != generation {
                    return;
                }
                let Ok(entries) = std::fs::read_dir(&dir) else { continue };
                for e in entries.flatten() {
                    let Ok(meta) = e.path().symlink_metadata() else { continue };
                    if meta.file_type().is_symlink() {
                        continue;
                    }
                    total += meta.len() as i64;
                    if meta.is_dir() {
                        pending.push(e.path().to_string_lossy().into_owned());
                    }
                }
            }
            let formatted = fileutils::format_size(total);
            let _ = thread.queue(move |mut model| {
                if model.size_generation.load(AtomicOrdering::Relaxed) != generation {
                    return;
                }
                let formatted = qs(&formatted);
                if model.directory_size_formatted != formatted {
                    model.as_mut().rust_mut().directory_size_formatted = formatted;
                    model.directory_size_changed();
                }
            });
        });
    }

    fn update_directory_granular(mut self: Pin<&mut Self>, raw: Vec<RawEntry>) {
        if !self.expanded_paths.is_empty() {
            self.reset_rows(raw);
            return;
        }

        let mut modified: Vec<String> = Vec::new();
        let existing: HashMap<String, EntryPtr> =
            self.raw_entries.iter().map(|e| (entry(*e).raw.path.clone(), *e)).collect();
        let incoming: HashSet<String> = raw.iter().map(|d| d.path.clone()).collect();

        // Update existing entries or add new ones.
        for d in raw {
            match existing.get(&d.path) {
                Some(e) => {
                    if entry(*e).raw != d {
                        modified.push(d.path.clone());
                        entry_mut(*e).rust_mut().raw = d;
                    }
                }
                None => {
                    modified.push(d.path.clone());
                    let created = self.as_mut().create_entry(d);
                    self.as_mut().rust_mut().raw_entries.push(created);
                }
            }
        }

        // Drop entries that are gone.
        let (keep, gone): (Vec<EntryPtr>, Vec<EntryPtr>) =
            self.raw_entries.iter().partition(|e| incoming.contains(&entry(**e).raw.path));
        self.as_mut().rust_mut().raw_entries = keep.clone();

        let target = self.as_mut().calculate_filtered_and_sorted(&keep);
        let target_set: HashSet<EntryPtr> = target.iter().copied().collect();
        let root = QModelIndex::default();

        // Remove rows no longer present.
        for i in (0..self.filtered_entries.len()).rev() {
            if !target_set.contains(&self.filtered_entries[i]) {
                self.as_mut().begin_remove_rows(&root, i as i32, i as i32);
                self.as_mut().rust_mut().filtered_entries.remove(i);
                self.as_mut().end_remove_rows();
            }
        }
        Self::delete_entries(gone);

        // Insert new rows.
        for (i, t) in target.iter().enumerate() {
            if !self.filtered_entries.contains(t) {
                let pos = i.min(self.filtered_entries.len());
                self.as_mut().begin_insert_rows(&root, pos as i32, pos as i32);
                self.as_mut().rust_mut().filtered_entries.insert(pos, *t);
                self.as_mut().end_insert_rows();
            }
        }

        // Move misplaced rows into sorted order.
        for (i, t) in target.iter().enumerate() {
            let Some(current) = self.filtered_entries.iter().position(|e| e == t) else { continue };
            if current != i {
                let dest = if i > current { i + 1 } else { i };
                if self.as_mut().begin_move_rows(&root, current as i32, current as i32, &root, dest as i32) {
                    let moved = self.as_mut().rust_mut().filtered_entries.remove(current);
                    self.as_mut().rust_mut().filtered_entries.insert(i, moved);
                    self.as_mut().end_move_rows();
                    let p = entry(*t).raw.path.clone();
                    if !modified.contains(&p) {
                        modified.push(p);
                    }
                }
            }
        }

        let no_roles = QList::<i32>::default();
        for path in modified {
            let idx = self.index_of(&path);
            if idx >= 0 {
                let mi = self.index(idx, 0, &root);
                self.as_mut().data_changed(&mi, &mi, &no_roles);
                self.as_mut().file_modified(&qs(&path));
            }
        }
        self.count_changed();
    }

    fn perform_search(self: Pin<&mut Self>, root: String, query: String) {
        let show_hidden = self.show_hidden;
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            const MAX_RESULTS: usize = 500;
            let lower = query.to_lowercase();
            let mut found: Vec<RawEntry> = Vec::new();
            // Walk by hand so hidden directories are pruned when hidden
            // files are not shown, and directory symlinks (which can form
            // cycles, e.g. Wine prefixes) are never followed.
            let mut pending = vec![root];
            while let Some(dir) = pending.pop() {
                if found.len() >= MAX_RESULTS {
                    break;
                }
                for p in entry::list_dir(&dir, show_hidden) {
                    if found.len() >= MAX_RESULTS {
                        break;
                    }
                    let name = crate::core::paths::file_name(&p);
                    if name.to_lowercase().contains(&lower) {
                        if let Some(d) = RawEntry::from_path(&p) {
                            found.push(d);
                        }
                    }
                    if std::fs::symlink_metadata(&p).is_ok_and(|m| m.is_dir()) {
                        pending.push(p);
                    }
                }
            }
            let _ = thread.queue(move |model| {
                if model.search_query.to_string().trim() != query {
                    return;
                }
                model.reset_rows(found);
            });
        });
    }

    // ---- Filtering, sorting and the folder tree ----

    fn filter_and_sort_only(&self, source: &[EntryPtr]) -> Vec<EntryPtr> {
        let filter = self.filter_text.to_string().to_lowercase();
        let filters_active = !self.name_filters.is_empty() && !self.name_filters.iter().any(|f| f == "*");
        let mut result: Vec<EntryPtr> = source
            .iter()
            .copied()
            .filter(|e| {
                let d = &entry(*e).raw;
                if !self.show_hidden && d.is_hidden {
                    return false;
                }
                if !filter.is_empty() && !d.name.to_lowercase().contains(&filter) {
                    return false;
                }
                if filters_active && !d.is_dir {
                    let suffix = d.suffix.to_lowercase();
                    return self.name_filters.iter().any(|f| f == "*" || f == "*.*" || f.to_lowercase() == suffix);
                }
                true
            })
            .collect();

        if recent::is_recent_path(&self.path.to_string()) {
            return result;
        }

        let case_sensitive = self.case_sensitive_sort;
        let text = |a: &str, b: &str| if case_sensitive { a.cmp(b) } else { natural_cmp(a, b) };
        let dirs_first = self.show_dirs_first;
        let field = self.sort_field;
        let ascending = self.sort_order == 0;
        result.sort_by(|a, b| {
            let (a, b) = (&entry(*a).raw, &entry(*b).raw);
            if dirs_first && a.is_dir != b.is_dir {
                return if a.is_dir { Ordering::Less } else { Ordering::Greater };
            }
            let res = match field {
                1 => a.size.cmp(&b.size).then_with(|| text(&a.name, &b.name)),
                2 => a.last_modified.cmp(&b.last_modified).then_with(|| text(&a.name, &b.name)),
                3 => text(&a.mime_description, &b.mime_description).then_with(|| text(&a.name, &b.name)),
                4 => a.deletion_date.cmp(&b.deletion_date).then_with(|| natural_cmp(&a.name, &b.name)),
                _ => text(&a.name, &b.name),
            };
            if ascending { res } else { res.reverse() }
        });
        result
    }

    fn calculate_filtered_and_sorted(mut self: Pin<&mut Self>, source: &[EntryPtr]) -> Vec<EntryPtr> {
        let old_children = std::mem::take(&mut self.as_mut().rust_mut().child_entries);
        Self::delete_entries(old_children);
        let result = self.filter_and_sort_only(source);
        if self.expanded_paths.is_empty() {
            return result;
        }
        let mut out = Vec::with_capacity(result.len());
        for e in result {
            self.as_mut().append_with_children(e, 0, &mut out);
        }
        out
    }

    fn children_of(mut self: Pin<&mut Self>, path: &str) -> Vec<EntryPtr> {
        if !std::path::Path::new(path).is_dir() {
            return Vec::new();
        }
        let show_hidden = self.show_hidden;
        let mut children = Vec::new();
        for p in entry::list_dir(path, show_hidden) {
            if let Some(d) = RawEntry::from_path(&p) {
                let created = self.as_mut().create_entry(d);
                self.as_mut().rust_mut().child_entries.push(created);
                children.push(created);
            }
        }
        self.filter_and_sort_only(&children)
    }

    fn append_with_children(mut self: Pin<&mut Self>, e: EntryPtr, depth: i32, out: &mut Vec<EntryPtr>) {
        let d = &entry(e).raw;
        let open = d.is_dir && self.expanded_paths.contains(&d.path);
        let path = d.path.clone();
        entry_mut(e).set_tree_state(depth, open);
        out.push(e);
        if !open {
            return;
        }
        for child in self.as_mut().children_of(&path) {
            self.as_mut().append_with_children(child, depth + 1, out);
        }
    }

    fn apply_filter_and_sort(mut self: Pin<&mut Self>) {
        self.as_mut().begin_reset_model();
        let raw = self.raw_entries.clone();
        let filtered = self.as_mut().calculate_filtered_and_sorted(&raw);
        self.as_mut().rust_mut().filtered_entries = filtered;
        self.as_mut().end_reset_model();
        self.count_changed();
    }

    // ---- QAbstractListModel ----

    fn row_count(&self, parent: &QModelIndex) -> i32 {
        if parent.is_valid() { 0 } else { self.filtered_entries.len() as i32 }
    }

    fn data(&self, index: &QModelIndex, role: i32) -> QVariant {
        let row = index.row();
        if !index.is_valid() || row < 0 || row as usize >= self.filtered_entries.len() {
            return QVariant::default();
        }
        let ptr = self.filtered_entries[row as usize];
        let e = entry(ptr);
        let d = &e.raw;
        match role {
            role::ENTRY => {
                let object = unsafe { <FileSystemEntry as Upcast<cxx_qt::QObject>>::upcast_ptr(ptr) } as *mut cxx_qt::QObject;
                QVariant::from(&unsafe { QObjectMutPtr::from_raw(object) })
            }
            role::NAME | role::DISPLAY => QVariant::from(&qs(&d.name)),
            role::PATH => QVariant::from(&qs(&d.path)),
            role::IS_DIR => QVariant::from(&d.is_dir),
            role::SIZE => QVariant::from(&d.size),
            role::SIZE_FORMATTED => QVariant::from(&qs(&d.formatted_size)),
            role::MIME_TYPE => QVariant::from(&qs(&d.mime_type)),
            role::MIME_DESCRIPTION => QVariant::from(&qs(&d.mime_description)),
            role::DATE_MODIFIED => QVariant::from(&QDateTime::from_msecs_since_epoch(d.last_modified, &QTimeZone::utc())),
            role::DATE_MODIFIED_FORMATTED => QVariant::from(&qs(&d.formatted_date)),
            role::PERMISSIONS => QVariant::from(&qs(&d.permissions)),
            role::OWNER => QVariant::from(&qs(&d.owner)),
            role::IS_IMAGE => QVariant::from(&d.is_image),
            role::IS_HIDDEN => QVariant::from(&d.is_hidden),
            role::DEPTH => QVariant::from(&e.depth),
            role::EXPANDED => QVariant::from(&e.expanded),
            _ => QVariant::default(),
        }
    }

    fn role_names(&self) -> QHash<QHashPair_i32_QByteArray> {
        let mut roles = QHash::<QHashPair_i32_QByteArray>::default();
        for (r, name) in [
            (role::ENTRY, "modelData"),
            (role::NAME, "name"),
            (role::PATH, "path"),
            (role::IS_DIR, "isDir"),
            (role::SIZE, "size"),
            (role::SIZE_FORMATTED, "sizeFormatted"),
            (role::MIME_TYPE, "mimeType"),
            (role::MIME_DESCRIPTION, "mimeDescription"),
            (role::DATE_MODIFIED, "dateModified"),
            (role::DATE_MODIFIED_FORMATTED, "dateModifiedFormatted"),
            (role::PERMISSIONS, "permissions"),
            (role::OWNER, "owner"),
            (role::IS_IMAGE, "isImage"),
            (role::IS_HIDDEN, "isHidden"),
            (role::DEPTH, "depth"),
            (role::EXPANDED, "expanded"),
        ] {
            roles.insert(r, QByteArray::from(name));
        }
        roles
    }
}
