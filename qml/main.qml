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
import "components/media"
import atlas

ApplicationWindow {
    id: window

    title: TabManager.currentTab && TabManager.currentTab.title
        ? (TabManager.currentTab.title + " — Atlas")
        : "Atlas"

    visible: true
    width: 1060
    height: 680
    minimumWidth: 520
    minimumHeight: 400
    color: Colours.tPalette.m3surfaceContainerLowest

    property real zoomLevel: 80

    Component.onCompleted: zoomLevel = AppController.iconZoomLevel
    onZoomLevelChanged: AppController.iconZoomLevel = Math.round(zoomLevel)

    function getActiveDirectory() {
        if (!TabManager.currentTab) return "";
        return (TabManager.currentTab.isSplit && TabManager.currentTab.activePane === 1)
            ? TabManager.currentTab.splitPath
            : TabManager.currentTab.currentPath;
    }

    function requestPermanentDelete(paths) {
        if (!paths || paths.length === 0) return;
        if (AppController.confirmPermanentDelete) {
            confirmDeleteModal.permanent = true;
            confirmDeleteModal.targetPaths = paths;
            confirmDeleteModal.expanded = true;
        } else {
            FileOperations.deletePermanently(paths);
        }
    }

    function requestMoveToTrash(paths) {
        if (!paths || paths.length === 0) return;
        if (AppController.confirmMoveToTrash) {
            confirmDeleteModal.permanent = false;
            confirmDeleteModal.targetPaths = paths;
            confirmDeleteModal.expanded = true;
        } else {
            FileOperations.moveToTrash(paths);
        }
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

    // Paste files from the clipboard, or write a clipboard image to disk
    // as a .png and prompt the user to name it.
    function pasteFromClipboard() {
        let dir = getActiveDirectory();
        if (!dir) return;
        if (FileOperations.clipboardFiles.length > 0) {
            FileOperations.paste(dir);
        } else if (FileOperations.clipboardImageData && FileOperations.clipboardImageData.length > 0) {
            let created = FileOperations.pasteImage(dir);
            if (created && created.length > 0) {
                newItemModal.title = qsTr("Rename");
                newItemModal.icon = "drive_file_rename_outline";
                newItemModal.targetRenamePath = created;
                newItemModal.initialText = FileUtils.baseName(created);
                newItemModal.expanded = true;
            }
        }
    }

    // Full File Manager Mode
    Item {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Tab Bar
            TabBar {
                Layout.fillWidth: true
                onTabContextMenuRequested: (idx, gx, gy) => {
                    tabContextMenu.open(gx, gy, idx);
                }
                onFilesDropped: (sources, destDir, x, y) => {
                    dropActionMenu.sourceFiles = sources;
                    dropActionMenu.targetDir = destDir;
                    dropActionMenu.menuX = x;
                    dropActionMenu.menuY = y;
                    dropActionMenu.expanded = true;
                }
            }

            // Main Content Area
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

                    // Navigation Bar
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

                    // Central Workspace
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 0

                        // Places Sidebar
                        PlacesSidebar {
                            Layout.fillHeight: true
                            z: 1
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
                                editPlaceModal.reopenManager = false;
                                editPlaceModal.expanded = true;
                            }

                            onManagePlacesRequested: {
                                placesManageModal.expanded = true;
                            }

                            onConnectServerRequested: {
                                connectServerModal.expanded = true;
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

                            onItemOpenedInNewTab: item => {
                                if (item && item.isDir)
                                    TabManager.newTab(item.path, false);
                            }

                            onItemOpened: (item, pane) => {
                                if (AppIntegration.isRunnable(item.path))
                                    runFileModal.open(item.path);
                                else
                                    AppIntegration.openWithDefault(item.path);
                            }
                        }

                        // Information Preview Panel
                        PreviewPanel {
                            id: previewPanel
                            Layout.fillHeight: true
                            targetPath: splitContainer.currentSelectedPath
                            onPreviewClicked: path => {
                                mediaViewerModal.openFile(path, splitContainer.activeModel);
                            }
                        }
                    }

                    // Status Bar
                    StatusBar {
                        id: statusBar
                        Layout.fillWidth: true
                        activeModel: splitContainer.activeModel
                        activeTab: TabManager.currentTab
                        zoomLevel: window.zoomLevel
                        selectedCount: splitContainer.selectedPaths.length > 0 ? splitContainer.selectedPaths.length : (contextMenu.targetItem ? 1 : 0)
                        selectedName: {
                            if (splitContainer.selectedPaths.length === 1)
                                return splitContainer.selectedPaths[0].split("/").pop();
                            if (splitContainer.selectedPaths.length === 0 && contextMenu.targetItem)
                                return contextMenu.targetItem.name;
                            return "";
                        }
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
                    TabManager.newTab(item.path, false);
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
                    window.pasteFromClipboard();
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
                    if (targetPaths.length > 1) {
                        bulkRenameModal.targets = FileUtils.describePaths(targetPaths);
                        bulkRenameModal.expanded = true;
                    } else {
                        newItemModal.title = qsTr("Rename");
                        newItemModal.icon = "drive_file_rename_outline";
                        newItemModal.targetRenamePath = item.path;
                        newItemModal.initialText = item.name;
                        newItemModal.expanded = true;
                    }
                } else if (action === "trash" && item) {
                    window.requestMoveToTrash(targetPaths);
                } else if (action === "delete" && item) {
                    window.requestPermanentDelete(targetPaths);
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
                } else if (action.startsWith("quickCompress:") && item) {
                    let fmt = action.substring(14);
                    let defaultBase = targetPaths.length === 1 ? item.name : FileUtils.baseName(targetPaths[0]);
                    let ext = (fmt === "tar.gz") ? ".tar.gz" : ((fmt === "tar.xz") ? ".tar.xz" : ((fmt === "7z") ? ".7z" : ".zip"));
                    let destName = defaultBase.replace(/\.[^/.]+$/, "") + ext;
                    let curDir = window.getActiveDirectory();
                    FileOperations.createArchive(targetPaths, curDir + "/" + destName, fmt);
                } else if (action === "compress" && item) {
                    compressModal.sourcePaths = targetPaths;
                    compressModal.defaultName = targetPaths.length === 1 ? item.name : FileUtils.baseName(targetPaths[0]);
                    compressModal.expanded = true;
                } else if (action === "mediaClip" && item) {
                    mediaToolsModal.openFor(item.path, "clip");
                } else if (action === "mediaAspect" && item) {
                    mediaToolsModal.openFor(item.path, "aspect");
                } else if (action.startsWith("mediaConvert:") && item) {
                    MediaTools.convertMedia(item.path, action.substring(13));
                } else if (action.startsWith("mediaRotate:") && item) {
                    MediaTools.rotateMedia(item.path, Number(action.substring(12)));
                } else if (action === "mediaFlip:h" && item) {
                    MediaTools.flipMedia(item.path, true);
                } else if (action === "mediaFlip:v" && item) {
                    MediaTools.flipMedia(item.path, false);
                } else if (action === "mediaCircle" && item) {
                    MediaTools.circleCrop(item.path);
                } else if (action === "uploadCatbox") {
                    let pathsToUpload = (targetPaths && targetPaths.length > 0) ? targetPaths : (item && item.path ? [item.path] : []);
                    if (pathsToUpload.length > 0) {
                        operationsModal.expanded = true;
                        FileOperations.uploadToCatbox(pathsToUpload);
                    }
                } else if (action.startsWith("uploadLitterbox")) {
                    let time = "24h";
                    if (action.indexOf(":") !== -1) {
                        time = action.split(":")[1];
                    }
                    let pathsToUpload = (targetPaths && targetPaths.length > 0) ? targetPaths : (item && item.path ? [item.path] : []);
                    if (pathsToUpload.length > 0) {
                        operationsModal.expanded = true;
                        FileOperations.uploadToLitterbox(pathsToUpload, time);
                    }
                } else if (action.startsWith("newFromTemplate:")) {
                    const templatePath = action.substring(16);
                    newItemModal.title = qsTr("New from Template");
                    newItemModal.icon = "file_copy";
                    newItemModal.templateSource = templatePath;
                    newItemModal.initialText = templatePath.split("/").pop();
                    newItemModal.expanded = true;
                } else if (action === "newFile") {
                    newItemModal.title = qsTr("Create New File");
                    newItemModal.icon = "note_add";
                    newItemModal.initialText = "untitled.txt";
                    newItemModal.expanded = true;
                } else if (action === "restore" && item) {
                    for (let i = 0; i < targetPaths.length; ++i) {
                        FileOperations.restoreFromTrash(targetPaths[i]);
                    }
                } else if (action === "removeFromRecent" && item) {
                    FileOperations.removeFromRecent(targetPaths);
                    if (splitContainer.activeModel) {
                        splitContainer.activeModel.refresh();
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

        // Media Tools Modal (trim, convert, rotate, circle crop, aspect ratio)
        MediaToolsModal {
            id: mediaToolsModal
        }

        // Operations & Background Activity Modal
        OperationsModal {
            id: operationsModal
        }

        // Permanent Delete Confirmation Modal
        ConfirmDeleteModal {
            id: confirmDeleteModal
            onConfirmed: paths => {
                if (confirmDeleteModal.permanent)
                    FileOperations.deletePermanently(paths);
                else
                    FileOperations.moveToTrash(paths);
            }
        }

        // Executable File Run Prompt
        RunFileModal {
            id: runFileModal
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
                editPlaceModal.reopenManager = true;
                editPlaceModal.expanded = true;
            }
        }

        // Edit Place Modal
        EditPlaceModal {
            id: editPlaceModal

            property bool reopenManager: false

            onExpandedChanged: {
                if (!expanded && reopenManager) {
                    reopenManager = false;
                    placesManageModal.expanded = true;
                }
            }

            onAccepted: (idx, name, iconName) => {
                PlacesModel.updatePlace(idx, name, iconName);
            }
            onRemoveRequested: idx => {
                PlacesModel.removeBookmark(idx);
            }
        }

        // New Item / Rename Modal
        BulkRenameModal {
            id: bulkRenameModal
            onApplied: (paths, names) => FileOperations.bulkRename(paths, names)
        }

        NewItemModal {
            id: newItemModal
            onAccepted: text => {
                let currentDir = window.getActiveDirectory();
                if (title === qsTr("Create New Folder")) {
                    FileOperations.createDirectory(currentDir, text);
                } else if (title === qsTr("Create New File")) {
                    FileOperations.createFile(currentDir, text);
                } else if (title === qsTr("Select by Pattern")) {
                    splitContainer.selectByPattern(text);
                } else if (title === qsTr("New from Template")) {
                    FileOperations.createFromTemplate(newItemModal.templateSource, currentDir, text);
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
        Binding {
            target: GitManager
            property: "currentPath"
            value: TabManager.currentTab ? TabManager.currentTab.currentPath : ""
        }

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

        // Connect to Remote Server / SFTP Modal
        ConnectServerModal {
            id: connectServerModal
            activeTab: TabManager.currentTab
            onConnected: localPath => {
                window.setActiveDirectory(localPath);
            }
        }

        // Drive Manager Navigation Handler
        Connections {
            target: DriveManager
            function onDeviceMounted(mountPoint, tabIndex) {
                if (!mountPoint || mountPoint.length === 0) return;
                if (tabIndex === -1) {
                    TabManager.newTab(mountPoint);
                } else if (tabIndex >= 0 && tabIndex < TabManager.count) {
                    TabManager.currentIndex = tabIndex;
                    let tab = TabManager.currentTab;
                    if (tab) {
                        if (tab.isSplit && tab.activePane === 1) {
                            tab.splitPath = mountPoint;
                        } else {
                            tab.currentPath = mountPoint;
                        }
                    }
                } else if (TabManager.currentTab) {
                    let tab = TabManager.currentTab;
                    if (tab.isSplit && tab.activePane === 1) {
                        tab.splitPath = mountPoint;
                    } else {
                        tab.currentPath = mountPoint;
                    }
                }
            }
        }

        VectorBloomOverlay {
            id: vectorBloomOverlay
        }

        RunnerGameModal {
            id: runnerGameModal
        }

        AppShortcut {
            actionId: "view.previewMedia"
            active: !mediaViewerModal.expanded && !newItemModal.expanded && !editPlaceModal.expanded && !placesManageModal.expanded && !compressModal.expanded && !openWithModal.expanded && !preferencesModal.expanded && !mediaToolsModal.expanded && !runnerGameModal.isOpen && !vectorBloomOverlay.isOpen
            onActivated: {
                let paths = splitContainer.selectedPaths;
                if (paths && paths.length > 0) {
                    let path = paths[0];
                    if (FileUtils.isImage(path) || FileUtils.isVideo(path)) {
                        mediaViewerModal.openFile(path, splitContainer.activeModel);
                    }
                }
            }
        }

        AppShortcut {
            actionId: "app.preferences"
            onActivated: preferencesModal.expanded = true
        }

        AppShortcut {
            actionId: "tabs.new"
            onActivated: TabManager.newTab()
        }

        AppShortcut {
            actionId: "tabs.close"
            onActivated: {
                if (TabManager.currentTab && TabManager.currentTab.isSplit) {
                    TabManager.closeSplitPane(TabManager.currentIndex, TabManager.currentTab.activePane);
                } else {
                    TabManager.closeTab(TabManager.currentIndex);
                }
            }
        }

        AppShortcut {
            actionId: "tabs.next"
            onActivated: TabManager.nextTab()
        }

        AppShortcut {
            actionId: "tabs.previous"
            onActivated: TabManager.prevTab()
        }

        AppShortcut {
            actionId: "file.newFile"
            onActivated: {
                newItemModal.title = qsTr("Create New File");
                newItemModal.icon = "note_add";
                newItemModal.initialText = "untitled.txt";
                newItemModal.expanded = true;
            }
        }

        AppShortcut {
            actionId: "file.newFolder"
            onActivated: {
                newItemModal.title = qsTr("Create New Folder");
                newItemModal.icon = "create_new_folder";
                newItemModal.initialText = qsTr("New Folder");
                newItemModal.expanded = true;
            }
        }

        AppShortcut {
            actionId: "edit.copy"
            onActivated: {
                let paths = splitContainer.selectedPaths.length > 0 ? splitContainer.selectedPaths : (splitContainer.currentSelectedPath ? [splitContainer.currentSelectedPath] : []);
                if (paths.length > 0) FileOperations.copyPaths(paths);
            }
        }

        AppShortcut {
            actionId: "edit.cut"
            onActivated: {
                let paths = splitContainer.selectedPaths.length > 0 ? splitContainer.selectedPaths : (splitContainer.currentSelectedPath ? [splitContainer.currentSelectedPath] : []);
                if (paths.length > 0) FileOperations.cutPaths(paths);
            }
        }

        AppShortcut {
            actionId: "edit.paste"
            onActivated: window.pasteFromClipboard()
        }

        AppShortcut {
            actionId: "file.trash"
            onActivated: {
                let paths = splitContainer.selectedPaths.length > 0 ? splitContainer.selectedPaths : (splitContainer.currentSelectedPath ? [splitContainer.currentSelectedPath] : []);
                if (paths.length > 0) window.requestMoveToTrash(paths);
            }
        }

        AppShortcut {
            actionId: "file.deletePermanent"
            onActivated: {
                let paths = splitContainer.selectedPaths.length > 0 ? splitContainer.selectedPaths : (splitContainer.currentSelectedPath ? [splitContainer.currentSelectedPath] : []);
                if (paths.length > 0) window.requestPermanentDelete(paths);
            }
        }

        AppShortcut {
            actionId: "file.rename"
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

        AppShortcut {
            actionId: "file.properties"
            onActivated: {
                let sel = splitContainer.currentSelectedPath;
                if (sel && sel.length > 0) {
                    propertiesModal.targetPath = sel;
                    propertiesModal.expanded = true;
                }
            }
        }

        AppShortcut {
            actionId: "view.toggleHidden"
            onActivated: AppController.showHidden = !AppController.showHidden
        }

        AppShortcut {
            actionId: "edit.selectAll"
            onActivated: splitContainer.selectAll()
        }

        AppShortcut {
            actionId: "edit.clearSelection"
            onActivated: splitContainer.clearSelection()
        }

        AppShortcut {
            actionId: "edit.invertSelection"
            onActivated: splitContainer.invertSelection()
        }

        AppShortcut {
            actionId: "edit.selectByPattern"
            onActivated: {
                newItemModal.title = qsTr("Select by Pattern");
                newItemModal.icon = "filter_alt";
                newItemModal.initialText = "*";
                newItemModal.expanded = true;
            }
        }

        AppShortcut {
            actionId: "view.grid"
            onActivated: if (TabManager.currentTab) TabManager.currentTab.viewMode = 0
        }

        AppShortcut {
            actionId: "view.details"
            onActivated: if (TabManager.currentTab) TabManager.currentTab.viewMode = 1
        }

        AppShortcut {
            actionId: "view.compact"
            onActivated: if (TabManager.currentTab) TabManager.currentTab.viewMode = 2
        }

        AppShortcut {
            actionId: "nav.back"
            onActivated: if (TabManager.currentTab && TabManager.currentTab.canGoBack) TabManager.currentTab.goBack()
        }

        AppShortcut {
            actionId: "nav.forward"
            onActivated: if (TabManager.currentTab && TabManager.currentTab.canGoForward) TabManager.currentTab.goForward()
        }

        AppShortcut {
            actionId: "nav.parent"
            onActivated: if (TabManager.currentTab) TabManager.currentTab.goUp()
        }

        AppShortcut {
            actionId: "nav.home"
            onActivated: window.setActiveDirectory(FileUtils.home)
        }

        AppShortcut {
            actionId: "nav.search"
            onActivated: navBar.openSearch()
        }

        AppShortcut {
            actionId: "nav.address"
            onActivated: navBar.openAddressEdit()
        }

        AppShortcut {
            actionId: "view.split"
            onActivated: {
                if (TabManager.currentTab) {
                    TabManager.currentTab.isSplit = !TabManager.currentTab.isSplit;
                    if (TabManager.currentTab.isSplit && !TabManager.currentTab.splitPath) {
                        TabManager.currentTab.splitPath = TabManager.currentTab.currentPath;
                    }
                }
            }
        }

        AppShortcut {
            actionId: "tools.terminal"
            onActivated: {
                if (TabManager.currentTab) {
                    AppIntegration.openInTerminal(window.getActiveDirectory());
                }
            }
        }

        AppShortcut {
            actionId: "view.refresh"
            onActivated: {
                if (splitContainer.activeModel) {
                    splitContainer.activeModel.refresh();
                }
            }
        }

        AppShortcut {
            actionId: "view.previewPanel"
            onActivated: previewPanel.expanded = !previewPanel.expanded
        }

        AppShortcut {
            actionId: "app.fullscreen"
            onActivated: {
                if (window.visibility === Window.FullScreen) {
                    window.visibility = Window.Windowed;
                } else {
                    window.visibility = Window.FullScreen;
                }
            }
        }

        AppShortcut {
            actionId: "edit.undo"
            onActivated: FileOperations.undo()
        }

        AppShortcut {
            actionId: "edit.redo"
            onActivated: FileOperations.redo()
        }

        AppShortcut {
            actionId: "view.zoomIn"
            onActivated: window.zoomLevel = Math.min(180, window.zoomLevel + 16)
        }

        AppShortcut {
            actionId: "view.zoomOut"
            onActivated: window.zoomLevel = Math.max(48, window.zoomLevel - 16)
        }

        AppShortcut {
            actionId: "view.zoomReset"
            onActivated: window.zoomLevel = 80
        }

        // Global fallback MouseArea for Back/Forward Extra Mouse Buttons
        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.BackButton | Qt.ForwardButton | Qt.ExtraButton1 | Qt.ExtraButton2
            onClicked: mouse => {
                if (mouse.button === Qt.BackButton || mouse.button === Qt.ExtraButton1) {
                    if (TabManager.currentTab && TabManager.currentTab.canGoBack) {
                        TabManager.currentTab.goBack();
                    }
                } else if (mouse.button === Qt.ForwardButton || mouse.button === Qt.ExtraButton2) {
                    if (TabManager.currentTab && TabManager.currentTab.canGoForward) {
                        TabManager.currentTab.goForward();
                    }
                }
            }
        }
    }
}
