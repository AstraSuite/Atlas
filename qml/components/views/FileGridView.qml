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

        // Exact uniform cell dimensions (padded for >= 16 characters per line)
        cellWidth: Math.max(144, root.zoomSize + 48)
        cellHeight: root.zoomSize + 84

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

        delegate: Item {
            id: delegateContainer

            required property int index
            required property var modelData

            width: view.cellWidth
            height: view.cellHeight

            readonly property bool isSelected: root.isSelected(modelData.path) || (view.currentIndex === index)
            // Reactive Cut state: updates instantly on clipboard change
            readonly property bool isCut: FileOperations.isCutOperation && FileOperations.clipboardFiles.indexOf(modelData.path) !== -1
            // Unhidden hidden files (dotfiles) visual distinction
            readonly property bool isHidden: delegateContainer.modelData ? (delegateContainer.modelData.isHidden || delegateContainer.modelData.name.startsWith('.')) : false

            // Uniform Card Highlight Size
            StyledRect {
                id: itemCard
                anchors.centerIn: parent
                width: parent.width - 8
                height: parent.height - 8

                radius: Tokens.rounding.large
                color: delegateContainer.isSelected ? Colours.palette.m3secondaryContainer : (itemHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent")
                clip: true

                // Cut & Hidden Files Indication: Darkened / Ghosted Opacity
                opacity: delegateContainer.isCut ? 0.38 : (delegateContainer.isHidden ? 0.58 : 1.0)

                Behavior on opacity {
                    Anim {
                        type: Anim.FastEffects
                    }
                }

                // Pop in animation
                scale: 0.6
                Component.onCompleted: popInAnim.start()

                ParallelAnimation {
                    id: popInAnim
                    NumberAnimation {
                        target: itemCard
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
                                let paths = root.isSelected(delegateContainer.modelData.path) ? root.selectedPaths : [delegateContainer.modelData.path];
                                FileOperations.startNativeDrag(paths);
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
                            if (!root.isSelected(delegateContainer.modelData.path)) {
                                root.selectSingle(delegateContainer.modelData.path, delegateContainer.index);
                            }
                            let globalPos = mapToItem(null, mouse.x, mouse.y);
                            root.itemContextMenu(delegateContainer.modelData, globalPos.x, globalPos.y);
                        } else {
                            if (mouse.modifiers & Qt.ControlModifier) {
                                root.toggleSelection(delegateContainer.modelData.path);
                            } else {
                                root.selectSingle(delegateContainer.modelData.path, delegateContainer.index);
                            }
                        }
                    }

                    onDoubleClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            root.openItem(delegateContainer.modelData);
                        }
                    }
                }

                Item {
                    id: iconContainer
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    width: root.zoomSize
                    height: root.zoomSize

                    CachingIconImage {
                        id: icon
                        anchors.fill: parent
                        implicitSize: root.zoomSize

                        Component.onCompleted: {
                            const file = delegateContainer.modelData;
                            if (file.isImage) {
                                source = Qt.resolvedUrl("file://" + file.path);
                            } else {
                                source = FileUtils.iconForFile(file.name, file.isDir, file.mimeType);
                            }
                        }
                    }

                    // Lock Indicator Badge (Top Left)
                    StyledRect {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: Tokens.rounding.full
                        color: Qt.alpha(Colours.palette.m3surface, 0.9)
                        visible: delegateContainer.modelData ? delegateContainer.modelData.isReadOnly : false
                        z: 5

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "lock"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3error
                        }
                    }

                    // Symlink Indicator Badge (Bottom Right)
                    StyledRect {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: Tokens.rounding.full
                        color: Qt.alpha(Colours.palette.m3surface, 0.9)
                        visible: delegateContainer.modelData ? delegateContainer.modelData.isSymLink : false
                        z: 5

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
                    anchors.topMargin: 4
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 4

                    text: delegateContainer.modelData ? delegateContainer.modelData.name : ""
                    color: delegateContainer.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    font: Tokens.font.body.small
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignTop
                    elide: Text.ElideMiddle
                    maximumLineCount: 4
                    wrapMode: Text.WrapAnywhere
                }
            }
        }
    }

    // Top-Level Rubber Band Selection Overlay (renders ABOVE everything)
    MouseArea {
        id: dragSelectArea
        anchors.fill: parent
        z: 999
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton
        propagateComposedEvents: true

        onWheel: wheel => {
            view.flick(0, wheel.angleDelta.y * 6);
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
                        view.currentIndex = -1;
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
            let rx = Math.min(startX, currentX) - view.x + view.contentX;
            let ry = Math.min(startY, currentY) - view.y + view.contentY;
            let rw = Math.abs(currentX - startX);
            let rh = Math.abs(currentY - startY);

            let newlySelected = [];
            for (let i = 0; i < view.count; ++i) {
                let item = view.itemAtIndex(i);
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
