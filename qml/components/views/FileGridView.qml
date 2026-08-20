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
    property real zoomSize: 80
    property int currentIndex: view.currentIndex
    readonly property var currentItem: view.currentItem ? view.currentItem.modelData : null

    signal openItem(var item)
    signal itemContextMenu(var item, real mouseX, real mouseY)
    signal blankContextMenu(real mouseX, real mouseY)

    VerticalFadeGridView {
        id: view

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall + Tokens.padding.medium

        cellWidth: root.zoomSize + 24 + Tokens.spacing.small
        cellHeight: root.zoomSize + 24 + Tokens.spacing.large + Tokens.padding.medium * 2 + 1

        clip: true
        focus: true
        currentIndex: -1

        Keys.onEscapePressed: currentIndex = -1
        Keys.onReturnPressed: if (currentItem) root.openItem(currentItem)
        Keys.onEnterPressed: if (currentItem) root.openItem(currentItem)

        ScrollBar.vertical: StyledScrollBar {
            flickable: view
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
            id: item

            required property int index
            required property var modelData

            implicitWidth: root.zoomSize + 24
            implicitHeight: icon.implicitHeight + name.anchors.topMargin + name.implicitHeight + Tokens.padding.medium * 2

            radius: Tokens.rounding.large
            color: GridView.isCurrentItem ? Colours.palette.m3secondaryContainer : (itemHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent")
            z: GridView.isCurrentItem ? 1 : 0
            clip: true

            // Pop in animation on directory switch / item load
            scale: 0.6
            opacity: 0.0

            Component.onCompleted: popInAnim.start()

            ParallelAnimation {
                id: popInAnim

                NumberAnimation {
                    target: item
                    property: "scale"
                    from: 0.5
                    to: 1.0
                    duration: 250
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.3
                }

                NumberAnimation {
                    target: item
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                id: itemHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton

                onClicked: mouse => {
                    if (mouse.button === Qt.BackButton) {
                        if (root.activeTab && root.activeTab.canGoBack) root.activeTab.goBack();
                    } else if (mouse.button === Qt.ForwardButton) {
                        if (root.activeTab && root.activeTab.canGoForward) root.activeTab.goForward();
                    } else if (mouse.button === Qt.RightButton) {
                        view.currentIndex = item.index;
                        let globalPos = mapToItem(null, mouse.x, mouse.y);
                        root.itemContextMenu(item.modelData, globalPos.x, globalPos.y);
                    } else {
                        view.currentIndex = item.index;
                    }
                }

                onDoubleClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        root.openItem(item.modelData);
                    }
                }
            }

            Item {
                id: iconContainer
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Tokens.padding.medium
                width: root.zoomSize
                height: root.zoomSize

                CachingIconImage {
                    id: icon
                    anchors.fill: parent
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

                // Symlink Indicator Badge
                StyledRect {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: Tokens.rounding.full
                    color: Qt.alpha(Colours.palette.m3surface, 0.85)
                    visible: item.modelData ? item.modelData.isSymLink : false

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "link"
                        fontStyle: Tokens.font.icon.small
                        color: Colours.palette.m3primary
                    }
                }
            }

            StyledText {
                id: name

                anchors.top: iconContainer.bottom
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
