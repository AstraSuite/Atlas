//! CatboxUploader: uploads to catbox.moe and litterbox, one file at a time,
//! sharing FileOperations' progress bar.

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
        include!("cxx-qt-lib/qstringlist.h");
        type QStringList = cxx_qt_lib::QStringList;
    }

    #[qenum(CatboxUploader)]
    enum Service {
        Catbox,
        Litterbox,
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        #[qproperty(bool, is_uploading, cxx_name = "isUploading", READ, NOTIFY = is_uploading_changed)]
        #[qproperty(f64, upload_progress, cxx_name = "uploadProgress", READ, NOTIFY = upload_progress_changed)]
        #[qproperty(QString, current_file_name, cxx_name = "currentFileName", READ, NOTIFY = current_file_name_changed)]
        #[qproperty(QString, current_service, cxx_name = "currentService", READ, NOTIFY = current_service_changed)]
        #[qproperty(QString, last_url, cxx_name = "lastUrl", READ, NOTIFY = last_url_changed)]
        type CatboxUploader = super::CatboxUploaderRust;

        #[qsignal]
        #[cxx_name = "isUploadingChanged"]
        fn is_uploading_changed(self: Pin<&mut CatboxUploader>);
        #[qsignal]
        #[cxx_name = "uploadProgressChanged"]
        fn upload_progress_changed(self: Pin<&mut CatboxUploader>);
        #[qsignal]
        #[cxx_name = "currentFileNameChanged"]
        fn current_file_name_changed(self: Pin<&mut CatboxUploader>);
        #[qsignal]
        #[cxx_name = "currentServiceChanged"]
        fn current_service_changed(self: Pin<&mut CatboxUploader>);
        #[qsignal]
        #[cxx_name = "lastUrlChanged"]
        fn last_url_changed(self: Pin<&mut CatboxUploader>);
        #[qsignal]
        #[cxx_name = "uploadStarted"]
        fn upload_started(self: Pin<&mut CatboxUploader>, file_path: &QString);
        #[qsignal]
        #[cxx_name = "uploadProgressUpdated"]
        fn upload_progress_updated(self: Pin<&mut CatboxUploader>, progress: f64, status_text: &QString);
        #[qsignal]
        #[cxx_name = "uploadFinished"]
        fn upload_finished(self: Pin<&mut CatboxUploader>, success: bool, result_url_or_error: &QString, file_path: &QString);

        #[qinvokable]
        #[cxx_name = "uploadFile"]
        fn upload_file(self: Pin<&mut CatboxUploader>, file_path: &QString);
        #[qinvokable]
        #[cxx_name = "uploadFiles"]
        fn upload_files(self: Pin<&mut CatboxUploader>, file_paths: &QStringList);
        #[qinvokable]
        #[cxx_name = "uploadToLitterbox"]
        fn upload_to_litterbox(self: Pin<&mut CatboxUploader>, file_path: &QString, time: &QString);
        #[qinvokable]
        #[cxx_name = "uploadToLitterbox"]
        fn upload_to_litterbox_default(self: Pin<&mut CatboxUploader>, file_path: &QString);
        #[qinvokable]
        #[cxx_name = "uploadFilesToLitterbox"]
        fn upload_files_to_litterbox(self: Pin<&mut CatboxUploader>, file_paths: &QStringList, time: &QString);
        #[qinvokable]
        #[cxx_name = "uploadFilesToLitterbox"]
        fn upload_files_to_litterbox_default(self: Pin<&mut CatboxUploader>, file_paths: &QStringList);
        #[qinvokable]
        #[cxx_name = "cancelUpload"]
        fn cancel_upload(self: Pin<&mut CatboxUploader>);
    }

    impl cxx_qt::Threading for CatboxUploader {}
    impl cxx_qt::Constructor<()> for CatboxUploader {}
}

use crate::bridge::native::{self, from_qsl, mime, qs};
use crate::bridge::registry;
use crate::core::paths;
use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::{QString, QStringList};
use qobject::CatboxUploader;
use std::collections::VecDeque;
use std::io::{Chain, Cursor, Read};
use std::pin::Pin;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

#[derive(Clone)]
struct UploadItem {
    file_path: String,
    litterbox: bool,
    time: String,
}

fn service_name(litterbox: bool, time: &str) -> String {
    if litterbox {
        format!("Litterbox ({})", if time.is_empty() { "24h" } else { time })
    } else {
        "Catbox".to_string()
    }
}

