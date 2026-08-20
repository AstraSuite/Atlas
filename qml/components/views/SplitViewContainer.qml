import QtQuick
import QtQuick.Layouts
import "../"
import prism

Item {
    id: root

    required property var activeTab
    property real zoomSize: 80

    signal itemContextMenu(var item, real mouseX, real mouseY)
    signal blankContextMenu(real mouseX, real mouseY)

    RowLayout {
        anchors.fill: parent
        spacing: Tokens.spacing.small

        // Primary Pane
        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer

            FileSystemModel {
                id: mainModel
                path: root.activeTab ? root.activeTab.currentPath : ""
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
        }

        // Secondary Split Pane (F3)
        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer
            visible: root.activeTab && root.activeTab.isSplit

            FileSystemModel {
                id: splitModel
                path: (root.activeTab && root.activeTab.isSplit) ? root.activeTab.splitPath : ""
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
        }
    }

    // Main Components
    Component {
        id: gridComp
        FileGridView {
            model: mainModel
            activeTab: root.activeTab
            zoomSize: root.zoomSize
            onOpenItem: item => root.handleOpen(item, 0)
            onItemContextMenu: (item, x, y) => root.itemContextMenu(item, x, y)
            onBlankContextMenu: (x, y) => root.blankContextMenu(x, y)
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
        }
    }

    // Split Pane Components
    Component {
        id: splitGridComp
        FileGridView {
            model: splitModel
            activeTab: root.activeTab
            zoomSize: root.zoomSize
            onOpenItem: item => root.handleOpen(item, 1)
            onItemContextMenu: (item, x, y) => root.itemContextMenu(item, x, y)
            onBlankContextMenu: (x, y) => root.blankContextMenu(x, y)
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
            AppIntegration.openWithDefault(item.path);
        }
    }
}
