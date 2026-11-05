//! TabManager and TabItem: tabs, split panes, and per-tab history.

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!(<QtCore/QAbstractListModel>);
        type QAbstractListModel;

        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
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
        unsafe fn new_tab_item(parent: *mut TabManager) -> *mut TabItem;
        #[cxx_name = "atlasDeleteLater"]
        unsafe fn delete_tab_item(item: *mut TabItem);
    }

    extern "RustQt" {
        #[qobject]
        #[qproperty(QString, split_title, cxx_name = "splitTitle", READ = split_title, NOTIFY = split_path_changed)]
        #[qproperty(QString, current_path, cxx_name = "currentPath", READ, WRITE = set_current_path, NOTIFY = current_path_changed)]
        #[qproperty(QString, split_path, cxx_name = "splitPath", READ, WRITE = set_split_path, NOTIFY = split_path_changed)]
        #[qproperty(bool, is_split, cxx_name = "isSplit", READ, WRITE = set_is_split, NOTIFY = is_split_changed)]
        #[qproperty(i32, active_pane, cxx_name = "activePane", READ, WRITE = set_active_pane, NOTIFY = active_pane_changed)]
        #[qproperty(i32, view_mode, cxx_name = "viewMode", READ, WRITE = set_view_mode, NOTIFY = view_mode_changed)]
        #[qproperty(bool, can_go_back, cxx_name = "canGoBack", READ = can_go_back, NOTIFY = history_changed)]
        #[qproperty(bool, can_go_forward, cxx_name = "canGoForward", READ = can_go_forward, NOTIFY = history_changed)]
        type TabItem = super::TabItemRust;

        #[qsignal]
        #[cxx_name = "titleChanged"]
        fn title_changed(self: Pin<&mut TabItem>);
        #[qsignal]
        #[cxx_name = "currentPathChanged"]
        fn current_path_changed(self: Pin<&mut TabItem>);
        #[qsignal]
        #[cxx_name = "splitPathChanged"]
        fn split_path_changed(self: Pin<&mut TabItem>);
        #[qsignal]
        #[cxx_name = "isSplitChanged"]
        fn is_split_changed(self: Pin<&mut TabItem>);
        #[qsignal]
        #[cxx_name = "activePaneChanged"]
        fn active_pane_changed(self: Pin<&mut TabItem>);
        #[qsignal]
        #[cxx_name = "viewModeChanged"]
        fn view_mode_changed(self: Pin<&mut TabItem>);
        #[qsignal]
        #[cxx_name = "historyChanged"]
        fn history_changed(self: Pin<&mut TabItem>);

        #[cxx_name = "splitTitle"]
        fn split_title(self: &TabItem) -> QString;
        #[cxx_name = "canGoBack"]
        fn can_go_back(self: &TabItem) -> bool;
        #[cxx_name = "canGoForward"]
        fn can_go_forward(self: &TabItem) -> bool;
        #[cxx_name = "setCurrentPath"]
        fn set_current_path(self: Pin<&mut TabItem>, path: QString);
        #[cxx_name = "setSplitPath"]
        fn set_split_path(self: Pin<&mut TabItem>, path: QString);
        #[cxx_name = "setIsSplit"]
        fn set_is_split(self: Pin<&mut TabItem>, split: bool);
        #[cxx_name = "setActivePane"]
        fn set_active_pane(self: Pin<&mut TabItem>, pane: i32);
        #[cxx_name = "setViewMode"]
        fn set_view_mode(self: Pin<&mut TabItem>, mode: i32);

        #[qinvokable]
        #[cxx_name = "goBack"]
        fn go_back(self: Pin<&mut TabItem>);
        #[qinvokable]
        #[cxx_name = "goForward"]
        fn go_forward(self: Pin<&mut TabItem>);
        #[qinvokable]
        #[cxx_name = "goUp"]
        fn go_up(self: Pin<&mut TabItem>);
    }

    extern "RustQt" {
        #[qobject]
        #[base = QAbstractListModel]
        #[qml_element]
        #[qml_singleton]
        #[qproperty(i32, current_index, cxx_name = "currentIndex", READ, WRITE = set_current_index, NOTIFY = current_index_changed)]
        #[qproperty(*mut TabItem, current_tab, cxx_name = "currentTab", READ = current_tab, NOTIFY = current_tab_changed)]
        #[qproperty(i32, count, READ = count, NOTIFY = count_changed)]
        type TabManager = super::TabManagerRust;

        #[qsignal]
        #[cxx_name = "currentIndexChanged"]
        fn current_index_changed(self: Pin<&mut TabManager>);
        #[qsignal]
        #[cxx_name = "currentTabChanged"]
        fn current_tab_changed(self: Pin<&mut TabManager>);
        #[qsignal]
        #[cxx_name = "countChanged"]
        fn count_changed(self: Pin<&mut TabManager>);

        #[cxx_name = "setCurrentIndex"]
        fn set_current_index(self: Pin<&mut TabManager>, index: i32);
        #[cxx_name = "currentTab"]
        fn current_tab(self: &TabManager) -> *mut TabItem;
        fn count(self: &TabManager) -> i32;

        #[qinvokable]
        #[cxx_name = "newTab"]
        fn new_tab(self: Pin<&mut TabManager>, path: &QString, activate: bool);
        #[qinvokable]
        #[cxx_name = "newTab"]
        fn new_tab_path(self: Pin<&mut TabManager>, path: &QString);
        #[qinvokable]
        #[cxx_name = "newTab"]
        fn new_tab_default(self: Pin<&mut TabManager>);
        #[qinvokable]
        #[cxx_name = "closeTab"]
        fn close_tab(self: Pin<&mut TabManager>, index: i32);
        #[qinvokable]
        #[cxx_name = "duplicateTab"]
        fn duplicate_tab(self: Pin<&mut TabManager>, index: i32);
        #[qinvokable]
        #[cxx_name = "moveTab"]
        fn move_tab(self: Pin<&mut TabManager>, from_index: i32, to_index: i32);
        #[qinvokable]
        #[cxx_name = "toggleSplitView"]
        fn toggle_split_view(self: Pin<&mut TabManager>);
        #[qinvokable]
        #[cxx_name = "splitTabWith"]
        fn split_tab_with(self: Pin<&mut TabManager>, tab_index: i32, secondary_path: &QString);
        #[qinvokable]
        #[cxx_name = "closeSplitPane"]
        fn close_split_pane(self: Pin<&mut TabManager>, tab_index: i32, pane_index: i32);
    }

    unsafe extern "RustQt" {
        #[inherit]
        #[cxx_name = "beginInsertRows"]
        fn begin_insert_rows(self: Pin<&mut TabManager>, parent: &QModelIndex, first: i32, last: i32);
        #[inherit]
        #[cxx_name = "endInsertRows"]
        fn end_insert_rows(self: Pin<&mut TabManager>);
        #[inherit]
        #[cxx_name = "beginRemoveRows"]
        fn begin_remove_rows(self: Pin<&mut TabManager>, parent: &QModelIndex, first: i32, last: i32);
        #[inherit]
        #[cxx_name = "endRemoveRows"]
        fn end_remove_rows(self: Pin<&mut TabManager>);
        #[inherit]
        #[cxx_name = "beginMoveRows"]
        fn begin_move_rows(
            self: Pin<&mut TabManager>,
            source_parent: &QModelIndex,
            source_first: i32,
            source_last: i32,
            destination_parent: &QModelIndex,
            destination_child: i32,
        ) -> bool;
        #[inherit]
        #[cxx_name = "endMoveRows"]
        fn end_move_rows(self: Pin<&mut TabManager>);
        #[inherit]
        fn index(self: &TabManager, row: i32, column: i32, parent: &QModelIndex) -> QModelIndex;
        #[inherit]
        #[qsignal]
        #[cxx_name = "dataChanged"]
        fn data_changed(self: Pin<&mut TabManager>, top_left: &QModelIndex, bottom_right: &QModelIndex, roles: &QList_i32);

        #[cxx_override]
        fn data(self: &TabManager, index: &QModelIndex, role: i32) -> QVariant;
        #[cxx_override]
        #[cxx_name = "roleNames"]
        fn role_names(self: &TabManager) -> QHash_i32_QByteArray;
        #[cxx_override]
        #[cxx_name = "rowCount"]
        fn row_count(self: &TabManager, parent: &QModelIndex) -> i32;
    }

    impl cxx_qt::Constructor<()> for TabManager {}
}

