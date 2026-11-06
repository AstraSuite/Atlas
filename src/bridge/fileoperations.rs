//! FileOperations: copy, move, trash, clipboard, undo/redo and archives.
//! Blocking work runs on worker threads and reports back through
//! FileOperationProgress and operationFinished.

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
        include!("cxx-qt-lib/qstringlist.h");
        type QStringList = cxx_qt_lib::QStringList;
        include!("cxx-qt-lib/qlist.h");
        type QList_QVariant = cxx_qt_lib::QList<cxx_qt_lib::QVariant>;

        include!("qobjectfactory.h");
        #[cxx_name = "atlasNewChild"]
        unsafe fn new_progress(parent: *mut FileOperations) -> *mut FileOperationProgress;
    }

    #[qenum(FileOperations)]
    enum TransferEngine {
        StandardEngine,
        RsyncEngine,
        CustomEngine,
    }

    extern "RustQt" {
        #[qobject]
        #[qproperty(bool, running, READ, NOTIFY = running_changed)]
        #[qproperty(f64, progress, READ, NOTIFY = progress_changed)]
        #[qproperty(QString, status_text, cxx_name = "statusText", READ, NOTIFY = status_text_changed)]
        #[qproperty(QString, current_item, cxx_name = "currentItem", READ, NOTIFY = current_item_changed)]
        type FileOperationProgress = super::FileOperationProgressRust;

        #[qsignal]
        #[cxx_name = "runningChanged"]
        fn running_changed(self: Pin<&mut FileOperationProgress>);
        #[qsignal]
        #[cxx_name = "progressChanged"]
        fn progress_changed(self: Pin<&mut FileOperationProgress>);
        #[qsignal]
        #[cxx_name = "statusTextChanged"]
        fn status_text_changed(self: Pin<&mut FileOperationProgress>);
        #[qsignal]
        #[cxx_name = "currentItemChanged"]
        fn current_item_changed(self: Pin<&mut FileOperationProgress>);
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        #[qproperty(*mut FileOperationProgress, progress, READ = progress_object, CONSTANT)]
        #[qproperty(QStringList, clipboard_files, cxx_name = "clipboardFiles", READ = clipboard_files, NOTIFY = clipboard_changed)]
        #[qproperty(bool, is_cut_operation, cxx_name = "isCutOperation", READ = is_cut_operation, NOTIFY = clipboard_changed)]
        #[qproperty(bool, can_paste, cxx_name = "canPaste", READ = can_paste, NOTIFY = clipboard_changed)]
        #[qproperty(bool, can_undo, cxx_name = "canUndo", READ = can_undo, NOTIFY = undo_stack_changed)]
        #[qproperty(bool, can_redo, cxx_name = "canRedo", READ = can_redo, NOTIFY = undo_stack_changed)]
        #[qproperty(QStringList, active_drag_files, cxx_name = "activeDragFiles", READ = active_drag_files, NOTIFY = active_drag_files_changed)]
        #[qproperty(QList_QVariant, completed_tasks, cxx_name = "completedTasks", READ = completed_tasks, NOTIFY = completed_tasks_changed)]
        #[qproperty(QString, clipboard_image_data, cxx_name = "clipboardImageData", READ = clipboard_image_data, NOTIFY = clipboard_changed)]
        #[qproperty(i32, transfer_engine, cxx_name = "transferEngine", READ, WRITE = set_transfer_engine, NOTIFY = transfer_engine_changed)]
        #[qproperty(QString, custom_command, cxx_name = "customCommand", READ, WRITE = set_custom_command, NOTIFY = custom_command_changed)]
        type FileOperations = super::FileOperationsRust;

        #[qsignal]
        #[cxx_name = "clipboardChanged"]
        fn clipboard_changed(self: Pin<&mut FileOperations>);
        #[qsignal]
        #[cxx_name = "activeDragFilesChanged"]
        fn active_drag_files_changed(self: Pin<&mut FileOperations>);
        #[qsignal]
        #[cxx_name = "transferEngineChanged"]
        fn transfer_engine_changed(self: Pin<&mut FileOperations>);
        #[qsignal]
        #[cxx_name = "customCommandChanged"]
        fn custom_command_changed(self: Pin<&mut FileOperations>);
        #[qsignal]
        #[cxx_name = "undoStackChanged"]
        fn undo_stack_changed(self: Pin<&mut FileOperations>);
        #[qsignal]
        #[cxx_name = "operationFinished"]
        fn operation_finished(self: Pin<&mut FileOperations>, success: bool, message: &QString);
        #[qsignal]
        #[cxx_name = "completedTasksChanged"]
        fn completed_tasks_changed(self: Pin<&mut FileOperations>);
        #[qsignal]
        #[cxx_name = "conflictOccurred"]
        fn conflict_occurred(self: Pin<&mut FileOperations>, source: &QString, destination: &QString);

        #[cxx_name = "progressObject"]
        fn progress_object(self: &FileOperations) -> *mut FileOperationProgress;
        #[cxx_name = "clipboardFiles"]
        fn clipboard_files(self: &FileOperations) -> QStringList;
        #[cxx_name = "isCutOperation"]
        fn is_cut_operation(self: &FileOperations) -> bool;
        #[cxx_name = "canPaste"]
        fn can_paste(self: &FileOperations) -> bool;
        #[cxx_name = "canUndo"]
        fn can_undo(self: &FileOperations) -> bool;
        #[cxx_name = "canRedo"]
        fn can_redo(self: &FileOperations) -> bool;
        #[cxx_name = "activeDragFiles"]
        fn active_drag_files(self: &FileOperations) -> QStringList;
        #[cxx_name = "completedTasks"]
        fn completed_tasks(self: &FileOperations) -> QList_QVariant;
        #[cxx_name = "clipboardImageData"]
        fn clipboard_image_data(self: &FileOperations) -> QString;
        #[cxx_name = "setTransferEngine"]
        fn set_transfer_engine(self: Pin<&mut FileOperations>, engine: i32);
        #[cxx_name = "setCustomCommand"]
        fn set_custom_command(self: Pin<&mut FileOperations>, cmd: QString);

        #[qinvokable]
        #[cxx_name = "addCompletedTask"]
        fn add_completed_task(self: Pin<&mut FileOperations>, success: bool, message: &QString, url: &QString);
        #[qinvokable]
        #[cxx_name = "addCompletedTask"]
        fn add_completed_task_no_url(self: Pin<&mut FileOperations>, success: bool, message: &QString);
        #[qinvokable]
        #[cxx_name = "clearCompletedTasks"]
        fn clear_completed_tasks(self: Pin<&mut FileOperations>);
        #[qinvokable]
        fn undo(self: Pin<&mut FileOperations>);
        #[qinvokable]
        fn redo(self: Pin<&mut FileOperations>);
        #[qinvokable]
        #[cxx_name = "isPathCut"]
        fn is_path_cut(self: &FileOperations, path: &QString) -> bool;
        #[qinvokable]
        #[cxx_name = "copyToClipboard"]
        fn copy_to_clipboard(self: Pin<&mut FileOperations>, paths: &QStringList);
        #[qinvokable]
        #[cxx_name = "cutToClipboard"]
        fn cut_to_clipboard(self: Pin<&mut FileOperations>, paths: &QStringList);
        #[qinvokable]
        #[cxx_name = "copyPaths"]
        fn copy_paths(self: Pin<&mut FileOperations>, paths: &QStringList);
        #[qinvokable]
        #[cxx_name = "cutPaths"]
        fn cut_paths(self: Pin<&mut FileOperations>, paths: &QStringList);
        #[qinvokable]
        #[cxx_name = "clearClipboard"]
        fn clear_clipboard(self: Pin<&mut FileOperations>);
        #[qinvokable]
        fn paste(self: Pin<&mut FileOperations>, destination_dir: &QString);
        #[qinvokable]
        #[cxx_name = "pasteImage"]
        fn paste_image(self: Pin<&mut FileOperations>, destination_dir: &QString) -> QString;
        #[qinvokable]
        #[cxx_name = "copyTextToClipboard"]
        fn copy_text_to_clipboard(self: &FileOperations, text: &QString);
        #[qinvokable]
        #[cxx_name = "extractArchive"]
        fn extract_archive(self: Pin<&mut FileOperations>, archive_path: &QString, destination_dir: &QString);
        #[qinvokable]
        #[cxx_name = "extractArchive"]
        fn extract_archive_here(self: Pin<&mut FileOperations>, archive_path: &QString);
        #[qinvokable]
        #[cxx_name = "createArchive"]
        fn create_archive(self: Pin<&mut FileOperations>, source_paths: &QStringList, destination_file: &QString, format: &QString);
        #[qinvokable]
        #[cxx_name = "uploadToCatbox"]
        fn upload_to_catbox(self: &FileOperations, paths: &QStringList);
        #[qinvokable]
        #[cxx_name = "uploadToLitterbox"]
        fn upload_to_litterbox(self: &FileOperations, paths: &QStringList, time: &QString);
        #[qinvokable]
        #[cxx_name = "copyFiles"]
        fn copy_files(self: Pin<&mut FileOperations>, sources: &QStringList, destination_dir: &QString);
        #[qinvokable]
        #[cxx_name = "moveFiles"]
        fn move_files(self: Pin<&mut FileOperations>, sources: &QStringList, destination_dir: &QString);
        #[qinvokable]
        #[cxx_name = "deleteFiles"]
        fn delete_files(self: Pin<&mut FileOperations>, paths: &QStringList, permanent: bool);
        #[qinvokable]
        #[cxx_name = "deletePermanently"]
        fn delete_permanently(self: Pin<&mut FileOperations>, paths: &QStringList);
        #[qinvokable]
        #[cxx_name = "moveToTrash"]
        fn move_to_trash(self: Pin<&mut FileOperations>, paths: &QStringList);
        #[qinvokable]
        #[cxx_name = "restoreFromTrash"]
        fn restore_from_trash(self: Pin<&mut FileOperations>, trash_info_path: &QString);
        #[qinvokable]
        #[cxx_name = "removeFromRecent"]
        fn remove_from_recent(self: Pin<&mut FileOperations>, paths: &QStringList);
        #[qinvokable]
        #[cxx_name = "emptyTrash"]
        fn empty_trash(self: Pin<&mut FileOperations>);
        #[qinvokable]
        #[cxx_name = "renameFile"]
        fn rename_file(self: Pin<&mut FileOperations>, old_path: &QString, new_name: &QString);
        #[qinvokable]
        #[cxx_name = "bulkRename"]
        fn bulk_rename(self: Pin<&mut FileOperations>, paths: &QStringList, new_names: &QStringList);
        #[qinvokable]
        #[cxx_name = "createDirectory"]
        fn create_directory(self: Pin<&mut FileOperations>, parent_dir: &QString, name: &QString);
        #[qinvokable]
        #[cxx_name = "createFile"]
        fn create_file(self: Pin<&mut FileOperations>, parent_dir: &QString, name: &QString, content: &QString);
        #[qinvokable]
        #[cxx_name = "createFile"]
        fn create_empty_file(self: Pin<&mut FileOperations>, parent_dir: &QString, name: &QString);
        #[qinvokable]
        #[cxx_name = "createFromTemplate"]
        fn create_from_template(self: Pin<&mut FileOperations>, template_path: &QString, parent_dir: &QString, name: &QString);
        #[qinvokable]
        #[cxx_name = "duplicateFile"]
        fn duplicate_file(self: Pin<&mut FileOperations>, path: &QString);
        #[qinvokable]
        #[cxx_name = "createSymlink"]
        fn create_symlink(self: Pin<&mut FileOperations>, target: &QString, link_path: &QString);
        #[qinvokable]
        #[cxx_name = "pasteAsSymlink"]
        fn paste_as_symlink(self: Pin<&mut FileOperations>, destination_dir: &QString);
        #[qinvokable]
        #[cxx_name = "cancelOperation"]
        fn cancel_operation(self: &FileOperations);
        #[qinvokable]
        #[cxx_name = "startNativeDrag"]
        fn start_native_drag(self: Pin<&mut FileOperations>, file_paths: &QStringList, card_width: i32, card_height: i32, icon_size: i32);
    }

    impl cxx_qt::Threading for FileOperations {}
    impl cxx_qt::Constructor<()> for FileOperations {}
}