#[derive(Default)]
pub struct CatboxUploaderRust {
    is_uploading: bool,
    upload_progress: f64,
    current_file_name: QString,
    current_service: QString,
    last_url: QString,
    queue: VecDeque<UploadItem>,
    current: Option<UploadItem>,
    current_size: i64,
    owns_shared_progress: bool,
    /// Set to abort the upload in flight; replaced for every upload.
    cancel: Arc<AtomicBool>,
    /// Bumped per upload so results of a cancelled one are ignored.
    upload_id: u64,
}

impl cxx_qt::Initialize for CatboxUploader {
    fn initialize(self: Pin<&mut Self>) {
        registry::CATBOX_UPLOADER.set(self);
    }
}

/// A reader that counts bytes for progress and stops when cancelled.
struct ProgressReader<R: Read> {
    inner: R,
    sent: u64,
    cancel: Arc<AtomicBool>,
    report: Box<dyn FnMut(u64) + Send>,
    last_report: std::time::Instant,
}

impl<R: Read> Read for ProgressReader<R> {
    fn read(&mut self, buf: &mut [u8]) -> std::io::Result<usize> {
        if self.cancel.load(Ordering::Relaxed) {
            return Err(std::io::Error::new(std::io::ErrorKind::Interrupted, "Operation canceled"));
        }
        let n = self.inner.read(buf)?;
        self.sent += n as u64;
        if self.last_report.elapsed().as_millis() >= 100 || n == 0 {
            self.last_report = std::time::Instant::now();
            (self.report)(self.sent);
        }
        Ok(n)
    }
}

type Body = Chain<Chain<Cursor<Vec<u8>>, std::fs::File>, Cursor<Vec<u8>>>;

fn multipart_body(item: &UploadItem, file_name: &str) -> std::io::Result<(String, u64, Body)> {
    let boundary = format!(
        "----AtlasBoundary{}{}",
        chrono::Utc::now().timestamp_millis(),
        rand::random::<u32>()
    );
    let mime_name = Some(mime::for_file(&item.file_path)).filter(|m| !m.is_empty()).unwrap_or_else(|| "application/octet-stream".into());
    let mut prologue = format!("--{boundary}\r\nContent-Disposition: form-data; name=\"reqtype\"\r\n\r\nfileupload\r\n");
    if item.litterbox {
        prologue.push_str(&format!(
            "--{boundary}\r\nContent-Disposition: form-data; name=\"time\"\r\n\r\n{}\r\n",
            item.time
        ));
    }
    prologue.push_str(&format!(
        "--{boundary}\r\nContent-Disposition: form-data; name=\"fileToUpload\"; filename=\"{file_name}\"\r\nContent-Type: {mime_name}\r\n\r\n"
    ));
    let epilogue = format!("\r\n--{boundary}--\r\n");
    let file = std::fs::File::open(&item.file_path)?;
    let size = file.metadata()?.len();
    let length = prologue.len() as u64 + size + epilogue.len() as u64;
    let body = Cursor::new(prologue.into_bytes()).chain(file).chain(Cursor::new(epilogue.into_bytes()));
    Ok((boundary, length, body))
}

impl CatboxUploader {
    fn with_progress(f: impl FnOnce(Pin<&mut crate::bridge::fileoperations::qobject::FileOperationProgress>)) {
        if let Some(ops) = registry::FILE_OPERATIONS.get() {
            f(ops.progress_pin());
        }
    }

    fn report_failure(&self, message: &str, completed: bool) {
        if let Some(mut ops) = registry::FILE_OPERATIONS.get() {
            if completed {
                ops.as_mut().push_completed_task(false, message, "");
            }
            ops.operation_finished(false, &qs(message));
        }
    }

    fn clear_shared_progress(mut self: Pin<&mut Self>, final_status: &str) {
        if !self.owns_shared_progress {
            return;
        }
        self.as_mut().rust_mut().owns_shared_progress = false;
        Self::with_progress(|mut p| {
            p.as_mut().set_running(false);
            p.as_mut().set_progress(0.0);
            p.as_mut().set_status_text(final_status);
            p.set_current_item("");
        });
    }

    fn set_state(mut self: Pin<&mut Self>, uploading: bool, file_name: &str, service: &str) {
        {
            let mut rust = self.as_mut().rust_mut();
            rust.is_uploading = uploading;
            rust.upload_progress = 0.0;
            rust.current_file_name = qs(file_name);
            rust.current_service = qs(service);
        }
        self.as_mut().is_uploading_changed();
        self.as_mut().upload_progress_changed();
        self.as_mut().current_file_name_changed();
        self.current_service_changed();
    }