use crate::bridge::native::{qs, settings};
use crate::bridge::registry;
use crate::core::{fileutils, paths};
use cxx_qt::casting::Upcast;
use cxx_qt::CxxQtType;
use cxx_qt_lib::{QByteArray, QHash, QHashPair_i32_QByteArray, QList, QModelIndex, QObjectMutPtr, QString, QVariant};
use qobject::{TabItem, TabManager};

/// Model roles, from Qt::UserRole + 1.
#[derive(Clone, Copy, PartialEq)]
#[repr(i32)]
enum TabRoles {
    TitleRole = 0x0101,
    PathRole,
    IsSplitRole,
    SplitTitleRole,
    SplitPathRole,
    ActivePaneRole,
    TabItemRole,
}
use std::pin::Pin;

fn title_for(path: &str) -> String {
    if path == paths::home() {
        "Home".to_string()
    } else if path == "/" {
        "Root".to_string()
    } else {
        let name = paths::file_name(path);
        if name.is_empty() { path.to_string() } else { name }
    }
}

pub struct TabItemRust {
    current_path: QString,
    split_path: QString,
    is_split: bool,
    active_pane: i32,
    view_mode: i32,
    title: String,
    history: Vec<String>,
    history_index: usize,
}

impl Default for TabItemRust {
    fn default() -> Self {
        let home = paths::home();
        Self {
            current_path: qs(&home),
            split_path: qs(&home),
            is_split: false,
            active_pane: 0,
            view_mode: 0,
            title: title_for(&home),
            history: vec![home],
            history_index: 0,
        }
    }
}