use crate::bridge::native::{self, from_qsl, qs, qsl, settings, to_qvariant_list};
use crate::bridge::registry;
use crate::core::fileops::{self, Progress};
use crate::core::{paths, recent};
use cxx_qt::{CxxQtThread, CxxQtType, Threading};
use cxx_qt_lib::{QList, QString, QStringList, QVariant};
use qobject::{FileOperationProgress, FileOperations};
use serde_json::{json, Value};
use std::collections::BTreeMap;
use std::pin::Pin;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Instant;

#[derive(Default)]
pub struct FileOperationProgressRust {
    running: bool,
    progress: f64,
    status_text: QString,
    current_item: QString,
}

impl FileOperationProgress {
    pub fn set_running(mut self: Pin<&mut Self>, running: bool) {
        if self.running != running {
            self.as_mut().rust_mut().running = running;
            self.running_changed();
        }
    }

    pub fn set_progress(mut self: Pin<&mut Self>, progress: f64) {
        if self.progress != progress {
            self.as_mut().rust_mut().progress = progress;
            self.progress_changed();
        }
    }

    pub fn set_status_text(mut self: Pin<&mut Self>, text: &str) {
        let text = qs(text);
        if self.status_text != text {
            self.as_mut().rust_mut().status_text = text;
            self.status_text_changed();
        }
    }

