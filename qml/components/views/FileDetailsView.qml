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
    property int currentIndex: listView.currentIndex
    readonly property var currentItem: listView.currentItem ? listView.currentItem.modelData : null
    property var selectedPaths: []
    readonly property bool isTrash: root.activeTab && (root.activeTab.currentPath.indexOf("Trash") !== -1 || root.activeTab.currentPath.indexOf("trash:") !== -1)

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
        listView.currentIndex = index;
        selectedPaths = [path];
    }

    ColumnLayout {
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
            interactive: true

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
                // Unhidden hidden files (dotfiles) visual distinction
                readonly property bool isHidden: rowItem.modelData ? (rowItem.modelData.isHidden || rowItem.modelData.name.startsWith('.')) : false

                width: listView.width
                implicitHeight: 36

                radius: Tokens.rounding.small
                color: isSelected ? Colours.palette.m3secondaryContainer : (rowHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : (index % 2 === 1 ? Qt.alpha(Colours.tPalette.m3surfaceContainerHigh, 0.3) : "transparent"))

                // Cut & Hidden Files Indication: Darkened / Ghosted Opacity
                opacity: isCut ? 0.38 : (isHidden ? 0.58 : 1.0)

                Behavior on opacity {
                    Anim {
                        type: Anim.FastEffects
                    }
                }

                MouseArea {
                    id: rowHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton

                    onClicked: mouse => {
                        if (mouse.button === Qt.BackButton) {
                            if (root.activeTab && root.activeTab.canGoBack) root.activeTab.goBack();
                        } else if (mouse.button === Qt.ForwardButton) {
                            if (root.activeTab && root.activeTab.canGoForward) root.activeTab.goForward();
                        } else if (mouse.button === Qt.RightButton) {
                            if (!root.isSelected(rowItem.modelData.path)) {
                                root.selectSingle(rowItem.modelData.path, rowItem.index);
                            }
                            let globalPos = mapToItem(null, mouse.x, mouse.y);
                            root.itemContextMenu(rowItem.modelData, globalPos.x, globalPos.y);
                        } else {
                            if (mouse.modifiers & Qt.ControlModifier) {
                                root.toggleSelection(rowItem.modelData.path);
                            } else {
                                root.selectSingle(rowItem.modelData.path, rowItem.index);
                            }
                        }
                    }

                    onDoubleClicked: mouse => {
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

                    // Name + Icon + Symlink
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
                                visible: rowItem.modelData ? rowItem.modelData.isSymLink : false
                                text: "link"
                                fontStyle: Tokens.font.icon.small
                                color: Colours.palette.m3primary
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

    // Top-Level Rubber Band Selection Overlay
    MouseArea {
        id: dragSelectArea
        anchors.fill: parent
        z: 999
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.BackButton | Qt.ForwardButton
        propagateComposedEvents: true

        onWheel: wheel => {
            listView.flick(0, wheel.angleDelta.y * 6);
        }

        property real startX: 0
        property real startY: 0
        property real currentX: 0
        property real currentY: 0
        property bool isSelecting: false

        onPressed: mouse => {
            if (mouse.button === Qt.LeftButton) {
                let item = listView.childAt(mouse.x - listView.x, mouse.y - listView.y + listView.contentY);
                if (!item) {
                    startX = mouse.x;
                    startY = mouse.y;
                    currentX = mouse.x;
                    currentY = mouse.y;
                    isSelecting = false;
                    if (!(mouse.modifiers & Qt.ControlModifier)) {
                        root.selectedPaths = [];
                        listView.currentIndex = -1;
                    }
                } else {
                    mouse.accepted = false;
                }
            } else {
                mouse.accepted = false;
            }
        }

        onPositionChanged: mouse => {
            if (pressed && (mouse.buttons & Qt.LeftButton)) {
                currentX = mouse.x;
                currentY = mouse.y;
                if (Math.abs(currentX - startX) > 6 || Math.abs(currentY - startY) > 6) {
                    isSelecting = true;
                    updateRubberBandSelection();
                }
            }
        }

        onReleased: mouse => {
            if (isSelecting) {
                isSelecting = false;
            } else {
                mouse.accepted = false;
            }
        }

        function updateRubberBandSelection() {
            let ry = Math.min(startY, currentY) - listView.y + listView.contentY;
            let rh = Math.abs(currentY - startY);

            let newlySelected = [];
            for (let i = 0; i < listView.count; ++i) {
                let item = listView.itemAtIndex(i);
                if (item && item.modelData) {
                    if (item.y + item.height > ry && item.y < ry + rh) {
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