    /// Queues files for upload (used by FileOperations too).
    pub fn upload_list(mut self: Pin<&mut Self>, file_paths: Vec<String>, litterbox: bool, time: &str) {
        let service = service_name(litterbox, time);
        let time = if time.is_empty() { "24h".to_string() } else { time.to_string() };
        let mut accepted = 0;
        for raw in file_paths {
            let path = paths::from_file_url(&raw);
            if path.is_empty() {
                continue;
            }
            if !paths::is_file(&path) {
                let name = Some(paths::file_name(&path)).filter(|n| !n.is_empty()).unwrap_or(path.clone());
                if let Some(mut ops) = registry::FILE_OPERATIONS.get() {
                    ops.as_mut().push_completed_task(
                        false,
                        &format!("Skipped {name}: only existing files can be uploaded to {service}"),
                        "",
                    );
                }
                continue;
            }
            self.as_mut().rust_mut().queue.push_back(UploadItem { file_path: path, litterbox, time: time.clone() });
            accepted += 1;
        }
        if accepted == 0 {
            self.report_failure(&format!("Nothing to upload to {service}"), false);
            return;
        }
        self.as_mut().rust_mut().owns_shared_progress = true;
        Self::with_progress(|mut p| {
            p.as_mut().set_running(true);
            p.set_status_text(&format!("Preparing to upload to {service}..."));
        });
        if !self.is_uploading {
            self.process_next();
        }
    }

    fn process_next(mut self: Pin<&mut Self>) {
        let Some(item) = self.as_mut().rust_mut().queue.pop_front() else {
            self.as_mut().rust_mut().current = None;
            self.as_mut().rust_mut().current_size = 0;
            self.as_mut().set_state(false, "", "");
            self.clear_shared_progress("");
            return;
        };
        let Ok(meta) = std::fs::metadata(&item.file_path) else {
            return self.process_next();
        };
        if meta.is_dir() {
            return self.process_next();
        }
        let file_name = paths::file_name(&item.file_path);
        let service = service_name(item.litterbox, &item.time);
        let cancel = Arc::new(AtomicBool::new(false));
        let upload_id = self.upload_id + 1;
        {
            let mut rust = self.as_mut().rust_mut();
            rust.current = Some(item.clone());
            rust.current_size = meta.len() as i64;
            rust.cancel = cancel.clone();
            rust.upload_id = upload_id;
            rust.owns_shared_progress = true;
        }
        self.as_mut().set_state(true, &file_name, &service);
        self.as_mut().upload_started(&qs(&item.file_path));
        Self::with_progress(|mut p| {
            p.as_mut().set_running(true);
            p.as_mut().set_progress(0.0);
            p.as_mut().set_current_item(&file_name);
            p.set_status_text(&format!("Uploading {file_name} to {service}..."));
        });

        let (boundary, length, body) = match multipart_body(&item, &file_name) {
            Ok(b) => b,
            Err(_) => {
                let err = "Failed to open file for reading";
                self.as_mut().upload_finished(false, &qs(err), &qs(&item.file_path));
                self.report_failure(&format!("{service} upload failed: {err}"), false);
                return self.process_next();
            }
        };

        let thread = self.qt_thread();
        let progress_thread = thread.clone();
        let reader = ProgressReader {
            inner: body,
            sent: 0,
            cancel: cancel.clone(),
            report: Box::new(move |sent| {
                let _ = progress_thread.queue(move |uploader| uploader.on_progress(upload_id, sent as i64, length as i64));
            }),
            last_report: std::time::Instant::now(),
        };
        let url = if item.litterbox {
            "https://litterbox.catbox.moe/resources/internals/api.php"
        } else {
            "https://catbox.moe/user/api.php"
        };
        std::thread::spawn(move || {
            let agent: ureq::Agent = ureq::Agent::config_builder()
                .http_status_as_error(false)
                .timeout_global(Some(std::time::Duration::from_secs(600)))
                .build()
                .into();
            let result = agent
                .post(url)
                .header("User-Agent", "Mozilla/5.0 Atlas/1.0")
                .header("Content-Type", &format!("multipart/form-data; boundary={boundary}"))
                .header("Content-Length", &length.to_string())
                .send(ureq::SendBody::from_owned_reader(reader));
            let outcome: Result<(u16, String), String> = match result {
                Ok(response) => {
                    let status = response.status().as_u16();
                    match response.into_body().read_to_string() {
                        Ok(text) => Ok((status, text.trim().to_string())),
                        Err(e) => Err(e.to_string()),
                    }
                }
                Err(e) => Err(e.to_string()),
            };
            let _ = thread.queue(move |uploader| uploader.on_finished(upload_id, outcome));
        });
    }