    pub fn set_current_item(mut self: Pin<&mut Self>, item: &str) {
        let item = qs(item);
        if self.current_item != item {
            self.as_mut().rust_mut().current_item = item;
            self.current_item_changed();
        }
    }
}

#[derive(Clone, Copy, PartialEq)]
enum UndoType {
    Rename,
    CreateFile,
    CreateDirectory,
    Move,
    Copy,
    MoveToTrash,
    BulkRename,
}

#[derive(Clone)]
struct UndoAction {
    kind: UndoType,
    old_path: String,
    new_path: String,
    parent_dir: String,
    name: String,
    content: String,
    source_paths: Vec<String>,
    dest_paths: Vec<String>,
    target_dir: String,
    trash_info_paths: Vec<String>,
}

impl UndoAction {
    fn new(kind: UndoType) -> Self {
        UndoAction {
            kind,
            old_path: String::new(),
            new_path: String::new(),
            parent_dir: String::new(),
            name: String::new(),
            content: String::new(),
            source_paths: Vec::new(),
            dest_paths: Vec::new(),
            target_dir: String::new(),
            trash_info_paths: Vec::new(),
        }
    }
}

/// Undo and redo replay operations through the normal entry points, which
/// finish asynchronously; each operation snapshots this when it starts.
#[derive(Clone, Copy, PartialEq, Default)]
enum Replay {
    #[default]
    None,
    Undo,
    Redo,
}

pub struct FileOperationsRust {
    progress: *mut FileOperationProgress,
    clipboard_files: Vec<String>,
    active_drag_files: Vec<String>,
    clipboard_image_data: String,
    drag_in_flight: bool,
    completed_tasks: Vec<Value>,
    last_completed_key: String,
    last_completed_at: Option<Instant>,
    undo_stack: Vec<UndoAction>,
    redo_stack: Vec<UndoAction>,
    is_cut: bool,
    transfer_engine: i32,
    custom_command: QString,
    cancel_requested: Arc<AtomicBool>,
    replay: Replay,
}

impl Default for FileOperationsRust {
    fn default() -> Self {
        Self {
            progress: std::ptr::null_mut(),
            clipboard_files: Vec::new(),
            active_drag_files: Vec::new(),
            clipboard_image_data: String::new(),
            drag_in_flight: false,
            completed_tasks: Vec::new(),
            last_completed_key: String::new(),
            last_completed_at: None,
            undo_stack: Vec::new(),
            redo_stack: Vec::new(),
            is_cut: false,
            transfer_engine: settings::int("preferences/transferEngine", 0).clamp(0, 2),
            custom_command: qs(&settings::string("preferences/customTransferCommand", "")),
            cancel_requested: Arc::new(AtomicBool::new(false)),
            replay: Replay::None,
        }
    }
}

impl cxx_qt::Initialize for FileOperations {
    fn initialize(mut self: Pin<&mut Self>) {
        let me = unsafe { self.as_mut().get_unchecked_mut() as *mut FileOperations };
        self.as_mut().rust_mut().progress = unsafe { qobject::new_progress(me) };
        registry::FILE_OPERATIONS.set(self.as_mut());
        native::ffi::clipboard_watch();
        self.sync_from_system_clipboard();
    }
}

/// Called by the native clipboard watcher.
pub fn on_clipboard_changed() {
    if let Some(ops) = registry::FILE_OPERATIONS.get() {
        ops.sync_from_system_clipboard();
    }
}

/// Called once a native drag started by startNativeDrag ends.
pub fn on_native_drag_finished() {
    if let Some(mut ops) = registry::FILE_OPERATIONS.get() {
        let mut rust = ops.as_mut().rust_mut();
        rust.drag_in_flight = false;
        rust.active_drag_files.clear();
        ops.active_drag_files_changed();
    }
}

/// Reports copy progress to the progress object from a worker thread.
fn progress_reporter(thread: CxxQtThread<FileOperations>) -> impl FnMut(f64, &str) {
    move |p: f64, item: &str| {
        let item = item.to_string();
        let _ = thread.queue(move |ops| {
            let mut progress = ops.progress_pin();
            progress.as_mut().set_progress(p);
            progress.set_current_item(&item);
        });
    }
}

impl FileOperations {
    pub fn progress_pin(&self) -> Pin<&mut FileOperationProgress> {
        unsafe { Pin::new_unchecked(&mut *self.progress) }
    }

    fn begin_progress(&self, status: &str, reset: bool) {
        let mut progress = self.progress_pin();
        progress.as_mut().set_running(true);
        if reset {
            progress.as_mut().set_progress(0.0);
        }
        progress.set_status_text(status);
    }

    fn end_progress(&self, complete: bool) {
        let mut progress = self.progress_pin();
        progress.as_mut().set_running(false);
        if complete {
            progress.set_progress(1.0);
        }
    }

