//! NetworkManager: SFTP, SMB, FTP, NFS and WebDAV mounts through gio/GVFS.

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
        include!("cxx-qt-lib/qstringlist.h");
        type QStringList = cxx_qt_lib::QStringList;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        #[qproperty(bool, is_connecting, cxx_name = "isConnecting", READ, NOTIFY = is_connecting_changed)]
        #[qproperty(QString, last_error, cxx_name = "lastError", READ, NOTIFY = last_error_changed)]
        #[qproperty(QString, last_mounted_path, cxx_name = "lastMountedPath", READ, NOTIFY = last_mounted_path_changed)]
        #[qproperty(QStringList, supported_schemes, cxx_name = "supportedSchemes", READ = supported_schemes, CONSTANT)]
        type NetworkManager = super::NetworkManagerRust;

        #[qsignal]
        #[cxx_name = "isConnectingChanged"]
        fn is_connecting_changed(self: Pin<&mut NetworkManager>);
        #[qsignal]
        #[cxx_name = "lastErrorChanged"]
        fn last_error_changed(self: Pin<&mut NetworkManager>);
        #[qsignal]
        #[cxx_name = "lastMountedPathChanged"]
        fn last_mounted_path_changed(self: Pin<&mut NetworkManager>);
        #[qsignal]
        #[cxx_name = "connectionFinished"]
        fn connection_finished(self: Pin<&mut NetworkManager>, success: bool, local_path: &QString, error_message: &QString);
        #[qsignal]
        fn unmounted(self: Pin<&mut NetworkManager>, path: &QString);

        #[cxx_name = "supportedSchemes"]
        fn supported_schemes(self: &NetworkManager) -> QStringList;

        #[qinvokable]
        #[cxx_name = "connectSftp"]
        fn connect_sftp(self: Pin<&mut NetworkManager>, host: &QString, port: i32, user: &QString, path: &QString, password: &QString, save_bookmark: bool);
        #[qinvokable]
        #[cxx_name = "connectServer"]
        fn connect_server(
            self: Pin<&mut NetworkManager>,
            scheme: &QString,
            host: &QString,
            port: i32,
            user: &QString,
            path: &QString,
            password: &QString,
            save_bookmark: bool,
        );
        #[qinvokable]
        #[cxx_name = "defaultPort"]
        fn default_port(self: &NetworkManager, scheme: &QString) -> i32;
        #[qinvokable]
        #[cxx_name = "connectUri"]
        fn connect_uri(self: Pin<&mut NetworkManager>, uri: &QString, password: &QString, save_bookmark: bool);
        #[qinvokable]
        #[cxx_name = "connectUri"]
        fn connect_uri_default(self: Pin<&mut NetworkManager>, uri: &QString);
        #[qinvokable]
        fn unmount(self: Pin<&mut NetworkManager>, path_or_uri: &QString);
        #[qinvokable]
        #[cxx_name = "findLocalMountPath"]
        fn find_local_mount_path(self: &NetworkManager, uri: &QString) -> QString;
        #[qinvokable]
        #[cxx_name = "getActiveRemoteMounts"]
        fn get_active_remote_mounts(self: &NetworkManager) -> QStringList;
    }

    impl cxx_qt::Threading for NetworkManager {}
}

use crate::bridge::native::{qs, qsl};
use crate::bridge::registry;
use crate::core::desktop::DesktopFile;
use crate::core::paths;
use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::{QString, QStringList};
use qobject::NetworkManager;
use std::io::{Read, Write};
use std::pin::Pin;
use std::process::{Command, Stdio};
use std::sync::OnceLock;

/// The parts of a URI the GVFS mount lookup needs.
struct Uri {
    scheme: String,
    user: String,
    host: String,
}

fn parse_uri(uri: &str) -> Uri {
    let (scheme, rest) = uri.split_once("://").unwrap_or(("", uri));
    let authority = rest.split(['/', '?', '#']).next().unwrap_or("");
    let (userinfo, hostport) = match authority.rsplit_once('@') {
        Some((u, h)) => (u, h),
        None => ("", authority),
    };
    let host = if hostport.starts_with('[') {
        hostport.split(']').next().unwrap_or("").trim_start_matches('[').to_string()
    } else {
        hostport.split(':').next().unwrap_or("").to_string()
    };
    let user = paths::decode(userinfo.split(':').next().unwrap_or(""));
    Uri { scheme: scheme.to_lowercase(), user, host: host.to_lowercase() }
}

fn gvfs_dir() -> String {
    format!("/run/user/{}/gvfs", unsafe { libc::getuid() })
}

