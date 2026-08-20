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
    property var selectedPaths: []

    signal openItem(var item)
    signal itemContextMenu(var item, real mouseX, real mouseY)
    signal blankContextMenu(real mouseX, real mouseY)

    function isSelected(path) {
        return selectedPaths.indexOf(path) !== -1;
    }

    function toggleSelection(path) {
        let idx = selectedPaths.indexOf(path);
        let arr = selectedPaths.slice();
        if (idx === -1) {
            arr.push(path);
        } else {
            arr.splice(idx, 1);
        }
        selectedPaths = arr;
    }

    function selectSingle(path, index) {
        view.currentIndex = index;
        selectedPaths = [path];
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

        Keys.onEscapePressed: {
            currentIndex = -1;
            root.selectedPaths = [];
        }
        Keys.onReturnPressed: if (currentItem) root.openItem(currentItem)
        Keys.onEnterPressed: if (currentItem) root.openItem(currentItem)

        ScrollBar.vertical: StyledScrollBar {
            flickable: view
        }

        model: root.model

        // Multi-Selection Rubber Band Dragging Area
        MouseArea {
            id: dragSelectArea
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton

            property real startX: 0
            property real startY: 0
            property real currentX: 0
            property real currentY: 0
            property bool isSelecting: false

            onPressed: mouse => {
                if (mouse.button === Qt.LeftButton) {
                    startX = mouse.x;
                    startY = mouse.y;
                    currentX = mouse.x;
                    currentY = mouse.y;
                    isSelecting = false;
                    if (!(mouse.modifiers & Qt.ControlModifier)) {
                        root.selectedPaths = [];
                        view.currentIndex = -1;
                    }
                }
            }

            onPositionChanged: mouse => {
                if (pressed && (mouse.buttons & Qt.LeftButton)) {
                    currentX = mouse.x;
                    currentY = mouse.y;
                    if (Math.abs(currentX - startX) > 4 || Math.abs(currentY - startY) > 4) {
                        isSelecting = true;
                        updateRubberBandSelection();
                    }
                }
            }

            onReleased: mouse => {
                if (mouse.button === Qt.BackButton) {
                    if (root.activeTab && root.activeTab.canGoBack) root.activeTab.goBack();
                } else if (mouse.button === Qt.ForwardButton) {
                    if (root.activeTab && root.activeTab.canGoForward) root.activeTab.goForward();
                } else if (mouse.button === Qt.RightButton) {
                    let globalPos = mapToItem(null, mouse.x, mouse.y);
                    root.blankContextMenu(globalPos.x, globalPos.y);
                }
                isSelecting = false;
            }

            function updateRubberBandSelection() {
                let rx = Math.min(startX, currentX);
                let ry = Math.min(startY, currentY);
                let rw = Math.abs(currentX - startX);
                let rh = Math.abs(currentY - startY);

                let newlySelected = [];
                for (let i = 0; i < view.count; ++i) {
                    let item = view.itemAtIndex(i);
                    if (item && item.modelData) {
                        // Check rectangle overlap
                        if (item.x + item.width > rx && item.x < rx + rw &&
                            item.y + item.height > ry && item.y < ry + rh) {
                            newlySelected.push(item.modelData.path);
                        }
                    }
                }
                root.selectedPaths = newlySelected;
            }

            // Visual Rubber Band Box
            Rectangle {
                visible: dragSelectArea.isSelecting
                x: Math.min(dragSelectArea.startX, dragSelectArea.currentX)
                y: Math.min(dragSelectArea.startY, dragSelectArea.currentY)
                width: Math.abs(dragSelectArea.currentX - dragSelectArea.startX)
                height: Math.abs(dragSelectArea.currentY - dragSelectArea.startY)
                color: Qt.alpha(Colours.palette.m3primary, 0.2)
                border.color: Colours.palette.m3primary
                border.width: 1.5
                radius: Tokens.rounding.extraSmall
                z: 100
            }
        }

        delegate: StyledRect {
            id: item

            required property int index
            required property var modelData

            readonly property bool isSelected: root.isSelected(modelData.path) || GridView.isCurrentItem
            readonly property bool isCut: FileOperations.isPathCut(modelData.path)

            implicitWidth: root.zoomSize + 24
            implicitHeight: icon.implicitHeight + name.anchors.topMargin + name.implicitHeight + Tokens.padding.medium * 2

            radius: Tokens.rounding.large
            color: isSelected ? Colours.palette.m3secondaryContainer : (itemHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent")
            z: isSelected ? 1 : 0
            clip: true

            // Cut Indication: Darkened / Ghosted Opacity
            opacity: isCut ? 0.42 : 1.0

            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }

            // Pop in animation on directory switch / item load
            scale: 0.6

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
                        if (!root.isSelected(item.modelData.path)) {
                            root.selectSingle(item.modelData.path, item.index);
                        }
                        let globalPos = mapToItem(null, mouse.x, mouse.y);
                        root.itemContextMenu(item.modelData, globalPos.x, globalPos.y);
                    } else {
                        if (mouse.modifiers & Qt.ControlModifier) {
                            root.toggleSelection(item.modelData.path);
                        } else {
                            root.selectSingle(item.modelData.path, item.index);
                        }
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
                color: item.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                font: Tokens.font.body.small
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
                maximumLineCount: 2
                wrapMode: Text.WrapAnywhere
            }
        }
    }
}