    fn on_progress(mut self: Pin<&mut Self>, upload_id: u64, sent: i64, total: i64) {
        if upload_id != self.upload_id || !self.is_uploading {
            return;
        }
        let total = if total <= 0 { self.current_size } else { total };
        if total <= 0 {
            return;
        }
        let progress = (sent as f64 / total as f64).clamp(0.0, 1.0);
        self.as_mut().rust_mut().upload_progress = progress;
        self.as_mut().upload_progress_changed();
        let name = self.current_file_name.to_string();
        let service = self.current_service.to_string();
        let percent = (progress * 100.0) as i32;
        self.as_mut().upload_progress_updated(progress, &qs(&format!("Uploading {name} ({percent}%)")));
        let queued = match self.queue.len() {
            0 => String::new(),
            1 => ", 1 more queued".to_string(),
            n => format!(", {n} more queued"),
        };
        let status = if progress >= 1.0 {
            format!("Waiting for {service} to process {name}...{queued}")
        } else {
            format!("Uploading {name} to {service} ({percent}%){queued}")
        };
        Self::with_progress(|mut p| {
            if *p.running() {
                p.as_mut().set_progress(progress);
                p.set_status_text(&status);
            }
        });
    }

    fn on_finished(mut self: Pin<&mut Self>, upload_id: u64, outcome: Result<(u16, String), String>) {
        if upload_id != self.upload_id {
            return;
        }
        let Some(item) = self.current.clone() else { return };
        let name = self.current_file_name.to_string();
        let service = self.current_service.to_string();
        let file_path = qs(&item.file_path);
        match outcome {
            Ok((status, text)) if (status == 200 || status == 201) && (text.starts_with("http://") || text.starts_with("https://")) => {
                self.as_mut().rust_mut().last_url = qs(&text);
                self.as_mut().last_url_changed();
                native::ffi::clipboard_set_text(&qs(&text));
                self.as_mut().upload_finished(true, &qs(&text), &file_path);
                if let Some(mut ops) = registry::FILE_OPERATIONS.get() {
                    ops.as_mut().push_completed_task(true, &format!("Uploaded {name} to {service}"), &text);
                    ops.operation_finished(true, &qs(&format!("Uploaded {name} to {service}: {text}")));
                }
            }
            Ok((status, text)) if status == 200 || status == 201 => {
                self.as_mut().upload_finished(false, &qs(&text), &file_path);
                self.report_failure(&format!("{service} upload failed for {name}: {text}"), true);
            }
            Ok((status, text)) => {
                let err = format!("HTTP {status} {text}").trim().to_string();
                self.as_mut().upload_finished(false, &qs(&err), &file_path);
                self.report_failure(&format!("{service} upload error for {name}: {err}"), true);
            }
            Err(err) => {
                self.as_mut().upload_finished(false, &qs(&err), &file_path);
                self.report_failure(&format!("{service} upload error for {name}: {err}"), true);
            }
        }
        self.process_next();
    }

    fn upload_file(self: Pin<&mut Self>, file_path: &QString) {
        if !file_path.is_empty() {
            self.upload_list(vec![file_path.to_string()], false, "");
        }
    }

    fn upload_files(self: Pin<&mut Self>, file_paths: &QStringList) {
        self.upload_list(from_qsl(file_paths), false, "");
    }

    fn upload_to_litterbox(self: Pin<&mut Self>, file_path: &QString, time: &QString) {
        if !file_path.is_empty() {
            self.upload_list(vec![file_path.to_string()], true, &time.to_string());
        }
    }

    fn upload_to_litterbox_default(self: Pin<&mut Self>, file_path: &QString) {
        self.upload_to_litterbox(file_path, &qs("24h"));
    }

    fn upload_files_to_litterbox(self: Pin<&mut Self>, file_paths: &QStringList, time: &QString) {
        self.upload_list(from_qsl(file_paths), true, &time.to_string());
    }

    fn upload_files_to_litterbox_default(self: Pin<&mut Self>, file_paths: &QStringList) {
        self.upload_list(from_qsl(file_paths), true, "24h");
    }

    fn cancel_upload(mut self: Pin<&mut Self>) {
        {
            let mut rust = self.as_mut().rust_mut();
            rust.queue.clear();
            rust.cancel.store(true, Ordering::Relaxed);
            rust.upload_id += 1;
            rust.current = None;
        }
        if self.is_uploading {
            self.as_mut().set_state(false, "", "");
        }
        self.clear_shared_progress("Upload cancelled");
    }
}
