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

        delegate: Item {
            id: compDelegate

            required property int index
            required property var modelData

            width: gridView.cellWidth
            height: gridView.cellHeight

            readonly property bool isSelected: root.isSelected(modelData.path) || (gridView.currentIndex === index)
            // Reactive Cut state
            readonly property bool isCut: FileOperations.isCutOperation && FileOperations.clipboardFiles.indexOf(modelData.path) !== -1
            // Reactive Drag state
            readonly property bool isDragged: FileOperations.activeDragFiles.indexOf(modelData.path) !== -1
            // Unhidden hidden files (dotfiles) visual distinction
            readonly property bool isHidden: compDelegate.modelData ? (compDelegate.modelData.isHidden || compDelegate.modelData.name.startsWith('.')) : false

            // Drop Area for Folders
            DropArea {
                id: folderDropArea
                anchors.fill: parent
                z: 1
                enabled: compDelegate.modelData ? compDelegate.modelData.isDir : false

                onDropped: drop => {
                    if (drop.hasUrls) {
                        let urls = [];
                        for (let i = 0; i < drop.urls.length; ++i) {
                            urls.push(FileUtils.toLocalFile(drop.urls[i]));
                        }
                        let destDir = compDelegate.modelData.path;
                        let filtered = urls.filter(u => u !== destDir);
                        if (filtered.length > 0) {
                            FileOperations.moveFiles(filtered, destDir);
                            drop.accept();
                        }
                    }
                }
            }

            StyledRect {
                id: compCard
                anchors.centerIn: parent
                width: parent.width - 6
                height: parent.height - 4

                radius: Tokens.rounding.small
                color: folderDropArea.containsDrag
                    ? Colours.palette.m3primaryContainer
                    : (compDelegate.isSelected ? Colours.palette.m3secondaryContainer : (compHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent"))

                // Cut & Hidden & Dragging Files Indication: Darkened / Ghosted Opacity
                opacity: compDelegate.isDragged ? 0.35 : (compDelegate.isCut ? 0.38 : (compDelegate.isHidden ? 0.58 : 1.0))

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

                    property real pressX: 0
                    property real pressY: 0
                    property bool isDragging: false

                    onPressed: mouse => {
                        pressX = mouse.x;
                        pressY = mouse.y;
                        isDragging = false;
                    }

                    onPositionChanged: mouse => {
                        if (dragSelectArea.isSelecting) return;
                        if (mouse.buttons & Qt.LeftButton) {
                            let dx = mouse.x - pressX;
                            let dy = mouse.y - pressY;
                            if (!isDragging && (dx * dx + dy * dy) > 64) {
                                isDragging = true;
                                let paths = root.isSelected(compDelegate.modelData.path) ? root.selectedPaths : [compDelegate.modelData.path];
                                FileOperations.startNativeDrag(paths, 180, 50, 24);
                            }
                        }
                    }

                    onClicked: mouse => {
                        if (isDragging || dragSelectArea.isSelecting) return;
                        if (mouse.button === Qt.BackButton) {
                            if (root.activeTab && root.activeTab.canGoBack) root.activeTab.goBack();
                        } else if (mouse.button === Qt.ForwardButton) {
                            if (root.activeTab && root.activeTab.canGoForward) root.activeTab.goForward();
                        } else if (mouse.button === Qt.RightButton) {
                            if (!root.isSelected(compDelegate.modelData.path)) {
                                root.selectSingle(compDelegate.modelData.path, compDelegate.index);
                            }
                            let globalPos = mapToItem(null, mouse.x, mouse.y);
                            root.itemContextMenu(compDelegate.modelData, globalPos.x, globalPos.y);
                        } else {
                            if (mouse.modifiers & Qt.ControlModifier) {
                                root.toggleSelection(compDelegate.modelData.path);
                            } else {
                                root.selectSingle(compDelegate.modelData.path, compDelegate.index);
                            }
                        }
                    }

                    onDoubleClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            root.openItem(compDelegate.modelData);
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
                                const file = compDelegate.modelData;
                                if (file.isImage) {
                                    source = Qt.resolvedUrl("file://" + file.path);
                                } else {
                                    source = FileUtils.iconForFile(file.name, file.isDir, file.mimeType);
                                }
                            }
                        }

                        // Lock Indicator (Top Left)
                        MaterialIcon {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: -4
                            visible: compDelegate.modelData ? compDelegate.modelData.isReadOnly : false
                            text: "lock"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3error
                            z: 2
                        }

                        // Symlink Indicator (Bottom Right)
                        MaterialIcon {
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.margins: -3
                            visible: compDelegate.modelData ? compDelegate.modelData.isSymLink : false
                            text: "link"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3primary
                            z: 2
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: compDelegate.modelData ? compDelegate.modelData.name : ""
                        color: compDelegate.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    // Top-Level Rubber Band Selection Overlay
    MouseArea {
        id: dragSelectArea
        anchors.fill: parent
        z: 999
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton
        propagateComposedEvents: true

        onWheel: wheel => {
            gridView.flick(wheel.angleDelta.y * 6, 0);
        }

        property real startX: 0
        property real startY: 0
        property real currentX: 0
        property real currentY: 0
        property bool isSelecting: false

        onPressed: mouse => {
            startX = mouse.x;
            startY = mouse.y;
            currentX = mouse.x;
            currentY = mouse.y;
            isSelecting = false;
            mouse.accepted = false;
        }

        onPositionChanged: mouse => {
            if (mouse.buttons & Qt.LeftButton) {
                currentX = mouse.x;
                currentY = mouse.y;
                let dx = currentX - startX;
                let dy = currentY - startY;
                if (!isSelecting && (dx * dx + dy * dy) > 36) {
                    isSelecting = true;
                    if (!(mouse.modifiers & Qt.ControlModifier)) {
                        root.selectedPaths = [];
                        gridView.currentIndex = -1;
                    }
                }
                if (isSelecting) {
                    updateRubberBandSelection();
                }
            }
        }

        onReleased: mouse => {
            if (isSelecting) {
                isSelecting = false;
                mouse.accepted = true;
            } else {
                mouse.accepted = false;
            }
        }

        function updateRubberBandSelection() {
            let rx = Math.min(startX, currentX) - gridView.x + gridView.contentX;
            let ry = Math.min(startY, currentY) - gridView.y;
            let rw = Math.abs(currentX - startX);
            let rh = Math.abs(currentY - startY);

            let newlySelected = [];
            for (let i = 0; i < gridView.count; ++i) {
                let item = gridView.itemAtIndex(i);
                if (item && item.modelData) {
                    if (item.x < rx + rw && item.x + item.width > rx &&
                        item.y < ry + rh && item.y + item.height > ry) {
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
            color: Qt.alpha(Colours.palette.m3primary, 0.22)
            border.color: Colours.palette.m3primary
            border.width: 1.5
            radius: Tokens.rounding.extraSmall
        }
    }
}