/// Tells the manager one of its tabs changed so the model rows update.
fn tab_item_changed(item: &TabItem, roles: &[TabRoles]) {
    if let Some(manager) = registry::TAB_MANAGER.get() {
        manager.tab_changed(item as *const TabItem, roles);
    }
}

impl TabItem {
    fn init_path(mut self: Pin<&mut Self>, initial_path: &str) {
        let path = if initial_path.is_empty() { paths::home() } else { fileutils::expand_path(initial_path, "") };
        let mut rust = self.as_mut().rust_mut();
        rust.current_path = qs(&path);
        rust.split_path = qs(&path);
        rust.history = vec![path];
        rust.history_index = 0;
        self.update_title();
    }

    pub fn title(&self) -> &str {
        &self.title
    }

    fn update_title(mut self: Pin<&mut Self>) {
        let path = if self.active_pane == 1 { self.split_path.to_string() } else { self.current_path.to_string() };
        self.as_mut().rust_mut().title = title_for(&path);
        self.as_mut().title_changed();
        tab_item_changed(&self, &[TabRoles::TitleRole]);
    }

    fn split_title(&self) -> QString {
        let p = if self.split_path.is_empty() { &self.current_path } else { &self.split_path };
        qs(&title_for(&p.to_string()))
    }

    fn can_go_back(&self) -> bool {
        self.history_index > 0
    }

    fn can_go_forward(&self) -> bool {
        self.history_index + 1 < self.history.len()
    }

    pub fn set_current_path(mut self: Pin<&mut Self>, path: QString) {
        let expanded = fileutils::expand_path(&path.to_string(), "");
        if self.current_path.to_string() == expanded {
            return;
        }
        {
            let mut rust = self.as_mut().rust_mut();
            rust.current_path = qs(&expanded);
            // Truncate forward history and append the new path.
            let keep = rust.history_index + 1;
            rust.history.truncate(keep);
            rust.history.push(expanded.clone());
            rust.history_index = rust.history.len() - 1;
        }
        self.as_mut().current_path_changed();
        self.as_mut().history_changed();
        if self.active_pane == 0 {
            self.as_mut().update_title();
        }
        settings::set_string("session/lastPath", &expanded);
        if let Some(manager) = registry::TAB_MANAGER.get() {
            manager.save_session();
        }
    }

    pub fn set_split_path(mut self: Pin<&mut Self>, path: QString) {
        let expanded = qs(&fileutils::expand_path(&path.to_string(), ""));
        if self.split_path == expanded {
            return;
        }
        self.as_mut().rust_mut().split_path = expanded;
        self.as_mut().split_path_changed();
        tab_item_changed(&self, &[TabRoles::SplitTitleRole, TabRoles::SplitPathRole]);
        if self.active_pane == 1 {
            self.update_title();
        }
    }

    pub fn set_is_split(mut self: Pin<&mut Self>, split: bool) {
        if self.is_split == split {
            return;
        }
        self.as_mut().rust_mut().is_split = split;
        if split && self.split_path.is_empty() {
            let current = self.current_path.clone();
            self.as_mut().rust_mut().split_path = current;
        }
        self.as_mut().is_split_changed();
        tab_item_changed(&self, &[TabRoles::IsSplitRole]);
    }

