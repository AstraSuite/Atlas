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
        gridView.currentIndex = index;
        selectedPaths = [path];
    }

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
        interactive: false

        ScrollBar.horizontal: StyledScrollBar {
            flickable: gridView
        }

        model: root.model

        // Rubber Band Multi-Selection Area
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
                        gridView.currentIndex = -1;
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
                for (let i = 0; i < gridView.count; ++i) {
                    let item = gridView.itemAtIndex(i);
                    if (item && item.modelData) {
                        if (item.x + item.width > rx && item.x < rx + rw &&
                            item.y + item.height > ry && item.y < ry + rh) {
                            newlySelected.push(item.modelData.path);
                        }
                    }
                }
                root.selectedPaths = newlySelected;
            }

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
            id: compItem

            required property int index
            required property var modelData

            readonly property bool isSelected: root.isSelected(modelData.path) || GridView.isCurrentItem
            readonly property bool isCut: FileOperations.isPathCut(modelData.path)

            width: 210
            implicitHeight: 32

            radius: Tokens.rounding.small
            color: isSelected ? Colours.palette.m3secondaryContainer : (compHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent")

            // Cut Indication: Darkened / Ghosted Opacity
            opacity: isCut ? 0.42 : 1.0

            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
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
                        if (!root.isSelected(compItem.modelData.path)) {
                            root.selectSingle(compItem.modelData.path, compItem.index);
                        }
                        let globalPos = mapToItem(null, mouse.x, mouse.y);
                        root.itemContextMenu(compItem.modelData, globalPos.x, globalPos.y);
                    } else {
                        if (mouse.modifiers & Qt.ControlModifier) {
                            root.toggleSelection(compItem.modelData.path);
                        } else {
                            root.selectSingle(compItem.modelData.path, compItem.index);
                        }
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
                    color: compItem.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }
        }
    }
}