    fn finished(self: Pin<&mut Self>, success: bool, message: &str) {
        self.operation_finished(success, &qs(message));
    }

    // ---- Properties ----

    fn progress_object(&self) -> *mut FileOperationProgress {
        self.progress
    }
    fn clipboard_files(&self) -> QStringList {
        qsl(&self.clipboard_files)
    }
    fn is_cut_operation(&self) -> bool {
        self.is_cut
    }
    fn can_paste(&self) -> bool {
        !self.clipboard_files.is_empty() || !self.clipboard_image_data.is_empty()
    }
    fn can_undo(&self) -> bool {
        !self.undo_stack.is_empty()
    }
    fn can_redo(&self) -> bool {
        !self.redo_stack.is_empty()
    }
    fn active_drag_files(&self) -> QStringList {
        qsl(&self.active_drag_files)
    }
    fn completed_tasks(&self) -> QList<QVariant> {
        to_qvariant_list(&self.completed_tasks)
    }
    fn clipboard_image_data(&self) -> QString {
        qs(&self.clipboard_image_data)
    }

    fn set_transfer_engine(mut self: Pin<&mut Self>, engine: i32) {
        if self.transfer_engine != engine {
            self.as_mut().rust_mut().transfer_engine = engine;
            settings::set_int("preferences/transferEngine", engine);
            self.transfer_engine_changed();
        }
    }

    fn set_custom_command(mut self: Pin<&mut Self>, cmd: QString) {
        if self.custom_command != cmd {
            settings::set_string("preferences/customTransferCommand", &cmd.to_string());
            self.as_mut().rust_mut().custom_command = cmd;
            self.custom_command_changed();
        }
    }

    // ---- Completed tasks ----

    pub fn push_completed_task(mut self: Pin<&mut Self>, success: bool, message: &str, url: &str) {
        let key = format!("{message}\n{url}");
        if key == self.last_completed_key && self.last_completed_at.is_some_and(|t| t.elapsed().as_millis() < 1000) {
            return;
        }
        let task = json!({
            "success": success,
            "message": message,
            "url": url,
            "time": chrono::Local::now().format("%H:%M:%S").to_string(),
        });
        {
            let mut rust = self.as_mut().rust_mut();
            rust.last_completed_key = key;
            rust.last_completed_at = Some(Instant::now());
            rust.completed_tasks.insert(0, task);
            rust.completed_tasks.truncate(30);
        }
        self.completed_tasks_changed();
    }

    fn add_completed_task(self: Pin<&mut Self>, success: bool, message: &QString, url: &QString) {
        self.push_completed_task(success, &message.to_string(), &url.to_string());
    }

    fn add_completed_task_no_url(self: Pin<&mut Self>, success: bool, message: &QString) {
        self.push_completed_task(success, &message.to_string(), "");
    }

    fn clear_completed_tasks(mut self: Pin<&mut Self>) {
        if !self.completed_tasks.is_empty() {
            self.as_mut().rust_mut().completed_tasks.clear();
            self.completed_tasks_changed();
        }
    }

    // ---- Undo / redo ----

    fn record_undo(mut self: Pin<&mut Self>, action: UndoAction, replay: Replay) {
        // Undoing an operation must not record its reversal; redoing one
        // records it again but keeps the rest of the redo stack.
        if replay == Replay::Undo {
            return;
        }
        let mut rust = self.as_mut().rust_mut();
        rust.undo_stack.push(action);
        if replay == Replay::None {
            rust.redo_stack.clear();
        }
        self.undo_stack_changed();
    }

    fn push_redo(mut self: Pin<&mut Self>, action: UndoAction) {
        self.as_mut().rust_mut().redo_stack.push(action);
        self.undo_stack_changed();
    }

    fn with_replay(mut self: Pin<&mut Self>, replay: Replay, f: impl FnOnce(Pin<&mut Self>)) {
        self.as_mut().rust_mut().replay = replay;
        f(self.as_mut());
        self.as_mut().rust_mut().replay = Replay::None;
    }

    fn undo(mut self: Pin<&mut Self>) {
        let Some(action) = self.as_mut().rust_mut().undo_stack.pop() else { return };
        self.as_mut().undo_stack_changed();
        match action.kind {
            UndoType::Rename => {
                if std::fs::rename(&action.new_path, &action.old_path).is_ok() {
                    self.as_mut().push_redo(action);
                    self.finished(true, "Undid rename");
                }
            }
            UndoType::CreateDirectory => {
                if fileops::remove_recursively(&action.new_path) {
                    self.as_mut().push_redo(action);
                    self.finished(true, "Undid folder creation");
                }
            }
            UndoType::CreateFile => {
                if std::fs::remove_file(&action.new_path).is_ok() {
                    self.as_mut().push_redo(action);
                    self.finished(true, "Undid file creation");
                }
            }
            UndoType::Move => {
                // Move each item back to the folder it came from.
                let mut by_folder: BTreeMap<String, Vec<String>> = BTreeMap::new();
                for (src, dest) in action.source_paths.iter().zip(&action.dest_paths) {
                    by_folder.entry(paths::parent(src)).or_default().push(dest.clone());
                }
                self.as_mut().with_replay(Replay::Undo, |mut ops| {
                    for (folder, items) in by_folder {
                        ops.as_mut().move_files_impl(items, folder);
                    }
                });
                self.push_redo(action);
            }
            UndoType::Copy => {
                // Copies go to the trash rather than being deleted, in case
                // one was edited after the copy.
                let dests = action.dest_paths.clone();
                self.as_mut().with_replay(Replay::Undo, |ops| ops.move_to_trash_impl(dests));
                self.push_redo(action);
            }
            UndoType::BulkRename => {
                for (src, dest) in action.source_paths.iter().zip(&action.dest_paths).rev() {
                    let _ = std::fs::rename(dest, src);
                }
                self.as_mut().push_redo(action);
                self.finished(true, "Undid rename");
            }
            UndoType::MoveToTrash => {
                for info in &action.trash_info_paths {
                    self.as_mut().restore_impl(info);
                }
                self.as_mut().push_redo(action);
                self.finished(true, "Undid trash");
            }
        }
    }