    pub fn set_active_pane(mut self: Pin<&mut Self>, pane: i32) {
        if self.active_pane == pane {
            return;
        }
        self.as_mut().rust_mut().active_pane = pane;
        self.as_mut().active_pane_changed();
        tab_item_changed(&self, &[TabRoles::ActivePaneRole, TabRoles::TitleRole]);
        self.update_title();
    }

    pub fn set_view_mode(mut self: Pin<&mut Self>, mode: i32) {
        if self.view_mode == mode {
            return;
        }
        self.as_mut().rust_mut().view_mode = mode;
        self.as_mut().view_mode_changed();
        settings::set_int("session/viewMode", mode);
    }

    fn step_history(mut self: Pin<&mut Self>, forward: bool) {
        {
            let mut rust = self.as_mut().rust_mut();
            rust.history_index = if forward { rust.history_index + 1 } else { rust.history_index - 1 };
            let path = rust.history[rust.history_index].clone();
            rust.current_path = qs(&path);
        }
        self.as_mut().current_path_changed();
        self.as_mut().history_changed();
        if self.active_pane == 0 {
            self.update_title();
        }
    }

    fn go_back(self: Pin<&mut Self>) {
        if self.can_go_back() {
            self.step_history(false);
        }
    }

    fn go_forward(self: Pin<&mut Self>) {
        if self.can_go_forward() {
            self.step_history(true);
        }
    }

    fn go_up(self: Pin<&mut Self>) {
        let split = self.active_pane == 1;
        let path = if split { self.split_path.to_string() } else { self.current_path.to_string() };
        let clean = paths::clean_path(&path);
        if clean == "/" || clean.is_empty() || !clean.starts_with('/') {
            return;
        }
        let up = qs(&paths::parent(&clean));
        if split {
            self.set_split_path(up);
        } else {
            self.set_current_path(up);
        }
    }
}

#[derive(Default)]
pub struct TabManagerRust {
    current_index: i32,
    tabs: Vec<*mut TabItem>,
}

impl cxx_qt::Initialize for TabManager {
    fn initialize(mut self: Pin<&mut Self>) {
        registry::TAB_MANAGER.set(self.as_mut());

        let startup_mode = settings::string("preferences/startupDirectory", "home");
        let home = paths::home();
        let mut startup_path = if startup_mode == "home" {
            home.clone()
        } else if startup_mode == "last" {
            [0, 1, 2]
                .into_iter()
                .find(|s| settings::legacy_contains(*s, "session/lastPath"))
                .map(|s| settings::legacy_string(s, "session/lastPath"))
                .unwrap_or_else(|| home.clone())
        } else if paths::is_dir(&startup_mode) {
            startup_mode
        } else {
            home.clone()
        };
        if startup_path.is_empty() || !paths::is_dir(&startup_path) {
            startup_path = home.clone();
        }

        // preferences/defaultViewMode, else the last session's view mode.
        let view_mode = if settings::contains("preferences/defaultViewMode") {
            settings::int("preferences/defaultViewMode", 0)
        } else {
            [0, 1, 2]
                .into_iter()
                .find(|s| settings::legacy_contains(*s, "session/viewMode"))
                .map(|s| settings::legacy_string(s, "session/viewMode").parse().unwrap_or(0))
                .unwrap_or(0)
        };

        let mut restored: Vec<String> = Vec::new();
        if settings::bool("preferences/restoreTabs", false) {
            for path in settings::string_list("session/tabPaths") {
                if !path.is_empty() && (paths::is_dir(&path) || path.starts_with("recent:")) {
                    restored.push(path);
                }
            }
        }
        if restored.is_empty() {
            self.as_mut().add_tab(&startup_path, true);
        } else {
            for path in &restored {
                self.as_mut().add_tab(path, true);
            }
            let saved = settings::int("session/currentTab", 0);
            self.as_mut().set_current_index(saved);
        }
        for tab in self.tabs.clone() {
            unsafe { Pin::new_unchecked(&mut *tab) }.set_view_mode(view_mode);
        }

        // A path given on the command line opens in the current tab.
        if let Some(dir) = &crate::cli::options().initial_dir {
            if let Some(tab) = self.tab_at(self.current_index) {
                tab.set_current_path(qs(dir));
            }
        }
    }
}

impl TabManager {
    fn tab_at(&self, index: i32) -> Option<Pin<&mut TabItem>> {
        let ptr = *self.tabs.get(usize::try_from(index).ok()?)?;
        Some(unsafe { Pin::new_unchecked(&mut *ptr) })
    }

