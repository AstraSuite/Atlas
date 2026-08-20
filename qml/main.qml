import QtQuick
import QtQuick.Window
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

ApplicationWindow {
    id: root

    width: isPickerMode ? 820 : 1060
    height: isPickerMode ? 540 : 700
    minimumWidth: isPickerMode ? 640 : 640
    minimumHeight: isPickerMode ? 420 : 420

    visible: true
    title: isPickerMode ? (AppController.title.length > 0 ? AppController.title : qsTr("Select a file")) : qsTr("Prism")

    color: Colours.palette.m3surface

    // File Picker Mode
    Loader {
        anchors.fill: parent
        active: isPickerMode
        visible: isPickerMode

        sourceComponent: FileDialog {
            id: fileDialog

            title: AppController.title
            initialDirectory: AppController.initialDirectory
            filters: AppController.filters
            filterLabel: AppController.filterLabel
            showHidden: AppController.showHidden
            directoryOnly: AppController.directoryOnly

            onAccepted: path => {
                AppController.accept(path);
            }

            onRejected: {
                AppController.reject();
            }
        }
    }

    // Full File Manager Mode
    Item {
        anchors.fill: parent
        visible: !isPickerMode

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
                    targetPath: contextMenu.targetItem ? contextMenu.targetItem.path : ""
                    onCloseRequested: expanded = false
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
            sequence: "F11"
            onActivated: previewPanel.expanded = !previewPanel.expanded
        }

        Shortcut {
            sequence: "Ctrl+H"
            onActivated: AppController.showHidden = !AppController.showHidden
        }

        Shortcut {
            sequence: "Ctrl+Shift+N"
            onActivated: {
                newItemModal.title = qsTr("Create New Folder");
                newItemModal.icon = "create_new_folder";
                newItemModal.initialText = qsTr("New Folder");
                newItemModal.expanded = true;
            }
        }
    }
}