    fn redo(mut self: Pin<&mut Self>) {
        let Some(action) = self.as_mut().rust_mut().redo_stack.pop() else { return };
        self.as_mut().undo_stack_changed();
        match action.kind {
            UndoType::Rename => {
                if std::fs::rename(&action.old_path, &action.new_path).is_ok() {
                    self.as_mut().rust_mut().undo_stack.push(action);
                    self.as_mut().undo_stack_changed();
                    self.finished(true, "Redid rename");
                }
            }
            UndoType::BulkRename => {
                for (src, dest) in action.source_paths.iter().zip(&action.dest_paths) {
                    let _ = std::fs::rename(src, dest);
                }
                self.as_mut().rust_mut().undo_stack.push(action);
                self.as_mut().undo_stack_changed();
                self.finished(true, "Redid rename");
            }
            _ => self.with_replay(Replay::Redo, |ops| match action.kind {
                UndoType::CreateDirectory => ops.create_directory_impl(&action.parent_dir, &action.name),
                UndoType::CreateFile => ops.create_file_impl(&action.parent_dir, &action.name, &action.content),
                UndoType::Move => ops.move_files_impl(action.source_paths.clone(), action.target_dir.clone()),
                UndoType::Copy => ops.copy_files_impl(action.source_paths.clone(), action.target_dir.clone()),
                UndoType::MoveToTrash => ops.move_to_trash_impl(action.source_paths.clone()),
                _ => {}
            }),
        }
    }

    // ---- Clipboard ----

    fn sync_from_system_clipboard(mut self: Pin<&mut Self>) {
        let state = native::ffi::clipboard_read();
        let files = from_qsl(&state.files);
        let image = state.image_png_base64.to_string();
        let image_changed = self.clipboard_image_data != image;
        let files_changed = files != self.clipboard_files || state.cut != self.is_cut;
        self.as_mut().rust_mut().clipboard_image_data = image;
        if files_changed || image_changed {
            let mut rust = self.as_mut().rust_mut();
            rust.clipboard_files = files;
            rust.is_cut = state.cut;
            self.clipboard_changed();
        }
    }

    fn is_path_cut(&self, path: &QString) -> bool {
        self.is_cut && self.clipboard_files.contains(&path.to_string())
    }

    fn set_clipboard(mut self: Pin<&mut Self>, paths: &QStringList, cut: bool) {
        {
            let mut rust = self.as_mut().rust_mut();
            rust.clipboard_files = from_qsl(paths);
            rust.is_cut = cut;
        }
        native::ffi::clipboard_set_files(paths, cut);
        self.clipboard_changed();
    }

    fn copy_to_clipboard(self: Pin<&mut Self>, paths: &QStringList) {
        self.set_clipboard(paths, false);
    }
    fn cut_to_clipboard(self: Pin<&mut Self>, paths: &QStringList) {
        self.set_clipboard(paths, true);
    }
    fn copy_paths(self: Pin<&mut Self>, paths: &QStringList) {
        self.set_clipboard(paths, false);
    }
    fn cut_paths(self: Pin<&mut Self>, paths: &QStringList) {
        self.set_clipboard(paths, true);
    }

    fn clear_clipboard(mut self: Pin<&mut Self>) {
        {
            let mut rust = self.as_mut().rust_mut();
            rust.clipboard_files.clear();
            rust.is_cut = false;
        }
        native::ffi::clipboard_set_files(&QStringList::default(), false);
        self.clipboard_changed();
    }

    fn paste(mut self: Pin<&mut Self>, destination_dir: &QString) {
        self.as_mut().sync_from_system_clipboard();
        let dest = destination_dir.to_string();
        if self.clipboard_files.is_empty() || dest.is_empty() {
            return;
        }
        let sources = self.clipboard_files.clone();
        if self.is_cut {
            self.as_mut().move_files_impl(sources, dest);
            self.clear_clipboard();
        } else {
            self.copy_files_impl(sources, dest);
        }
    }

    fn paste_image(mut self: Pin<&mut Self>, destination_dir: &QString) -> QString {
        use base64::Engine;
        self.as_mut().sync_from_system_clipboard();
        let dest = destination_dir.to_string();
        if self.clipboard_image_data.is_empty() || dest.is_empty() {
            return QString::default();
        }
        let Ok(data) = base64::engine::general_purpose::STANDARD.decode(&self.clipboard_image_data) else {
            return QString::default();
        };
        if data.is_empty() {
            return QString::default();
        }
        let mut file_path = format!("{dest}/image.png");
        let mut n = 1;
        while paths::exists(&file_path) {
            file_path = format!("{dest}/image ({n}).png");
            n += 1;
        }
        if std::fs::write(&file_path, data).is_err() {
            self.finished(false, &format!("Failed to create image file: {file_path}"));
            return QString::default();
        }
        qs(&file_path)
    }

    fn copy_text_to_clipboard(&self, text: &QString) {
        native::ffi::clipboard_set_text(text);
    }

    // ---- Archives ----

