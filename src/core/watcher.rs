//! A small inotify file watcher standing in for QFileSystemWatcher. Events
//! arrive on a background thread; callers hop back to the Qt thread.

use std::collections::HashMap;
use std::ffi::CString;
use std::sync::{Arc, Mutex};

type Callback = Box<dyn Fn(&str) + Send + Sync>;

struct Shared {
    fd: i32,
    wake_fd: i32,
    // watch descriptor -> watched path
    watches: Mutex<HashMap<i32, String>>,
}

pub struct Watcher {
    shared: Arc<Shared>,
}

const MASK: u32 = libc::IN_MODIFY
    | libc::IN_CLOSE_WRITE
    | libc::IN_ATTRIB
    | libc::IN_CREATE
    | libc::IN_DELETE
    | libc::IN_DELETE_SELF
    | libc::IN_MOVE_SELF
    | libc::IN_MOVED_FROM
    | libc::IN_MOVED_TO;

impl Watcher {
    /// `callback` receives the watched path (file or directory) that changed.
    pub fn new(callback: impl Fn(&str) + Send + Sync + 'static) -> Option<Watcher> {
        let fd = unsafe { libc::inotify_init1(libc::IN_NONBLOCK | libc::IN_CLOEXEC) };
        if fd < 0 {
            return None;
        }
        let wake_fd = unsafe { libc::eventfd(0, libc::EFD_NONBLOCK | libc::EFD_CLOEXEC) };
        if wake_fd < 0 {
            unsafe { libc::close(fd) };
            return None;
        }
        let shared = Arc::new(Shared { fd, wake_fd, watches: Mutex::new(HashMap::new()) });
        let thread_shared = shared.clone();
        let callback: Callback = Box::new(callback);
        std::thread::Builder::new()
            .name("atlas-watcher".into())
            .spawn(move || run(thread_shared, callback))
            .ok()?;
        Some(Watcher { shared })
    }

    pub fn add_path(&self, path: &str) -> bool {
        let Ok(c) = CString::new(path) else { return false };
        let wd = unsafe { libc::inotify_add_watch(self.shared.fd, c.as_ptr(), MASK) };
        if wd < 0 {
            return false;
        }
        self.shared.watches.lock().unwrap().insert(wd, path.to_string());
        true
    }

    pub fn remove_path(&self, path: &str) {
        let mut watches = self.shared.watches.lock().unwrap();
        let wds: Vec<i32> = watches.iter().filter(|(_, p)| p.as_str() == path).map(|(wd, _)| *wd).collect();
        for wd in wds {
            unsafe { libc::inotify_rm_watch(self.shared.fd, wd) };
            watches.remove(&wd);
        }
    }

    pub fn clear(&self) {
        let mut watches = self.shared.watches.lock().unwrap();
        for wd in watches.keys() {
            unsafe { libc::inotify_rm_watch(self.shared.fd, *wd) };
        }
        watches.clear();
    }

    pub fn paths(&self) -> Vec<String> {
        self.shared.watches.lock().unwrap().values().cloned().collect()
    }

    pub fn is_watching(&self, path: &str) -> bool {
        self.shared.watches.lock().unwrap().values().any(|p| p == path)
    }
}

impl Drop for Watcher {
    fn drop(&mut self) {
        let one: u64 = 1;
        unsafe { libc::write(self.shared.wake_fd, &one as *const u64 as *const libc::c_void, 8) };
    }
}

fn run(shared: Arc<Shared>, callback: Callback) {
    let mut buf = [0u8; 8192];
    loop {
        let mut fds = [
            libc::pollfd { fd: shared.fd, events: libc::POLLIN, revents: 0 },
            libc::pollfd { fd: shared.wake_fd, events: libc::POLLIN, revents: 0 },
        ];
        let n = unsafe { libc::poll(fds.as_mut_ptr(), 2, -1) };
        if n < 0 {
            if std::io::Error::last_os_error().kind() == std::io::ErrorKind::Interrupted {
                continue;
            }
            break;
        }
        if fds[1].revents != 0 {
            break;
        }
        let len = unsafe { libc::read(shared.fd, buf.as_mut_ptr() as *mut libc::c_void, buf.len()) };
        if len <= 0 {
            continue;
        }
        let mut changed: Vec<String> = Vec::new();
        let mut offset = 0usize;
        while offset + std::mem::size_of::<libc::inotify_event>() <= len as usize {
            let event = unsafe { &*(buf.as_ptr().add(offset) as *const libc::inotify_event) };
            let mut watches = shared.watches.lock().unwrap();
            if let Some(path) = watches.get(&event.wd).cloned() {
                if !changed.contains(&path) {
                    changed.push(path);
                }
                // A deleted or moved watch target is gone for good, like
                // QFileSystemWatcher dropping the path.
                if event.mask & (libc::IN_DELETE_SELF | libc::IN_MOVE_SELF | libc::IN_IGNORED) != 0 {
                    watches.remove(&event.wd);
                }
            }
            offset += std::mem::size_of::<libc::inotify_event>() + event.len as usize;
        }
        for path in changed {
            callback(&path);
        }
    }
    unsafe {
        libc::close(shared.fd);
        libc::close(shared.wake_fd);
    }
}
