import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"
import "components/tabs"
import "components/navigation"
import "components/panels"
import "components/views"
import "components/statusbar"
import "components/menus"
import "components/dialogs"
import "components/filedialog"
import "components/media"
import prism

ApplicationWindow {
    id: window

    visible: true
    width: 1060
    height: 680
    minimumWidth: 520
    minimumHeight: 400
    color: Colours.tPalette.m3surfaceContainerLowest

    property bool pickerActive: typeof isPickerMode !== "undefined" ? isPickerMode : false
    property real zoomLevel: 80

    // Full File Manager Mode
    Item {
        anchors.fill: parent
        visible: !pickerActive

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // 1. Tab Bar
            TabBar {
                Layout.fillWidth: true
                onTabContextMenuRequested: (idx, gx, gy) => {
                    tabContextMenu.open(gx, gy, idx);
                }
            }

            // Main Content Area with Chrome-like rounded top corners connecting to the titlebar/tabstrip
            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: true
                topLeftRadius: Tokens.rounding.large
                topRightRadius: Tokens.rounding.large
                bottomLeftRadius: 0
                bottomRightRadius: 0
                color: Colours.tPalette.m3surfaceContainer
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // 2. Navigation Bar
                    NavigationBar {
                        id: navBar
                        Layout.fillWidth: true
                        activeTab: TabManager.currentTab

                        onGitRequested: {
                            gitModal.expanded = true;
                        }

                        onTogglePreview: {
                            previewPanel.expanded = !previewPanel.expanded;
                        }

                        onToggleTerminal: {
                            if (TabManager.currentTab) {
                                AppIntegration.openInTerminal(TabManager.currentTab.currentPath);
                            }
                        }

                        onCreateNewFolder: {
                            newItemModal.title = qsTr("Create New Folder");
                            newItemModal.icon = "create_new_folder";
                            newItemModal.initialText = qsTr("New Folder");
                            newItemModal.expanded = true;
                        }

                        onCreateNewFile: {
                            newItemModal.title = qsTr("Create New File");
                            newItemModal.icon = "note_add";
                            newItemModal.initialText = "untitled.txt";
                            newItemModal.expanded = true;
                        }

                        onReload: {
                            if (TabManager.currentTab) {
                                TabManager.currentTab.currentPath = TabManager.currentTab.currentPath;
                            }
                        }

                        onSearchRequested: query => {
                            splitContainer.searchQuery = query;
                        }
                    }

                    // 3. Central Workspace (Sidebar + Single View + Preview Panel)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 0

                        // Places Sidebar
                        PlacesSidebar {
                            Layout.fillHeight: true
                            activeTab: TabManager.currentTab

                            onPlaceContextMenuRequested: (gx, gy, idx, name, path, iconName, custom, trash) => {
                                placeContextMenu.openForPlace(gx, gy, idx, name, path, iconName, custom, trash);
                            }

                            onDeviceContextMenuRequested: (gx, gy, devPath, name, mountPt, mounted) => {
                                placeContextMenu.openForDevice(gx, gy, devPath, name, mountPt, mounted);
                            }

                            onEditPlaceRequested: (index, name, path, iconName, isCustom) => {
                                editPlaceModal.targetIndex = index;
                                editPlaceModal.placeName = name;
                                editPlaceModal.placePath = path;
                                editPlaceModal.selectedIcon = iconName;
                                editPlaceModal.isCustom = isCustom;
                                editPlaceModal.expanded = true;
                            }

                            onManagePlacesRequested: {
                                placesManageModal.expanded = true;
                            }

                            onFilesDropped: (sources, destDir, x, y) => {
                                dropActionMenu.sourceFiles = sources;
                                dropActionMenu.targetDir = destDir;
                                dropActionMenu.menuX = x;
                                dropActionMenu.menuY = y;
                                dropActionMenu.expanded = true;
                            }
                        }

                        // View Container (Main Pane)
                        SplitViewContainer {
                            id: splitContainer
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            activeTab: TabManager.currentTab
                            zoomSize: statusBar.zoomLevel

                            onItemContextMenu: (item, x, y) => {
                                contextMenu.targetItem = item;
                                contextMenu.menuX = x;
                                contextMenu.menuY = y;
                                contextMenu.expanded = true;
                            }

                            onBlankContextMenu: (x, y) => {
                                contextMenu.targetItem = null;
                                contextMenu.menuX = x;
                                contextMenu.menuY = y;
                                contextMenu.expanded = true;
                            }

                            onCreateNewFolder: {
                                newItemModal.title = qsTr("Create New Folder");
                                newItemModal.icon = "create_new_folder";
                                newItemModal.initialText = qsTr("New Folder");
                                newItemModal.expanded = true;
                            }

                            onCreateNewFile: {
                                newItemModal.title = qsTr("Create New File");
                                newItemModal.icon = "note_add";
                                newItemModal.initialText = "untitled.txt";
                                newItemModal.expanded = true;
                            }

                            onFilesDropped: (sources, destDir, x, y) => {
                                dropActionMenu.sourceFiles = sources;
                                dropActionMenu.targetDir = destDir;
                                dropActionMenu.menuX = x;
                                dropActionMenu.menuY = y;
                                dropActionMenu.expanded = true;
                            }

                            onItemOpened: (item, pane) => {
                                if (item.isImage || item.isVideo || FileUtils.isImage(item.path) || FileUtils.isVideo(item.path)) {
                                    mediaViewerModal.openFile(item.path, pane === 1 ? splitContainer.splitModel : splitContainer.activeModel);
                                } else {
                                    AppIntegration.openWithDefault(item.path);
                                }
                            }
                        }

                        // Information / Preview Panel (F1)
                        PreviewPanel {
                            id: previewPanel
                            Layout.fillHeight: true
                            targetPath: splitContainer.currentSelectedPath
                            onPreviewClicked: path => {
                                mediaViewerModal.openFile(path, splitContainer.activeModel);
                            }
                        }
                    }

                    // 4. Bottom Status Bar
                    StatusBar {
                        id: statusBar
                        Layout.fillWidth: true
                        activeModel: splitContainer.activeModel
                        activeTab: TabManager.currentTab
                        selectedCount: splitContainer.selectedPaths.length > 0 ? splitContainer.selectedPaths.length : (contextMenu.targetItem ? 1 : 0)
                        selectedSizeFormatted: contextMenu.targetItem ? (contextMenu.targetItem.isDir ? "" : contextMenu.targetItem.formattedSize) : ""
                        onZoomChanged: level => zoomLevel = level
                        onGitRequested: {
                            gitModal.expanded = true;
                        }
                        onOperationsRequested: {
                            operationsModal.expanded = !operationsModal.expanded;
                        }
                    }
                }
            }
        }

        // Context Menu Overlay
        ContextMenu {
            id: contextMenu
            currentDir: TabManager.currentTab ? TabManager.currentTab.currentPath : ""

            onActionTriggered: (action, item) => {
                let currentDir = TabManager.currentTab ? TabManager.currentTab.currentPath : "";
                if (action === "preview" && item) {
                    mediaViewerModal.openFile(item.path, splitContainer.activeModel);
                } else if (action === "open" && item) {
                    if (item.isDir) {
                        TabManager.currentTab.currentPath = item.path;
                    } else if (item.isImage || item.isVideo || FileUtils.isImage(item.path) || FileUtils.isVideo(item.path)) {
                        mediaViewerModal.openFile(item.path, splitContainer.activeModel);
                    } else {
                        AppIntegration.openWithDefault(item.path);
                    }
                } else if (action === "openNewTab" && item) {
                    TabManager.newTab(item.path);
                } else if (action === "openNewWindow" && item) {
                    AppIntegration.openNewWindow(item.path);
                } else if (action === "openSplit" && item) {
                    if (TabManager.currentTab) {
                        TabManager.currentTab.splitPath = item.path;
                        TabManager.currentTab.isSplit = true;
                    }
                } else if (action === "openTerminalItem" && item) {
                    AppIntegration.openInTerminal(item.path);
                } else if (action === "cut" && item) {
                    FileOperations.cutPaths([item.path]);
                } else if (action === "copy" && item) {
                    FileOperations.copyPaths([item.path]);
                } else if (action === "copyPath" && item) {
                    FileOperations.copyTextToClipboard(item.path);
                } else if (action === "paste") {
                    FileOperations.paste(currentDir);
                } else if (action === "pasteSymlink") {
                    FileOperations.pasteAsSymlink(currentDir);
                } else if (action === "rename" && item) {
                    newItemModal.title = qsTr("Rename");
                    newItemModal.icon = "drive_file_rename_outline";
                    newItemModal.initialText = item.name;
                    newItemModal.expanded = true;
                } else if (action === "trash" && item) {
                    FileOperations.moveToTrash([item.path]);
                } else if (action === "delete" && item) {
                    FileOperations.deletePermanently([item.path]);
                } else if (action === "newFolder") {
                    newItemModal.title = qsTr("Create New Folder");
                    newItemModal.icon = "create_new_folder";
                    newItemModal.initialText = qsTr("New Folder");
                    newItemModal.expanded = true;
                } else if (action === "openWith" && item) {
                    openWithModal.targetPath = item.path;
                    openWithModal.expanded = true;
                } else if (action === "extractHere" && item) {
                    FileOperations.extractArchive(item.path);
                } else if (action === "extractTo" && item) {
                    let dest = item.path.replace(/\.[^/.]+$/, "");
                    FileOperations.extractArchive(item.path, dest);
                } else if (action === "compress" && item) {
                    compressModal.sourcePaths = splitContainer.selectedPaths.length > 0 ? splitContainer.selectedPaths : [item.path];
                    compressModal.defaultName = item.name;
                    compressModal.expanded = true;
                } else if (action === "newFile") {
                    newItemModal.title = qsTr("Create New File");
                    newItemModal.icon = "note_add";
                    newItemModal.initialText = "untitled.txt";
                    newItemModal.expanded = true;
                } else if (action === "restore" && item) {
                    FileOperations.restoreFromTrash(item.path);
                } else if (action === "emptyTrash") {
                    FileOperations.emptyTrash();
                } else if (action === "bookmark") {
                    PlacesModel.addBookmark(currentDir);
                } else if (action === "openTerminal") {
                    AppIntegration.openInTerminal(currentDir);
                } else if (action === "properties" && item) {
                    propertiesModal.targetPath = item.path;
                    propertiesModal.expanded = true;
                } else if (action === "propertiesDir") {
                    propertiesModal.targetPath = currentDir;
                    propertiesModal.expanded = true;
                }
            }
        }

        // Open With Modal
        OpenWithModal {
            id: openWithModal
        }

        // Compress Modal
        CompressModal {
            id: compressModal
            onAccepted: (sources, dest, fmt) => {
                let curDir = TabManager.currentTab ? TabManager.currentTab.currentPath : "";
                FileOperations.createArchive(sources, curDir + "/" + dest, fmt);
            }
        }

        // Operations & Background Activity Modal
        OperationsModal {
            id: operationsModal
        }

        // Places & Devices Management Modal
        PlacesManageModal {
            id: placesManageModal
            onEditPlaceRequested: (idx, name, path, iconName, custom) => {
                editPlaceModal.targetIndex = idx;
                editPlaceModal.placeName = name;
                editPlaceModal.placePath = path;
                editPlaceModal.selectedIcon = iconName;
                editPlaceModal.isCustom = custom;
                editPlaceModal.expanded = true;
            }
        }

        // Edit Place Modal
        EditPlaceModal {
            id: editPlaceModal
            onAccepted: (idx, name, iconName) => {
                PlacesModel.updatePlace(idx, name, iconName);
            }
            onRemoveRequested: idx => {
                PlacesModel.removeBookmark(idx);
            }
        }

        // New Item / Rename Modal
        NewItemModal {
            id: newItemModal
            onAccepted: text => {
                let currentDir = TabManager.currentTab ? TabManager.currentTab.currentPath : "";
                if (title === qsTr("Create New Folder")) {
                    FileOperations.createDirectory(currentDir, text);
                } else if (title === qsTr("Create New File")) {
                    FileOperations.createFile(currentDir, text);
                } else if (title === qsTr("Rename")) {
                    let oldPath = newItemModal.targetRenamePath || (contextMenu.targetItem ? contextMenu.targetItem.path : "");
                    if (oldPath) {
                        FileOperations.renameFile(oldPath, text);
                    }
                }
            }
        }

        // Properties Modal
        PropertiesModal {
            id: propertiesModal
        }

        // Git Repository Modal
        GitModal {
            id: gitModal
        }

        // Tab Context Menu (Top-level window overlay)
        TabContextMenu {
            id: tabContextMenu
        }

        // Place & Device Context Menu (Top-level window overlay)
        PlaceContextMenu {
            id: placeContextMenu
            onEditRequested: (idx, name, path, iconName, custom) => {
                editPlaceModal.targetIndex = idx;
                editPlaceModal.placeName = name;
                editPlaceModal.placePath = path;
                editPlaceModal.selectedIcon = iconName;
                editPlaceModal.isCustom = custom;
                editPlaceModal.expanded = true;
            }
            onEmptyTrashRequested: {
                FileOperations.emptyTrash();
            }
        }

        // Drop Action Menu (Dolphin-style DND modal popup)
        DropActionMenu {
            id: dropActionMenu
            onActionTriggered: (action, sources, dest) => {
                if (action === "moveNewFolder") {
                    newItemModal.title = qsTr("Create New Folder");
                    newItemModal.icon = "create_new_folder";
                    newItemModal.initialText = qsTr("New Folder");
                    newItemModal.expanded = true;
                    let pendingMove = sources.slice();
                    let handler = function(folderName) {
                        newItemModal.accepted.disconnect(handler);
                        let fullPath = dest + "/" + folderName;
                        FileOperations.createDirectory(dest, folderName);
                        FileOperations.moveFiles(pendingMove, fullPath);
                    };
                    newItemModal.accepted.connect(handler);
                }
            }
        }

        // In-App Media Viewer Modal (Images, Videos, Audio)
        MediaViewerModal {
            id: mediaViewerModal
        }

        // Global Desktop Shortcuts
        Shortcut {
            sequence: "Space"
            enabled: !mediaViewerModal.expanded && !newItemModal.expanded && !editPlaceModal.expanded && !placesManageModal.expanded && !compressModal.expanded && !openWithModal.expanded
            onActivated: {
                if (splitContainer.currentSelectedPath) {
                    let path = splitContainer.currentSelectedPath;
                    if (FileUtils.isImage(path) || FileUtils.isVideo(path)) {
                        mediaViewerModal.openFile(path, splitContainer.activeModel);
                    }
                }
            }
        }

        Shortcut {
            sequence: "Ctrl+T"
            onActivated: TabManager.newTab()
        }

        Shortcut {
            sequence: "Ctrl+W"
            onActivated: TabManager.closeTab(TabManager.currentIndex)
        }

        Shortcut {
            sequence: "Ctrl+Tab"
            onActivated: TabManager.nextTab()
        }

        Shortcut {
            sequence: "Ctrl+Shift+Tab"
            onActivated: TabManager.prevTab()
        }

        Shortcut {
            sequence: "Ctrl+N"
            onActivated: {
                newItemModal.title = qsTr("Create New Folder");
                newItemModal.icon = "create_new_folder";
                newItemModal.initialText = qsTr("New Folder");
                newItemModal.expanded = true;
            }
        }

        Shortcut {
            sequence: "Ctrl+Shift+N"
            onActivated: {
                newItemModal.title = qsTr("Create New File");
                newItemModal.icon = "note_add";
                newItemModal.initialText = "untitled.txt";
                newItemModal.expanded = true;
            }
        }

        Shortcut {
            sequence: "Ctrl+C"
            onActivated: {
                let paths = splitContainer.selectedPaths.length > 0 ? splitContainer.selectedPaths : (splitContainer.currentSelectedPath ? [splitContainer.currentSelectedPath] : []);
                if (paths.length > 0) FileOperations.copyPaths(paths);
            }
        }

        Shortcut {
            sequence: "Ctrl+X"
            onActivated: {
                let paths = splitContainer.selectedPaths.length > 0 ? splitContainer.selectedPaths : (splitContainer.currentSelectedPath ? [splitContainer.currentSelectedPath] : []);
                if (paths.length > 0) FileOperations.cutPaths(paths);
            }
        }

        Shortcut {
            sequence: "Ctrl+V"
            onActivated: {
                if (TabManager.currentTab) FileOperations.paste(TabManager.currentTab.currentPath);
            }
        }

        Shortcut {
            sequence: "Delete"
            onActivated: {
                let paths = splitContainer.selectedPaths.length > 0 ? splitContainer.selectedPaths : (splitContainer.currentSelectedPath ? [splitContainer.currentSelectedPath] : []);
                if (paths.length > 0) FileOperations.moveToTrash(paths);
            }
        }

        Shortcut {
            sequence: "Shift+Delete"
            onActivated: {
                let paths = splitContainer.selectedPaths.length > 0 ? splitContainer.selectedPaths : (splitContainer.currentSelectedPath ? [splitContainer.currentSelectedPath] : []);
                if (paths.length > 0) FileOperations.deletePermanently(paths);
            }
        }

        Shortcut {
            sequence: "F2"
            onActivated: {
                let sel = splitContainer.currentSelectedPath;
                if (sel && sel.length > 0) {
                    newItemModal.title = qsTr("Rename");
                    newItemModal.icon = "drive_file_rename_outline";
                    newItemModal.targetRenamePath = sel;
                    newItemModal.initialText = FileUtils.baseName(sel);
                    newItemModal.expanded = true;
                }
            }
        }

        Shortcut {
            sequence: "Alt+Return"
            onActivated: {
                let sel = splitContainer.currentSelectedPath;
                if (sel && sel.length > 0) {
                    propertiesModal.targetPath = sel;
                    propertiesModal.expanded = true;
                }
            }
        }

        Shortcut {
            sequence: "Ctrl+H"
            onActivated: AppController.showHidden = !AppController.showHidden
        }

        Shortcut {
            sequence: "Alt+."
            onActivated: AppController.showHidden = !AppController.showHidden
        }

        Shortcut {
            sequence: "Ctrl+A"
            onActivated: {
                if (splitContainer.activeModel) {
                    let all = [];
                    for (let i = 0; i < splitContainer.activeModel.count; ++i) {
                        let e = splitContainer.activeModel.get(i);
                        if (e) all.push(e.path);
                    }
                    if (splitContainer.mainViewLoader && splitContainer.mainViewLoader.item) {
                        splitContainer.mainViewLoader.item.selectedPaths = all;
                    }
                }
            }
        }

        Shortcut {
            sequence: "Ctrl+Shift+A"
            onActivated: {
                if (splitContainer.mainViewLoader && splitContainer.mainViewLoader.item) {
                    splitContainer.mainViewLoader.item.selectedPaths = [];
                }
            }
        }

        Shortcut {
            sequence: "Ctrl+D"
            onActivated: {
                if (splitContainer.mainViewLoader && splitContainer.mainViewLoader.item) {
                    splitContainer.mainViewLoader.item.selectedPaths = [];
                }
            }
        }

        Shortcut {
            sequence: "Ctrl+I"
            onActivated: {
                if (splitContainer.activeModel && splitContainer.mainViewLoader && splitContainer.mainViewLoader.item) {
                    let cur = splitContainer.mainViewLoader.item.selectedPaths;
                    let inverted = [];
                    for (let i = 0; i < splitContainer.activeModel.count; ++i) {
                        let e = splitContainer.activeModel.get(i);
                        if (e && cur.indexOf(e.path) === -1) {
                            inverted.push(e.path);
                        }
                    }
                    splitContainer.mainViewLoader.item.selectedPaths = inverted;
                }
            }
        }

        Shortcut {
            sequence: "Ctrl+1"
            onActivated: if (TabManager.currentTab) TabManager.currentTab.viewMode = 0
        }

        Shortcut {
            sequence: "Ctrl+2"
            onActivated: if (TabManager.currentTab) TabManager.currentTab.viewMode = 1
        }

        Shortcut {
            sequence: "Ctrl+3"
            onActivated: if (TabManager.currentTab) TabManager.currentTab.viewMode = 2
        }

        Shortcut {
            sequence: "Alt+Left"
            onActivated: if (TabManager.currentTab && TabManager.currentTab.canGoBack) TabManager.currentTab.goBack()
        }

        Shortcut {
            sequence: "Alt+Right"
            onActivated: if (TabManager.currentTab && TabManager.currentTab.canGoForward) TabManager.currentTab.goForward()
        }

        Shortcut {
            sequence: "Alt+Up"
            onActivated: if (TabManager.currentTab) TabManager.currentTab.goUp()
        }

        Shortcut {
            sequence: "Alt+Home"
            onActivated: if (TabManager.currentTab) TabManager.currentTab.currentPath = FileUtils.home
        }

        Shortcut {
            sequence: "Ctrl+F"
            onActivated: navBar.openSearch()
        }

        Shortcut {
            sequence: "F9"
            onActivated: navBar.openSearch()
        }

        Shortcut {
            sequence: "Ctrl+L"
            onActivated: navBar.openAddressEdit()
        }

        Shortcut {
            sequence: "Alt+D"
            onActivated: navBar.openAddressEdit()
        }

        Shortcut {
            sequence: "F3"
            onActivated: {
                if (TabManager.currentTab) {
                    TabManager.currentTab.isSplit = !TabManager.currentTab.isSplit;
                    if (TabManager.currentTab.isSplit && !TabManager.currentTab.splitPath) {
                        TabManager.currentTab.splitPath = TabManager.currentTab.currentPath;
                    }
                }
            }
        }

        Shortcut {
            sequence: "F4"
            onActivated: {
                if (TabManager.currentTab) {
                    AppIntegration.openInTerminal(TabManager.currentTab.currentPath);
                }
            }
        }

        Shortcut {
            sequence: "F5"
            onActivated: {
                if (splitContainer.activeModel) {
                    splitContainer.activeModel.refresh();
                }
            }
        }

        Shortcut {
            sequence: "Ctrl+R"
            onActivated: {
                if (splitContainer.activeModel) {
                    splitContainer.activeModel.refresh();
                }
            }
        }

        Shortcut {
            sequence: "F10"
            onActivated: {
                newItemModal.title = qsTr("Create New Folder");
                newItemModal.icon = "create_new_folder";
                newItemModal.initialText = qsTr("New Folder");
                newItemModal.expanded = true;
            }
        }

        Shortcut {
            sequence: "F1"
            onActivated: previewPanel.expanded = !previewPanel.expanded
        }

        Shortcut {
            sequence: "F11"
            onActivated: {
                if (window.visibility === Window.FullScreen) {
                    window.visibility = Window.Windowed;
                } else {
                    window.visibility = Window.FullScreen;
                }
            }
        }

        Shortcut {
            sequence: "Ctrl+Z"
            onActivated: FileOperations.undo()
        }

        Shortcut {
            sequence: "Ctrl+Shift+Z"
            onActivated: FileOperations.redo()
        }

        Shortcut {
            sequence: "Ctrl+Y"
            onActivated: FileOperations.redo()
        }

        Shortcut {
            sequence: "Ctrl+="
            onActivated: zoomLevel = Math.min(2.0, zoomLevel + 0.15)
        }

        Shortcut {
            sequence: "Ctrl++"
            onActivated: zoomLevel = Math.min(2.0, zoomLevel + 0.15)
        }

        Shortcut {
            sequence: "Ctrl+-"
            onActivated: zoomLevel = Math.max(0.4, zoomLevel - 0.15)
        }

        Shortcut {
            sequence: "Ctrl+0"
            onActivated: zoomLevel = 1.0
        }

        // Global MouseArea for Back/Forward Extra Mouse Buttons
        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.BackButton | Qt.ForwardButton | Qt.ExtraButton1 | Qt.ExtraButton2
            onPressed: mouse => {
                if (mouse.button === Qt.BackButton || mouse.button === Qt.ExtraButton1) {
                    if (TabManager.currentTab && TabManager.currentTab.canGoBack) {
                        TabManager.currentTab.goBack();
                        mouse.accepted = true;
                    }
                } else if (mouse.button === Qt.ForwardButton || mouse.button === Qt.ExtraButton2) {
                    if (TabManager.currentTab && TabManager.currentTab.canGoForward) {
                        TabManager.currentTab.goForward();
                        mouse.accepted = true;
                    }
                }
            }
        }
    }

    // Modal File Dialog Picker Mode
    FileDialog {
        id: fileDialogComponent
        anchors.fill: parent
        visible: pickerActive
    }
}