    fn extract_archive(self: Pin<&mut Self>, archive_path: &QString, destination_dir: &QString) {
        let archive = archive_path.to_string();
        let dest = destination_dir.to_string();
        let dest = if dest.is_empty() { paths::parent(&archive) } else { dest };
        self.begin_progress("Extracting archive...", false);
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let success = fileops::extract_archive(&archive, &dest);
            let name = paths::file_name(&archive);
            let _ = thread.queue(move |ops| {
                ops.end_progress(false);
                let message = if success { format!("Extracted {name}") } else { "Extraction failed".to_string() };
                ops.finished(success, &message);
            });
        });
    }

    fn extract_archive_here(self: Pin<&mut Self>, archive_path: &QString) {
        self.extract_archive(archive_path, &QString::default());
    }

    fn create_archive(self: Pin<&mut Self>, source_paths: &QStringList, destination_file: &QString, format: &QString) {
        let sources = from_qsl(source_paths);
        let dest = destination_file.to_string();
        let format = format.to_string();
        self.begin_progress("Creating archive...", false);
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let success = fileops::create_archive(&sources, &dest, &format);
            let name = paths::file_name(&dest);
            let _ = thread.queue(move |ops| {
                ops.end_progress(false);
                let message = if success { format!("Created {name}") } else { "Archive creation failed".to_string() };
                ops.finished(success, &message);
            });
        });
    }

    fn upload_to_catbox(&self, paths: &QStringList) {
        if let Some(uploader) = registry::CATBOX_UPLOADER.get() {
            uploader.upload_list(from_qsl(paths), false, "24h");
        }
    }

    fn upload_to_litterbox(&self, paths: &QStringList, time: &QString) {
        if let Some(uploader) = registry::CATBOX_UPLOADER.get() {
            uploader.upload_list(from_qsl(paths), true, &time.to_string());
        }
    }

    // ---- Copy / move ----

    fn copy_files(self: Pin<&mut Self>, sources: &QStringList, destination_dir: &QString) {
        self.copy_files_impl(from_qsl(sources), destination_dir.to_string());
    }

    fn copy_files_impl(self: Pin<&mut Self>, sources: Vec<String>, destination_dir: String) {
        self.cancel_requested.store(false, Ordering::Relaxed);
        self.begin_progress("Copying files...", true);
        let replay = self.replay;
        let engine = self.transfer_engine;
        let command = self.custom_command.to_string();
        let cancel = self.cancel_requested.clone();
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let mut all_success = true;
            // Only the standard engine knows where each copy landed; rsync and
            // custom commands may overwrite files, so they aren't undoable.
            let mut copied_sources = Vec::new();
            let mut copied_paths = Vec::new();
            if engine == 1 {
                all_success = fileops::run_rsync(&sources, &destination_dir, false);
            } else if engine == 2 {
                all_success = fileops::run_custom_transfer(&command, &sources, &destination_dir);
            } else {
                let mut report = progress_reporter(thread.clone());
                let mut progress = Progress { processed: 0, total: fileops::calculate_total_size(&sources), report: &mut report };
                for src in &sources {
                    if cancel.load(Ordering::Relaxed) {
                        all_success = false;
                        break;
                    }
                    let name = paths::file_name(src);
                    let mut dest = format!("{destination_dir}/{name}");
                    if paths::exists(&dest) {
                        let base = paths::complete_base_name(&name);
                        let ext = paths::suffix(&name);
                        let ext = if ext.is_empty() { String::new() } else { format!(".{ext}") };
                        let mut counter = 1;
                        while paths::exists(&dest) {
                            dest = format!("{destination_dir}/{base} (copy {counter}){ext}");
                            counter += 1;
                        }
                    }
                    if !fileops::copy_recursively(src, &dest, &cancel, &mut progress) {
                        all_success = false;
                        break;
                    }
                    copied_sources.push(src.clone());
                    copied_paths.push(dest);
                }
            }
            let _ = thread.queue(move |mut ops| {
                if !copied_paths.is_empty() {
                    let mut action = UndoAction::new(UndoType::Copy);
                    action.source_paths = copied_sources;
                    action.dest_paths = copied_paths;
                    action.target_dir = destination_dir;
                    ops.as_mut().record_undo(action, replay);
                }
                ops.end_progress(true);
                ops.finished(all_success, if all_success { "Copy completed" } else { "Copy failed or cancelled" });
            });
        });
    }

    fn move_files(self: Pin<&mut Self>, sources: &QStringList, destination_dir: &QString) {
        self.move_files_impl(from_qsl(sources), destination_dir.to_string());
    }

    fn move_files_impl(self: Pin<&mut Self>, sources: Vec<String>, destination_dir: String) {
        self.cancel_requested.store(false, Ordering::Relaxed);
        self.begin_progress("Moving files...", true);
        let replay = self.replay;
        let engine = self.transfer_engine;
        let command = self.custom_command.to_string();
        let cancel = self.cancel_requested.clone();
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let mut all_success = true;
            let mut moved_sources = Vec::new();
            let mut moved_paths = Vec::new();
            if engine == 1 {
                all_success = fileops::run_rsync(&sources, &destination_dir, true);
                if all_success {
                    for src in &sources {
                        moved_sources.push(src.clone());
                        moved_paths.push(format!("{destination_dir}/{}", paths::file_name(src)));
                    }
                }
            } else {
                let canon = |p: &str| std::fs::canonicalize(p).map(|p| p.to_string_lossy().into_owned()).unwrap_or_default();
                let target_canon = canon(&destination_dir);
                let mut report = progress_reporter(thread.clone());
                let mut progress = Progress { processed: 0, total: fileops::calculate_total_size(&sources), report: &mut report };
                // Items that can't be renamed (another filesystem) and must go
                // through the custom command.
                let mut pending_custom = Vec::new();
                for src in &sources {
                    if cancel.load(Ordering::Relaxed) {
                        all_success = false;
                        break;
                    }
                    if !fileops::entry_exists(src) {
                        continue;
                    }
                    let dest = format!("{destination_dir}/{}", paths::file_name(src));
                    let src_canon = canon(src);
                    // Moving into the folder it is already in is a no-op.
                    if canon(&paths::parent(src)) == target_canon || (!src_canon.is_empty() && src_canon == canon(&dest)) {
                        continue;
                    }
                    // Never move a folder into itself or one of its subfolders.
                    if paths::is_dir(src) && (target_canon.starts_with(&format!("{src_canon}/")) || target_canon == src_canon) {
                        continue;
                    }
                    if std::fs::rename(src, &dest).is_ok() {
                        moved_sources.push(src.clone());
                        moved_paths.push(dest);
                    } else if engine == 2 {
                        pending_custom.push(src.clone());
                    } else if fileops::copy_recursively(src, &dest, &cancel, &mut progress) {
                        fileops::remove_recursively(src);
                        moved_sources.push(src.clone());
                        moved_paths.push(dest);
                    } else {
                        all_success = false;
                    }
                }
                if !pending_custom.is_empty() && !cancel.load(Ordering::Relaxed) {
                    if fileops::run_custom_transfer(&command, &pending_custom, &destination_dir) {
                        for src in &pending_custom {
                            fileops::remove_recursively(src);
                            moved_sources.push(src.clone());
                            moved_paths.push(format!("{destination_dir}/{}", paths::file_name(src)));
                        }
                    } else {
                        all_success = false;
                    }
                }
            }
            let _ = thread.queue(move |mut ops| {
                if !moved_paths.is_empty() {
                    let mut action = UndoAction::new(UndoType::Move);
                    action.source_paths = moved_sources;
                    action.dest_paths = moved_paths;
                    action.target_dir = destination_dir;
                    ops.as_mut().record_undo(action, replay);
                }
                ops.end_progress(true);
                ops.finished(all_success, if all_success { "Move completed" } else { "Move failed or cancelled" });
            });
        });
    }

    // ---- Delete / trash ----

    fn delete_files(self: Pin<&mut Self>, paths_in: &QStringList, permanent: bool) {
        let list = from_qsl(paths_in);
        if !permanent {
            self.move_to_trash_impl(list);
            return;
        }
        self.begin_progress("Deleting files...", false);
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let mut all_success = true;
            let trash_dir = crate::core::trash::home_trash_dir();
            for p in &list {
                if !fileops::remove_recursively(p) {
                    all_success = false;
                }
                if p.contains("/Trash/files/") {
                    let _ = std::fs::remove_file(format!("{trash_dir}/info/{}.trashinfo", paths::file_name(p)));
                }
            }
            let _ = thread.queue(move |ops| {
                ops.end_progress(false);
                ops.finished(all_success, if all_success { "Deleted files" } else { "Failed to delete some files" });
            });
        });
    }

    fn delete_permanently(self: Pin<&mut Self>, paths_in: &QStringList) {
        self.delete_files(paths_in, true);
    }

    fn move_to_trash(self: Pin<&mut Self>, paths_in: &QStringList) {
        self.move_to_trash_impl(from_qsl(paths_in));
    }

    fn move_to_trash_impl(self: Pin<&mut Self>, list: Vec<String>) {
        self.begin_progress("Moving to trash...", false);
        let replay = self.replay;
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let mut all_success = true;
            let mut trashed = Vec::new();
            let mut infos = Vec::new();
            for p in &list {
                if !fileops::entry_exists(p) {
                    continue;
                }
                match fileops::trash_one(p) {
                    Some(info) => {
                        trashed.push(paths::clean_path(p));
                        infos.push(info);
                    }
                    None => all_success = false,
                }
            }
            let _ = thread.queue(move |mut ops| {
                if !infos.is_empty() {
                    let mut action = UndoAction::new(UndoType::MoveToTrash);
                    action.source_paths = trashed;
                    action.trash_info_paths = infos;
                    ops.as_mut().record_undo(action, replay);
                }
                ops.end_progress(false);
                ops.finished(all_success, if all_success { "Moved to trash" } else { "Failed to trash some items" });
            });
        });
    }

    fn remove_from_recent(self: Pin<&mut Self>, paths_in: &QStringList) {
        let list = from_qsl(paths_in);
        if list.is_empty() {
            return;
        }
        for p in &list {
            recent::forget(p);
        }
        let message = if list.len() == 1 {
            "Removed one item from Recent".to_string()
        } else {
            format!("Removed {} items from Recent", list.len())
        };
        self.finished(true, &message);
    }

    fn restore_impl(self: Pin<&mut Self>, target: &str) {
        if let Some(name) = fileops::restore_from_trash(target) {
            self.finished(true, &format!("Restored {name}"));
        }
    }

    fn restore_from_trash(self: Pin<&mut Self>, trash_info_path: &QString) {
        self.restore_impl(&trash_info_path.to_string());
    }

    fn empty_trash(self: Pin<&mut Self>) {
        self.begin_progress("Emptying trash...", true);
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let all_success = fileops::empty_trash();
            let _ = thread.queue(move |ops| {
                ops.end_progress(true);
                ops.finished(all_success, if all_success { "Trash emptied" } else { "Failed to empty some trash items" });
            });
        });
    }

    // ---- Rename / create ----

    fn rename_file(mut self: Pin<&mut Self>, old_path: &QString, new_name: &QString) {
        let old_path = old_path.to_string();
        let new_name = new_name.to_string();
        let new_path = format!("{}/{new_name}", paths::parent(&old_path));
        let success = std::fs::rename(&old_path, &new_path).is_ok();
        if success {
            let mut action = UndoAction::new(UndoType::Rename);
            action.old_path = old_path;
            action.new_path = new_path;
            action.name = new_name;
            let replay = self.replay;
            self.as_mut().record_undo(action, replay);
        }
        self.finished(success, if success { "Renamed successfully" } else { "Rename failed" });
    }

    fn bulk_rename(mut self: Pin<&mut Self>, paths_in: &QStringList, new_names: &QStringList) {
        let list = from_qsl(paths_in);
        let names = from_qsl(new_names);
        if list.is_empty() || list.len() != names.len() {
            self.finished(false, "Rename failed");
            return;
        }
        let mut sources: Vec<String> = Vec::new();
        let mut targets: Vec<String> = Vec::new();
        for (path, name) in list.iter().zip(&names) {
            let name = name.trim();
            if !paths::exists(path) {
                self.finished(false, &format!("Rename failed: {} no longer exists", paths::file_name(path)));
                return;
            }
            if name.is_empty() || name.contains('/') {
                self.finished(false, &format!("Rename failed: {name} is not a valid name"));
                return;
            }
            let abs = paths::clean_path(path);
            let target = format!("{}/{name}", paths::parent(&abs));
            if target == abs {
                continue;
            }
            if targets.contains(&target) {
                self.finished(false, &format!("Rename failed: {name} would be used twice"));
                return;
            }
            sources.push(abs);
            targets.push(target);
        }
        if sources.is_empty() {
            self.finished(true, "Nothing to rename");
            return;
        }
        for target in &targets {
            if paths::exists(target) && !sources.contains(target) {
                self.finished(false, &format!("Rename failed: {} already exists", paths::file_name(target)));
                return;
            }
        }
        // Stage through temporary names so swaps (a -> b, b -> a) work.
        let mut staged: Vec<String> = Vec::new();
        for (i, src) in sources.iter().enumerate() {
            let mut n = 0;
            let mut temp = format!("{}.atlas-rename-{n}", targets[i]);
            while paths::exists(&temp) {
                n += 1;
                temp = format!("{}.atlas-rename-{n}", targets[i]);
            }
            if std::fs::rename(src, &temp).is_err() {
                for (j, s) in staged.iter().enumerate().rev() {
                    let _ = std::fs::rename(s, &sources[j]);
                }
                self.finished(false, &format!("Rename failed: could not rename {}", paths::file_name(src)));
                return;
            }
            staged.push(temp);
        }
        for i in 0..staged.len() {
            if std::fs::rename(&staged[i], &targets[i]).is_err() {
                for j in (0..i).rev() {
                    let _ = std::fs::rename(&targets[j], &staged[j]);
                }
                for (j, s) in staged.iter().enumerate().rev() {
                    let _ = std::fs::rename(s, &sources[j]);
                }
                self.finished(false, &format!("Rename failed: could not rename {}", paths::file_name(&sources[i])));
                return;
            }
        }
        let count = sources.len();
        let mut action = UndoAction::new(UndoType::BulkRename);
        action.source_paths = sources;
        action.dest_paths = targets;
        let replay = self.replay;
        self.as_mut().record_undo(action, replay);
        self.finished(true, &if count == 1 { "Renamed 1 item".to_string() } else { format!("Renamed {count} items") });
    }

    fn create_from_template(mut self: Pin<&mut Self>, template_path: &QString, parent_dir: &QString, name: &QString) {
        let template = template_path.to_string();
        let parent = parent_dir.to_string();
        let trimmed = name.to_string().trim().to_string();
        if template.is_empty() || parent.is_empty() || trimmed.is_empty() || trimmed.contains('/') {
            self.finished(false, "Invalid name");
            return;
        }
        if !paths::exists(&template) {
            self.finished(false, "Template no longer exists");
            return;
        }
        let destination = format!("{parent}/{trimmed}");
        if paths::exists(&destination) {
            self.finished(false, &format!("{trimmed} already exists"));
            return;
        }
        if std::fs::copy(&template, &destination).is_err() {
            self.finished(false, &format!("Could not create {trimmed}"));
            return;
        }
        if let Ok(meta) = std::fs::metadata(&destination) {
            use std::os::unix::fs::PermissionsExt;
            let mut perms = meta.permissions();
            perms.set_mode(perms.mode() | 0o200);
            let _ = std::fs::set_permissions(&destination, perms);
        }
        let mut action = UndoAction::new(UndoType::CreateFile);
        action.new_path = destination;
        action.parent_dir = parent;
        action.name = trimmed.clone();
        let replay = self.replay;
        self.as_mut().record_undo(action, replay);
        self.finished(true, &format!("Created {trimmed}"));
    }

    fn create_directory_impl(mut self: Pin<&mut Self>, parent_dir: &str, name: &str) {
        let new_path = format!("{parent_dir}/{name}");
        let success = !name.is_empty() && std::fs::create_dir(&new_path).is_ok();
        if success {
            let mut action = UndoAction::new(UndoType::CreateDirectory);
            action.parent_dir = parent_dir.to_string();
            action.name = name.to_string();
            action.new_path = new_path;
            let replay = self.replay;
            self.as_mut().record_undo(action, replay);
        }
        self.finished(success, if success { "Folder created" } else { "Failed to create folder" });
    }

    fn create_directory(self: Pin<&mut Self>, parent_dir: &QString, name: &QString) {
        self.create_directory_impl(&parent_dir.to_string(), &name.to_string());
    }

    fn create_file_impl(mut self: Pin<&mut Self>, parent_dir: &str, name: &str, content: &str) {
        let file_path = format!("{parent_dir}/{name}");
        let success = std::fs::write(&file_path, content.as_bytes()).is_ok();
        if success {
            let mut action = UndoAction::new(UndoType::CreateFile);
            action.parent_dir = parent_dir.to_string();
            action.name = name.to_string();
            action.content = content.to_string();
            action.new_path = file_path;
            let replay = self.replay;
            self.as_mut().record_undo(action, replay);
        }
        self.finished(success, if success { "File created" } else { "Failed to create file" });
    }

    fn create_file(self: Pin<&mut Self>, parent_dir: &QString, name: &QString, content: &QString) {
        self.create_file_impl(&parent_dir.to_string(), &name.to_string(), &content.to_string());
    }

    fn create_empty_file(self: Pin<&mut Self>, parent_dir: &QString, name: &QString) {
        self.create_file_impl(&parent_dir.to_string(), &name.to_string(), "");
    }

    fn duplicate_file(self: Pin<&mut Self>, path: &QString) {
        let path = path.to_string();
        let parent = paths::parent(&path);
        self.copy_files_impl(vec![path], parent);
    }

    fn create_symlink(self: Pin<&mut Self>, target: &QString, link_path: &QString) {
        let success = std::os::unix::fs::symlink(target.to_string(), link_path.to_string()).is_ok();
        self.finished(success, if success { "Link created" } else { "Failed to create link" });
    }

    fn paste_as_symlink(self: Pin<&mut Self>, destination_dir: &QString) {
        let dest = destination_dir.to_string();
        if self.clipboard_files.is_empty() || dest.is_empty() {
            return;
        }
        let mut success_count = 0;
        for src in &self.clipboard_files {
            let name = paths::file_name(src);
            let mut link = format!("{dest}/{name}");
            if paths::exists(&link) {
                link = format!("{dest}/{} (symlink).{}", paths::complete_base_name(&name), paths::suffix(&name));
            }
            if std::os::unix::fs::symlink(src, &link).is_ok() {
                success_count += 1;
            }
        }
        let all = success_count == self.clipboard_files.len();
        self.finished(all, if all { "Created symlink(s)" } else { "Failed to create some symlinks" });
    }

    fn cancel_operation(&self) {
        self.cancel_requested.store(true, Ordering::Relaxed);
    }

    fn start_native_drag(mut self: Pin<&mut Self>, file_paths: &QStringList, card_width: i32, card_height: i32, icon_size: i32) {
        let list = from_qsl(file_paths);
        if list.is_empty() || self.drag_in_flight {
            return;
        }
        {
            let mut rust = self.as_mut().rust_mut();
            rust.active_drag_files = list;
            rust.drag_in_flight = true;
        }
        self.as_mut().active_drag_files_changed();
        native::ffi::start_native_drag(file_paths, card_width, card_height, icon_size);
    }
}
