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
    signal createNewFolder()
    signal createNewFile()

    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall
        spacing: Tokens.spacing.extraSmall

        // Left / Main Pane
        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
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

            // Floating Bottom-Right Pane Close Pill (media_1787207433898.png)
            StyledRect {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 12
                implicitHeight: 28
                implicitWidth: pane1Row.implicitWidth + 16
                radius: Tokens.rounding.full
                color: Colours.palette.m3surfaceContainerLowest
                border.color: Colours.palette.m3outlineVariant
                border.width: 1
                visible: root.isSplit
                z: 100

                RowLayout {
                    id: pane1Row
                    anchors.centerIn: parent
                    spacing: 6

                    StyledText {
                        text: (root.activeTab && root.activeTab.title) ? root.activeTab.title : ""
                        font: Tokens.font.label.small
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideRight
                    }

                    Item {
                        implicitWidth: 16
                        implicitHeight: 16

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "close"
                            fontStyle: Tokens.font.icon.small
                            color: closePane1Hover.containsMouse ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                        }

                        MouseArea {
                            id: closePane1Hover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (TabManager.currentTab) {
                                    TabManager.closeSplitPane(TabManager.currentIndex, 0);
                                }
                            }
                        }
                    }
                }
            }
        }

        // Split Divider Bar
        Rectangle {
            visible: root.isSplit
            Layout.fillHeight: true
            implicitWidth: 2
            color: Colours.palette.m3outlineVariant
            opacity: 0.5
        }

        // Right / Secondary Pane (media_1787207433898.png)
        StyledRect {
            visible: root.isSplit
            Layout.fillWidth: true
            Layout.fillHeight: true
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

            // Floating Bottom-Right Secondary Pane Close Pill
            StyledRect {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 12
                implicitHeight: 28
                implicitWidth: pane2Row.implicitWidth + 16
                radius: Tokens.rounding.full
                color: Colours.palette.m3surfaceContainerLowest
                border.color: Colours.palette.m3outlineVariant
                border.width: 1
                visible: root.isSplit
                z: 100

                RowLayout {
                    id: pane2Row
                    anchors.centerIn: parent
                    spacing: 6

                    StyledText {
                        text: (root.activeTab && root.activeTab.splitTitle) ? root.activeTab.splitTitle : ""
                        font: Tokens.font.label.small
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideRight
                    }

                    Item {
                        implicitWidth: 16
                        implicitHeight: 16

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "close"
                            fontStyle: Tokens.font.icon.small
                            color: closePane2Hover.containsMouse ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                        }

                        MouseArea {
                            id: closePane2Hover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (TabManager.currentTab) {
                                    TabManager.closeSplitPane(TabManager.currentIndex, 1);
                                }
                            }
                        }
                    }
                }
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
