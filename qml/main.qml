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

                            onEditPlaceRequested: (index, name, path, iconName, isCustom) => {
                                editPlaceModal.targetIndex = index;
                                editPlaceModal.placeName = name;
                                editPlaceModal.placePath = path;
                                editPlaceModal.selectedIcon = iconName;
                                editPlaceModal.isCustom = isCustom;
                                editPlaceModal.expanded = true;
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
                        }

                        // Information / Preview Panel (F11)
                        PreviewPanel {
                            id: previewPanel
                            Layout.fillHeight: true
                            targetPath: splitContainer.currentSelectedPath
                        }
                    }

                    // 4. Bottom Status Bar
                    StatusBar {
                        id: statusBar
                        Layout.fillWidth: true
                        activeModel: splitContainer.activeModel
                        selectedCount: splitContainer.selectedPaths.length > 0 ? splitContainer.selectedPaths.length : (contextMenu.targetItem ? 1 : 0)
                        selectedSizeFormatted: contextMenu.targetItem ? (contextMenu.targetItem.isDir ? "" : contextMenu.targetItem.formattedSize) : ""
                        onZoomChanged: level => zoomLevel = level
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
                if (action === "open" && item) {
                    if (item.isDir) {
                        TabManager.currentTab.currentPath = item.path;
                    } else {
                        AppIntegration.openWithDefault(item.path);
                    }
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

        // Edit Place Modal
        EditPlaceModal {
            id: editPlaceModal
            onAccepted: (idx, name, iconName) => {
                PlacesModel.updatePlace(idx, name, iconName);
            }
            onRemoveRequested: idx => {
                PlacesModel.removePlace(idx);
            }
        }

        // New Item / Rename Modal
        NewItemModal {
            id: newItemModal
            onAccepted: text => {
                let currentDir = TabManager.currentTab ? TabManager.currentTab.currentPath : "";
                if (title === qsTr("Create New Folder")) {
                    FileOperations.createFolder(currentDir, text);
                } else if (title === qsTr("Create New File")) {
                    FileOperations.createFile(currentDir, text);
                } else if (title === qsTr("Rename") && contextMenu.targetItem) {
                    FileOperations.renameItem(contextMenu.targetItem.path, text);
                }
            }
        }

        // Properties Modal
        PropertiesModal {
            id: propertiesModal
        }

        // Global Desktop Shortcuts
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
            sequence: "Ctrl+F"
            onActivated: navBar.openSearch()
        }

        Shortcut {
            sequence: "Ctrl+L"
            onActivated: navBar.openAddressEdit()
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
                if (TabManager.currentTab) {
                    TabManager.currentTab.currentPath = TabManager.currentTab.currentPath;
                }
            }
        }

        Shortcut {
            sequence: "F11"
            onActivated: previewPanel.expanded = !previewPanel.expanded
        }
    }

    // Modal File Dialog Picker Mode
    FileDialog {
        id: fileDialogComponent
        anchors.fill: parent
        visible: pickerActive
    }
}
