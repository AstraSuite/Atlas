import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

Item {
    id: root

    required property var model
    required property var activeTab
    property real zoomSize: 80
    property int currentIndex: view.currentIndex
    readonly property var currentItem: view.currentItem ? view.currentItem.modelData : null

    signal openItem(var item)
    signal itemContextMenu(var item, real mouseX, real mouseY)
    signal blankContextMenu(real mouseX, real mouseY)

    GridView {
        id: view

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall + Tokens.padding.medium

        cellWidth: root.zoomSize + 24 + Tokens.spacing.small
        cellHeight: root.zoomSize + 24 + Tokens.spacing.large + Tokens.padding.medium * 2 + 1

        clip: true
        focus: true
        currentIndex: -1

        Keys.onEscapePressed: currentIndex = -1
        Keys.onReturnPressed: {
            if (currentItem) root.openItem(currentItem)
        }
        Keys.onEnterPressed: {
            if (currentItem) root.openItem(currentItem)
        }

        ScrollBar.vertical: StyledScrollBar {
            flickable: view
        }

        model: root.model

        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.RightButton
            onClicked: mouse => {
                let globalPos = mapToItem(null, mouse.x, mouse.y);
                root.blankContextMenu(globalPos.x, globalPos.y);
            }
        }

        delegate: StyledRect {
            id: item

            required property int index
            required property var modelData

            implicitWidth: root.zoomSize + 24
            implicitHeight: icon.implicitHeight + name.anchors.topMargin + name.implicitHeight + Tokens.padding.medium * 2

            radius: Tokens.rounding.large
            color: GridView.isCurrentItem ? Colours.palette.m3secondaryContainer : (itemHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent")
            z: GridView.isCurrentItem ? 1 : 0
            clip: true

            MouseArea {
                id: itemHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: mouse => {
                    view.currentIndex = item.index;
                    if (mouse.button === Qt.RightButton) {
                        let globalPos = mapToItem(null, mouse.x, mouse.y);
                        root.itemContextMenu(item.modelData, globalPos.x, globalPos.y);
                    }
                }

                onDoubleClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        root.openItem(item.modelData);
                    }
                }
            }

            CachingIconImage {
                id: icon

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Tokens.padding.medium

                implicitSize: root.zoomSize

                Component.onCompleted: {
                    const file = item.modelData;
                    if (file.isImage) {
                        source = Qt.resolvedUrl("file://" + file.path);
                    } else {
                        source = FileUtils.iconForFile(file.name, file.isDir, file.mimeType);
                    }
                }
            }

            StyledText {
                id: name

                anchors.top: icon.bottom
                anchors.topMargin: Tokens.padding.small
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Tokens.padding.small

                text: item.modelData ? item.modelData.name : ""
                color: item.GridView.isCurrentItem ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                font: Tokens.font.body.small
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
                maximumLineCount: 2
                wrapMode: Text.WrapAnywhere
            }
        }
    }
}