    fn tab_ref(&self, index: usize) -> &TabItem {
        unsafe { &*self.tabs[index] }
    }

    fn tab_changed(mut self: Pin<&mut Self>, item: *const TabItem, roles: &[TabRoles]) {
        let Some(row) = self.tabs.iter().position(|t| *t as *const TabItem == item) else { return };
        let index = self.index(row as i32, 0, &QModelIndex::default());
        let mut list = QList::<i32>::default();
        for role in roles {
            list.append(*role as i32);
        }
        self.as_mut().data_changed(&index, &index, &list);
    }

    pub fn save_session(&self) {
        let paths: Vec<String> = (0..self.tabs.len()).map(|i| self.tab_ref(i).current_path.to_string()).collect();
        settings::set_string_list("session/tabPaths", &paths);
        settings::set_int("session/currentTab", self.current_index);
    }

    fn count(&self) -> i32 {
        self.tabs.len() as i32
    }

    fn current_tab(&self) -> *mut TabItem {
        self.tabs.get(self.current_index as usize).copied().unwrap_or(std::ptr::null_mut())
    }

    pub fn set_current_index(mut self: Pin<&mut Self>, index: i32) {
        if index >= 0 && (index as usize) < self.tabs.len() && self.current_index != index {
            self.as_mut().rust_mut().current_index = index;
            self.as_mut().current_index_changed();
            self.current_tab_changed();
        }
    }

    fn add_tab(mut self: Pin<&mut Self>, path: &str, activate: bool) {
        let path = if path.is_empty() {
            match self.tab_at(self.current_index) {
                Some(tab) => tab.current_path.to_string(),
                None => paths::home(),
            }
        } else {
            path.to_string()
        };
        let idx = self.tabs.len() as i32;
        self.as_mut().begin_insert_rows(&QModelIndex::default(), idx, idx);
        let me = unsafe { self.as_mut().get_unchecked_mut() as *mut TabManager };
        let tab = unsafe { qobject::new_tab_item(me) };
        unsafe { Pin::new_unchecked(&mut *tab) }.init_path(&path);
        self.as_mut().rust_mut().tabs.push(tab);
        self.as_mut().end_insert_rows();
        self.as_mut().count_changed();
        if activate {
            self.as_mut().set_current_index(idx);
        }
        self.save_session();
    }

    fn new_tab(self: Pin<&mut Self>, path: &QString, activate: bool) {
        self.add_tab(&path.to_string(), activate);
    }

    fn new_tab_path(self: Pin<&mut Self>, path: &QString) {
        self.add_tab(&path.to_string(), true);
    }

    fn new_tab_default(self: Pin<&mut Self>) {
        self.add_tab("", true);
    }

    fn close_tab(mut self: Pin<&mut Self>, index: i32) {
        if self.tabs.len() <= 1 || index < 0 || index as usize >= self.tabs.len() {
            return;
        }
        self.as_mut().begin_remove_rows(&QModelIndex::default(), index, index);
        let tab = self.as_mut().rust_mut().tabs.remove(index as usize);
        unsafe { qobject::delete_tab_item(tab) };
        self.as_mut().end_remove_rows();
        if self.current_index as usize >= self.tabs.len() {
            let last = self.tabs.len() as i32 - 1;
            self.as_mut().rust_mut().current_index = last;
            self.as_mut().current_index_changed();
        }
        self.as_mut().current_tab_changed();
        self.as_mut().count_changed();
        self.save_session();
    }

    fn duplicate_tab(self: Pin<&mut Self>, index: i32) {
        if index >= 0 && (index as usize) < self.tabs.len() {
            let path = self.tab_ref(index as usize).current_path.to_string();
            self.add_tab(&path, true);
        }
    }

    fn move_tab(mut self: Pin<&mut Self>, from: i32, to: i32) {
        let len = self.tabs.len() as i32;
        if from < 0 || from >= len || to < 0 || to >= len || from == to {
            return;
        }
        let dest = if to > from { to + 1 } else { to };
        let root = QModelIndex::default();
        self.as_mut().begin_move_rows(&root, from, from, &root, dest);
        {
            let mut rust = self.as_mut().rust_mut();
            let tab = rust.tabs.remove(from as usize);
            rust.tabs.insert(to as usize, tab);
        }
        self.as_mut().end_move_rows();
        let current = self.current_index;
        let new_current = if current == from {
            to
        } else if from < current && to >= current {
            current - 1
        } else if from > current && to <= current {
            current + 1
        } else {
            current
        };
        if new_current != current {
            self.as_mut().rust_mut().current_index = new_current;
            self.as_mut().current_index_changed();
            self.as_mut().current_tab_changed();
        }
    }

