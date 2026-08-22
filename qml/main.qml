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

    function getActiveDirectory() {
        if (!TabManager.currentTab) return "";
        return (TabManager.currentTab.isSplit && TabManager.currentTab.activePane === 1)
            ? TabManager.currentTab.splitPath
            : TabManager.currentTab.currentPath;
    }

    function setActiveDirectory(path) {
        if (!TabManager.currentTab) return;
        let expanded = FileUtils.expandPath(path);
        if (TabManager.currentTab.isSplit && TabManager.currentTab.activePane === 1) {
            TabManager.currentTab.splitPath = expanded;
        } else {
            TabManager.currentTab.currentPath = expanded;
        }
    }

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
                        z: (navBar.isEditingPath && navBar.showSuggestions) ? 500 : 10
                        activeTab: TabManager.currentTab

                        onSpecialProtocolInvoked: protocolId => {
                            if (protocolId === 1) {
                                vectorBloomOverlay.open();
                            } else if (protocolId === 2) {
                                runnerGameModal.open();
                            }
                        }

                        onGitRequested: {
                            gitModal.expanded = true;
                        }

                        onTogglePreview: {
                            previewPanel.expanded = !previewPanel.expanded;
                        }

                        onToggleTerminal: {
                            AppIntegration.openInTerminal(window.getActiveDirectory());
                        }

                        onPreferencesRequested: {
                            preferencesModal.expanded = true;
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
                                if (TabManager.currentTab.isSplit && TabManager.currentTab.activePane === 1) {
                                    TabManager.currentTab.splitPath = TabManager.currentTab.splitPath;
                                } else {
                                    TabManager.currentTab.currentPath = TabManager.currentTab.currentPath;
                                }
                            }
                        }

                        onSearchRequested: query => {
                            splitContainer.searchQuery = query;
                        }
                    }

                    // 3. Central Workspace
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

                        // View Container
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
                                AppIntegration.openWithDefault(item.path);
                            }
                        }

                        // Information / Preview Panel
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
                        zoomLevel: window.zoomLevel
                        selectedCount: splitContainer.selectedPaths.length > 0 ? splitContainer.selectedPaths.length : (contextMenu.targetItem ? 1 : 0)
                        selectedSizeFormatted: contextMenu.targetItem ? (contextMenu.targetItem.isDir ? "" : contextMenu.targetItem.formattedSize) : ""
                        onZoomChanged: level => window.zoomLevel = level
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
            currentDir: window.getActiveDirectory()

            onActionTriggered: (action, item) => {
                let currentDir = window.getActiveDirectory();
                let selected = splitContainer.selectedPaths;
                let targetPaths = (item && selected.length > 0 && selected.indexOf(item.path) !== -1) ? selected : (item ? [item.path] : []);

                if (action === "preview" && item) {
                    mediaViewerModal.openFile(item.path, splitContainer.activeModel);
                } else if (action === "open" && item) {
                    if (item.isDir) {
                        window.setActiveDirectory(item.path);
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
                    FileOperations.cutPaths(targetPaths);
                } else if (action === "copy" && item) {
                    FileOperations.copyPaths(targetPaths);
                } else if (action === "copyPath" && item) {
                    FileOperations.copyTextToClipboard(targetPaths.join("\n"));
                } else if (action === "copyCurrentDirPath") {
                    FileOperations.copyTextToClipboard(currentDir);
                } else if (action === "paste") {
                    FileOperations.paste(currentDir);
                } else if (action === "pasteSymlink") {
                    FileOperations.pasteAsSymlink(currentDir);
                } else if (action === "symlink" && item) {
                    for (let i = 0; i < targetPaths.length; ++i) {
                        let base = FileUtils.baseName(targetPaths[i]);
                        FileOperations.createSymlink(targetPaths[i], currentDir + "/" + base + " (symlink)");
                    }
                } else if (action === "duplicate" && item) {
                    for (let i = 0; i < targetPaths.length; ++i) {
                        FileOperations.duplicateFile(targetPaths[i]);
                    }
                } else if (action.startsWith("sendTo:") && item) {
                    let serviceId = action.substring(7);
                    AppIntegration.shareFiles(serviceId, targetPaths);
                } else if (action === "rename" && item) {
                    newItemModal.title = qsTr("Rename");
                    newItemModal.icon = "drive_file_rename_outline";
                    newItemModal.targetRenamePath = item.path;
                    newItemModal.initialText = item.name;
                    newItemModal.expanded = true;
                } else if (action === "trash" && item) {
                    FileOperations.moveToTrash(targetPaths);
                } else if (action === "delete" && item) {
                    FileOperations.deletePermanently(targetPaths);
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
                    compressModal.sourcePaths = targetPaths;
                    compressModal.defaultName = targetPaths.length === 1 ? item.name : FileUtils.baseName(targetPaths[0]);
                    compressModal.expanded = true;
                } else if (action === "newFile") {
                    newItemModal.title = qsTr("Create New File");
                    newItemModal.icon = "note_add";
                    newItemModal.initialText = "untitled.txt";
                    newItemModal.expanded = true;
                } else if (action === "restore" && item) {
                    for (let i = 0; i < targetPaths.length; ++i) {
                        FileOperations.restoreFromTrash(targetPaths[i]);
                    }
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
                } else if (action.startsWith("custom:")) {
                    let actId = action.substring(7);
                    AppIntegration.executeCustomAction(actId, currentDir, targetPaths);
                } else if (action === "openScriptsFolder") {
                    AppIntegration.openScriptsFolder();
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
                let curDir = window.getActiveDirectory();
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
                let currentDir = window.getActiveDirectory();
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

        // Tab Context Menu
        TabContextMenu {
            id: tabContextMenu
        }

        // Place & Device Context Menu
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
            onManageRequested: {
                placesManageModal.expanded = true;
            }
        }

        // Drop Action Menu
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

        // In-App Media Viewer Modal
        MediaViewerModal {
            id: mediaViewerModal
        }

        // Preferences / Settings Modal
        PreferencesModal {
            id: preferencesModal
        }

        VectorBloomOverlay {
            id: vectorBloomOverlay
        }

        RunnerGameModal {
            id: runnerGameModal
        }

        Shortcut {
            sequence: "Space"
            context: Qt.ApplicationShortcut
            enabled: !mediaViewerModal.expanded && !newItemModal.expanded && !editPlaceModal.expanded && !placesManageModal.expanded && !compressModal.expanded && !openWithModal.expanded && !preferencesModal.expanded && !runnerGameModal.isOpen && !vectorBloomOverlay.isOpen
            onActivated: {
                if (splitContainer.currentSelectedPath) {
                    let path = splitContainer.currentSelectedPath;
                    mediaViewerModal.openFile(path, splitContainer.activeModel);
                }
            }
        }

        Shortcut {
            sequence: "Ctrl+,"
            context: Qt.ApplicationShortcut
            onActivated: preferencesModal.expanded = true
        }

        Shortcut {
            sequence: "Ctrl+T"
            context: Qt.ApplicationShortcut
            onActivated: TabManager.newTab()
        }

        Shortcut {
            sequence: "Ctrl+W"
            context: Qt.ApplicationShortcut
            onActivated: {
                if (TabManager.currentTab && TabManager.currentTab.isSplit) {
                    TabManager.closeSplitPane(TabManager.currentIndex, TabManager.currentTab.activePane);
                } else {
                    TabManager.closeTab(TabManager.currentIndex);
                }
            }
        }

        Shortcut {
            sequence: "Ctrl+Tab"
            context: Qt.ApplicationShortcut
            onActivated: TabManager.nextTab()
        }

        Shortcut {
            sequence: "Ctrl+Shift+Tab"
            context: Qt.ApplicationShortcut
            onActivated: TabManager.prevTab()
        }

        Shortcut {
            sequence: "Ctrl+N"
            context: Qt.ApplicationShortcut
            onActivated: {
                newItemModal.title = qsTr("Create New Folder");
                newItemModal.icon = "create_new_folder";
                newItemModal.initialText = qsTr("New Folder");
                newItemModal.expanded = true;
            }
        }

        Shortcut {
            sequence: "Ctrl+Shift+N"
            context: Qt.ApplicationShortcut
            onActivated: {
                newItemModal.title = qsTr("Create New File");
                newItemModal.icon = "note_add";
                newItemModal.initialText = "untitled.txt";
                newItemModal.expanded = true;
            }
        }

        Shortcut {
            sequence: "Ctrl+C"
            context: Qt.ApplicationShortcut
            onActivated: {
                let paths = splitContainer.selectedPaths.length > 0 ? splitContainer.selectedPaths : (splitContainer.currentSelectedPath ? [splitContainer.currentSelectedPath] : []);
                if (paths.length > 0) FileOperations.copyPaths(paths);
            }
        }

        Shortcut {
            sequence: "Ctrl+X"
            context: Qt.ApplicationShortcut
            onActivated: {
                let paths = splitContainer.selectedPaths.length > 0 ? splitContainer.selectedPaths : (splitContainer.currentSelectedPath ? [splitContainer.currentSelectedPath] : []);
                if (paths.length > 0) FileOperations.cutPaths(paths);
            }
        }

        Shortcut {
            sequence: "Ctrl+V"
            context: Qt.ApplicationShortcut
            onActivated: {
                if (TabManager.currentTab) FileOperations.paste(window.getActiveDirectory());
            }
        }

        Shortcut {
            sequence: "Delete"
            context: Qt.ApplicationShortcut
            onActivated: {
                let paths = splitContainer.selectedPaths.length > 0 ? splitContainer.selectedPaths : (splitContainer.currentSelectedPath ? [splitContainer.currentSelectedPath] : []);
                if (paths.length > 0) FileOperations.moveToTrash(paths);
            }
        }

        Shortcut {
            sequence: "Shift+Delete"
            context: Qt.ApplicationShortcut
            onActivated: {
                let paths = splitContainer.selectedPaths.length > 0 ? splitContainer.selectedPaths : (splitContainer.currentSelectedPath ? [splitContainer.currentSelectedPath] : []);
                if (paths.length > 0) FileOperations.deletePermanently(paths);
            }
        }

        Shortcut {
            sequences: ["F2", "Shift+F2"]
            context: Qt.ApplicationShortcut
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
            context: Qt.ApplicationShortcut
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
            context: Qt.ApplicationShortcut
            onActivated: AppController.showHidden = !AppController.showHidden
        }

        Shortcut {
            sequence: "Alt+."
            context: Qt.ApplicationShortcut
            onActivated: AppController.showHidden = !AppController.showHidden
        }

        Shortcut {
            sequence: "Ctrl+A"
            context: Qt.ApplicationShortcut
            onActivated: splitContainer.selectAll()
        }

        Shortcut {
            sequence: "Ctrl+Shift+A"
            context: Qt.ApplicationShortcut
            onActivated: splitContainer.clearSelection()
        }

        Shortcut {
            sequence: "Ctrl+D"
            context: Qt.ApplicationShortcut
            onActivated: splitContainer.clearSelection()
        }

        Shortcut {
            sequence: "Ctrl+I"
            context: Qt.ApplicationShortcut
            onActivated: splitContainer.invertSelection()
        }

        Shortcut {
            sequence: "Ctrl+1"
            context: Qt.ApplicationShortcut
            onActivated: if (TabManager.currentTab) TabManager.currentTab.viewMode = 0
        }

        Shortcut {
            sequence: "Ctrl+2"
            context: Qt.ApplicationShortcut
            onActivated: if (TabManager.currentTab) TabManager.currentTab.viewMode = 1
        }

        Shortcut {
            sequence: "Ctrl+3"
            context: Qt.ApplicationShortcut
            onActivated: if (TabManager.currentTab) TabManager.currentTab.viewMode = 2
        }

        Shortcut {
            sequence: "Alt+Left"
            context: Qt.ApplicationShortcut
            onActivated: if (TabManager.currentTab && TabManager.currentTab.canGoBack) TabManager.currentTab.goBack()
        }

        Shortcut {
            sequence: "Alt+Right"
            context: Qt.ApplicationShortcut
            onActivated: if (TabManager.currentTab && TabManager.currentTab.canGoForward) TabManager.currentTab.goForward()
        }

        Shortcut {
            sequence: "Alt+Up"
            context: Qt.ApplicationShortcut
            onActivated: if (TabManager.currentTab) TabManager.currentTab.goUp()
        }

        Shortcut {
            sequence: "Alt+Home"
            context: Qt.ApplicationShortcut
            onActivated: window.setActiveDirectory(FileUtils.home)
        }

        Shortcut {
            sequences: ["Ctrl+F", "F9", "Shift+F9"]
            context: Qt.ApplicationShortcut
            onActivated: navBar.openSearch()
        }

        Shortcut {
            sequence: "Ctrl+L"
            context: Qt.ApplicationShortcut
            onActivated: navBar.openAddressEdit()
        }

        Shortcut {
            sequence: "Alt+D"
            context: Qt.ApplicationShortcut
            onActivated: navBar.openAddressEdit()
        }

        Shortcut {
            sequences: ["F3", "Shift+F3"]
            context: Qt.ApplicationShortcut
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
            sequences: ["F4", "Shift+F4", "Ctrl+Alt+T", "Ctrl+`"]
            context: Qt.ApplicationShortcut
            onActivated: {
                if (TabManager.currentTab) {
                    AppIntegration.openInTerminal(window.getActiveDirectory());
                }
            }
        }

        Shortcut {
            sequences: ["F5", "Shift+F5", "Ctrl+R"]
            context: Qt.ApplicationShortcut
            onActivated: {
                if (splitContainer.activeModel) {
                    splitContainer.activeModel.refresh();
                }
            }
        }

        Shortcut {
            sequences: ["F10", "Shift+F10"]
            context: Qt.ApplicationShortcut
            onActivated: {
                newItemModal.title = qsTr("Create New Folder");
                newItemModal.icon = "create_new_folder";
                newItemModal.initialText = qsTr("New Folder");
                newItemModal.expanded = true;
            }
        }

        Shortcut {
            sequences: ["F1", "Shift+F1", "Alt+P"]
            context: Qt.ApplicationShortcut
            onActivated: previewPanel.expanded = !previewPanel.expanded
        }

        Shortcut {
            sequences: ["F11", "Shift+F11"]
            context: Qt.ApplicationShortcut
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
            context: Qt.ApplicationShortcut
            onActivated: FileOperations.undo()
        }

        Shortcut {
            sequence: "Ctrl+Shift+Z"
            context: Qt.ApplicationShortcut
            onActivated: FileOperations.redo()
        }

        Shortcut {
            sequence: "Ctrl+Y"
            context: Qt.ApplicationShortcut
            onActivated: FileOperations.redo()
        }

        Shortcut {
            sequence: "Ctrl+="
            context: Qt.ApplicationShortcut
            onActivated: window.zoomLevel = Math.min(180, window.zoomLevel + 16)
        }

        Shortcut {
            sequence: "Ctrl++"
            context: Qt.ApplicationShortcut
            onActivated: window.zoomLevel = Math.min(180, window.zoomLevel + 16)
        }

        Shortcut {
            sequence: "Ctrl+-"
            context: Qt.ApplicationShortcut
            onActivated: window.zoomLevel = Math.max(48, window.zoomLevel - 16)
        }

        Shortcut {
            sequence: "Ctrl+0"
            context: Qt.ApplicationShortcut
            onActivated: window.zoomLevel = 80
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
