import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "components"
import "components/filedialog"
import "components/tabs"
import "components/navigation"
import "components/panels"
import "components/views"
import "components/menus"
import "components/dialogs"
import "components/statusbar"
import prism

ApplicationWindow {
    id: root

    visible: true
    title: pickerActive ? (AppController.title.length > 0 ? AppController.title : qsTr("Select a file")) : (TabManager.currentTab ? TabManager.currentTab.title + " — Prism" : qsTr("Prism"))
    width: 1060
    height: 680
    minimumWidth: 520
    minimumHeight: 400
    color: Colours.tPalette.m3surface

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

            // 3. Central Workspace (Sidebar + Split Views + Preview Panel)
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

                // Split View Container (Main Pane + Split Pane)
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
                activeModel: null
                selectedCount: contextMenu.targetItem ? 1 : 0
                selectedSizeFormatted: contextMenu.targetItem ? (contextMenu.targetItem.isDir ? "" : contextMenu.targetItem.formattedSize) : ""
                onZoomChanged: level => zoomLevel = level
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
                    FileOperations.cutToClipboard([item.path]);
                } else if (action === "copy" && item) {
                    FileOperations.copyToClipboard([item.path]);
                } else if (action === "paste") {
                    FileOperations.paste(currentDir);
                } else if (action === "symlink" && item) {
                    symlinkModal.targetPath = item.path;
                    symlinkModal.initialText = item.name + " (link)";
                    symlinkModal.expanded = true;
                } else if (action === "pasteSymlink") {
                    FileOperations.pasteAsSymlink(currentDir);
                } else if (action === "rename" && item) {
                    renameModal.targetPath = item.path;
                    renameModal.initialText = item.name;
                    renameModal.expanded = true;
                } else if (action === "duplicate" && item) {
                    FileOperations.duplicateFile(item.path);
                } else if (action === "trash" && item) {
                    FileOperations.moveToTrash([item.path]);
                } else if (action === "properties" && item) {
                    propertiesModal.targetPath = item.path;
                    propertiesModal.expanded = true;
                } else if (action === "propertiesDir") {
                    propertiesModal.targetPath = currentDir;
                    propertiesModal.expanded = true;
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
                } else if (action === "bookmark") {
                    PlacesModel.addBookmark(currentDir);
                } else if (action === "terminal") {
                    AppIntegration.openInTerminal(currentDir);
                }
            }
        }

        // Modals
        NewItemModal {
            id: newItemModal
            onAccepted: text => {
                let currentDir = TabManager.currentTab ? TabManager.currentTab.currentPath : "";
                if (icon === "create_new_folder") {
                    FileOperations.createDirectory(currentDir, text);
                } else {
                    FileOperations.createFile(currentDir, text);
                }
            }
        }

        NewItemModal {
            id: renameModal
            property string targetPath: ""
            title: qsTr("Rename")
            icon: "drive_file_rename_outline"
            onAccepted: text => {
                FileOperations.renameFile(targetPath, text);
            }
        }

        NewItemModal {
            id: symlinkModal
            property string targetPath: ""
            title: qsTr("Create Symlink")
            icon: "link"
            onAccepted: text => {
                let currentDir = TabManager.currentTab ? TabManager.currentTab.currentPath : "";
                FileOperations.createSymlink(targetPath, currentDir + "/" + text);
            }
        }

        EditPlaceModal {
            id: editPlaceModal
            onAccepted: (index, name, iconName) => {
                PlacesModel.updatePlace(index, name, iconName);
            }
            onRemoveRequested: index => {
                PlacesModel.removeBookmark(index);
            }
        }

        PropertiesModal {
            id: propertiesModal
        }

        // Global Shortcuts
        Shortcut {
            sequence: "Ctrl+T"
            onActivated: TabManager.newTab()
        }

        Shortcut {
            sequence: "Ctrl+W"
            onActivated: TabManager.closeTab(TabManager.currentIndex)
        }

        Shortcut {
            sequence: "Ctrl+C"
            onActivated: {
                if (splitContainer.currentSelectedPath.length > 0) {
                    FileOperations.copyToClipboard([splitContainer.currentSelectedPath]);
                }
            }
        }

        Shortcut {
            sequence: "Ctrl+X"
            onActivated: {
                if (splitContainer.currentSelectedPath.length > 0) {
                    FileOperations.cutToClipboard([splitContainer.currentSelectedPath]);
                }
            }
        }

        Shortcut {
            sequence: "Ctrl+V"
            onActivated: {
                if (TabManager.currentTab) {
                    FileOperations.paste(TabManager.currentTab.currentPath);
                }
            }
        }

        Shortcut {
            sequence: "Delete"
            onActivated: {
                if (splitContainer.currentSelectedPath.length > 0) {
                    FileOperations.moveToTrash([splitContainer.currentSelectedPath]);
                }
            }
        }

        Shortcut {
            sequence: "Shift+Delete"
            onActivated: {
                if (splitContainer.currentSelectedPath.length > 0) {
                    FileOperations.deleteFiles([splitContainer.currentSelectedPath], true);
                }
            }
        }

        Shortcut {
            sequence: "F2"
            onActivated: {
                if (splitContainer.currentSelectedPath.length > 0) {
                    renameModal.targetPath = splitContainer.currentSelectedPath;
                    renameModal.initialText = splitContainer.currentSelectedPath.split("/").pop();
                    renameModal.expanded = true;
                }
            }
        }

        Shortcut {
            sequence: "Alt+Return"
            onActivated: {
                if (splitContainer.currentSelectedPath.length > 0) {
                    propertiesModal.targetPath = splitContainer.currentSelectedPath;
                    propertiesModal.expanded = true;
                }
            }
        }

        Shortcut {
            sequence: "Alt+Left"
            onActivated: if (TabManager.currentTab && TabManager.currentTab.canGoBack) TabManager.currentTab.goBack()
        }

        Shortcut {
            sequence: "Backspace"
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
            sequence: "F3"
            onActivated: TabManager.toggleSplitView()
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

    // Modal File Picker Dialog Mode (--picker)
    FileDialog {
        id: fileDialog
        visible: pickerActive
        anchors.centerIn: parent
        title: AppController.title.length > 0 ? AppController.title : qsTr("Select a file")
        filterLabel: AppController.filterLabel.length > 0 ? AppController.filterLabel : qsTr("All files")
        filters: AppController.filters
        showHidden: AppController.showHidden
        directoryOnly: AppController.directoryOnly
        initialDirectory: AppController.initialDirectory

        onAccepted: path => {
            AppController.acceptFile(path);
        }

        onRejected: {
            AppController.cancelPicker();
        }
    }
}
