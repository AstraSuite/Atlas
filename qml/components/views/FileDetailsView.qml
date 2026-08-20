import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
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

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Column Headers
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 34
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: 0

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.medium
                spacing: Tokens.spacing.small

                // Name Column
                Item {
                    Layout.fillWidth: true
                    implicitHeight: parent.height

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.model.sortField === FileSystemModel.SortByName) {
                                root.model.sortOrder = (root.model.sortOrder === Qt.AscendingOrder) ? Qt.DescendingOrder : Qt.AscendingOrder;
                            } else {
                                root.model.sortField = FileSystemModel.SortByName;
                                root.model.sortOrder = Qt.AscendingOrder;
                            }
                        }
                    }

                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            text: qsTr("Name")
                            font: Tokens.font.label.medium
                            color: root.model.sortField === FileSystemModel.SortByName ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        }

                        MaterialIcon {
                            visible: root.model.sortField === FileSystemModel.SortByName
                            text: root.model.sortOrder === Qt.AscendingOrder ? "arrow_upward" : "arrow_downward"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3primary
                        }
                    }
                }

                // Size Column
                Item {
                    implicitWidth: 100
                    implicitHeight: parent.height

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.model.sortField === FileSystemModel.SortBySize) {
                                root.model.sortOrder = (root.model.sortOrder === Qt.AscendingOrder) ? Qt.DescendingOrder : Qt.AscendingOrder;
                            } else {
                                root.model.sortField = FileSystemModel.SortBySize;
                                root.model.sortOrder = Qt.AscendingOrder;
                            }
                        }
                    }

                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            text: qsTr("Size")
                            font: Tokens.font.label.medium
                            color: root.model.sortField === FileSystemModel.SortBySize ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        }

                        MaterialIcon {
                            visible: root.model.sortField === FileSystemModel.SortBySize
                            text: root.model.sortOrder === Qt.AscendingOrder ? "arrow_upward" : "arrow_downward"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3primary
                        }
                    }
                }

                // Type Column
                Item {
                    implicitWidth: 150
                    implicitHeight: parent.height

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.model.sortField === FileSystemModel.SortByType) {
                                root.model.sortOrder = (root.model.sortOrder === Qt.AscendingOrder) ? Qt.DescendingOrder : Qt.AscendingOrder;
                            } else {
                                root.model.sortField = FileSystemModel.SortByType;
                                root.model.sortOrder = Qt.AscendingOrder;
                            }
                        }
                    }

                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            text: qsTr("Type")
                            font: Tokens.font.label.medium
                            color: root.model.sortField === FileSystemModel.SortByType ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        }

                        MaterialIcon {
                            visible: root.model.sortField === FileSystemModel.SortByType
                            text: root.model.sortOrder === Qt.AscendingOrder ? "arrow_upward" : "arrow_downward"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3primary
                        }
                    }
                }

                // Date Column
                Item {
                    implicitWidth: 140
                    implicitHeight: parent.height

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.model.sortField === FileSystemModel.SortByDate) {
                                root.model.sortOrder = (root.model.sortOrder === Qt.AscendingOrder) ? Qt.DescendingOrder : Qt.AscendingOrder;
                            } else {
                                root.model.sortField = FileSystemModel.SortByDate;
                                root.model.sortOrder = Qt.AscendingOrder;
                            }
                        }
                    }

                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            text: qsTr("Date Modified")
                            font: Tokens.font.label.medium
                            color: root.model.sortField === FileSystemModel.SortByDate ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        }

                        MaterialIcon {
                            visible: root.model.sortField === FileSystemModel.SortByDate
                            text: root.model.sortOrder === Qt.AscendingOrder ? "arrow_upward" : "arrow_downward"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3primary
                        }
                    }
                }

                // Permissions Column
                Item {
                    implicitWidth: 90
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

        // Details List View
        ListView {
            id: listView

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            focus: true
            currentIndex: -1

            model: root.model

            ScrollBar.vertical: StyledScrollBar {
                flickable: listView
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.RightButton
                onClicked: mouse => {
                    let globalPos = mapToItem(null, mouse.x, mouse.y);
                    root.blankContextMenu(globalPos.x, globalPos.y);
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

                MouseArea {
                    id: rowHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: mouse => {
                        listView.currentIndex = rowItem.index;
                        if (mouse.button === Qt.RightButton) {
                            let globalPos = mapToItem(null, mouse.x, mouse.y);
                            root.itemContextMenu(rowItem.modelData, globalPos.x, globalPos.y);
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

                    // Name + Icon
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small

                        CachingIconImage {
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

                        StyledText {
                            Layout.fillWidth: true
                            text: rowItem.modelData ? rowItem.modelData.name : ""
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
