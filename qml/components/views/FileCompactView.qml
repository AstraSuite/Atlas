import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../containers"
import prism

Item {
    id: root

    required property var model
    required property var activeTab
    property int currentIndex: gridView.currentIndex
    readonly property var currentItem: gridView.currentItem ? gridView.currentItem.modelData : null

    signal openItem(var item)
    signal itemContextMenu(var item, real mouseX, real mouseY)
    signal blankContextMenu(real mouseX, real mouseY)

    GridView {
        id: gridView

        anchors.fill: parent
        anchors.margins: Tokens.padding.small
        cellWidth: 220
        cellHeight: 38
        flow: GridView.FlowTopToBottom
        clip: true
        focus: true
        currentIndex: -1

        ScrollBar.horizontal: StyledScrollBar {
            flickable: gridView
        }

        model: root.model

        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.RightButton | Qt.BackButton | Qt.ForwardButton
            onClicked: mouse => {
                if (mouse.button === Qt.BackButton) {
                    if (root.activeTab && root.activeTab.canGoBack) root.activeTab.goBack();
                } else if (mouse.button === Qt.ForwardButton) {
                    if (root.activeTab && root.activeTab.canGoForward) root.activeTab.goForward();
                } else if (mouse.button === Qt.RightButton) {
                    let globalPos = mapToItem(null, mouse.x, mouse.y);
                    root.blankContextMenu(globalPos.x, globalPos.y);
                }
            }
        }

        delegate: StyledRect {
            id: compItem

            required property int index
            required property var modelData

            width: 210
            implicitHeight: 32

            radius: Tokens.rounding.small
            color: compItem.GridView.isCurrentItem ? Colours.palette.m3secondaryContainer : (compHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent")

            // Cut Indicator: Dim item when cut
            readonly property bool isCut: compItem.modelData ? FileOperations.isPathCut(compItem.modelData.path) : false
            opacity: isCut ? 0.45 : (populated ? 1.0 : 0.0)
            scale: populated ? 1.0 : 0.6
            property bool populated: false

            Component.onCompleted: {
                populated = true;
            }

            Behavior on opacity {
                Anim { type: Anim.DefaultEffects }
            }

            Behavior on scale {
                Anim {
                    type: Anim.SlowEffects
                    easing: Tokens.anim.emphasizedDecel
                }
            }

            MouseArea {
                id: compHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton

                onClicked: mouse => {
                    if (mouse.button === Qt.BackButton) {
                        if (root.activeTab && root.activeTab.canGoBack) root.activeTab.goBack();
                    } else if (mouse.button === Qt.ForwardButton) {
                        if (root.activeTab && root.activeTab.canGoForward) root.activeTab.goForward();
                    } else if (mouse.button === Qt.RightButton) {
                        gridView.currentIndex = compItem.index;
                        let globalPos = mapToItem(null, mouse.x, mouse.y);
                        root.itemContextMenu(compItem.modelData, globalPos.x, globalPos.y);
                    } else {
                        gridView.currentIndex = compItem.index;
                    }
                }

                onDoubleClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        root.openItem(compItem.modelData);
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.small
                anchors.rightMargin: Tokens.padding.small
                spacing: Tokens.spacing.small

                Item {
                    implicitWidth: 20
                    implicitHeight: 20

                    CachingIconImage {
                        anchors.fill: parent
                        implicitSize: 20

                        Component.onCompleted: {
                            const file = compItem.modelData;
                            if (file.isImage) {
                                source = Qt.resolvedUrl("file://" + file.path);
                            } else {
                                source = FileUtils.iconForFile(file.name, file.isDir, file.mimeType);
                            }
                        }
                    }

                    MaterialIcon {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        visible: compItem.modelData ? compItem.modelData.isSymLink : false
                        text: "link"
                        fontStyle: Tokens.font.icon.small
                        color: Colours.palette.m3primary
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: compItem.modelData ? compItem.modelData.name : ""
                    color: compItem.GridView.isCurrentItem ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }
        }
    }
}
