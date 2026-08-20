import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../"
import prism

StyledRect {
    id: root

    required property var activeTab
    property real zoomSize: 80
    property string searchQuery: ""
    readonly property bool isSplit: activeTab && activeTab.isSplit
    property real splitRatio: 0.5

    readonly property var currentSelectedPath: {
        if (mainViewLoader && mainViewLoader.item && mainViewLoader.item.currentItem) {
            return mainViewLoader.item.currentItem.path;
        }
        return activeTab ? activeTab.currentPath : "";
    }
    readonly property var selectedPaths: (mainViewLoader && mainViewLoader.item && mainViewLoader.item.selectedPaths) ? mainViewLoader.item.selectedPaths : []
    readonly property var activeModel: mainModel

    signal itemContextMenu(var item, real mouseX, real mouseY)
    signal blankContextMenu(real mouseX, real mouseY)
    signal filesDropped(var sources, string destDir, real mouseX, real mouseY)
    signal createNewFolder()
    signal createNewFile()
    signal itemOpened(var item, int pane)

    color: Colours.tPalette.m3surfaceContainer

    Item {
        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall

        // Left / Main Pane
        StyledRect {
            id: pane1
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.isSplit ? Math.max(120, Math.min(parent.width - 120, (parent.width - resizer.width) * root.splitRatio)) : parent.width

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surface
            clip: true

            FileSystemModel {
                id: mainModel
                path: root.activeTab ? root.activeTab.currentPath : ""
                searchQuery: root.searchQuery
                showHidden: AppController.showHidden
            }

            Loader {
                id: mainViewLoader
                anchors.fill: parent

                sourceComponent: {
                    let mode = root.activeTab ? root.activeTab.viewMode : 0;
                    if (mode === 1) return detailsComp;
                    if (mode === 2) return compactComp;
                    return gridComp;
                }
            }

            // Nexus-Style Empty State
            EmptyStateView {
                visible: mainModel.count === 0
                path: root.activeTab ? root.activeTab.currentPath : ""
                isSearching: mainModel.isSearching
                searchQuery: root.searchQuery
                onCreateFolder: root.createNewFolder()
                onCreateFile: root.createNewFile()
            }
        }

        // Resizable Splitter Divider Bar
        Item {
            id: resizer
            visible: root.isSplit
            anchors.left: pane1.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 8
            z: 20

            Rectangle {
                anchors.centerIn: parent
                width: 2
                height: parent.height - 16
                radius: 1
                color: (resizeMouse.containsMouse || resizeMouse.drag.active) ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
                opacity: (resizeMouse.containsMouse || resizeMouse.drag.active) ? 1.0 : 0.45

                Behavior on color { Anim { type: Anim.FastEffects } }
                Behavior on opacity { Anim { type: Anim.FastEffects } }
            }

            MouseArea {
                id: resizeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor

                property real startMouseX: 0
                property real startRatio: 0.5

                onPressed: mouse => {
                    startMouseX = mouse.x;
                    startRatio = root.splitRatio;
                }

                onPositionChanged: mouse => {
                    if (pressed) {
                        let totalW = root.width - resizer.width - Tokens.padding.extraSmall * 2;
                        if (totalW > 200) {
                            let currentPos = pane1.width + (mouse.x - startMouseX);
                            let newRatio = currentPos / totalW;
                            root.splitRatio = Math.max(0.15, Math.min(0.85, newRatio));
                        }
                    }
                }
            }
        }

        // Right / Secondary Pane
        StyledRect {
            id: pane2
            visible: root.isSplit
            anchors.left: resizer.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surface
            clip: true

            FileSystemModel {
                id: splitModel
                path: (root.activeTab && root.activeTab.splitPath) ? root.activeTab.splitPath : ""
                showHidden: AppController.showHidden
            }

            Loader {
                id: splitViewLoader
                anchors.fill: parent

                sourceComponent: {
                    let mode = root.activeTab ? root.activeTab.viewMode : 0;
                    if (mode === 1) return splitDetailsComp;
                    if (mode === 2) return splitCompactComp;
                    return splitGridComp;
                }
            }

            // Secondary Empty State
            EmptyStateView {
                visible: splitModel.count === 0
                path: (root.activeTab && root.activeTab.splitPath) ? root.activeTab.splitPath : ""
                isSearching: false
                onCreateFolder: root.createNewFolder()
                onCreateFile: root.createNewFile()
            }
        }
    }

    // Left Pane Components
    Component {
        id: gridComp
        FileGridView {
            model: mainModel
            activeTab: root.activeTab
            zoomSize: root.zoomSize
            onOpenItem: item => root.handleOpen(item, 0)
            onItemContextMenu: (item, x, y) => root.itemContextMenu(item, x, y)
            onBlankContextMenu: (x, y) => root.blankContextMenu(x, y)
            onFilesDropped: (sources, destDir, x, y) => root.filesDropped(sources, destDir, x, y)
        }
    }

    Component {
        id: detailsComp
        FileDetailsView {
            model: mainModel
            activeTab: root.activeTab
            onOpenItem: item => root.handleOpen(item, 0)
            onItemContextMenu: (item, x, y) => root.itemContextMenu(item, x, y)
            onBlankContextMenu: (x, y) => root.blankContextMenu(x, y)
            onFilesDropped: (sources, destDir, x, y) => root.filesDropped(sources, destDir, x, y)
        }
    }

    Component {
        id: compactComp
        FileCompactView {
            model: mainModel
            activeTab: root.activeTab
            onOpenItem: item => root.handleOpen(item, 0)
            onItemContextMenu: (item, x, y) => root.itemContextMenu(item, x, y)
            onBlankContextMenu: (x, y) => root.blankContextMenu(x, y)
            onFilesDropped: (sources, destDir, x, y) => root.filesDropped(sources, destDir, x, y)
        }
    }

    // Right Pane Components
    Component {
        id: splitGridComp
        FileGridView {
            model: splitModel
            activeTab: root.activeTab
            zoomSize: root.zoomSize
            onOpenItem: item => root.handleOpen(item, 1)
            onItemContextMenu: (item, x, y) => root.itemContextMenu(item, x, y)
            onBlankContextMenu: (x, y) => root.blankContextMenu(x, y)
            onFilesDropped: (sources, destDir, x, y) => root.filesDropped(sources, destDir, x, y)
        }
    }

    Component {
        id: splitDetailsComp
        FileDetailsView {
            model: splitModel
            activeTab: root.activeTab
            onOpenItem: item => root.handleOpen(item, 1)
            onItemContextMenu: (item, x, y) => root.itemContextMenu(item, x, y)
            onBlankContextMenu: (x, y) => root.blankContextMenu(x, y)
            onFilesDropped: (sources, destDir, x, y) => root.filesDropped(sources, destDir, x, y)
        }
    }

    Component {
        id: splitCompactComp
        FileCompactView {
            model: splitModel
            activeTab: root.activeTab
            onOpenItem: item => root.handleOpen(item, 1)
            onItemContextMenu: (item, x, y) => root.itemContextMenu(item, x, y)
            onBlankContextMenu: (x, y) => root.blankContextMenu(x, y)
            onFilesDropped: (sources, destDir, x, y) => root.filesDropped(sources, destDir, x, y)
        }
    }

    function handleOpen(item, pane) {
        if (!item) return;
        if (item.isDir) {
            if (pane === 1) {
                root.activeTab.splitPath = item.path;
            } else {
                root.activeTab.currentPath = item.path;
            }
        } else {
            root.itemOpened(item, pane);
        }
    }
}