    fn toggle_split_view(self: Pin<&mut Self>) {
        if let Some(tab) = self.tab_at(self.current_index) {
            let split = tab.is_split;
            tab.set_is_split(!split);
        }
    }

    fn split_tab_with(mut self: Pin<&mut Self>, tab_index: i32, secondary_path: &QString) {
        let len = self.tabs.len() as i32;
        if tab_index < 0 || tab_index >= len {
            return;
        }
        if !secondary_path.is_empty() {
            let mut tab = self.tab_at(tab_index).unwrap();
            tab.as_mut().set_split_path(secondary_path.clone());
            tab.set_is_split(true);
            self.set_current_index(tab_index);
            return;
        }
        // Splitting another tab with the current one joins them in a split view.
        let current = self.current_index;
        if current != tab_index && current >= 0 && current < len {
            let target_path = self.tab_ref(tab_index as usize).current_path.clone();
            let mut active = self.tab_at(current).unwrap();
            active.as_mut().set_split_path(target_path);
            active.set_is_split(true);
            self.close_tab(tab_index);
            return;
        }
        // Splitting the current tab merges an adjacent one into it.
        if len > 1 {
            let other = if tab_index == 0 { 1 } else { tab_index - 1 };
            let other_path = self.tab_ref(other as usize).current_path.clone();
            let mut active = self.tab_at(tab_index).unwrap();
            active.as_mut().set_split_path(other_path);
            active.set_is_split(true);
            self.close_tab(other);
            return;
        }
        let mut tab = self.tab_at(tab_index).unwrap();
        let path = tab.current_path.clone();
        tab.as_mut().set_split_path(path);
        tab.set_is_split(true);
    }

    fn close_split_pane(self: Pin<&mut Self>, tab_index: i32, pane_index: i32) {
        if let Some(mut tab) = self.tab_at(tab_index) {
            if pane_index == 0 {
                let split = tab.split_path.clone();
                tab.as_mut().set_current_path(split);
            }
            tab.as_mut().set_is_split(false);
            tab.set_active_pane(0);
        }
    }

    fn row_count(&self, parent: &QModelIndex) -> i32 {
        if parent.is_valid() { 0 } else { self.tabs.len() as i32 }
    }

    fn data(&self, index: &QModelIndex, role: i32) -> QVariant {
        if !index.is_valid() || index.row() < 0 || index.row() as usize >= self.tabs.len() {
            return QVariant::default();
        }
        let tab = self.tab_ref(index.row() as usize);
        match role {
            r if r == TabRoles::TitleRole as i32 => QVariant::from(&qs(tab.title())),
            r if r == TabRoles::PathRole as i32 => QVariant::from(&tab.current_path),
            r if r == TabRoles::IsSplitRole as i32 => QVariant::from(&tab.is_split),
            r if r == TabRoles::SplitTitleRole as i32 => QVariant::from(&tab.split_title()),
            r if r == TabRoles::SplitPathRole as i32 => QVariant::from(&tab.split_path),
            r if r == TabRoles::ActivePaneRole as i32 => QVariant::from(&tab.active_pane),
            r if r == TabRoles::TabItemRole as i32 => {
                let object = unsafe { <TabItem as Upcast<cxx_qt::QObject>>::upcast_ptr(tab) } as *mut cxx_qt::QObject;
                QVariant::from(&unsafe { QObjectMutPtr::from_raw(object) })
            }
            _ => QVariant::default(),
        }
    }

    fn role_names(&self) -> QHash<QHashPair_i32_QByteArray> {
        let mut roles = QHash::<QHashPair_i32_QByteArray>::default();
        for (role, name) in [
            (TabRoles::TitleRole, "title"),
            (TabRoles::PathRole, "path"),
            (TabRoles::IsSplitRole, "isSplit"),
            (TabRoles::SplitTitleRole, "splitTitle"),
            (TabRoles::SplitPathRole, "splitPath"),
            (TabRoles::ActivePaneRole, "activePane"),
            (TabRoles::TabItemRole, "tabItem"),
        ] {
            roles.insert(role as i32, QByteArray::from(name));
        }
        roles
    }
}

