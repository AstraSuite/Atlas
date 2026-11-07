//! GitManager: branch, recent commits and pull/fetch for the git modal.

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
        include!("cxx-qt-lib/qstringlist.h");
        type QStringList = cxx_qt_lib::QStringList;
        include!("cxx-qt-lib/qlist.h");
        type QList_QVariant = cxx_qt_lib::QList<cxx_qt_lib::QVariant>;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        #[qproperty(QString, current_path, cxx_name = "currentPath", READ, WRITE = set_current_path, NOTIFY = current_path_changed)]
        #[qproperty(bool, is_git_repo, cxx_name = "isGitRepo", READ, NOTIFY = repo_changed)]
        #[qproperty(QString, branch_name, cxx_name = "branchName", READ, NOTIFY = repo_changed)]
        #[qproperty(QStringList, branches, READ = branches, NOTIFY = repo_changed)]
        #[qproperty(QList_QVariant, commits, READ = commits, NOTIFY = repo_changed)]
        #[qproperty(bool, is_operating, cxx_name = "isOperating", READ, NOTIFY = operating_changed)]
        #[qproperty(QString, last_status_message, cxx_name = "lastStatusMessage", READ, NOTIFY = status_message_changed)]
        type GitManager = super::GitManagerRust;

        #[qsignal]
        #[cxx_name = "currentPathChanged"]
        fn current_path_changed(self: Pin<&mut GitManager>);
        #[qsignal]
        #[cxx_name = "repoChanged"]
        fn repo_changed(self: Pin<&mut GitManager>);
        #[qsignal]
        #[cxx_name = "operatingChanged"]
        fn operating_changed(self: Pin<&mut GitManager>);
        #[qsignal]
        #[cxx_name = "statusMessageChanged"]
        fn status_message_changed(self: Pin<&mut GitManager>);

        #[cxx_name = "setCurrentPath"]
        fn set_current_path(self: Pin<&mut GitManager>, path: QString);
        fn branches(self: &GitManager) -> QStringList;
        fn commits(self: &GitManager) -> QList_QVariant;

        #[qinvokable]
        #[cxx_name = "checkRepo"]
        fn check_repo(self: Pin<&mut GitManager>);
        #[qinvokable]
        #[cxx_name = "switchBranch"]
        fn switch_branch(self: Pin<&mut GitManager>, branch: &QString);
        #[qinvokable]
        fn pull(self: Pin<&mut GitManager>);
        #[qinvokable]
        fn fetch(self: Pin<&mut GitManager>);
    }

    impl cxx_qt::Threading for GitManager {}
}

use crate::bridge::native::{qs, qsl, to_qvariant_list};
use crate::core::{desktop, paths};
use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::{QList, QString, QStringList, QVariant};
use qobject::GitManager;
use serde_json::{json, Value};
use std::pin::Pin;
use std::process::{Command, Stdio};

fn find_git_root(start: &str) -> Option<String> {
    if start.is_empty() {
        return None;
    }
    let mut dir = paths::clean_path(start);
    loop {
        if paths::exists(&format!("{dir}/.git")) {
            return Some(dir);
        }
        if dir == "/" || dir.is_empty() {
            return None;
        }
        dir = paths::parent(&dir);
    }
}

/// Runs git in `root`, giving up after `timeout_ms`: (success, stdout, stderr).
fn git(root: &str, args: &[&str], timeout_ms: u64) -> (bool, String, String) {
    let mut cmd_args = vec!["-C", root];
    cmd_args.extend_from_slice(args);
    match desktop::run_timeout("git", &cmd_args, timeout_ms) {
        Some((code, out, err)) => (code == 0, out, err),
        None => (false, String::new(), String::new()),
    }
}

struct RepoInfo {
    branch: String,
    branches: Vec<String>,
    commits: Vec<Value>,
}

fn read_repo(root: &str) -> RepoInfo {
    let head = std::fs::read_to_string(format!("{root}/.git/HEAD")).unwrap_or_default();
    let head = head.lines().next().unwrap_or("").trim();
    let branch = match head.strip_prefix("ref: refs/heads/") {
        Some(b) => b.to_string(),
        None if head.len() >= 7 => head[..7].to_string(),
        None => String::new(),
    };
    let (ok, out, _) = git(root, &["branch", "--list", "--no-color"], 2000);
    let branches = if ok {
        out.lines()
            .map(|l| l.trim().trim_start_matches('*').trim().to_string())
            .filter(|l| !l.is_empty())
            .collect()
    } else {
        Vec::new()
    };
    let (ok, out, _) = git(root, &["log", "-n", "20", "--format=%h|%s|%an|%cr"], 2000);
    let commits = if ok {
        out.lines()
            .filter_map(|line| {
                let parts: Vec<&str> = line.split('|').collect();
                (parts.len() >= 4).then(|| json!({ "hash": parts[0], "subject": parts[1], "author": parts[2], "time": parts[3] }))
            })
            .collect()
    } else {
        Vec::new()
    };
    RepoInfo { branch, branches, commits }
}