fn gvfs_entries() -> Vec<String> {
    let Ok(entries) = std::fs::read_dir(gvfs_dir()) else { return Vec::new() };
    let mut list: Vec<String> = entries
        .flatten()
        .filter(|e| e.path().is_dir())
        .map(|e| e.path().to_string_lossy().into_owned())
        .collect();
    list.sort();
    list
}

fn resolve_gvfs_path(uri: &str) -> String {
    let parsed = parse_uri(uri);
    let user = parsed.user.to_lowercase();
    let entries = gvfs_entries();
    for path in &entries {
        let name = paths::file_name(path).to_lowercase();
        if name.starts_with(&parsed.scheme)
            && (parsed.host.is_empty() || name.contains(&parsed.host))
            && (user.is_empty() || name.contains(&user))
        {
            return path.clone();
        }
    }
    if parsed.host.is_empty() {
        if let Some(first) = entries.first() {
            return first.clone();
        }
    }
    String::new()
}

fn supported_schemes() -> &'static Vec<String> {
    static SCHEMES: OnceLock<Vec<String>> = OnceLock::new();
    SCHEMES.get_or_init(|| {
        let mut dirs: Vec<String> = std::env::var("XDG_DATA_DIRS")
            .unwrap_or_default()
            .split(':')
            .filter(|s| !s.is_empty())
            .map(String::from)
            .collect();
        if dirs.is_empty() {
            dirs = vec!["/usr/local/share".into(), "/usr/share".into()];
        }
        let mut found: Vec<String> = Vec::new();
        for dir in dirs {
            let Ok(entries) = std::fs::read_dir(format!("{dir}/gvfs/mounts")) else { continue };
            let mut files: Vec<String> = entries
                .flatten()
                .map(|e| e.path().to_string_lossy().into_owned())
                .filter(|p| p.ends_with(".mount"))
                .collect();
            files.sort();
            for file in files {
                let Some(mount) = DesktopFile::load(&file) else { continue };
                let scheme = mount.get("Mount", "Scheme");
                let aliases = mount.get("Mount", "SchemeAliases");
                for s in std::iter::once(scheme.as_str()).chain(aliases.split(',')) {
                    let s = s.trim();
                    if !s.is_empty() && !found.iter().any(|f| f == s) {
                        found.push(s.to_string());
                    }
                }
            }
        }
        found
    })
}

pub fn default_port(scheme: &str) -> i32 {
    match scheme.to_lowercase().as_str() {
        "sftp" | "ssh" => 22,
        "ftp" => 21,
        "ftps" => 990,
        "smb" => 445,
        "nfs" => 2049,
        "dav" => 80,
        "davs" => 443,
        "afp" => 548,
        _ => 0,
    }
}

#[derive(Default)]
pub struct NetworkManagerRust {
    is_connecting: bool,
    last_error: QString,
    last_mounted_path: QString,
    /// The gio mount in flight, killed if another connection starts.
    current_pid: Option<u32>,
    connect_id: u64,
}

impl NetworkManager {
    fn supported_schemes(&self) -> QStringList {
        qsl(supported_schemes())
    }

    fn default_port(&self, scheme: &QString) -> i32 {
        default_port(&scheme.to_string())
    }

    fn connect_sftp(self: Pin<&mut Self>, host: &QString, port: i32, user: &QString, path: &QString, password: &QString, save_bookmark: bool) {
        self.connect_server(&qs("sftp"), host, port, user, path, password, save_bookmark);
    }

    #[allow(clippy::too_many_arguments)]
    fn connect_server(
        self: Pin<&mut Self>,
        scheme: &QString,
        host: &QString,
        port: i32,
        user: &QString,
        path: &QString,
        password: &QString,
        save_bookmark: bool,
    ) {
        let host = host.to_string();
        if host.is_empty() {
            self.connection_finished(false, &QString::default(), &qs("Host cannot be empty"));
            return;
        }
        let scheme = scheme.to_string();
        let scheme = if scheme.is_empty() { "sftp".to_string() } else { scheme.to_lowercase() };
        let mut remote = path.to_string();
        if remote.is_empty() {
            remote = "/".into();
        }
        if !remote.starts_with('/') {
            remote.insert(0, '/');
        }
        let mut uri = format!("{scheme}://");
        let user = user.to_string();
        if !user.is_empty() {
            let encoded = percent_encoding::utf8_percent_encode(&user, percent_encoding::NON_ALPHANUMERIC).to_string();
            uri.push_str(&format!("{encoded}@"));
        }
        uri.push_str(&host);
        if port > 0 && port != default_port(&scheme) {
            uri.push_str(&format!(":{port}"));
        }
        uri.push_str(&remote);
        self.connect_uri_impl(uri, password.to_string(), save_bookmark);
    }

