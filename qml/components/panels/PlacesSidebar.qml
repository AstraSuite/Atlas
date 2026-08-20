import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../containers"
import prism

StyledRect {
    id: root

    required property var activeTab
    property int sidebarWidth: 230

    signal editPlaceRequested(int index, string name, string path, string iconName, bool isCustom)

    implicitWidth: sidebarWidth
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.extraSmall

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.padding.extraSmall / 2
            Layout.bottomMargin: Tokens.spacing.small
            text: qsTr("Places")
            color: Colours.palette.m3onSurface
            font: Tokens.font.body.builders.large.weight(Font.Bold).build()
        }

        // Scrollable Places & Devices List with vertical edge fade
        VerticalFadeFlickable {
            id: flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentCol.implicitHeight
            clip: true
            fadeAmount: 0.08

            ScrollBar.vertical: StyledScrollBar {
                flickable: flickable
            }

            ColumnLayout {
                id: contentCol
                width: flickable.width
                spacing: Tokens.spacing.small

                // Section 1: Places
                Repeater {
                    model: PlacesModel

                    delegate: StyledRect {
                        id: placeItem

                        required property int index
                        required property string name
                        required property string path
                        required property string iconName
                        required property bool isDevice
                        required property bool isTrash
                        required property bool isCustom
                        required property string freeSpaceFormatted

                        readonly property bool selected: root.activeTab && root.activeTab.currentPath === path

                        Layout.fillWidth: true
                        implicitHeight: placeRow.implicitHeight + Tokens.padding.small * 2

                        radius: Tokens.rounding.full
                        color: selected ? Colours.palette.m3secondaryContainer : (placeHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent")

                        RowLayout {
                            id: placeRow

                            anchors.fill: parent
                            anchors.margins: Tokens.padding.small
                            anchors.leftMargin: Tokens.padding.medium
                            anchors.rightMargin: Tokens.padding.medium
                            spacing: Tokens.spacing.medium

                            MaterialIcon {
                                text: placeItem.iconName
                                color: placeItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                fontStyle: Tokens.font.icon.medium
                                fill: placeItem.selected ? 1 : 0
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: placeItem.name
                                color: placeItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: placeHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor

                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    root.editPlaceRequested(placeItem.index, placeItem.name, placeItem.path, placeItem.iconName, placeItem.isCustom);
                                } else {
                                    if (root.activeTab) {
                                        root.activeTab.currentPath = placeItem.path;
                                    }
                                }
                            }
                        }
                    }
                }

                // Section 2: Devices Header
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Tokens.spacing.medium
                    Layout.bottomMargin: Tokens.spacing.extraSmall
                    visible: DriveManager.count > 0
                    text: qsTr("Devices")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.builders.large.weight(Font.Bold).build()
                }

                // Section 2: Devices / Drives List
                Repeater {
                    model: DriveManager

                    delegate: StyledRect {
                        id: driveItem

                        required property int index
                        required property string name
                        required property string devicePath
                        required property string mountPoint
                        required property string sizeFormatted
                        required property string fsType
                        required property string model
                        required property bool isMounted
                        required property bool isRemovable
                        required property string freeSpaceFormatted

                        readonly property bool selected: root.activeTab && driveItem.isMounted && !driveItem.mountPoint.isEmpty && root.activeTab.currentPath === mountPoint

                        Layout.fillWidth: true
                        implicitHeight: driveRow.implicitHeight + Tokens.padding.small * 2

                        radius: Tokens.rounding.full
                        color: selected ? Colours.palette.m3secondaryContainer : (driveHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent")

                        RowLayout {
                            id: driveRow

                            anchors.fill: parent
                            anchors.margins: Tokens.padding.small
                            anchors.leftMargin: Tokens.padding.medium
                            anchors.rightMargin: Tokens.padding.medium
                            spacing: Tokens.spacing.medium

                            MaterialIcon {
                                text: driveItem.isRemovable ? "usb" : "hard_drive"
                                color: driveItem.selected ? Colours.palette.m3onSecondaryContainer : (driveItem.isMounted ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant)
                                fontStyle: Tokens.font.icon.medium
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: driveItem.name
                                    color: driveItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                    font: Tokens.font.body.small
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: driveItem.isMounted ? driveItem.freeSpaceFormatted : `${driveItem.fsType} (${driveItem.sizeFormatted})`
                                    color: Colours.palette.m3outline
                                    font: Tokens.font.label.small
                                    elide: Text.ElideRight
                                }
                            }

                            // Unmount / Eject Button
                            Item {
                                implicitWidth: 24
                                implicitHeight: 24
                                visible: driveItem.isMounted

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "eject"
                                    color: Colours.palette.m3onSurfaceVariant
                                    fontStyle: Tokens.font.icon.small
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mouse => {
                                        mouse.accepted = true;
                                        DriveManager.unmountDevice(driveItem.devicePath);
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: driveHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor

                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    if (driveItem.isMounted) {
                                        DriveManager.unmountDevice(driveItem.devicePath);
                                    } else {
                                        DriveManager.mountDevice(driveItem.devicePath, TabManager.currentIndex);
                                    }
                                } else {
                                    if (driveItem.isMounted && driveItem.mountPoint && driveItem.mountPoint.length > 0) {
                                        if (root.activeTab) {
                                            root.activeTab.currentPath = driveItem.mountPoint;
                                        }
                                    } else {
                                        DriveManager.mountDevice(driveItem.devicePath, TabManager.currentIndex);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: DriveManager
        function onDeviceMounted(mountPoint, tabIndex) {
            if (TabManager.currentTab) {
                TabManager.currentTab.currentPath = mountPoint;
            }
        }
    }
}