#[derive(Default)]
pub struct GitManagerRust {
    current_path: QString,
    is_git_repo: bool,
    branch_name: QString,
    branches: Vec<String>,
    commits: Vec<Value>,
    is_operating: bool,
    last_status_message: QString,
}

impl GitManager {
    fn set_current_path(mut self: Pin<&mut Self>, path: QString) {
        if self.current_path != path {
            self.as_mut().rust_mut().current_path = path;
            self.as_mut().current_path_changed();
            self.check_repo();
        }
    }

    fn branches(&self) -> QStringList {
        qsl(&self.branches)
    }

    fn commits(&self) -> QList<QVariant> {
        to_qvariant_list(&self.commits)
    }

    fn set_repo(mut self: Pin<&mut Self>, info: Option<RepoInfo>) {
        {
            let mut rust = self.as_mut().rust_mut();
            rust.is_git_repo = info.is_some();
            let info = info.unwrap_or(RepoInfo { branch: String::new(), branches: Vec::new(), commits: Vec::new() });
            rust.branch_name = qs(&info.branch);
            rust.branches = info.branches;
            rust.commits = info.commits;
        }
        self.repo_changed();
    }

    fn check_repo(self: Pin<&mut Self>) {
        let search = self.current_path.to_string();
        if search.is_empty() {
            self.set_repo(None);
            return;
        }
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let info = find_git_root(&search).map(|root| read_repo(&root));
            let _ = thread.queue(move |git| git.set_repo(info));
        });
    }

    fn set_status(mut self: Pin<&mut Self>, operating: bool, message: &str) {
        {
            let mut rust = self.as_mut().rust_mut();
            rust.is_operating = operating;
            rust.last_status_message = qs(message);
        }
        self.as_mut().operating_changed();
        self.status_message_changed();
    }

    /// Runs one git command in the background, then reports and rechecks.
    fn run_operation(
        mut self: Pin<&mut Self>,
        start_message: String,
        args: Vec<String>,
        describe: impl FnOnce(bool, String, String) -> String + Send + 'static,
    ) {
        let Some(root) = find_git_root(&self.current_path.to_string()) else { return };
        self.as_mut().set_status(true, &start_message);
        let thread = self.qt_thread();
        std::thread::spawn(move || {
            let mut cmd = Command::new("git");
            cmd.current_dir(&root).args(&args).stdin(Stdio::null());
            let (ok, out, err) = match cmd.output() {
                Ok(o) => (
                    o.status.success(),
                    String::from_utf8_lossy(&o.stdout).trim().to_string(),
                    String::from_utf8_lossy(&o.stderr).trim().to_string(),
                ),
                Err(e) => (false, String::new(), e.to_string()),
            };
            let message = describe(ok, out, err);
            let _ = thread.queue(move |mut git| {
                git.as_mut().set_status(false, &message);
                git.check_repo();
            });
        });
    }

    fn switch_branch(self: Pin<&mut Self>, branch: &QString) {
        let branch = branch.to_string();
        if branch.is_empty() {
            return;
        }
        let start = format!("Switching to branch {branch}...");
        let args = vec!["switch".to_string(), branch.clone()];
        self.run_operation(start, args, move |ok, _, err| {
            if ok {
                format!("Switched to {branch}")
            } else if err.is_empty() {
                "Failed to switch branch".into()
            } else {
                err
            }
        });
    }

    fn pull(self: Pin<&mut Self>) {
        self.run_operation("Pulling latest changes...".into(), vec!["pull".into()], |ok, out, err| {
            if ok {
                if out.is_empty() { "Pull successful".into() } else { out }
            } else if err.is_empty() {
                "Pull failed".into()
            } else {
                err
            }
        });
    }

    fn fetch(self: Pin<&mut Self>) {
        self.run_operation("Fetching remote updates...".into(), vec!["fetch".into()], |ok, _, _| {
            if ok { "Fetch completed".into() } else { "Fetch failed".into() }
        });
    }
}
