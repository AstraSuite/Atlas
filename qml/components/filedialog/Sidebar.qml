import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import atlas
import "../"
import "../containers"

StyledRect {
    id: root

    required property var dialog

    implicitWidth: sizes.sidebarWidth
    implicitHeight: 600

    Sizes {
        id: sizes
    }

    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.extraSmall

        Item {
            Layout.fillWidth: true
            implicitHeight: 28
            Layout.topMargin: Tokens.padding.extraSmall / 2
            Layout.bottomMargin: Tokens.spacing.small

            StyledText {
                anchors.centerIn: parent
                text: qsTr("Places")
                color: Colours.palette.m3onSurface
                font: Tokens.font.body.builders.large.weight(Font.Bold).build()
            }
        }

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

                // Section 1: Places & Bookmarks
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

                        readonly property bool selected: root.dialog.currentPath === placeItem.path

                        Layout.fillWidth: true
                        implicitHeight: placeRow.implicitHeight + Tokens.padding.small * 2

                        radius: Tokens.rounding.full
                        color: "transparent"

                        // Selection highlight
                        Rectangle {
                            anchors.fill: parent
                            radius: Tokens.rounding.full
                            color: Colours.palette.m3secondaryContainer
                            opacity: placeItem.selected ? 1.0 : 0.0
                            Behavior on opacity {
                                Anim { type: Anim.FastEffects }
                            }
                        }

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
                                pointSize: AppController.placesIconSize
                                fill: placeItem.selected ? 1 : 0

                                Behavior on color { CAnim {} }
                                Behavior on fill { Anim { type: Anim.DefaultEffects } }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: placeItem.name
                                color: placeItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }
                        }

                        StateLayer {
                            id: placeHover
                            anchors.fill: parent
                            radius: Tokens.rounding.full
                            color: placeItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface

                            onClicked: {
                                root.dialog.cwd = root.dialog.pathToCwd(placeItem.path);
                            }
                        }
                    }
                }

                // Section 2: Devices / Drives Header
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
                        required property real bytesFree
                        required property real bytesTotal
                        required property string freeSpaceFormatted

                        readonly property bool selected: driveItem.isMounted && driveItem.mountPoint.length > 0 && root.dialog.currentPath === driveItem.mountPoint

                        Layout.fillWidth: true
                        implicitHeight: driveRow.implicitHeight + Tokens.padding.small * 2

                        radius: Tokens.rounding.full
                        color: "transparent"

                        // Selection highlight
                        Rectangle {
                            anchors.fill: parent
                            radius: Tokens.rounding.full
                            color: Colours.palette.m3secondaryContainer
                            opacity: driveItem.selected ? 1.0 : 0.0
                            Behavior on opacity {
                                Anim { type: Anim.FastEffects }
                            }
                        }

                        RowLayout {
                            id: driveRow

                            anchors.fill: parent
                            anchors.margins: Tokens.padding.small
                            anchors.leftMargin: Tokens.padding.medium
                            anchors.rightMargin: Tokens.padding.medium
                            spacing: Tokens.spacing.medium

                            MaterialIcon {
                                text: driveItem.isRemovable ? "usb" : "hard_drive"
                                color: driveItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                pointSize: AppController.placesIconSize
                                fill: driveItem.selected ? 1 : 0

                                Behavior on color { CAnim {} }
                                Behavior on fill { Anim { type: Anim.DefaultEffects } }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    Layout.fillWidth: true
                                    text: driveItem.name
                                    color: driveItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                    font: Tokens.font.body.small
                                    elide: Text.ElideRight
                                }

                                // Visual Storage Bar
                                StyledRect {
                                    Layout.fillWidth: true
                                    implicitHeight: 4
                                    radius: Tokens.rounding.full
                                    color: Qt.alpha(Colours.palette.m3outline, 0.25)
                                    clip: true
                                    visible: driveItem.isMounted && driveItem.bytesTotal > 0

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: Math.max(4, parent.width * (driveItem.bytesTotal > 0 ? (driveItem.bytesTotal - driveItem.bytesFree) / driveItem.bytesTotal : 0))
                                        radius: Tokens.rounding.full
                                        color: ((driveItem.bytesTotal - driveItem.bytesFree) / driveItem.bytesTotal) > 0.9
                                            ? Colours.palette.m3error
                                            : (driveItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3primary)

                                        Behavior on width {
                                            Anim { type: Anim.FastEffects }
                                        }
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    visible: !driveItem.isMounted || driveItem.bytesTotal === 0
                                    text: `${driveItem.fsType} (${driveItem.sizeFormatted})`
                                    color: Colours.palette.m3outline
                                    font: Tokens.font.label.small
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        StateLayer {
                            id: driveHover
                            anchors.fill: parent
                            radius: Tokens.rounding.full
                            color: driveItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface

                            onClicked: {
                                if (driveItem.isMounted && driveItem.mountPoint && driveItem.mountPoint.length > 0) {
                                    root.dialog.cwd = root.dialog.pathToCwd(driveItem.mountPoint);
                                } else {
                                    DriveManager.mountDevice(driveItem.devicePath, -1);
                                }
                            }

                            StyledToolTip {
                                text: {
                                    if (driveItem.isMounted && driveItem.bytesTotal > 0) {
                                        let used = driveItem.bytesTotal - driveItem.bytesFree;
                                        let percent = Math.round((used / driveItem.bytesTotal) * 100);
                                        return qsTr("Used: %1\nFree: %2\nTotal: %3 (%4% used)")
                                            .arg(FileUtils.formatSize(used))
                                            .arg(FileUtils.formatSize(driveItem.bytesFree))
                                            .arg(FileUtils.formatSize(driveItem.bytesTotal))
                                            .arg(percent);
                                    } else if (driveItem.isMounted) {
                                        return qsTr("Mounted at: %1\nSize: %2").arg(driveItem.mountPoint).arg(driveItem.sizeFormatted);
                                    } else {
                                        return qsTr("Unmounted\nSize: %1").arg(driveItem.sizeFormatted);
                                    }
                                }
                                visible: driveHover.containsMouse
                            }
                        }
                    }
                }
            }
        }
    }
}
