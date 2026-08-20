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

                // Size Column
                Item {
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

                // Type Column
                Item {
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

                // Date Modified Column
                Item {
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

                // Permissions Column
                Item {
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
            }
        }

        // Details List View with vertical edge fade
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
                        listView.currentIndex = -1;
                    }
                }

                onPositionChanged: mouse => {
                    if (pressed && (Math.abs(mouse.x - startX) > 5 || Math.abs(mouse.y - startY) > 5)) {
                        isSelecting = true;
                        rubberBand.x = Math.min(startX, mouse.x) + listView.x;
                        rubberBand.y = Math.min(startY, mouse.y) + listView.y;
                        rubberBand.width = Math.abs(mouse.x - startX);
                        rubberBand.height = Math.abs(mouse.y - startY);
                        rubberBand.visible = true;

                        let idx = listView.indexAt(mouse.x, mouse.y + listView.contentY);
                        if (idx >= 0) listView.currentIndex = idx;
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
                id: rowItem

                required property int index
                required property var modelData

                width: listView.width
                implicitHeight: 36

                radius: Tokens.rounding.small
                color: ListView.isCurrentItem ? Colours.palette.m3secondaryContainer : (rowHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : (index % 2 === 1 ? Qt.alpha(Colours.tPalette.m3surfaceContainerHigh, 0.3) : "transparent"))

                // Cut Indicator: Dim item when marked for cut
                readonly property bool isCut: rowItem.modelData ? FileOperations.isPathCut(rowItem.modelData.path) : false
                opacity: isCut ? 0.45 : (populated ? 1.0 : 0.0)
                property bool populated: false

                Component.onCompleted: {
                    populated = true;
                }

                Behavior on opacity {
                    Anim { type: Anim.DefaultEffects }
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
                            listView.currentIndex = rowItem.index;
                            let globalPos = mapToItem(null, mouse.x, mouse.y);
                            root.itemContextMenu(rowItem.modelData, globalPos.x, globalPos.y);
                        } else {
                            listView.currentIndex = rowItem.index;
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
                            color: rowItem.ListView.isCurrentItem ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }
                    }

                    // Size
                    StyledText {
                        Layout.preferredWidth: 100
                        text: rowItem.modelData ? (rowItem.modelData.isDir ? "" : rowItem.modelData.formattedSize) : ""
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                    }

                    // Type
                    StyledText {
                        Layout.preferredWidth: 150
                        text: rowItem.modelData ? rowItem.modelData.mimeDescription : ""
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    // Date
                    StyledText {
                        Layout.preferredWidth: 140
                        text: rowItem.modelData ? rowItem.modelData.formattedDate : ""
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                    }

                    // Permissions
                    StyledText {
                        Layout.preferredWidth: 90
                        text: rowItem.modelData ? rowItem.modelData.permissions : ""
                        color: Colours.palette.m3outline
                        font: Tokens.font.mono.small
                    }
                }
            }
        }
    }
}
