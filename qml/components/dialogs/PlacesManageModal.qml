import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../containers"
import "../controls"
import "../tabs"
import prism

MouseArea {
    id: root

    property bool expanded: false
    property int currentTab: 0
    property var allDevicesList: []

    signal editPlaceRequested(int index, string name, string path, string iconName, bool isCustom)

    function refreshDevices() {
        allDevicesList = DriveManager.allDevices();
    }

    onExpandedChanged: {
        if (expanded) {
            refreshDevices();
        }
    }

    function movePlaceSafely(fromIdx, toIdx) {
        let savedY = placesList.contentY;
        PlacesModel.movePlace(fromIdx, toIdx);
        placesList.contentY = savedY;
        Qt.callLater(() => {
            placesList.contentY = savedY;
        });
    }

    anchors.fill: parent
    visible: opacity > 0.001
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    z: 100

    opacity: expanded ? 1.0 : 0.0
    Behavior on opacity { Anim { type: Anim.FastEffects } }

    onClicked: root.expanded = false
    Keys.onEscapePressed: root.expanded = false

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.45)
    }

    StyledRect {
        id: modalCard

        anchors.centerIn: parent
        implicitWidth: 560
        implicitHeight: 600

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerHigh

        scale: root.expanded ? 1.0 : 0.94
        Behavior on scale {
            Anim {
                type: Anim.FastEffects
                easing: Tokens.anim.standard
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "tune"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    text: qsTr("Places & Devices")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.builders.large.weight(Font.Bold).build()
                    Layout.fillWidth: true
                }
            }

            // Tab Bar Navigation
            M3TopTabBar {
                Layout.fillWidth: true
                currentIndex: root.currentTab
                model: [
                    { label: qsTr("Places & Bookmarks"), icon: "bookmarks" },
                    { label: qsTr("Devices & Drives"), icon: "hard_drive" }
                ]
                onTabSelected: index => {
                    root.currentTab = index;
                    if (index === 1) {
                        root.refreshDevices();
                    }
                }
            }

            // Sliding Content Area
            Item {
                id: contentArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Row {
                    id: pagesRow
                    width: contentArea.width * 2
                    height: contentArea.height
                    x: -root.currentTab * contentArea.width

                    Behavior on x {
                        Anim {
                            type: Anim.DefaultSpatial
                        }
                    }

                    // --- TAB 0: Places & Bookmarks ---
                    Item {
                        width: contentArea.width
                        height: contentArea.height

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Tokens.spacing.small

                            StyledText {
                                text: qsTr("Reorder and manage pinned bookmarks:")
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.small
                            }

                            VerticalFadeListView {
                                id: placesList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 4
                                model: PlacesModel

                                ScrollBar.vertical: StyledScrollBar {
                                    flickable: placesList
                                }

                                delegate: StyledRect {
                                    id: placeRowCard
                                    required property int index
                                    required property string name
                                    required property string path
                                    required property string iconName
                                    required property bool isCustom

                                    width: placesList.width
                                    height: 46
                                    implicitHeight: 46
                                    radius: Tokens.rounding.medium
                                    color: rowHoverArea.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer

                                    MaterialIcon {
                                        id: placeIcon
                                        anchors.left: parent.left
                                        anchors.leftMargin: Tokens.padding.medium
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: placeRowCard.iconName
                                        color: Colours.palette.m3primary
                                        fontStyle: Tokens.font.icon.medium
                                    }

                                    Row {
                                        id: placeActions
                                        anchors.right: parent.right
                                        anchors.rightMargin: Tokens.padding.small
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        // Reorder Up
                                        StyledRect {
                                            implicitWidth: 28
                                            implicitHeight: 28
                                            radius: Tokens.rounding.full
                                            color: upHover.containsMouse ? Colours.palette.m3surfaceContainerHigh : "transparent"
                                            enabled: placeRowCard.index > 0
                                            opacity: enabled ? 1.0 : 0.3

                                            MaterialIcon {
                                                anchors.centerIn: parent
                                                text: "keyboard_arrow_up"
                                                color: Colours.palette.m3onSurface
                                                fontStyle: Tokens.font.icon.small
                                            }

                                            MouseArea {
                                                id: upHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: placeRowCard.index > 0 ? Qt.PointingHandCursor : undefined
                                                onClicked: root.movePlaceSafely(placeRowCard.index, placeRowCard.index - 1)
                                            }
                                        }

                                        // Reorder Down
                                        StyledRect {
                                            implicitWidth: 28
                                            implicitHeight: 28
                                            radius: Tokens.rounding.full
                                            color: downHover.containsMouse ? Colours.palette.m3surfaceContainerHigh : "transparent"
                                            enabled: placeRowCard.index < PlacesModel.count - 1
                                            opacity: enabled ? 1.0 : 0.3

                                            MaterialIcon {
                                                anchors.centerIn: parent
                                                text: "keyboard_arrow_down"
                                                color: Colours.palette.m3onSurface
                                                fontStyle: Tokens.font.icon.small
                                            }

                                            MouseArea {
                                                id: downHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: placeRowCard.index < PlacesModel.count - 1 ? Qt.PointingHandCursor : undefined
                                                onClicked: root.movePlaceSafely(placeRowCard.index, placeRowCard.index + 1)
                                            }
                                        }

                                        // Edit Button
                                        StyledRect {
                                            implicitWidth: 28
                                            implicitHeight: 28
                                            radius: Tokens.rounding.full
                                            color: editHover.containsMouse ? Colours.palette.m3surfaceContainerHigh : "transparent"

                                            MaterialIcon {
                                                anchors.centerIn: parent
                                                text: "edit"
                                                color: Colours.palette.m3onSurface
                                                fontStyle: Tokens.font.icon.small
                                            }

                                            MouseArea {
                                                id: editHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.expanded = false;
                                                    root.editPlaceRequested(placeRowCard.index, placeRowCard.name, placeRowCard.path, placeRowCard.iconName, placeRowCard.isCustom);
                                                }
                                            }
                                        }

                                        // Delete / Unpin Button
                                        StyledRect {
                                            implicitWidth: 28
                                            implicitHeight: 28
                                            radius: Tokens.rounding.full
                                            color: delHover.containsMouse ? Colours.palette.m3errorContainer : "transparent"
                                            visible: placeRowCard.isCustom

                                            MaterialIcon {
                                                anchors.centerIn: parent
                                                text: "delete"
                                                color: delHover.containsMouse ? Colours.palette.m3onErrorContainer : Colours.palette.m3error
                                                fontStyle: Tokens.font.icon.small
                                            }

                                            MouseArea {
                                                id: delHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: PlacesModel.removeBookmark(placeRowCard.index)
                                            }
                                        }
                                    }

                                    Column {
                                        id: placeTextCol
                                        anchors.left: placeIcon.right
                                        anchors.leftMargin: Tokens.spacing.small
                                        anchors.right: placeActions.left
                                        anchors.rightMargin: Tokens.spacing.small
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 0

                                        StyledText {
                                            width: parent.width
                                            text: placeRowCard.name
                                            color: Colours.palette.m3onSurface
                                            font: Tokens.font.body.small
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            width: parent.width
                                            text: placeRowCard.path
                                            color: Colours.palette.m3onSurfaceVariant
                                            font: Tokens.font.label.small
                                            elide: Text.ElideMiddle
                                        }
                                    }

                                    MouseArea {
                                        id: rowHoverArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.NoButton
                                    }
                                }
                            }
                        }
                    }

                    // --- TAB 1: Devices & Partitions ---
                    Item {
                        width: contentArea.width
                        height: contentArea.height

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Tokens.spacing.small

                            StyledText {
                                text: qsTr("Toggle visibility of partitions and storage devices in the sidebar:")
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.small
                            }

                            VerticalFadeListView {
                                id: devicesList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 4
                                model: root.allDevicesList

                                ScrollBar.vertical: StyledScrollBar {
                                    flickable: devicesList
                                }

                                delegate: StyledRect {
                                    id: devRowCard
                                    required property int index
                                    required property var modelData

                                    width: devicesList.width
                                    height: 46
                                    implicitHeight: 46
                                    radius: Tokens.rounding.medium
                                    color: devHoverArea.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer

                                    MaterialIcon {
                                        id: devIcon
                                        anchors.left: parent.left
                                        anchors.leftMargin: Tokens.padding.medium
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: devRowCard.modelData.isRemovable ? "usb" : "hard_drive"
                                        color: devRowCard.modelData.isHidden ? Colours.palette.m3outline : Colours.palette.m3primary
                                        fontStyle: Tokens.font.icon.medium
                                    }

                                    // Visibility Toggle Button
                                    StyledRect {
                                        id: visBtn
                                        anchors.right: parent.right
                                        anchors.rightMargin: Tokens.padding.small
                                        anchors.verticalCenter: parent.verticalCenter
                                        implicitWidth: 28
                                        implicitHeight: 28
                                        radius: Tokens.rounding.full
                                        color: visHover.containsMouse ? Colours.palette.m3surfaceContainerHigh : "transparent"

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            text: devRowCard.modelData.isHidden ? "visibility_off" : "visibility"
                                            color: devRowCard.modelData.isHidden ? Colours.palette.m3error : Colours.palette.m3primary
                                            fontStyle: Tokens.font.icon.small
                                        }

                                        MouseArea {
                                            id: visHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                DriveManager.toggleDeviceHidden(devRowCard.modelData.devicePath);
                                                root.refreshDevices();
                                            }
                                        }
                                    }

                                    Column {
                                        id: devTextCol
                                        anchors.left: devIcon.right
                                        anchors.leftMargin: Tokens.spacing.small
                                        anchors.right: visBtn.left
                                        anchors.rightMargin: Tokens.spacing.small
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 0

                                        StyledText {
                                            width: parent.width
                                            text: devRowCard.modelData.name + (devRowCard.modelData.fsType ? ` (${devRowCard.modelData.sizeFormatted} • ${devRowCard.modelData.fsType})` : ` (${devRowCard.modelData.sizeFormatted})`)
                                            color: devRowCard.modelData.isHidden ? Colours.palette.m3outline : Colours.palette.m3onSurface
                                            font: Tokens.font.body.small
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            width: parent.width
                                            text: devRowCard.modelData.devicePath + (devRowCard.modelData.mountPoint ? ` → ${devRowCard.modelData.mountPoint}` : qsTr(" (unmounted)"))
                                            color: Colours.palette.m3onSurfaceVariant
                                            font: Tokens.font.label.small
                                            elide: Text.ElideMiddle
                                        }
                                    }

                                    MouseArea {
                                        id: devHoverArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.NoButton
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Bottom Action Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Item { Layout.fillWidth: true }

                // Cancel Button
                StyledRect {
                    implicitWidth: 90
                    implicitHeight: 38
                    radius: Tokens.rounding.full
                    color: cancelHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Cancel")
                        color: Colours.palette.m3primary
                        font: Tokens.font.label.large
                    }

                    MouseArea {
                        id: cancelHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.expanded = false
                    }
                }

                // Done Button
                StyledRect {
                    implicitWidth: 96
                    implicitHeight: 38
                    radius: Tokens.rounding.full
                    color: doneHover.containsMouse ? Colours.palette.m3primaryContainer : Colours.palette.m3primary

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Done")
                        color: doneHover.containsMouse ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onPrimary
                        font: Tokens.font.label.large
                    }

                    MouseArea {
                        id: doneHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.expanded = false
                    }
                }
            }
        }
    }
}
