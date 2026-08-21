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
    property int currentIndex: listView.currentIndex
    readonly property var currentItem: listView.currentItem ? listView.currentItem.modelData : null
    property var selectedPaths: []
    property int anchorIndex: -1
    readonly property bool isTrash: root.activeTab && (
        ((root.activeTab.isSplit && root.paneIndex === 1 ? root.activeTab.splitPath : root.activeTab.currentPath).indexOf("Trash") !== -1)
        || ((root.activeTab.isSplit && root.paneIndex === 1 ? root.activeTab.splitPath : root.activeTab.currentPath).indexOf("trash:") !== -1)
    )

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
        listView.currentIndex = index;
        selectedPaths = [path];
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
    }

    ColumnLayout {
        z: 1
        anchors.fill: parent
        anchors.margins: Tokens.padding.small
        spacing: Tokens.spacing.extraSmall

        // Header Row
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainerHigh

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.medium
                spacing: Tokens.spacing.small

                // Name Column
                Item {
                    Layout.fillWidth: true
                    implicitHeight: parent.height

                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        spacing: 4

                        StyledText {
                            text: qsTr("Name")
                            font: Tokens.font.label.medium
                            color: Colours.palette.m3onSurface
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
                        onClicked: {
                            if (root.model.sortField === FileSystemModel.SortByName) {
                                root.model.sortOrder = root.model.sortOrder === Qt.AscendingOrder ? Qt.DescendingOrder : Qt.AscendingOrder;
                            } else {
                                root.model.sortField = FileSystemModel.SortByName;
                                root.model.sortOrder = Qt.AscendingOrder;
                            }
                        }
                    }
                }

                // Normal Mode Columns
                Item {
                    visible: !root.isTrash
                    Layout.preferredWidth: 100
                    implicitHeight: parent.height

                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        spacing: 4

                        StyledText {
                            text: qsTr("Size")
                            font: Tokens.font.label.medium
                            color: Colours.palette.m3onSurface
                        }

                        MaterialIcon {
                            visible: root.model.sortField === FileSystemModel.SortBySize
                            text: root.model.sortOrder === Qt.AscendingOrder ? "arrow_upward" : "arrow_downward"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3primary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.model.sortField === FileSystemModel.SortBySize) {
                                root.model.sortOrder = root.model.sortOrder === Qt.AscendingOrder ? Qt.DescendingOrder : Qt.AscendingOrder;
                            } else {
                                root.model.sortField = FileSystemModel.SortBySize;
                                root.model.sortOrder = Qt.AscendingOrder;
                            }
                        }
                    }
                }

                Item {
                    visible: !root.isTrash
                    Layout.preferredWidth: 150
                    implicitHeight: parent.height

                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        spacing: 4

                        StyledText {
                            text: qsTr("Type")
                            font: Tokens.font.label.medium
                            color: Colours.palette.m3onSurface
                        }

                        MaterialIcon {
                            visible: root.model.sortField === FileSystemModel.SortByType
                            text: root.model.sortOrder === Qt.AscendingOrder ? "arrow_upward" : "arrow_downward"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3primary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.model.sortField === FileSystemModel.SortByType) {
                                root.model.sortOrder = root.model.sortOrder === Qt.AscendingOrder ? Qt.DescendingOrder : Qt.AscendingOrder;
                            } else {
                                root.model.sortField = FileSystemModel.SortByType;
                                root.model.sortOrder = Qt.AscendingOrder;
                            }
                        }
                    }
                }

                Item {
                    visible: !root.isTrash
                    Layout.preferredWidth: 140
                    implicitHeight: parent.height

                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        spacing: 4

                        StyledText {
                            text: qsTr("Date Modified")
                            font: Tokens.font.label.medium
                            color: Colours.palette.m3onSurface
                        }

                        MaterialIcon {
                            visible: root.model.sortField === FileSystemModel.SortByDate
                            text: root.model.sortOrder === Qt.AscendingOrder ? "arrow_upward" : "arrow_downward"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3primary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.model.sortField === FileSystemModel.SortByDate) {
                                root.model.sortOrder = root.model.sortOrder === Qt.AscendingOrder ? Qt.DescendingOrder : Qt.AscendingOrder;
                            } else {
                                root.model.sortField = FileSystemModel.SortByDate;
                                root.model.sortOrder = Qt.DescendingOrder;
                            }
                        }
                    }
                }

                Item {
                    visible: !root.isTrash
                    Layout.preferredWidth: 90
                    implicitHeight: parent.height

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        text: qsTr("Permissions")
                        font: Tokens.font.label.medium
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                // Trash Mode Columns (like Dolphin)
                Item {
                    visible: root.isTrash
                    Layout.preferredWidth: 320
                    implicitHeight: parent.height

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        text: qsTr("Original Path")
                        font: Tokens.font.label.medium
                        color: Colours.palette.m3onSurface
                    }
                }

                Item {
                    visible: root.isTrash
                    Layout.preferredWidth: 180
                    implicitHeight: parent.height

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        text: qsTr("Deletion Time")
                        font: Tokens.font.label.medium
                        color: Colours.palette.m3onSurface
                    }
                }
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

            model: root.model

            ScrollBar.vertical: StyledScrollBar {
                flickable: listView
            }

            delegate: StyledRect {
                id: rowItem

                required property int index
                required property var modelData

                readonly property bool isSelected: root.isSelected(modelData.path) || (listView.currentIndex === index)
                // Reactive Cut state
                readonly property bool isCut: FileOperations.isCutOperation && FileOperations.clipboardFiles.indexOf(modelData.path) !== -1
                // Reactive Drag state
                readonly property bool isDragged: FileOperations.activeDragFiles.indexOf(modelData.path) !== -1
                // Unhidden hidden files (dotfiles) visual distinction
                readonly property bool isHidden: rowItem.modelData ? (rowItem.modelData.isHidden || rowItem.modelData.name.startsWith('.')) : false

                width: listView.width
                implicitHeight: 36

                radius: Tokens.rounding.small
                color: folderDropArea.containsDrag
                    ? Colours.palette.m3primaryContainer
                    : (isSelected ? Colours.palette.m3secondaryContainer : (rowHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : (index % 2 === 1 ? Qt.alpha(Colours.tPalette.m3surfaceContainerHigh, 0.3) : "transparent")))

                // Cut & Hidden & Dragging Files Indication: Darkened / Ghosted Opacity
                opacity: isDragged ? 0.35 : (isCut ? 0.38 : (isHidden ? 0.58 : 1.0))

                scale: folderDropArea.containsDrag ? 1.02 : 1.0
                Behavior on scale {
                    Anim { type: Anim.FastEffects }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.FastEffects
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

                MouseArea {
                    id: rowHover
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
                                let paths = root.isSelected(rowItem.modelData.path) ? root.selectedPaths : [rowItem.modelData.path];
                                FileOperations.startNativeDrag(paths, 160, 110, 48);
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
                                root.selectSingle(rowItem.modelData.path, rowItem.index);
                            }
                        }
                    }

                    onDoubleClicked: mouse => {
                        root.notifyFocus();
                        if (mouse.button === Qt.LeftButton) {
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
                        spacing: Tokens.spacing.small

                        Item {
                            implicitWidth: 22
                            implicitHeight: 22

                            CachingIconImage {
                                id: rowIcon
                                anchors.fill: parent
                                implicitSize: 22

                                Component.onCompleted: {
                                    const file = rowItem.modelData;
                                    if (file.isImage || file.isVideo) {
                                        source = "image://thumb/" + file.path;
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
                                visible: rowItem.modelData ? rowItem.modelData.isReadOnly : false
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

                    // Normal Mode Details
                    StyledText {
                        visible: !root.isTrash
                        Layout.preferredWidth: 100
                        text: rowItem.modelData ? (rowItem.modelData.isDir ? "" : rowItem.modelData.formattedSize) : ""
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                    }

                    StyledText {
                        visible: !root.isTrash
                        Layout.preferredWidth: 150
                        text: rowItem.modelData ? rowItem.modelData.mimeDescription : ""
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        visible: !root.isTrash
                        Layout.preferredWidth: 140
                        text: rowItem.modelData ? rowItem.modelData.formattedDate : ""
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                    }

                    StyledText {
                        visible: !root.isTrash
                        Layout.preferredWidth: 90
                        text: rowItem.modelData ? rowItem.modelData.permissions : ""
                        color: Colours.palette.m3outline
                        font: Tokens.font.mono.small
                    }

                    // Trash Mode Details
                    StyledText {
                        visible: root.isTrash
                        Layout.preferredWidth: 320
                        text: rowItem.modelData ? (rowItem.modelData.originalPath || "") : ""
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        elide: Text.ElideMiddle
                    }

                    StyledText {
                        visible: root.isTrash
                        Layout.preferredWidth: 180
                        text: rowItem.modelData ? (rowItem.modelData.deletionTime || rowItem.modelData.formattedDate) : ""
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
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
                listView.flick(0, wheel.angleDelta.y * 6);
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
            if (mouse.button === Qt.RightButton) {
                let globalPos = mapToItem(null, mouse.x, mouse.y);
                root.blankContextMenu(globalPos.x, globalPos.y);
            } else if (mouse.button === Qt.LeftButton) {
                root.selectedPaths = [];
                listView.currentIndex = -1;
                root.anchorIndex = -1;
            }
        }

        function updateRubberBandSelection() {
            let ry = Math.min(startY, currentY) - listView.y + listView.contentY;
            let rh = Math.abs(currentY - startY);

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
