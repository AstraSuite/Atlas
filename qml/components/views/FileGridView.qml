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
    property int paneIndex: 0
    property real zoomSize: 80
    property int currentIndex: view.currentIndex
    readonly property var currentItem: view.currentItem ? view.currentItem.modelData : null
    property var selectedPaths: []
    property int anchorIndex: -1

    function notifyFocus() {
        if (root.activeTab && root.activeTab.activePane !== root.paneIndex) {
            root.activeTab.activePane = root.paneIndex;
        }
    }

    signal openItem(var item)
    signal itemContextMenu(var item, real mouseX, real mouseY)
    signal blankContextMenu(real mouseX, real mouseY)
    signal filesDropped(var sourceFiles, string targetDir, real mouseX, real mouseY)

    // Background Drop Area (Dropping into current folder empty space)
    DropArea {
        id: backgroundDropArea
        anchors.fill: parent
        z: 0

        onDropped: drop => {
            if (drop.hasUrls) {
                let urls = [];
                for (let i = 0; i < drop.urls.length; ++i) {
                    urls.push(FileUtils.toLocalFile(drop.urls[i]));
                }
                let destDir = root.activeTab ? root.activeTab.currentPath : "";
                let filtered = urls.filter(u => u !== destDir);
                if (filtered.length > 0 && destDir) {
                    let globalPos = mapToItem(null, drop.x, drop.y);
                    if (drop.modifiers & Qt.ShiftModifier) {
                        FileOperations.moveFiles(filtered, destDir);
                    } else if (drop.modifiers & Qt.ControlModifier) {
                        FileOperations.copyFiles(filtered, destDir);
                    } else {
                        root.filesDropped(filtered, destDir, globalPos.x, globalPos.y);
                    }
                    drop.accept();
                }
            }
        }
    }

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
        anchorIndex = index;
        view.currentIndex = index;
        selectedPaths = [path];
    }

    function selectRange(targetIndex) {
        if (!root.model || root.model.count === 0) return;
        let start = anchorIndex !== -1 ? anchorIndex : (view.currentIndex !== -1 ? view.currentIndex : 0);
        let minIdx = Math.max(0, Math.min(start, targetIndex));
        let maxIdx = Math.min(root.model.count - 1, Math.max(start, targetIndex));
        let arr = [];
        for (let i = minIdx; i <= maxIdx; ++i) {
            let entry = root.model.get(i);
            if (entry) {
                arr.push(entry.path);
            }
        }
        selectedPaths = arr;
        view.currentIndex = targetIndex;
    }

    VerticalFadeGridView {
        id: view
        z: 1

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
            // Reactive Drag state: indicates items currently in flight
            readonly property bool isDragged: FileOperations.activeDragFiles.indexOf(modelData.path) !== -1
            // Unhidden hidden files (dotfiles) visual distinction
            readonly property bool isHidden: delegateContainer.modelData ? (delegateContainer.modelData.isHidden || delegateContainer.modelData.name.startsWith('.')) : false

            // Drop Area for Folders (Drag-over Drop Target)
            DropArea {
                id: folderDropArea
                anchors.fill: parent
                z: 1
                enabled: delegateContainer.modelData ? delegateContainer.modelData.isDir : false

                onDropped: drop => {
                    if (drop.hasUrls) {
                        let urls = [];
                        for (let i = 0; i < drop.urls.length; ++i) {
                            urls.push(FileUtils.toLocalFile(drop.urls[i]));
                        }
                        let destDir = delegateContainer.modelData.path;
                        let filtered = urls.filter(u => u !== destDir);
                        if (filtered.length > 0) {
                            let globalPos = mapToItem(null, drop.x, drop.y);
                            if (drop.modifiers & Qt.ShiftModifier) {
                                FileOperations.moveFiles(filtered, destDir);
                            } else if (drop.modifiers & Qt.ControlModifier) {
                                FileOperations.copyFiles(filtered, destDir);
                            } else {
                                root.filesDropped(filtered, destDir, globalPos.x, globalPos.y);
                            }
                            drop.accept();
                        }
                    }
                }
            }

            // Uniform Card Highlight Size
            StyledRect {
                id: itemCard
                anchors.centerIn: parent
                width: parent.width - 8
                height: parent.height - 8

                radius: Tokens.rounding.large
                color: folderDropArea.containsDrag
                    ? Colours.palette.m3primaryContainer
                    : (delegateContainer.isSelected ? Colours.palette.m3secondaryContainer : (itemHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent"))

                clip: true

                // Cut & Hidden & Dragging Files Indication: Darkened / Ghosted Opacity
                opacity: delegateContainer.isDragged ? 0.35 : (delegateContainer.isCut ? 0.38 : (delegateContainer.isHidden ? 0.58 : 1.0))

                Behavior on opacity {
                    Anim {
                        type: Anim.FastEffects
                    }
                }

                // Pop in animation on folder entry / reload and grow animation when hovered during drag
                scale: folderDropArea.containsDrag ? 1.08 : 1.0
                Component.onCompleted: popInAnim.start()

                Behavior on scale {
                    enabled: !popInAnim.running
                    Anim { type: Anim.FastEffects }
                }

                ParallelAnimation {
                    id: popInAnim
                    NumberAnimation {
                        target: itemCard
                        property: "scale"
                        from: 0.6
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
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton | Qt.ExtraButton1 | Qt.ExtraButton2

                    property real pressX: 0
                    property real pressY: 0
                    property bool isDragging: false

                    onPressed: mouse => {
                        root.notifyFocus();
                        if (mouse.button === Qt.BackButton || mouse.button === Qt.ExtraButton1) {
                            if (root.activeTab && root.activeTab.canGoBack) root.activeTab.goBack();
                            return;
                        } else if (mouse.button === Qt.ForwardButton || mouse.button === Qt.ExtraButton2) {
                            if (root.activeTab && root.activeTab.canGoForward) root.activeTab.goForward();
                            return;
                        }
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
                                FileOperations.startNativeDrag(paths, itemCard.width, itemCard.height, root.zoomSize);
                            }
                        }
                    }

                    onClicked: mouse => {
                        root.notifyFocus();
                        if (isDragging || dragSelectArea.isSelecting) return;
                        if (mouse.button === Qt.BackButton || mouse.button === Qt.ExtraButton1) {
                            if (root.activeTab && root.activeTab.canGoBack) root.activeTab.goBack();
                        } else if (mouse.button === Qt.ForwardButton || mouse.button === Qt.ExtraButton2) {
                            if (root.activeTab && root.activeTab.canGoForward) root.activeTab.goForward();
                        } else if (mouse.button === Qt.RightButton) {
                            if (!root.isSelected(delegateContainer.modelData.path)) {
                                root.selectSingle(delegateContainer.modelData.path, delegateContainer.index);
                            }
                            let globalPos = mapToItem(null, mouse.x, mouse.y);
                            root.itemContextMenu(delegateContainer.modelData, globalPos.x, globalPos.y);
                        } else {
                            if (mouse.modifiers & Qt.ShiftModifier) {
                                root.selectRange(delegateContainer.index);
                            } else if (mouse.modifiers & Qt.ControlModifier) {
                                root.toggleSelection(delegateContainer.modelData.path);
                                root.anchorIndex = delegateContainer.index;
                            } else {
                                root.selectSingle(delegateContainer.modelData.path, delegateContainer.index);
                            }
                        }
                    }

                    onDoubleClicked: mouse => {
                        root.notifyFocus();
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
                            if (file.isImage || file.isVideo) {
                                source = "image://thumb/" + file.path;
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

    // Background Mouse Area for Deselection, Context Menu on empty space, and Rubber Band Selection
    MouseArea {
        id: dragSelectArea
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton | Qt.ExtraButton1 | Qt.ExtraButton2

        onWheel: wheel => {
            if (wheel.modifiers & Qt.ControlModifier) {
                if (wheel.angleDelta.y > 0) {
                    zoomLevel = Math.min(2.0, zoomLevel + 0.15);
                } else if (wheel.angleDelta.y < 0) {
                    zoomLevel = Math.max(0.4, zoomLevel - 0.15);
                }
                wheel.accepted = true;
            } else {
                view.flick(0, wheel.angleDelta.y * 6);
            }
        }

        property real startX: 0
        property real startY: 0
        property real currentX: 0
        property real currentY: 0
        property bool isSelecting: false
        property bool wasSelecting: false

        onPressed: mouse => {
            root.notifyFocus();
            if (mouse.button === Qt.BackButton || mouse.button === Qt.ExtraButton1) {
                if (root.activeTab && root.activeTab.canGoBack) root.activeTab.goBack();
                return;
            } else if (mouse.button === Qt.ForwardButton || mouse.button === Qt.ExtraButton2) {
                if (root.activeTab && root.activeTab.canGoForward) root.activeTab.goForward();
                return;
            }
            startX = mouse.x;
            startY = mouse.y;
            currentX = mouse.x;
            currentY = mouse.y;
            isSelecting = false;
            wasSelecting = false;
        }

        onPositionChanged: mouse => {
            if (mouse.buttons & Qt.LeftButton) {
                currentX = mouse.x;
                currentY = mouse.y;
                let dx = currentX - startX;
                let dy = currentY - startY;
                if (!isSelecting && (dx * dx + dy * dy) > 36) {
                    isSelecting = true;
                    wasSelecting = true;
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
            }
        }

        onClicked: mouse => {
            if (wasSelecting) {
                wasSelecting = false;
                return;
            }
            if (mouse.button === Qt.RightButton) {
                let globalPos = mapToItem(null, mouse.x, mouse.y);
                root.blankContextMenu(globalPos.x, globalPos.y);
            } else if (mouse.button === Qt.LeftButton) {
                root.selectedPaths = [];
                view.currentIndex = -1;
                root.anchorIndex = -1;
            }
        }

        function updateRubberBandSelection() {
            let rx = Math.min(startX, currentX) - view.x + view.contentX;
            let ry = Math.min(startY, currentY) - view.y + view.contentY;
            let rw = Math.abs(currentX - startX);
            let rh = Math.abs(currentY - startY);

            let cols = Math.max(1, Math.floor(view.width / view.cellWidth));
            let newlySelected = [];
            let total = root.model ? root.model.count : 0;
            for (let i = 0; i < total; ++i) {
                let col = i % cols;
                let row = Math.floor(i / cols);
                let ix = col * view.cellWidth;
                let iy = row * view.cellHeight;
                let iw = view.cellWidth;
                let ih = view.cellHeight;

                if (ix < rx + rw && ix + iw > rx && iy < ry + rh && iy + ih > ry) {
                    let entry = root.model.get(i);
                    if (entry) {
                        newlySelected.push(entry.path);
                    }
                }
            }
            root.selectedPaths = newlySelected;
        }
    }

    // Rubber Band Visual Rectangle (renders on top of everything)
    Rectangle {
        z: 999
        visible: dragSelectArea.isSelecting
        x: Math.min(dragSelectArea.startX, dragSelectArea.currentX)
        y: Math.min(dragSelectArea.startY, dragSelectArea.currentY)
        width: Math.abs(dragSelectArea.currentX - dragSelectArea.startX)
        height: Math.abs(dragSelectArea.currentY - dragSelectArea.startY)
        color: Qt.alpha(Colours.palette.m3primary, 0.18)
        border.color: Colours.palette.m3primary
        border.width: 1.5
        radius: Tokens.rounding.extraSmall
    }
}
