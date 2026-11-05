//! AppController: preferences and remembered UI state, persisted to
//! QSettings("astra-atlas", "atlas"). The plain properties below are
//! generated from one table; see the bottom of the file for the rest.

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
        include!("cxx-qt-lib/qstringlist.h");
        type QStringList = cxx_qt_lib::QStringList;
        include!("cxx-qt-lib/qmap.h");
        type QMap_QString_QVariant = cxx_qt_lib::QMap<cxx_qt_lib::QMapPair_QString_QVariant>;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        #[qproperty(bool, show_hidden, cxx_name = "showHidden", READ, WRITE = set_show_hidden, NOTIFY = show_hidden_changed)]
        #[qproperty(bool, opaque_hidden, cxx_name = "opaqueHidden", READ, WRITE = set_opaque_hidden, NOTIFY = opaque_hidden_changed)]
        #[qproperty(bool, confirm_permanent_delete, cxx_name = "confirmPermanentDelete", READ, WRITE = set_confirm_permanent_delete, NOTIFY = confirm_permanent_delete_changed)]
        #[qproperty(bool, restore_tabs, cxx_name = "restoreTabs", READ, WRITE = set_restore_tabs, NOTIFY = restore_tabs_changed)]
        #[qproperty(bool, confirm_move_to_trash, cxx_name = "confirmMoveToTrash", READ, WRITE = set_confirm_move_to_trash, NOTIFY = confirm_move_to_trash_changed)]
        #[qproperty(i32, date_format, cxx_name = "dateFormat", READ, WRITE = set_date_format, NOTIFY = date_format_changed)]
        #[qproperty(QString, custom_date_format, cxx_name = "customDateFormat", READ, WRITE = set_custom_date_format, NOTIFY = custom_date_format_changed)]
        #[qproperty(bool, thumbnails_enabled, cxx_name = "thumbnailsEnabled", READ, WRITE = set_thumbnails_enabled, NOTIFY = thumbnails_enabled_changed)]
        #[qproperty(i32, thumbnail_max_mb, cxx_name = "thumbnailMaxMb", READ, WRITE = set_thumbnail_max_mb, NOTIFY = thumbnail_max_mb_changed)]
        #[qproperty(bool, show_size_column, cxx_name = "showSizeColumn", READ, WRITE = set_show_size_column, NOTIFY = show_size_column_changed)]
        #[qproperty(bool, show_type_column, cxx_name = "showTypeColumn", READ, WRITE = set_show_type_column, NOTIFY = show_type_column_changed)]
        #[qproperty(bool, show_date_column, cxx_name = "showDateColumn", READ, WRITE = set_show_date_column, NOTIFY = show_date_column_changed)]
        #[qproperty(bool, show_permissions_column, cxx_name = "showPermissionsColumn", READ, WRITE = set_show_permissions_column, NOTIFY = show_permissions_column_changed)]
        #[qproperty(bool, single_click, cxx_name = "singleClick", READ, WRITE = set_single_click, NOTIFY = single_click_changed)]
        #[qproperty(bool, drag_to_scroll, cxx_name = "dragToScroll", READ, WRITE = set_drag_to_scroll, NOTIFY = drag_to_scroll_changed)]
        #[qproperty(QString, default_startup_directory, cxx_name = "defaultStartupDirectory", READ, WRITE = set_default_startup_directory, NOTIFY = default_startup_directory_changed)]
        #[qproperty(i32, default_view_mode, cxx_name = "defaultViewMode", READ, WRITE = set_default_view_mode, NOTIFY = default_view_mode_changed)]
        #[qproperty(i32, default_sort_field, cxx_name = "defaultSortField", READ, WRITE = set_default_sort_field, NOTIFY = default_sort_field_changed)]
        #[qproperty(i32, default_sort_order, cxx_name = "defaultSortOrder", READ, WRITE = set_default_sort_order, NOTIFY = default_sort_order_changed)]
        #[qproperty(bool, show_dirs_first, cxx_name = "showDirsFirst", READ, WRITE = set_show_dirs_first, NOTIFY = show_dirs_first_changed)]
        #[qproperty(bool, case_sensitive_sort, cxx_name = "caseSensitiveSort", READ, WRITE = set_case_sensitive_sort, NOTIFY = case_sensitive_sort_changed)]
        #[qproperty(bool, directory_specific_views, cxx_name = "directorySpecificViews", READ, WRITE = set_directory_specific_views, NOTIFY = directory_specific_views_changed)]
        #[qproperty(bool, vim_motions, cxx_name = "vimMotions", READ, WRITE = set_vim_motions, NOTIFY = vim_motions_changed)]
        #[qproperty(bool, show_free_space, cxx_name = "showFreeSpace", READ, WRITE = set_show_free_space, NOTIFY = show_free_space_changed)]
        #[qproperty(i32, places_icon_size, cxx_name = "placesIconSize", READ, WRITE = set_places_icon_size, NOTIFY = places_icon_size_changed)]
        #[qproperty(i32, icon_zoom_level, cxx_name = "iconZoomLevel", READ, WRITE = set_icon_zoom_level, NOTIFY = icon_zoom_level_changed)]
        #[qproperty(i32, sidebar_width, cxx_name = "sidebarWidth", READ, WRITE = set_sidebar_width, NOTIFY = sidebar_width_changed)]
        #[qproperty(bool, expandable_folders, cxx_name = "expandableFolders", READ, WRITE = set_expandable_folders, NOTIFY = expandable_folders_changed)]
        #[qproperty(i32, folder_item_count, cxx_name = "folderItemCount", READ, WRITE = set_folder_item_count, NOTIFY = folder_item_count_changed)]
        #[qproperty(bool, menu_show_secondary_editor, cxx_name = "menuShowSecondaryEditor", READ, WRITE = set_menu_show_secondary_editor, NOTIFY = menu_preferences_changed)]
        #[qproperty(bool, menu_show_upload_online, cxx_name = "menuShowUploadOnline", READ, WRITE = set_menu_show_upload_online, NOTIFY = menu_preferences_changed)]
        #[qproperty(bool, menu_show_send_to, cxx_name = "menuShowSendTo", READ, WRITE = set_menu_show_send_to, NOTIFY = menu_preferences_changed)]
        #[qproperty(bool, menu_show_compress, cxx_name = "menuShowCompress", READ, WRITE = set_menu_show_compress, NOTIFY = menu_preferences_changed)]
        #[qproperty(bool, menu_show_symlink, cxx_name = "menuShowSymlink", READ, WRITE = set_menu_show_symlink, NOTIFY = menu_preferences_changed)]
        #[qproperty(bool, menu_show_terminal, cxx_name = "menuShowTerminal", READ, WRITE = set_menu_show_terminal, NOTIFY = menu_preferences_changed)]
        #[qproperty(bool, menu_show_delete, cxx_name = "menuShowDelete", READ, WRITE = set_menu_show_delete, NOTIFY = menu_preferences_changed)]
        #[qproperty(bool, show_network_section, cxx_name = "showNetworkSection", READ, WRITE = set_show_network_section, NOTIFY = show_network_section_changed)]
        #[qproperty(f64, scroll_speed, cxx_name = "scrollSpeed", READ, WRITE = set_scroll_speed, NOTIFY = scroll_speed_changed)]
        #[qproperty(QMap_QString_QVariant, details_column_widths, cxx_name = "detailsColumnWidths", READ = details_column_widths, NOTIFY = details_column_widths_changed)]
        #[qproperty(QStringList, details_column_order, cxx_name = "detailsColumnOrder", READ = details_column_order, NOTIFY = details_column_order_changed)]
        #[qproperty(i32, icon_theme_version, cxx_name = "iconThemeVersion", READ, NOTIFY = icon_theme_version_changed)]
        type AppController = super::AppControllerRust;

        #[qsignal]
        #[cxx_name = "showHiddenChanged"]
        fn show_hidden_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "opaqueHiddenChanged"]
        fn opaque_hidden_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "confirmPermanentDeleteChanged"]
        fn confirm_permanent_delete_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "restoreTabsChanged"]
        fn restore_tabs_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "confirmMoveToTrashChanged"]
        fn confirm_move_to_trash_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "dateFormatChanged"]
        fn date_format_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "customDateFormatChanged"]
        fn custom_date_format_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "thumbnailsEnabledChanged"]
        fn thumbnails_enabled_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "thumbnailMaxMbChanged"]
        fn thumbnail_max_mb_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "showSizeColumnChanged"]
        fn show_size_column_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "showTypeColumnChanged"]
        fn show_type_column_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "showDateColumnChanged"]
        fn show_date_column_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "showPermissionsColumnChanged"]
        fn show_permissions_column_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "singleClickChanged"]
        fn single_click_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "dragToScrollChanged"]
        fn drag_to_scroll_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "defaultStartupDirectoryChanged"]
        fn default_startup_directory_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "defaultViewModeChanged"]
        fn default_view_mode_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "defaultSortFieldChanged"]
        fn default_sort_field_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "defaultSortOrderChanged"]
        fn default_sort_order_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "showDirsFirstChanged"]
        fn show_dirs_first_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "caseSensitiveSortChanged"]
        fn case_sensitive_sort_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "directorySpecificViewsChanged"]
        fn directory_specific_views_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "vimMotionsChanged"]
        fn vim_motions_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "showFreeSpaceChanged"]
        fn show_free_space_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "placesIconSizeChanged"]
        fn places_icon_size_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "iconZoomLevelChanged"]
        fn icon_zoom_level_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "sidebarWidthChanged"]
        fn sidebar_width_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "expandableFoldersChanged"]
        fn expandable_folders_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "folderItemCountChanged"]
        fn folder_item_count_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "menuPreferencesChanged"]
        fn menu_preferences_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "showNetworkSectionChanged"]
        fn show_network_section_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "scrollSpeedChanged"]
        fn scroll_speed_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "detailsColumnWidthsChanged"]
        fn details_column_widths_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "detailsColumnOrderChanged"]
        fn details_column_order_changed(self: Pin<&mut AppController>);
        #[qsignal]
        #[cxx_name = "iconThemeVersionChanged"]
        fn icon_theme_version_changed(self: Pin<&mut AppController>);

        #[cxx_name = "setShowHidden"]
        fn set_show_hidden(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setOpaqueHidden"]
        fn set_opaque_hidden(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setConfirmPermanentDelete"]
        fn set_confirm_permanent_delete(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setRestoreTabs"]
        fn set_restore_tabs(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setConfirmMoveToTrash"]
        fn set_confirm_move_to_trash(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setDateFormat"]
        fn set_date_format(self: Pin<&mut AppController>, value: i32);
        #[cxx_name = "setCustomDateFormat"]
        fn set_custom_date_format(self: Pin<&mut AppController>, value: QString);
        #[cxx_name = "setThumbnailsEnabled"]
        fn set_thumbnails_enabled(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setThumbnailMaxMb"]
        fn set_thumbnail_max_mb(self: Pin<&mut AppController>, value: i32);
        #[cxx_name = "setShowSizeColumn"]
        fn set_show_size_column(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setShowTypeColumn"]
        fn set_show_type_column(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setShowDateColumn"]
        fn set_show_date_column(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setShowPermissionsColumn"]
        fn set_show_permissions_column(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setSingleClick"]
        fn set_single_click(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setDragToScroll"]
        fn set_drag_to_scroll(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setDefaultStartupDirectory"]
        fn set_default_startup_directory(self: Pin<&mut AppController>, value: QString);
        #[cxx_name = "setDefaultViewMode"]
        fn set_default_view_mode(self: Pin<&mut AppController>, value: i32);
        #[cxx_name = "setDefaultSortField"]
        fn set_default_sort_field(self: Pin<&mut AppController>, value: i32);
        #[cxx_name = "setDefaultSortOrder"]
        fn set_default_sort_order(self: Pin<&mut AppController>, value: i32);
        #[cxx_name = "setShowDirsFirst"]
        fn set_show_dirs_first(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setCaseSensitiveSort"]
        fn set_case_sensitive_sort(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setDirectorySpecificViews"]
        fn set_directory_specific_views(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setVimMotions"]
        fn set_vim_motions(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setShowFreeSpace"]
        fn set_show_free_space(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setPlacesIconSize"]
        fn set_places_icon_size(self: Pin<&mut AppController>, value: i32);
        #[cxx_name = "setIconZoomLevel"]
        fn set_icon_zoom_level(self: Pin<&mut AppController>, value: i32);
        #[cxx_name = "setSidebarWidth"]
        fn set_sidebar_width(self: Pin<&mut AppController>, value: i32);
        #[cxx_name = "setExpandableFolders"]
        fn set_expandable_folders(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setFolderItemCount"]
        fn set_folder_item_count(self: Pin<&mut AppController>, value: i32);
        #[cxx_name = "setMenuShowSecondaryEditor"]
        fn set_menu_show_secondary_editor(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setMenuShowUploadOnline"]
        fn set_menu_show_upload_online(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setMenuShowSendTo"]
        fn set_menu_show_send_to(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setMenuShowCompress"]
        fn set_menu_show_compress(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setMenuShowSymlink"]
        fn set_menu_show_symlink(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setMenuShowTerminal"]
        fn set_menu_show_terminal(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setMenuShowDelete"]
        fn set_menu_show_delete(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setShowNetworkSection"]
        fn set_show_network_section(self: Pin<&mut AppController>, value: bool);
        #[cxx_name = "setScrollSpeed"]
        fn set_scroll_speed(self: Pin<&mut AppController>, value: f64);

        #[cxx_name = "detailsColumnWidths"]
        fn details_column_widths(self: &AppController) -> QMap_QString_QVariant;
        #[cxx_name = "detailsColumnOrder"]
        fn details_column_order(self: &AppController) -> QStringList;

        #[qinvokable]
        #[cxx_name = "triggerIconReload"]
        fn trigger_icon_reload(self: Pin<&mut AppController>);
        #[qinvokable]
        #[cxx_name = "shiftPressed"]
        fn shift_pressed(self: &AppController) -> bool;
        #[qinvokable]
        #[cxx_name = "setDetailsColumnWidth"]
        fn set_details_column_width(self: Pin<&mut AppController>, key: &QString, width: i32);
        #[qinvokable]
        #[cxx_name = "resetDetailsColumnWidths"]
        fn reset_details_column_widths(self: Pin<&mut AppController>);
        #[qinvokable]
        #[cxx_name = "setDetailsColumnOrder"]
        fn set_details_column_order(self: Pin<&mut AppController>, order: &QStringList);
        #[qinvokable]
        #[cxx_name = "resetDetailsColumnOrder"]
        fn reset_details_column_order(self: Pin<&mut AppController>);
        #[qinvokable]
        #[cxx_name = "directoryView"]
        fn directory_view(self: &AppController, path: &QString) -> QMap_QString_QVariant;
        #[qinvokable]
        #[cxx_name = "rememberDirectoryView"]
        fn remember_directory_view(self: Pin<&mut AppController>, path: &QString, view_mode: i32, sort_field: i32, sort_order: i32);
        #[qinvokable]
        #[cxx_name = "forgetDirectoryViews"]
        fn forget_directory_views(self: Pin<&mut AppController>);
        #[qinvokable]
        #[cxx_name = "resetScrollSpeed"]
        fn reset_scroll_speed(self: Pin<&mut AppController>);
    }

    impl cxx_qt::Constructor<()> for AppController {}
}

use crate::bridge::native::{self, from_qsl, qs, qsl, settings, to_qvariant_map, QVariantMap};
use crate::bridge::registry;
use crate::core::fileutils;
use cxx_qt::CxxQtType;
use cxx_qt_lib::{QString, QStringList};
use serde_json::{json, Map, Value};
use std::pin::Pin;

const DEFAULT_COLUMN_ORDER: &[&str] = &["size", "type", "date", "perms", "origPath", "deleted"];

fn sanitise_column_order(order: &[String]) -> Vec<String> {
    let mut result: Vec<String> = Vec::new();
    for key in order {
        if DEFAULT_COLUMN_ORDER.contains(&key.as_str()) && !result.contains(key) {
            result.push(key.clone());
        }
    }
    for key in DEFAULT_COLUMN_ORDER {
        if !result.iter().any(|k| k == key) {
            result.push(key.to_string());
        }
    }
    result
}

fn json_setting(key: &str) -> Map<String, Value> {
    serde_json::from_str::<Value>(&settings::string(key, ""))
        .ok()
        .and_then(|v| v.as_object().cloned())
        .unwrap_or_default()
}

pub struct AppControllerRust {
    show_hidden: bool,
    opaque_hidden: bool,
    confirm_permanent_delete: bool,
    restore_tabs: bool,
    confirm_move_to_trash: bool,
    date_format: i32,
    custom_date_format: QString,
    thumbnails_enabled: bool,
    thumbnail_max_mb: i32,
    show_size_column: bool,
    show_type_column: bool,
    show_date_column: bool,
    show_permissions_column: bool,
    single_click: bool,
    drag_to_scroll: bool,
    default_startup_directory: QString,
    default_view_mode: i32,
    default_sort_field: i32,
    default_sort_order: i32,
    show_dirs_first: bool,
    case_sensitive_sort: bool,
    directory_specific_views: bool,
    vim_motions: bool,
    show_free_space: bool,
    places_icon_size: i32,
    icon_zoom_level: i32,
    sidebar_width: i32,
    expandable_folders: bool,
    folder_item_count: i32,
    menu_show_secondary_editor: bool,
    menu_show_upload_online: bool,
    menu_show_send_to: bool,
    menu_show_compress: bool,
    menu_show_symlink: bool,
    menu_show_terminal: bool,
    menu_show_delete: bool,
    show_network_section: bool,
    scroll_speed: f64,
    details_column_widths: Map<String, Value>,
    details_column_order: Vec<String>,
    directory_views: Map<String, Value>,
    icon_theme_version: i32,
}

impl Default for AppControllerRust {
    fn default() -> Self {
        let speed = settings::double("preferences/scrollSpeed", 1.0);
        let s = Self {
            show_hidden: settings::bool_with_legacy("session/showHidden", false),
            opaque_hidden: settings::bool("preferences/opaqueHidden", false),
            confirm_permanent_delete: settings::bool("session/confirmPermanentDelete", true),
            restore_tabs: settings::bool("preferences/restoreTabs", false),
            confirm_move_to_trash: settings::bool("session/confirmMoveToTrash", false),
            date_format: settings::int("preferences/dateFormat", 1),
            custom_date_format: qs(&settings::string("preferences/customDateFormat", "yyyy-MM-dd hh:mm")),
            thumbnails_enabled: settings::bool("preferences/thumbnailsEnabled", true),
            thumbnail_max_mb: settings::int("preferences/thumbnailMaxMb", 0),
            show_size_column: settings::bool("preferences/showSizeColumn", true),
            show_type_column: settings::bool("preferences/showTypeColumn", true),
            show_date_column: settings::bool("preferences/showDateColumn", true),
            show_permissions_column: settings::bool("preferences/showPermissionsColumn", true),
            single_click: settings::bool_with_legacy("session/singleClick", false),
            drag_to_scroll: settings::bool_with_legacy("session/dragToScroll", false),
            default_startup_directory: qs(&settings::string("preferences/startupDirectory", "home")),
            default_view_mode: settings::int("preferences/defaultViewMode", 0),
            default_sort_field: settings::int("preferences/defaultSortField", 0),
            default_sort_order: settings::int("preferences/defaultSortOrder", 0),
            show_dirs_first: settings::bool("preferences/showDirsFirst", true),
            case_sensitive_sort: settings::bool("preferences/caseSensitiveSort", false),
            directory_specific_views: settings::bool("preferences/directorySpecificViews", false),
            vim_motions: settings::bool("preferences/vimMotions", true),
            show_free_space: settings::bool("preferences/showFreeSpace", true),
            places_icon_size: settings::int("preferences/placesIconSize", 20),
            icon_zoom_level: settings::int("session/iconZoomLevel", 80).clamp(48, 180),
            sidebar_width: settings::int("session/sidebarWidth", 230).clamp(160, 480),
            expandable_folders: settings::bool("preferences/expandableFolders", false),
            folder_item_count: settings::int("preferences/folderItemCount", 0),
            menu_show_secondary_editor: settings::bool("contextMenu/showSecondaryEditor", true),
            menu_show_upload_online: settings::bool("contextMenu/showUploadOnline", true),
            menu_show_send_to: settings::bool("contextMenu/showSendTo", true),
            menu_show_compress: settings::bool("contextMenu/showCompress", true),
            menu_show_symlink: settings::bool("contextMenu/showSymlink", true),
            menu_show_terminal: settings::bool("contextMenu/showTerminal", true),
            menu_show_delete: settings::bool("contextMenu/showDelete", true),
            show_network_section: settings::bool("preferences/showNetworkSection", false),
            scroll_speed: settings::double("preferences/scrollSpeed", 1.0),
            details_column_widths: json_setting("preferences/detailsColumnWidths"),
            details_column_order: sanitise_column_order(&settings::string_list("preferences/detailsColumnOrder")),
            directory_views: json_setting("preferences/directoryViews"),
            icon_theme_version: 0,
        };
        let mut s = s;
        if speed <= 0.05 {
            s.scroll_speed = 1.0;
        }
        fileutils::set_folder_count_mode(s.folder_item_count);
        fileutils::set_custom_date_format(&s.custom_date_format.to_string());
        fileutils::set_date_format(s.date_format);
        fileutils::set_thumbnails_enabled(s.thumbnails_enabled);
        fileutils::set_thumbnail_max_bytes(s.thumbnail_max_mb as i64 * 1024 * 1024);
        s
    }
}

impl cxx_qt::Initialize for qobject::AppController {
    fn initialize(mut self: Pin<&mut Self>) {
        if crate::cli::options().show_hidden {
            self.as_mut().set_show_hidden(true);
        }
        registry::APP_CONTROLLER.set(self);
    }
}

impl qobject::AppController {
    pub fn set_show_hidden(mut self: Pin<&mut Self>, value: bool) {
        if self.show_hidden == value {
            return;
        }
        settings::set_bool("session/showHidden", value);
        self.as_mut().rust_mut().show_hidden = value;
        self.show_hidden_changed();
    }

    pub fn set_opaque_hidden(mut self: Pin<&mut Self>, value: bool) {
        if self.opaque_hidden == value {
            return;
        }
        settings::set_bool("preferences/opaqueHidden", value);
        self.as_mut().rust_mut().opaque_hidden = value;
        self.opaque_hidden_changed();
    }

    pub fn set_confirm_permanent_delete(mut self: Pin<&mut Self>, value: bool) {
        if self.confirm_permanent_delete == value {
            return;
        }
        settings::set_bool("session/confirmPermanentDelete", value);
        self.as_mut().rust_mut().confirm_permanent_delete = value;
        self.confirm_permanent_delete_changed();
    }

    pub fn set_restore_tabs(mut self: Pin<&mut Self>, value: bool) {
        if self.restore_tabs == value {
            return;
        }
        settings::set_bool("preferences/restoreTabs", value);
        self.as_mut().rust_mut().restore_tabs = value;
        self.restore_tabs_changed();
    }

    pub fn set_confirm_move_to_trash(mut self: Pin<&mut Self>, value: bool) {
        if self.confirm_move_to_trash == value {
            return;
        }
        settings::set_bool("session/confirmMoveToTrash", value);
        self.as_mut().rust_mut().confirm_move_to_trash = value;
        self.confirm_move_to_trash_changed();
    }

    pub fn set_date_format(mut self: Pin<&mut Self>, value: i32) {
        if self.date_format == value {
            return;
        }
        fileutils::set_date_format(value);
        settings::set_int("preferences/dateFormat", value);
        self.as_mut().rust_mut().date_format = value;
        self.date_format_changed();
    }

    pub fn set_custom_date_format(mut self: Pin<&mut Self>, value: QString) {
        if self.custom_date_format == value {
            return;
        }
        fileutils::set_custom_date_format(&value.to_string());
        settings::set_string("preferences/customDateFormat", &value.to_string());
        self.as_mut().rust_mut().custom_date_format = value;
        self.custom_date_format_changed();
    }

    pub fn set_thumbnails_enabled(mut self: Pin<&mut Self>, value: bool) {
        if self.thumbnails_enabled == value {
            return;
        }
        fileutils::set_thumbnails_enabled(value);
        settings::set_bool("preferences/thumbnailsEnabled", value);
        self.as_mut().rust_mut().thumbnails_enabled = value;
        self.thumbnails_enabled_changed();
    }

    pub fn set_thumbnail_max_mb(mut self: Pin<&mut Self>, value: i32) {
        if self.thumbnail_max_mb == value {
            return;
        }
        fileutils::set_thumbnail_max_bytes(value as i64 * 1024 * 1024);
        settings::set_int("preferences/thumbnailMaxMb", value);
        self.as_mut().rust_mut().thumbnail_max_mb = value;
        self.thumbnail_max_mb_changed();
    }

    pub fn set_show_size_column(mut self: Pin<&mut Self>, value: bool) {
        if self.show_size_column == value {
            return;
        }
        settings::set_bool("preferences/showSizeColumn", value);
        self.as_mut().rust_mut().show_size_column = value;
        self.show_size_column_changed();
    }

    pub fn set_show_type_column(mut self: Pin<&mut Self>, value: bool) {
        if self.show_type_column == value {
            return;
        }
        settings::set_bool("preferences/showTypeColumn", value);
        self.as_mut().rust_mut().show_type_column = value;
        self.show_type_column_changed();
    }

    pub fn set_show_date_column(mut self: Pin<&mut Self>, value: bool) {
        if self.show_date_column == value {
            return;
        }
        settings::set_bool("preferences/showDateColumn", value);
        self.as_mut().rust_mut().show_date_column = value;
        self.show_date_column_changed();
    }

    pub fn set_show_permissions_column(mut self: Pin<&mut Self>, value: bool) {
        if self.show_permissions_column == value {
            return;
        }
        settings::set_bool("preferences/showPermissionsColumn", value);
        self.as_mut().rust_mut().show_permissions_column = value;
        self.show_permissions_column_changed();
    }

    pub fn set_single_click(mut self: Pin<&mut Self>, value: bool) {
        if self.single_click == value {
            return;
        }
        settings::set_bool("session/singleClick", value);
        self.as_mut().rust_mut().single_click = value;
        self.single_click_changed();
    }

    pub fn set_drag_to_scroll(mut self: Pin<&mut Self>, value: bool) {
        if self.drag_to_scroll == value {
            return;
        }
        settings::set_bool("session/dragToScroll", value);
        self.as_mut().rust_mut().drag_to_scroll = value;
        self.drag_to_scroll_changed();
    }

    pub fn set_default_startup_directory(mut self: Pin<&mut Self>, value: QString) {
        if self.default_startup_directory == value {
            return;
        }
        settings::set_string("preferences/startupDirectory", &value.to_string());
        self.as_mut().rust_mut().default_startup_directory = value;
        self.default_startup_directory_changed();
    }

    pub fn set_default_view_mode(mut self: Pin<&mut Self>, value: i32) {
        if self.default_view_mode == value {
            return;
        }
        settings::set_int("preferences/defaultViewMode", value);
        self.as_mut().rust_mut().default_view_mode = value;
        self.default_view_mode_changed();
    }

    pub fn set_default_sort_field(mut self: Pin<&mut Self>, value: i32) {
        if self.default_sort_field == value {
            return;
        }
        settings::set_int("preferences/defaultSortField", value);
        self.as_mut().rust_mut().default_sort_field = value;
        self.default_sort_field_changed();
    }

    pub fn set_default_sort_order(mut self: Pin<&mut Self>, value: i32) {
        if self.default_sort_order == value {
            return;
        }
        settings::set_int("preferences/defaultSortOrder", value);
        self.as_mut().rust_mut().default_sort_order = value;
        self.default_sort_order_changed();
    }

    pub fn set_show_dirs_first(mut self: Pin<&mut Self>, value: bool) {
        if self.show_dirs_first == value {
            return;
        }
        settings::set_bool("preferences/showDirsFirst", value);
        self.as_mut().rust_mut().show_dirs_first = value;
        self.show_dirs_first_changed();
    }

    pub fn set_case_sensitive_sort(mut self: Pin<&mut Self>, value: bool) {
        if self.case_sensitive_sort == value {
            return;
        }
        settings::set_bool("preferences/caseSensitiveSort", value);
        self.as_mut().rust_mut().case_sensitive_sort = value;
        self.case_sensitive_sort_changed();
    }

    pub fn set_directory_specific_views(mut self: Pin<&mut Self>, value: bool) {
        if self.directory_specific_views == value {
            return;
        }
        settings::set_bool("preferences/directorySpecificViews", value);
        self.as_mut().rust_mut().directory_specific_views = value;
        self.directory_specific_views_changed();
    }

    pub fn set_vim_motions(mut self: Pin<&mut Self>, value: bool) {
        if self.vim_motions == value {
            return;
        }
        settings::set_bool("preferences/vimMotions", value);
        self.as_mut().rust_mut().vim_motions = value;
        self.vim_motions_changed();
    }

    pub fn set_show_free_space(mut self: Pin<&mut Self>, value: bool) {
        if self.show_free_space == value {
            return;
        }
        settings::set_bool("preferences/showFreeSpace", value);
        self.as_mut().rust_mut().show_free_space = value;
        self.show_free_space_changed();
    }

    pub fn set_places_icon_size(mut self: Pin<&mut Self>, value: i32) {
        if self.places_icon_size == value || value <= 0 {
            return;
        }
        settings::set_int("preferences/placesIconSize", value);
        self.as_mut().rust_mut().places_icon_size = value;
        self.places_icon_size_changed();
    }

    pub fn set_icon_zoom_level(mut self: Pin<&mut Self>, value: i32) {
        let value = value.clamp(48, 180);
        if self.icon_zoom_level == value {
            return;
        }
        settings::set_int("session/iconZoomLevel", value);
        self.as_mut().rust_mut().icon_zoom_level = value;
        self.icon_zoom_level_changed();
    }

    pub fn set_sidebar_width(mut self: Pin<&mut Self>, value: i32) {
        let value = value.clamp(160, 480);
        if self.sidebar_width == value {
            return;
        }
        settings::set_int("session/sidebarWidth", value);
        self.as_mut().rust_mut().sidebar_width = value;
        self.sidebar_width_changed();
    }

    pub fn set_expandable_folders(mut self: Pin<&mut Self>, value: bool) {
        if self.expandable_folders == value {
            return;
        }
        settings::set_bool("preferences/expandableFolders", value);
        self.as_mut().rust_mut().expandable_folders = value;
        self.expandable_folders_changed();
    }

    pub fn set_folder_item_count(mut self: Pin<&mut Self>, value: i32) {
        if self.folder_item_count == value {
            return;
        }
        fileutils::set_folder_count_mode(value);
        settings::set_int("preferences/folderItemCount", value);
        self.as_mut().rust_mut().folder_item_count = value;
        self.folder_item_count_changed();
    }

    pub fn set_menu_show_secondary_editor(mut self: Pin<&mut Self>, value: bool) {
        if self.menu_show_secondary_editor == value {
            return;
        }
        settings::set_bool("contextMenu/showSecondaryEditor", value);
        self.as_mut().rust_mut().menu_show_secondary_editor = value;
        self.menu_preferences_changed();
    }

    pub fn set_menu_show_upload_online(mut self: Pin<&mut Self>, value: bool) {
        if self.menu_show_upload_online == value {
            return;
        }
        settings::set_bool("contextMenu/showUploadOnline", value);
        self.as_mut().rust_mut().menu_show_upload_online = value;
        self.menu_preferences_changed();
    }

    pub fn set_menu_show_send_to(mut self: Pin<&mut Self>, value: bool) {
        if self.menu_show_send_to == value {
            return;
        }
        settings::set_bool("contextMenu/showSendTo", value);
        self.as_mut().rust_mut().menu_show_send_to = value;
        self.menu_preferences_changed();
    }

    pub fn set_menu_show_compress(mut self: Pin<&mut Self>, value: bool) {
        if self.menu_show_compress == value {
            return;
        }
        settings::set_bool("contextMenu/showCompress", value);
        self.as_mut().rust_mut().menu_show_compress = value;
        self.menu_preferences_changed();
    }

    pub fn set_menu_show_symlink(mut self: Pin<&mut Self>, value: bool) {
        if self.menu_show_symlink == value {
            return;
        }
        settings::set_bool("contextMenu/showSymlink", value);
        self.as_mut().rust_mut().menu_show_symlink = value;
        self.menu_preferences_changed();
    }

    pub fn set_menu_show_terminal(mut self: Pin<&mut Self>, value: bool) {
        if self.menu_show_terminal == value {
            return;
        }
        settings::set_bool("contextMenu/showTerminal", value);
        self.as_mut().rust_mut().menu_show_terminal = value;
        self.menu_preferences_changed();
    }

    pub fn set_menu_show_delete(mut self: Pin<&mut Self>, value: bool) {
        if self.menu_show_delete == value {
            return;
        }
        settings::set_bool("contextMenu/showDelete", value);
        self.as_mut().rust_mut().menu_show_delete = value;
        self.menu_preferences_changed();
    }

    pub fn set_show_network_section(mut self: Pin<&mut Self>, value: bool) {
        if self.show_network_section == value {
            return;
        }
        settings::set_bool("preferences/showNetworkSection", value);
        self.as_mut().rust_mut().show_network_section = value;
        self.show_network_section_changed();
    }

    pub fn set_scroll_speed(mut self: Pin<&mut Self>, value: f64) {
        if (self.scroll_speed - value).abs() < 1e-12 {
            return;
        }
        settings::set_double("preferences/scrollSpeed", value);
        self.as_mut().rust_mut().scroll_speed = value;
        self.scroll_speed_changed();
    }

    fn details_column_widths(&self) -> QVariantMap {
        to_qvariant_map(&Value::Object(self.details_column_widths.clone())).unwrap_or_default()
    }

    fn details_column_order(&self) -> QStringList {
        qsl(&self.details_column_order)
    }

    pub fn trigger_icon_reload(mut self: Pin<&mut Self>) {
        native::ffi::clear_icon_cache();
        self.as_mut().rust_mut().icon_theme_version += 1;
        self.icon_theme_version_changed();
    }

    fn shift_pressed(&self) -> bool {
        native::ffi::query_keyboard_modifiers() & 0x0200_0000 != 0
    }

    fn set_details_column_width(mut self: Pin<&mut Self>, key: &QString, width: i32) {
        let clamped = width.clamp(48, 800);
        let key = key.to_string();
        if self.details_column_widths.get(&key).and_then(Value::as_i64) == Some(clamped as i64) {
            return;
        }
        self.as_mut().rust_mut().details_column_widths.insert(key, json!(clamped));
        settings::set_string("preferences/detailsColumnWidths", &Value::Object(self.details_column_widths.clone()).to_string());
        self.details_column_widths_changed();
    }

    fn reset_details_column_widths(mut self: Pin<&mut Self>) {
        if self.details_column_widths.is_empty() {
            return;
        }
        self.as_mut().rust_mut().details_column_widths.clear();
        settings::remove("preferences/detailsColumnWidths");
        self.details_column_widths_changed();
    }

    fn set_details_column_order(mut self: Pin<&mut Self>, order: &QStringList) {
        let sanitised = sanitise_column_order(&from_qsl(order));
        if self.details_column_order == sanitised {
            return;
        }
        settings::set_string_list("preferences/detailsColumnOrder", &sanitised);
        self.as_mut().rust_mut().details_column_order = sanitised;
        self.details_column_order_changed();
    }

    fn reset_details_column_order(mut self: Pin<&mut Self>) {
        if self.details_column_order.iter().eq(DEFAULT_COLUMN_ORDER.iter()) {
            return;
        }
        self.as_mut().rust_mut().details_column_order = DEFAULT_COLUMN_ORDER.iter().map(|s| s.to_string()).collect();
        settings::remove("preferences/detailsColumnOrder");
        self.details_column_order_changed();
    }

    fn directory_view(&self, path: &QString) -> QVariantMap {
        let path = path.to_string();
        if !self.directory_specific_views || path.is_empty() {
            return QVariantMap::default();
        }
        self.directory_views.get(&path).and_then(to_qvariant_map).unwrap_or_default()
    }

    fn remember_directory_view(mut self: Pin<&mut Self>, path: &QString, view_mode: i32, sort_field: i32, sort_order: i32) {
        let path = path.to_string();
        if !self.directory_specific_views || path.is_empty() {
            return;
        }
        let entry = json!({ "viewMode": view_mode, "sortField": sort_field, "sortOrder": sort_order });
        if self.directory_views.get(&path) == Some(&entry) {
            return;
        }
        let mut views = std::mem::take(&mut self.as_mut().rust_mut().directory_views);
        views.shift_remove(&path);
        views.insert(path, entry);
        while views.len() > 300 {
            let Some(oldest) = views.keys().next().cloned() else { break };
            views.shift_remove(&oldest);
        }
        settings::set_string("preferences/directoryViews", &Value::Object(views.clone()).to_string());
        self.as_mut().rust_mut().directory_views = views;
    }

    fn forget_directory_views(mut self: Pin<&mut Self>) {
        if self.directory_views.is_empty() {
            return;
        }
        self.as_mut().rust_mut().directory_views.clear();
        settings::remove("preferences/directoryViews");
    }

    fn reset_scroll_speed(self: Pin<&mut Self>) {
        self.set_scroll_speed(1.0);
    }
}