    fn connect_uri(self: Pin<&mut Self>, uri: &QString, password: &QString, save_bookmark: bool) {
        self.connect_uri_impl(uri.to_string(), password.to_string(), save_bookmark);
    }

    fn connect_uri_default(self: Pin<&mut Self>, uri: &QString) {
        self.connect_uri_impl(uri.to_string(), String::new(), true);
    }

    fn connect_uri_impl(mut self: Pin<&mut Self>, uri: String, password: String, save_bookmark: bool) {
        if uri.is_empty() {
            self.connection_finished(false, &QString::default(), &qs("URI cannot be empty"));
            return;
        }
        let uri = if uri.contains("://") { uri } else { format!("sftp://{uri}") };

        let existing = resolve_gvfs_path(&uri);
        if !existing.is_empty() && paths::is_dir(&existing) {
            self.as_mut().rust_mut().last_mounted_path = qs(&existing);
            self.as_mut().last_mounted_path_changed();
            self.connection_finished(true, &qs(&existing), &QString::default());
            return;
        }

        if let Some(pid) = self.as_mut().rust_mut().current_pid.take() {
            unsafe { libc::kill(pid as i32, libc::SIGKILL) };
        }
        let connect_id = self.connect_id + 1;
        {
            let mut rust = self.as_mut().rust_mut();
            rust.connect_id = connect_id;
            rust.is_connecting = true;
            rust.last_error = QString::default();
        }
        self.as_mut().is_connecting_changed();
        self.as_mut().last_error_changed();

        let child = Command::new("gio")
            .args(["mount", &uri])
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn();
        let mut child = match child {
            Ok(c) => c,
            Err(e) => {
                self.on_mount_finished(connect_id, uri, save_bookmark, -1, e.to_string());
                return;
            }
        };
        self.as_mut().rust_mut().current_pid = Some(child.id());
        if let Some(mut stdin) = child.stdin.take() {
            if !password.is_empty() {
                let _ = stdin.write_all(format!("{password}\n").as_bytes());
            }
        }
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let mut stderr = String::new();
            if let Some(mut err) = child.stderr.take() {
                let _ = err.read_to_string(&mut stderr);
            }
            let code = child.wait().ok().and_then(|s| s.code()).unwrap_or(-1);
            let _ = thread.queue(move |nm| nm.on_mount_finished(connect_id, uri, save_bookmark, code, stderr.trim().to_string()));
        });
    }

    fn on_mount_finished(mut self: Pin<&mut Self>, connect_id: u64, uri: String, save_bookmark: bool, exit_code: i32, stderr: String) {
        if connect_id != self.connect_id {
            return;
        }
        {
            let mut rust = self.as_mut().rust_mut();
            rust.current_pid = None;
            rust.is_connecting = false;
        }
        self.as_mut().is_connecting_changed();

        let local = resolve_gvfs_path(&uri);
        if exit_code == 0 || (!local.is_empty() && paths::is_dir(&local)) {
            let mounted = if local.is_empty() { uri.clone() } else { local };
            {
                let mut rust = self.as_mut().rust_mut();
                rust.last_mounted_path = qs(&mounted);
                rust.last_error = QString::default();
            }
            self.as_mut().last_mounted_path_changed();
            self.as_mut().last_error_changed();
            if save_bookmark {
                let parsed = parse_uri(&uri);
                let mut title = if parsed.host.is_empty() { uri.clone() } else { parsed.host.clone() };
                if !parsed.user.is_empty() {
                    title = format!("{}@{title}", parsed.user);
                }
                if let Some(places) = registry::PLACES_MODEL.get() {
                    places.add_bookmark_impl(&mounted, &title, "cloud");
                }
            }
            self.connection_finished(true, &qs(&mounted), &QString::default());
        } else {
            let error = if stderr.is_empty() { "Failed to connect to remote server".to_string() } else { stderr };
            self.as_mut().rust_mut().last_error = qs(&error);
            self.as_mut().last_error_changed();
            self.connection_finished(false, &QString::default(), &qs(&error));
        }
    }

    fn unmount(self: Pin<&mut Self>, path_or_uri: &QString) {
        let target = path_or_uri.to_string();
        if target.is_empty() {
            return;
        }
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let _ = Command::new("gio")
                .args(["mount", "-u", &target])
                .stdin(Stdio::null())
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .status();
            let _ = thread.queue(move |nm| {
                if let Some(places) = registry::PLACES_MODEL.get() {
                    places.remove_by_path(&target);
                }
                nm.unmounted(&qs(&target));
            });
        });
    }

    fn find_local_mount_path(&self, uri: &QString) -> QString {
        qs(&resolve_gvfs_path(&uri.to_string()))
    }

    fn get_active_remote_mounts(&self) -> QStringList {
        qsl(&gvfs_entries())
    }
}
