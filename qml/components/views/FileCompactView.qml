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
    readonly property int iconSize: Math.max(16, Math.min(64, Math.round(20 * zoomSize / 80)))
    property int paneIndex: 0
    property int currentIndex: gridView.currentIndex
    readonly property var currentItem: {
        if (gridView.currentIndex >= 0 && root.model && gridView.currentIndex < root.model.count) {
            return root.model.get(gridView.currentIndex);
        }
        if (selectedPaths.length > 0 && root.model) {
            let idx = root.model.indexOfPath(selectedPaths[0]);
            if (idx >= 0) return root.model.get(idx);
        }
        if (gridView.currentItem && gridView.currentItem.modelData) {
            return gridView.currentItem.modelData;
        }
        return null;
    }
    property var selectedPaths: []
    property int anchorIndex: -1

    function forceActiveFocus() {
        gridView.forceActiveFocus();
    }

    function notifyFocus() {
        gridView.forceActiveFocus();
        if (root.activeTab && root.activeTab.activePane !== root.paneIndex) {
            root.activeTab.activePane = root.paneIndex;
        }
    }

    signal openItem(var item)
    signal itemContextMenu(var item, real mouseX, real mouseY)
    signal blankContextMenu(real mouseX, real mouseY)
    signal filesDropped(var sourceFiles, string targetDir, real mouseX, real mouseY)

    // Background Drop Area
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
        gridView.forceActiveFocus();
    }

    function selectSingle(path, index) {
        anchorIndex = index;
        gridView.currentIndex = index;
        selectedPaths = [path];
        gridView.forceActiveFocus();
    }

    function selectRange(targetIndex) {
        if (!root.model || root.model.count === 0) return;
        let start = anchorIndex !== -1 ? anchorIndex : (gridView.currentIndex !== -1 ? gridView.currentIndex : 0);
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
        gridView.currentIndex = targetIndex;
        gridView.forceActiveFocus();
    }

    GridView {
        id: gridView
        z: 1

        anchors.fill: parent
        anchors.margins: Tokens.padding.small
        cellWidth: Math.max(220, 200 + root.iconSize)
        cellHeight: root.iconSize + 18
        flow: GridView.FlowTopToBottom
        clip: true
        focus: true
        currentIndex: -1
        interactive: false
        boundsBehavior: Flickable.DragAndOvershootBounds
        maximumFlickVelocity: 5000
        flickDeceleration: 5000

        WheelHandler {
            target: gridView
            acceptedModifiers: Qt.NoModifier
            onWheel: event => {
                let vx = 0;
                if (event.pixelDelta.x !== 0) {
                    vx = event.pixelDelta.x * 25;
                } else if (event.pixelDelta.y !== 0) {
                    vx = event.pixelDelta.y * 25;
                } else if (event.angleDelta.y !== 0) {
                    vx = event.angleDelta.y * 14;
                } else if (event.angleDelta.x !== 0) {
                    vx = event.angleDelta.x * 14;
                }
                if (vx !== 0) {
                    gridView.flick(vx, 0);
                    event.accepted = true;
                }
            }
        }

        displaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: Tokens.anim.durations.expressiveFastSpatial
                easing: Tokens.anim.expressiveFastSpatial
            }
        }
        move: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: Tokens.anim.durations.expressiveFastSpatial
                easing: Tokens.anim.expressiveFastSpatial
            }
        }

        Component.onCompleted: gridView.forceActiveFocus()

        onCurrentIndexChanged: {
            if (currentIndex >= 0 && currentIndex < (root.model ? root.model.count : 0)) {
                let entry = root.model.get(currentIndex);
                if (entry && root.selectedPaths.length <= 1) {
                    root.selectedPaths = [entry.path];
                    root.anchorIndex = currentIndex;
                }
            }
        }

        Keys.onEscapePressed: {
            currentIndex = -1;
            root.selectedPaths = [];
        }
        Keys.onReturnPressed: if (root.currentItem) root.openItem(root.currentItem)
        Keys.onEnterPressed: if (root.currentItem) root.openItem(root.currentItem)
        Keys.onSpacePressed: if (root.currentItem && typeof mediaViewerModal !== "undefined" && mediaViewerModal) mediaViewerModal.openFile(root.currentItem.path, root.model)

        Keys.onPressed: event => {
            // F-Key Accelerators
            if (event.key === Qt.Key_F2) {
                if (root.currentItem && typeof newItemModal !== "undefined" && newItemModal) {
                    newItemModal.title = qsTr("Rename");
                    newItemModal.icon = "drive_file_rename_outline";
                    newItemModal.targetRenamePath = root.currentItem.path;
                    newItemModal.initialText = FileUtils.baseName(root.currentItem.path);
                    newItemModal.expanded = true;
                    event.accepted = true;
                    return;
                }
            } else if (event.key === Qt.Key_F4) {
                let curDir = root.activeTab ? root.activeTab.currentPath : "";
                if (curDir.length > 0) {
                    AppIntegration.openInTerminal(curDir);
                    event.accepted = true;
                    return;
                }
            } else if (event.key === Qt.Key_F5) {
                if (root.model) {
                    root.model.refresh();
                    event.accepted = true;
                    return;
                }
            } else if (event.key === Qt.Key_F1) {
                if (typeof previewPanel !== "undefined" && previewPanel) {
                    previewPanel.expanded = !previewPanel.expanded;
                    event.accepted = true;
                    return;
                }
            } else if (event.key === Qt.Key_F3) {
                if (root.activeTab) {
                    root.activeTab.isSplit = !root.activeTab.isSplit;
                    if (root.activeTab.isSplit && !root.activeTab.splitPath) {
                        root.activeTab.splitPath = root.activeTab.currentPath;
                    }
                    event.accepted = true;
                    return;
                }
            }

            if (event.modifiers === Qt.NoModifier || event.modifiers === Qt.KeypadModifier) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (root.currentItem) {
                        root.openItem(root.currentItem);
                        event.accepted = true;
                        return;
                    }
                } else if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
                    if (gridView.currentIndex === -1 && root.model && root.model.count > 0) {
                        gridView.currentIndex = 0;
                    } else {
                        gridView.moveCurrentIndexLeft();
                    }
                    event.accepted = true;
                    return;
                } else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                    if (gridView.currentIndex === -1 && root.model && root.model.count > 0) {
                        gridView.currentIndex = 0;
                    } else {
                        gridView.moveCurrentIndexDown();
                    }
                    event.accepted = true;
                    return;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                    if (gridView.currentIndex === -1 && root.model && root.model.count > 0) {
                        gridView.currentIndex = 0;
                    } else {
                        gridView.moveCurrentIndexUp();
                    }
                    event.accepted = true;
                    return;
                } else if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
                    if (gridView.currentIndex === -1 && root.model && root.model.count > 0) {
                        gridView.currentIndex = 0;
                    } else {
                        gridView.moveCurrentIndexRight();
                    }
                    event.accepted = true;
                    return;
                } else if (event.key === Qt.Key_Slash) {
                    if (typeof navBar !== "undefined" && navBar) {
                        navBar.openSearch("");
                    }
                    event.accepted = true;
                    return;
                }
            }
            if ((event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier) && event.text.length > 0) {
                let ch = event.text;
                let code = ch.charCodeAt(0);
                if (code >= 32 && ch !== ' ') {
                    if (typeof navBar !== "undefined" && navBar) {
                        navBar.openSearch(ch);
                        event.accepted = true;
                    }
                }
            }
        }

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

            readonly property bool isSelected: root.isSelected(modelData.path)
            // Reactive Cut state
            readonly property bool isCut: FileOperations.isCutOperation && FileOperations.clipboardFiles.indexOf(modelData.path) !== -1
            // Reactive Drag state
            readonly property bool isDragged: FileOperations.activeDragFiles.indexOf(modelData.path) !== -1
            // Unhidden hidden files visual distinction
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

            StyledRect {
                id: compCard
                anchors.centerIn: parent
                width: parent.width - 6
                height: parent.height - 4

                radius: Tokens.rounding.small
                color: folderDropArea.containsDrag
                    ? Colours.palette.m3primaryContainer
                    : (compDelegate.isSelected ? Colours.palette.m3secondaryContainer : (compHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : Qt.alpha(Colours.tPalette.m3surfaceContainerHigh, 0)))

                // Cut & Hidden & Dragging Files Indication: Darkened / Ghosted Opacity
                opacity: compDelegate.isDragged ? 0.35 : (compDelegate.isCut ? 0.38 : (compDelegate.isHidden ? 0.58 : 1.0))

                // Scale up when dragging over folder
                scale: folderDropArea.containsDrag ? 1.05 : 1.0
                Behavior on scale {
                    enabled: !bounceAnim.running
                    Anim { type: Anim.FastEffects }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.FastEffects
                    }
                }

                Connections {
                    target: root.model
                    function onFileModified(modifiedPath) {
                        if (compDelegate.modelData && compDelegate.modelData.path === modifiedPath) {
                            bounceAnim.restart();
                        }
                    }
                }

                SequentialAnimation {
                    id: bounceAnim
                    NumberAnimation {
                        target: compCard
                        property: "scale"
                        to: 1.08
                        duration: 120
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: compCard
                        property: "scale"
                        to: 1.0
                        duration: 200
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.4
                    }
                }


                MouseArea {
                    id: compHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    property real pressX: 0
                    property real pressY: 0
                    property bool isDragging: false

                    onPressed: mouse => {
                        root.notifyFocus();
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

                    onContainsMouseChanged: {
                        if (containsMouse && AppController.singleClick && !isDragging && !dragSelectArea.isSelecting) {
                            root.selectSingle(compDelegate.modelData.path, compDelegate.index);
                        }
                    }

                    onClicked: mouse => {
                        root.notifyFocus();
                        if (isDragging || dragSelectArea.isSelecting) return;
                        if (mouse.button === Qt.RightButton) {
                            if (!root.isSelected(compDelegate.modelData.path)) {
                                root.selectSingle(compDelegate.modelData.path, compDelegate.index);
                            }
                            let globalPos = mapToItem(null, mouse.x, mouse.y);
                            root.itemContextMenu(compDelegate.modelData, globalPos.x, globalPos.y);
                        } else {
                            if (mouse.modifiers & Qt.ShiftModifier) {
                                root.selectRange(compDelegate.index);
                            } else if (mouse.modifiers & Qt.ControlModifier) {
                                root.toggleSelection(compDelegate.modelData.path);
                                root.anchorIndex = compDelegate.index;
                            } else {
                                if (AppController.singleClick) {
                                    root.openItem(compDelegate.modelData);
                                } else {
                                    root.selectSingle(compDelegate.modelData.path, compDelegate.index);
                                }
                            }
                        }
                    }

                    onDoubleClicked: mouse => {
                        root.notifyFocus();
                        if (mouse.button === Qt.LeftButton && !AppController.singleClick) {
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
                        implicitWidth: root.iconSize
                        implicitHeight: root.iconSize

                        CachingIconImage {
                            anchors.fill: parent
                            implicitSize: root.iconSize

                            source: {
                                const file = compDelegate.modelData;
                                if (!file) return "";
                                if (file.hasThumbnail) {
                                    let t = file.lastModified ? file.lastModified.getTime() : file.size;
                                    return "image://thumb/" + file.path + "?t=" + t;
                                } else {
                                    return FileUtils.iconForFile(file.name, file.isDir, file.mimeType);
                                }
                            }
                        }

                        // Lock Indicator
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

                        // Symlink Indicator
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

    // Background Mouse Area for Deselection, Context Menu on empty space, and Rubber Band Selection
    MouseArea {
        id: dragSelectArea
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onWheel: wheel => {
            if (wheel.modifiers & Qt.ControlModifier) {
                if (wheel.angleDelta.y > 0) {
                    window.zoomLevel = Math.min(180, window.zoomLevel + 16);
                } else if (wheel.angleDelta.y < 0) {
                    window.zoomLevel = Math.max(48, window.zoomLevel - 16);
                }
                wheel.accepted = true;
            } else {
                let vx = 0;
                if (wheel.pixelDelta.x !== 0) {
                    vx = wheel.pixelDelta.x * 25;
                } else if (wheel.pixelDelta.y !== 0) {
                    vx = wheel.pixelDelta.y * 25;
                } else if (wheel.angleDelta.y !== 0) {
                    vx = wheel.angleDelta.y * 14;
                } else if (wheel.angleDelta.x !== 0) {
                    vx = wheel.angleDelta.x * 14;
                }
                if (vx !== 0) {
                    gridView.flick(vx, 0);
                    wheel.accepted = true;
                }
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
                gridView.currentIndex = -1;
                root.anchorIndex = -1;
            }
        }

        function updateRubberBandSelection() {
            let rx = Math.min(startX, currentX) - gridView.x + gridView.contentX;
            let ry = Math.min(startY, currentY) - gridView.y;
            let rw = Math.abs(currentX - startX);
            let rh = Math.abs(currentY - startY);

            let rows = Math.max(1, Math.floor(gridView.height / gridView.cellHeight));
            let newlySelected = [];
            let total = root.model ? root.model.count : 0;
            for (let i = 0; i < total; ++i) {
                let col = Math.floor(i / rows);
                let row = i % rows;
                let ix = col * gridView.cellWidth;
                let iy = row * gridView.cellHeight;
                let iw = gridView.cellWidth;
                let ih = gridView.cellHeight;

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

    // Rubber Band Visual Rectangle
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
