import QtQuick
import QtQuick.Layouts
import "../"

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
        anchors.margins: Tokens.padding.medium

        cellWidth: 220
        cellHeight: 36
        flow: GridView.FlowTopToBottom

        clip: true
        focus: true
        currentIndex: -1

        model: root.model

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: gridView
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.RightButton
            onClicked: mouse => {
                root.blankContextMenu(mouse.x, mouse.y)
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

            MouseArea {
                id: compHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: mouse => {
                    gridView.currentIndex = compItem.index;
                    if (mouse.button === Qt.RightButton) {
                        let globalPos = mapToItem(null, mouse.x, mouse.y);
                        root.itemContextMenu(compItem.modelData, globalPos.x, globalPos.y);
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

                CachingIconImage {
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
