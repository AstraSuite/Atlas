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

    // Rubberband Marquee Selection Box
    Rectangle {
        id: rubberBand
        visible: false
        color: Qt.alpha(Colours.palette.m3primary, 0.2)
        border.color: Colours.palette.m3primary
        border.width: 1
        radius: 3
        z: 90
    }

    VerticalFadeGridView {
        id: view

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall + Tokens.padding.medium

        cellWidth: root.zoomSize + 24 + Tokens.spacing.small
        cellHeight: root.zoomSize + 24 + Tokens.spacing.large + Tokens.padding.medium * 2 + 1

        clip: true
        focus: true
        currentIndex: -1
        interactive: false

        Keys.onEscapePressed: currentIndex = -1
        Keys.onReturnPressed: if (currentItem) root.openItem(currentItem)
        Keys.onEnterPressed: if (currentItem) root.openItem(currentItem)

        ScrollBar.vertical: StyledScrollBar {
            flickable: view
        }

        model: root.model

        // Drag to Select Multiple Files / Rubberband Marquee
        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton

            property real startX: 0
            property real startY: 0
            property bool isSelecting: false

            onPressed: mouse => {
                if (mouse.button === Qt.LeftButton) {
                    startX = mouse.x;
                    startY = mouse.y;
                    isSelecting = false;
                    view.currentIndex = -1;
                }
            }

            onPositionChanged: mouse => {
                if (pressed && (Math.abs(mouse.x - startX) > 5 || Math.abs(mouse.y - startY) > 5)) {
                    isSelecting = true;
                    rubberBand.x = Math.min(startX, mouse.x) + view.x;
                    rubberBand.y = Math.min(startY, mouse.y) + view.y;
                    rubberBand.width = Math.abs(mouse.x - startX);
                    rubberBand.height = Math.abs(mouse.y - startY);
                    rubberBand.visible = true;

                    // Select intersecting item
                    let midX = (startX + mouse.x) / 2;
                    let midY = (startY + mouse.y) / 2;
                    let idx = view.indexAt(midX, midY + view.contentY);
                    if (idx >= 0) view.currentIndex = idx;
                }
            }

            onReleased: mouse => {
                rubberBand.visible = false;
                isSelecting = false;
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

            // Cut Indicator: Darken / Dim item opacity when marked for cut
            readonly property bool isCut: item.modelData ? FileOperations.isPathCut(item.modelData.path) : false
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
