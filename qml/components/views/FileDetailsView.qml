import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../containers"
import atlas

Item {
    id: root

    required property var model
    required property var activeTab
    property real zoomSize: 80
    readonly property int iconSize: Math.max(16, Math.min(64, Math.round(22 * zoomSize / 80)))
    readonly property int rowHeight: Math.max(36, iconSize + 14)
    property int paneIndex: 0
    property int currentIndex: listView.currentIndex
    readonly property var currentItem: {
        if (listView.currentIndex >= 0 && root.model && listView.currentIndex < root.model.count) {
            return root.model.get(listView.currentIndex);
        }
        if (selectedPaths.length > 0 && root.model) {
            let idx = root.model.indexOfPath(selectedPaths[0]);
            if (idx >= 0) return root.model.get(idx);
        }
        if (listView.currentItem && listView.currentItem.modelData) {
            return listView.currentItem.modelData;
        }
        return null;
    }
    property var selectedPaths: []
    property int anchorIndex: -1
    readonly property bool isRecent: root.activeTab
        && (root.activeTab.isSplit && root.paneIndex === 1 ? root.activeTab.splitPath : root.activeTab.currentPath).startsWith("recent:")

    readonly property bool isTrash: root.activeTab && (
        ((root.activeTab.isSplit && root.paneIndex === 1 ? root.activeTab.splitPath : root.activeTab.currentPath).indexOf("Trash") !== -1)
        || ((root.activeTab.isSplit && root.paneIndex === 1 ? root.activeTab.splitPath : root.activeTab.currentPath).indexOf("trash:") !== -1)
    )

    function forceActiveFocus() {
        listView.forceActiveFocus();
    }

    function notifyFocus() {
        listView.forceActiveFocus();
        if (root.activeTab && root.activeTab.activePane !== root.paneIndex) {
            root.activeTab.activePane = root.paneIndex;
        }
    }

    property string typeAheadBuffer: ""

    Timer {
        id: typeAheadTimer
        interval: 800
        repeat: false
        onTriggered: {
            root.typeAheadBuffer = "";
        }
    }

    function handleTypeAhead(text) {
        if (!root.model || root.model.count === 0) return;
        typeAheadTimer.restart();

        let isSingleCharRepeat = (text.length === 1 && root.typeAheadBuffer.length === 1 && root.typeAheadBuffer.toLowerCase() === text.toLowerCase());

        let startIndex = 0;
        if (isSingleCharRepeat) {
            startIndex = listView.currentIndex + 1;
        } else {
            root.typeAheadBuffer += text;
        }

        let matchIdx = -1;
        if (root.model.findFirstIndexByPrefix) {
            matchIdx = root.model.findFirstIndexByPrefix(root.typeAheadBuffer, startIndex);
        }

        if (matchIdx !== -1) {
            listView.currentIndex = matchIdx;
            let item = root.model.get(matchIdx);
            if (item) {
                root.selectedPaths = [item.path];
                listView.positionViewAtIndex(matchIdx, ListView.Contain);
            }
        }
    }

    signal openItem(var item)
    signal openItemInNewTab(var item)
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
                    let mods = FileUtils.queryKeyboardModifiers();
                    if (mods & Qt.ShiftModifier && mods & Qt.ControlModifier) {
                        for (let i = 0; i < filtered.length; ++i) {
                            let linkName = filtered[i].substring(filtered[i].lastIndexOf('/') + 1);
                            FileOperations.createSymlink(filtered[i], destDir + "/" + linkName);
                        }
                    } else if (mods & Qt.ShiftModifier) {
                        FileOperations.moveFiles(filtered, destDir);
                    } else if (mods & Qt.ControlModifier) {
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
        listView.forceActiveFocus();
    }

    function selectSingle(path, index) {
        anchorIndex = index;
        listView.currentIndex = index;
        selectedPaths = [path];
        listView.forceActiveFocus();
    }

    function selectRange(targetIndex) {
        if (!root.model || root.model.count === 0) return;
        let start = anchorIndex !== -1 ? anchorIndex : (listView.currentIndex !== -1 ? listView.currentIndex : 0);
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
        listView.currentIndex = targetIndex;
        listView.forceActiveFocus();
    }

    function colWidth(key, fallback) {
        const stored = AppController.detailsColumnWidths[key];
        return stored !== undefined ? stored : fallback;
    }

    readonly property var columnSpecs: ({
        size: {
            label: qsTr("Size"),
            width: 100,
            sort: FileSystemModel.SortBySize
        },
        type: {
            label: qsTr("Type"),
            width: 150,
            sort: FileSystemModel.SortByType
        },
        date: {
            label: qsTr("Date Modified"),
            width: 140,
            sort: FileSystemModel.SortByDate,
            descendingFirst: true
        },
        perms: {
            label: qsTr("Permissions"),
            width: 90,
            sort: -1,
            muted: true
        },
        origPath: {
            label: root.isRecent ? qsTr("Location") : qsTr("Original Path"),
            width: 320,
            sort: -1
        },
        deleted: {
            label: qsTr("Deletion Time"),
            width: 180,
            sort: FileSystemModel.SortByDeleted,
            descendingFirst: true
        }
    })

    readonly property var activeColumns: {
        if (root.isTrash)
            return AppController.detailsColumnOrder.filter(key => key === "origPath" || key === "deleted");

        if (root.isRecent) {
            const shownRecent = {
                origPath: true,
                size: AppController.showSizeColumn,
                type: AppController.showTypeColumn,
                date: AppController.showDateColumn
            };
            return AppController.detailsColumnOrder.filter(key => shownRecent[key] === true);
        }

        const shown = {
            size: AppController.showSizeColumn,
            type: AppController.showTypeColumn,
            date: AppController.showDateColumn,
            perms: AppController.showPermissionsColumn
        };
        return AppController.detailsColumnOrder.filter(key => shown[key] === true);
    }

    property string dragKey: ""
    property int dropIndex: -1
    property real dropIndicatorX: 0

    function toggleSort(field, descendingFirst) {
        if (root.model.sortField === field) {
            root.model.sortOrder = root.model.sortOrder === Qt.AscendingOrder ? Qt.DescendingOrder : Qt.AscendingOrder;
        } else {
            root.model.sortField = field;
            root.model.sortOrder = descendingFirst ? Qt.DescendingOrder : Qt.AscendingOrder;
        }
    }

    function cellText(file, key) {
        if (!file)
            return "";
        switch (key) {
        case "size":
            return file.formattedSize;
        case "type":
            return file.mimeDescription;
        case "date":
            return file.formattedDate;
        case "perms":
            return file.permissions;
        case "origPath":
            return file.originalPath || "";
        case "deleted":
            return file.deletionTime || file.formattedDate;
        }
        return "";
    }

    function updateDropTarget(x) {
        const count = headerRepeater.count;
        let index = count;
        for (let i = 0; i < count; i++) {
            const item = headerRepeater.itemAt(i);
            if (item && x < item.x + item.width / 2) {
                index = i;
                break;
            }
        }
        root.dropIndex = index;

        const edge = headerRepeater.itemAt(index < count ? index : count - 1);
        if (edge)
            root.dropIndicatorX = headerRow.x + (index < count ? edge.x - Tokens.spacing.small / 2 : edge.x + edge.width);
    }

    function commitColumnDrag() {
        const columns = root.activeColumns;
        const from = columns.indexOf(root.dragKey);
        let to = root.dropIndex;
        if (from < 0 || to < 0)
            return;
        if (to > from)
            to -= 1;
        if (to === from)
            return;

        const reordered = columns.slice();
        reordered.splice(from, 1);
        reordered.splice(to, 0, root.dragKey);

        const stored = AppController.detailsColumnOrder.slice();
        const slots = [];
        for (let i = 0; i < stored.length; i++) {
            if (reordered.indexOf(stored[i]) >= 0)
                slots.push(i);
        }
        for (let i = 0; i < slots.length; i++)
            stored[slots[i]] = reordered[i];

        AppController.setDetailsColumnOrder(stored);
    }

    Flickable {
        id: hScroll

        z: 1
        anchors.fill: parent
        clip: true
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: Math.max(width, headerRow.implicitWidth + Tokens.padding.medium * 2 + Tokens.padding.small * 2)
        contentHeight: height

        ScrollBar.horizontal: StyledScrollBar {
            flickable: hScroll
        }

    ColumnLayout {
        x: Tokens.padding.small
        y: Tokens.padding.small
        width: hScroll.contentWidth - Tokens.padding.small * 2
        height: hScroll.height - Tokens.padding.small * 2
        spacing: Tokens.spacing.extraSmall

        // Header Row
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainerHigh

            RowLayout {
                id: headerRow

                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.medium
                spacing: Tokens.spacing.small

                // Name Column
                Item {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 120
                    implicitHeight: parent.height
                    clip: true

                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 4

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Name")
                            font: Tokens.font.label.medium
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                        }

                        MaterialIcon {
                            visible: root.model.sortField === FileSystemModel.SortByName
                            text: root.model.sortOrder === Qt.AscendingOrder ? "arrow_upward" : "arrow_downward"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3primary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleSort(FileSystemModel.SortByName, false)
                    }
                }

                Repeater {
                    id: headerRepeater

                    model: root.activeColumns

                    delegate: Item {
                        id: headerCell

                        required property string modelData
                        readonly property var spec: root.columnSpecs[modelData]

                        Layout.preferredWidth: root.colWidth(modelData, spec.width)
                        implicitHeight: parent.height
                        opacity: root.dragKey === modelData ? 0.4 : 1

                        ColumnResizeHandle {
                            columnKey: headerCell.modelData
                            defaultWidth: headerCell.spec.width
                        }

                        RowLayout {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: 4

                            StyledText {
                                Layout.fillWidth: true
                                text: headerCell.spec.label
                                font: Tokens.font.label.medium
                                color: headerCell.spec.muted ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }

                            MaterialIcon {
                                visible: headerCell.spec.sort >= 0 && root.model.sortField === headerCell.spec.sort
                                text: root.model.sortOrder === Qt.AscendingOrder ? "arrow_upward" : "arrow_downward"
                                fontStyle: Tokens.font.icon.small
                                color: Colours.palette.m3primary
                            }
                        }

                        MouseArea {
                            property real pressX: 0
                            property bool moved: false

                            anchors.fill: parent
                            cursorShape: moved ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                            onPressed: event => {
                                pressX = event.x;
                                moved = false;
                            }

                            onPositionChanged: event => {
                                if (!pressed)
                                    return;
                                if (!moved && Math.abs(event.x - pressX) < 8)
                                    return;
                                moved = true;
                                root.dragKey = headerCell.modelData;
                                root.updateDropTarget(mapToItem(headerRow, event.x, 0).x);
                            }

                            onReleased: {
                                if (moved)
                                    root.commitColumnDrag();
                                else if (headerCell.spec.sort >= 0)
                                    root.toggleSort(headerCell.spec.sort, headerCell.spec.descendingFirst === true);
                                moved = false;
                                root.dragKey = "";
                            }

                            onCanceled: {
                                moved = false;
                                root.dragKey = "";
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: root.dragKey !== ""
                x: root.dropIndicatorX
                y: Tokens.padding.extraSmall
                width: 2
                height: parent.height - Tokens.padding.extraSmall * 2
                radius: width / 2
                color: Colours.palette.m3primary
                z: 10
            }
        }

        // Details List View
        VerticalFadeListView {
            id: listView

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            focus: true
            currentIndex: -1
            interactive: false
            boundsBehavior: Flickable.DragAndOvershootBounds
            maximumFlickVelocity: 5000
            flickDeceleration: 5000

            WheelHandler {
                target: listView
                acceptedModifiers: Qt.NoModifier
                onWheel: event => {
                    const factor = AppController.scrollSpeed;
                    if (event.pixelDelta.y !== 0) {
                        const limit = Math.max(0, listView.contentHeight - listView.height);
                        listView.cancelFlick();
                        listView.contentY = Math.max(0, Math.min(limit, listView.contentY - event.pixelDelta.y * factor));
                        event.accepted = true;
                    } else if (event.angleDelta.y !== 0) {
                        listView.flick(0, event.angleDelta.y * 14 * factor);
                        event.accepted = true;
                    }
                }
            }

            displaced: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: Tokens.anim.durations.expressiveFastSpatial
                    easing: Tokens.anim.expressiveFastSpatial
                }
            }
            move: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: Tokens.anim.durations.expressiveFastSpatial
                    easing: Tokens.anim.expressiveFastSpatial
                }
            }

            Component.onCompleted: listView.forceActiveFocus()

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
                    } else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                        if (listView.currentIndex === -1 && root.model && root.model.count > 0) {
                            listView.currentIndex = 0;
                        } else if (listView.currentIndex < (root.model ? root.model.count - 1 : 0)) {
                            listView.currentIndex++;
                        }
                        event.accepted = true;
                        return;
                    } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                        if (listView.currentIndex > 0) {
                            listView.currentIndex--;
                        } else if (listView.currentIndex === -1 && root.model && root.model.count > 0) {
                            listView.currentIndex = 0;
                        }
                        event.accepted = true;
                        return;
                    } else if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
                        if (root.activeTab && root.activeTab.canGoUp) {
                            root.activeTab.goUp();
                        }
                        event.accepted = true;
                        return;
                    } else if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
                        if (root.currentItem) {
                            root.openItem(root.currentItem);
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
                        root.handleTypeAhead(ch);
                        event.accepted = true;
                        return;
                    }
                }
            }

            model: root.model

            delegate: StyledRect {
                id: rowItem

                required property int index
                required property var modelData

                readonly property bool isSelected: root.isSelected(modelData.path)
                // Reactive Cut state
                readonly property bool isCut: FileOperations.isCutOperation && FileOperations.clipboardFiles.indexOf(modelData.path) !== -1
                // Reactive Drag state
                readonly property bool isDragged: FileOperations.activeDragFiles.indexOf(modelData.path) !== -1
                // Unhidden hidden files visual distinction
                readonly property bool isHidden: rowItem.modelData ? (rowItem.modelData.isHidden || rowItem.modelData.name.startsWith('.')) : false

                width: listView.width
                implicitHeight: root.rowHeight

                radius: Tokens.rounding.small
                color: folderDropArea.containsDrag
                    ? Colours.palette.m3primaryContainer
                    : (isSelected ? Colours.palette.m3secondaryContainer : (rowHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : (index % 2 === 1 ? Qt.alpha(Colours.tPalette.m3surfaceContainerHigh, 0.3) : Qt.alpha(Colours.tPalette.m3surfaceContainerHigh, 0))))

                // Cut & Hidden & Dragging Files Indication: Darkened / Ghosted Opacity
                opacity: isDragged ? 0.35 : (isCut ? 0.38 : (isHidden ? 0.58 : 1.0))

                scale: folderDropArea.containsDrag ? 1.02 : 1.0
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
                        if (rowItem.modelData && rowItem.modelData.path === modifiedPath) {
                            bounceAnim.restart();
                        }
                    }
                }

                SequentialAnimation {
                    id: bounceAnim
                    NumberAnimation {
                        target: rowItem
                        property: "scale"
                        to: 1.03
                        duration: 120
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: rowItem
                        property: "scale"
                        to: 1.0
                        duration: 200
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.4
                    }
                }


                DropArea {
                    id: folderDropArea
                    anchors.fill: parent
                    z: 1
                    enabled: rowItem.modelData ? rowItem.modelData.isDir : false

                    onDropped: drop => {
                        if (drop.hasUrls) {
                            let urls = [];
                            for (let i = 0; i < drop.urls.length; ++i) {
                                urls.push(FileUtils.toLocalFile(drop.urls[i]));
                            }
                            let destDir = rowItem.modelData.path;
                            let filtered = urls.filter(u => u !== destDir);
                            if (filtered.length > 0) {
                                let globalPos = mapToItem(null, drop.x, drop.y);
                                let mods = FileUtils.queryKeyboardModifiers();
                                if (mods & Qt.ShiftModifier && mods & Qt.ControlModifier) {
                                    for (let i = 0; i < filtered.length; ++i) {
                                        let linkName = filtered[i].substring(filtered[i].lastIndexOf('/') + 1);
                                        FileOperations.createSymlink(filtered[i], destDir + "/" + linkName);
                                    }
                                } else if (mods & Qt.ShiftModifier) {
                                    FileOperations.moveFiles(filtered, destDir);
                                } else if (mods & Qt.ControlModifier) {
                                    FileOperations.copyFiles(filtered, destDir);
                                } else {
                                    root.filesDropped(filtered, destDir, globalPos.x, globalPos.y);
                                }
                                drop.accept();
                            }
                        }
                    }
                }

                MouseArea {
                    id: rowHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.ExtraButton1 | Qt.ExtraButton2

                    property real pressX: 0
                    property real pressY: 0
                    property bool isDragging: false

                    onPressed: mouse => {
                        root.notifyFocus();

                        if (mouse.button === Qt.MiddleButton) {

                            mouse.accepted = true;

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
                                let paths = root.isSelected(rowItem.modelData.path) ? root.selectedPaths : [rowItem.modelData.path];
                                FileOperations.startNativeDrag(paths, 160, 110, 48);
                            }
                        }
                    }

                    onContainsMouseChanged: {
                        if (containsMouse && AppController.singleClick && !isDragging && !dragSelectArea.isSelecting) {
                            root.selectSingle(rowItem.modelData.path, rowItem.index);
                        }
                    }

                    onClicked: mouse => {
                        root.notifyFocus();
                        if (mouse.button === Qt.MiddleButton) {
                            if (modelData && modelData.isDir)
                                root.openItemInNewTab(modelData);
                            return;
                        }
                        if (isDragging || dragSelectArea.isSelecting) return;
                        if (mouse.button === Qt.BackButton || mouse.button === Qt.ExtraButton1) {
                            if (root.activeTab && root.activeTab.canGoBack) root.activeTab.goBack();
                        } else if (mouse.button === Qt.ForwardButton || mouse.button === Qt.ExtraButton2) {
                            if (root.activeTab && root.activeTab.canGoForward) root.activeTab.goForward();
                        } else if (mouse.button === Qt.RightButton) {
                            if (!root.isSelected(rowItem.modelData.path)) {
                                root.selectSingle(rowItem.modelData.path, rowItem.index);
                            }
                            let globalPos = mapToItem(null, mouse.x, mouse.y);
                            root.itemContextMenu(rowItem.modelData, globalPos.x, globalPos.y);
                        } else {
                            if (mouse.modifiers & Qt.ShiftModifier) {
                                root.selectRange(rowItem.index);
                            } else if (mouse.modifiers & Qt.ControlModifier) {
                                root.toggleSelection(rowItem.modelData.path);
                                root.anchorIndex = rowItem.index;
                            } else {
                                if (AppController.singleClick) {
                                    root.openItem(rowItem.modelData);
                                } else {
                                    root.selectSingle(rowItem.modelData.path, rowItem.index);
                                }
                            }
                        }
                    }

                    onDoubleClicked: mouse => {
                        root.notifyFocus();
                        if (mouse.button === Qt.LeftButton && !AppController.singleClick) {
                            root.openItem(rowItem.modelData);
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.medium
                    anchors.rightMargin: Tokens.padding.medium
                    spacing: Tokens.spacing.small

                    // Name + Icon + Symlink / Lock
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 120 + (AppController.expandableFolders ? 18 + Tokens.spacing.small : 0)
                        spacing: Tokens.spacing.small

                        Item {
                            visible: AppController.expandableFolders
                            implicitWidth: visible ? (rowItem.modelData ? rowItem.modelData.depth : 0) * Tokens.padding.medium : 0
                            implicitHeight: 1
                        }

                        Item {
                            visible: AppController.expandableFolders
                            implicitWidth: visible ? 18 : 0
                            implicitHeight: 18

                            MaterialIcon {
                                anchors.centerIn: parent
                                visible: rowItem.modelData ? rowItem.modelData.isDir : false
                                text: "chevron_right"
                                rotation: (rowItem.modelData && rowItem.modelData.expanded) ? 90 : 0
                                fontStyle: Tokens.font.icon.small
                                color: expandArea.containsMouse
                                    ? Colours.palette.m3onSurface
                                    : Colours.palette.m3onSurfaceVariant

                                Behavior on rotation {
                                    Anim {
                                        type: Anim.DefaultSpatial
                                    }
                                }
                            }

                            MouseArea {
                                id: expandArea

                                anchors.fill: parent
                                anchors.margins: -4
                                enabled: rowItem.modelData ? rowItem.modelData.isDir : false
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.model.toggleExpanded(rowItem.modelData.path)
                            }
                        }

                        Item {
                            implicitWidth: root.iconSize
                            implicitHeight: root.iconSize

                            CachingIconImage {
                                id: rowIcon
                                anchors.fill: parent
                                implicitSize: root.iconSize

                                source: {
                                    const file = rowItem.modelData;
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
                                visible: rowItem.modelData ? rowItem.modelData.isReadOnly : false
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
                                visible: rowItem.modelData ? rowItem.modelData.isSymLink : false
                                text: "link"
                                fontStyle: Tokens.font.icon.small
                                color: Colours.palette.m3primary
                                z: 2
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: rowItem.modelData ? (rowItem.modelData.isSymLink ? `${rowItem.modelData.name} ↳` : rowItem.modelData.name) : ""
                            color: rowItem.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }
                    }

                    Repeater {
                        model: root.activeColumns

                        delegate: StyledText {
                            required property string modelData

                            Layout.preferredWidth: root.colWidth(modelData, root.columnSpecs[modelData].width)
                            text: root.cellText(rowItem.modelData, modelData)
                            color: modelData === "perms" ? Colours.palette.m3outline : Colours.palette.m3onSurfaceVariant
                            font: modelData === "perms" ? Tokens.font.mono.small : Tokens.font.body.small
                            elide: modelData === "origPath" ? Text.ElideMiddle : Text.ElideRight
                        }
                    }
                }
            }
        }
    }
    }

    StyledScrollBar {
        id: verticalBar

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        z: 2

        orientation: Qt.Vertical
        flickable: listView
        animatePosition: false
        size: listView.contentHeight > 0 ? Math.min(1, listView.height / listView.contentHeight) : 1
        position: listView.contentHeight > listView.height
            ? Math.max(0, Math.min(1 - size, listView.contentY / listView.contentHeight))
            : 0
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
                    window.zoomLevel = Math.min(180, window.zoomLevel + 16);
                } else if (wheel.angleDelta.y < 0) {
                    window.zoomLevel = Math.max(48, window.zoomLevel - 16);
                }
                wheel.accepted = true;
            } else {
                const factor = AppController.scrollSpeed;
                if (wheel.pixelDelta.y !== 0) {
                    const limit = Math.max(0, listView.contentHeight - listView.height);
                    listView.cancelFlick();
                    listView.contentY = Math.max(0, Math.min(limit, listView.contentY - wheel.pixelDelta.y * factor));
                    wheel.accepted = true;
                } else if (wheel.angleDelta.y !== 0) {
                    listView.flick(0, wheel.angleDelta.y * 14 * factor);
                    wheel.accepted = true;
                }
            }
        }

        property real startX: 0
        property real startY: 0
        property real currentX: 0
        property real currentY: 0
        property real anchorContentY: 0
        property real lastContentY: 0
        property bool isSelecting: false
        property bool wasSelecting: false

        readonly property real anchorViewY: anchorContentY + listView.y - listView.contentY

        function insideContent(px, py) {
            const p = mapToItem(listView, px, py);
            return p.x >= 0 && p.y >= 0 && p.x <= listView.width && p.y <= listView.height;
        }

        onPressed: mouse => {
            if (!insideContent(mouse.x, mouse.y)) {
                mouse.accepted = false;
                return;
            }
            root.notifyFocus();
            startX = mouse.x;
            startY = mouse.y;
            currentX = mouse.x;
            currentY = mouse.y;
            anchorContentY = mouse.y - listView.y + listView.contentY;
            lastContentY = listView.contentY;
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
                        listView.currentIndex = -1;
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
            if (mouse.button === Qt.BackButton || mouse.button === Qt.ExtraButton1) {
                if (root.activeTab && root.activeTab.canGoBack) root.activeTab.goBack();
            } else if (mouse.button === Qt.ForwardButton || mouse.button === Qt.ExtraButton2) {
                if (root.activeTab && root.activeTab.canGoForward) root.activeTab.goForward();
            } else if (mouse.button === Qt.RightButton) {
                let globalPos = mapToItem(null, mouse.x, mouse.y);
                root.blankContextMenu(globalPos.x, globalPos.y);
            } else if (mouse.button === Qt.LeftButton) {
                root.selectedPaths = [];
                listView.currentIndex = -1;
                root.anchorIndex = -1;
            }
        }

        function updateRubberBandSelection() {
            let cy = currentY - listView.y + listView.contentY;
            let ry = Math.min(anchorContentY, cy);
            let rh = Math.abs(cy - anchorContentY);

            let newlySelected = [];
            let total = root.model ? root.model.count : 0;
            for (let i = 0; i < total; ++i) {
                let iy = i * 36;
                let ih = 36;
                if (iy < ry + rh && iy + ih > ry) {
                    let entry = root.model.get(i);
                    if (entry) {
                        newlySelected.push(entry.path);
                    }
                }
            }
            root.selectedPaths = newlySelected;
        }

        Timer {
            running: dragSelectArea.isSelecting
            interval: 16
            repeat: true

            onTriggered: {
                const edge = 32;
                const top = listView.y;
                const bottom = listView.y + listView.height;
                let delta = 0;
                if (dragSelectArea.currentY < top + edge)
                    delta = -Math.min(28, (top + edge - dragSelectArea.currentY) / 2);
                else if (dragSelectArea.currentY > bottom - edge)
                    delta = Math.min(28, (dragSelectArea.currentY - (bottom - edge)) / 2);

                if (delta !== 0) {
                    const limit = Math.max(0, listView.contentHeight - listView.height);
                    listView.contentY = Math.max(0, Math.min(limit, listView.contentY + delta));
                }

                if (listView.contentY !== dragSelectArea.lastContentY) {
                    dragSelectArea.lastContentY = listView.contentY;
                    dragSelectArea.updateRubberBandSelection();
                }
            }
        }
    }

    // Rubber Band Visual Rectangle
    Rectangle {
        z: 999
        visible: dragSelectArea.isSelecting
        x: Math.min(dragSelectArea.startX, dragSelectArea.currentX)
        y: Math.min(dragSelectArea.anchorViewY, dragSelectArea.currentY)
        width: Math.abs(dragSelectArea.currentX - dragSelectArea.startX)
        height: Math.abs(dragSelectArea.currentY - dragSelectArea.anchorViewY)
        color: Qt.alpha(Colours.palette.m3primary, 0.18)
        border.color: Colours.palette.m3primary
        border.width: 1.5
        radius: Tokens.rounding.extraSmall
    }
}
