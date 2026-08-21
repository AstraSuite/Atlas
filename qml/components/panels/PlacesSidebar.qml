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
    signal placeContextMenuRequested(real globalX, real globalY, int index, string name, string path, string iconName, bool isCustom, bool isTrash)
    signal deviceContextMenuRequested(real globalX, real globalY, string devPath, string name, string mountPt, bool isMounted)
    signal filesDropped(var sourceFiles, string targetDir, real mouseX, real mouseY)
    signal managePlacesRequested()

    implicitWidth: sidebarWidth
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

            StyledRect {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 26
                implicitHeight: 26
                radius: Tokens.rounding.full
                color: cfgHover.containsMouse ? Qt.alpha(Colours.palette.m3onSurface, 0.08) : "transparent"

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "tune"
                    fontStyle: Tokens.font.icon.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                MouseArea {
                    id: cfgHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.managePlacesRequested()
                }
            }
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

            // Drop Area on empty sidebar background to pin folders as bookmarks
            DropArea {
                anchors.fill: parent
                z: -1
                onDropped: drop => {
                    if (drop.hasUrls) {
                        for (let i = 0; i < drop.urls.length; ++i) {
                            let path = FileUtils.toLocalFile(drop.urls[i]);
                            let name = FileUtils.baseName(path);
                            if (!name || name.length === 0) name = path;
                            PlacesModel.addCustomPlace(name, path, "folder");
                        }
                        drop.accept();
                    }
                }
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

                        readonly property bool selected: root.activeTab && (
                            (root.activeTab.isSplit && root.activeTab.activePane === 1)
                                ? root.activeTab.splitPath === path
                                : root.activeTab.currentPath === path
                        )

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

                        // Drag over highlight
                        Rectangle {
                            anchors.fill: parent
                            radius: Tokens.rounding.full
                            color: Colours.palette.m3primaryContainer
                            opacity: placeDropArea.containsDrag ? 1.0 : 0.0
                            Behavior on opacity {
                                Anim { type: Anim.FastEffects }
                            }
                        }

                        DropArea {
                            id: placeDropArea
                            anchors.fill: parent
                            onDropped: drop => {
                                if (drop.hasUrls) {
                                    let urls = [];
                                    for (let i = 0; i < drop.urls.length; ++i) {
                                        urls.push(FileUtils.toLocalFile(drop.urls[i]));
                                    }
                                    let filtered = urls.filter(u => u !== placeItem.path);
                                    if (filtered.length > 0) {
                                        let globalPos = mapToItem(null, drop.x, drop.y);
                                        if (drop.modifiers & Qt.ShiftModifier) {
                                            FileOperations.moveFiles(filtered, placeItem.path);
                                        } else if (drop.modifiers & Qt.ControlModifier) {
                                            FileOperations.copyFiles(filtered, placeItem.path);
                                        } else {
                                            root.filesDropped(filtered, placeItem.path, globalPos.x, globalPos.y);
                                        }
                                        drop.accept();
                                    }
                                }
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

                        StateLayer {
                            id: placeHover
                            anchors.fill: parent
                            radius: Tokens.rounding.full
                            color: placeItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                            onClicked: mouse => {
                                if (mouse.button === Qt.MiddleButton) {
                                    TabManager.newTab(placeItem.path);
                                } else if (mouse.button === Qt.RightButton) {
                                    let globalPos = mapToItem(null, mouse.x, mouse.y);
                                    root.placeContextMenuRequested(globalPos.x, globalPos.y, placeItem.index, placeItem.name, placeItem.path, placeItem.iconName, placeItem.isCustom, placeItem.isTrash);
                                } else {
                                    if (root.activeTab) {
                                        if (root.activeTab.isSplit && root.activeTab.activePane === 1) {
                                            root.activeTab.splitPath = placeItem.path;
                                        } else {
                                            root.activeTab.currentPath = placeItem.path;
                                        }
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
                        required property real bytesFree
                        required property real bytesTotal
                        required property string freeSpaceFormatted

                        readonly property bool selected: root.activeTab && driveItem.isMounted && !driveItem.mountPoint.isEmpty && (
                            (root.activeTab.isSplit && root.activeTab.activePane === 1)
                                ? root.activeTab.splitPath === mountPoint
                                : root.activeTab.currentPath === mountPoint
                        )

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

                        // Drag over highlight
                        Rectangle {
                            anchors.fill: parent
                            radius: Tokens.rounding.full
                            color: Colours.palette.m3primaryContainer
                            opacity: driveDropArea.containsDrag ? 1.0 : 0.0
                            Behavior on opacity {
                                Anim { type: Anim.FastEffects }
                            }
                        }

                        DropArea {
                            id: driveDropArea
                            anchors.fill: parent
                            onDropped: drop => {
                                if (drop.hasUrls && driveItem.isMounted && driveItem.mountPoint.length > 0) {
                                    let urls = [];
                                    for (let i = 0; i < drop.urls.length; ++i) {
                                        urls.push(FileUtils.toLocalFile(drop.urls[i]));
                                    }
                                    let filtered = urls.filter(u => u !== driveItem.mountPoint);
                                    if (filtered.length > 0) {
                                        let globalPos = mapToItem(null, drop.x, drop.y);
                                        if (drop.modifiers & Qt.ShiftModifier) {
                                            FileOperations.moveFiles(filtered, driveItem.mountPoint);
                                        } else if (drop.modifiers & Qt.ControlModifier) {
                                            FileOperations.copyFiles(filtered, driveItem.mountPoint);
                                        } else {
                                            root.filesDropped(filtered, driveItem.mountPoint, globalPos.x, globalPos.y);
                                        }
                                        drop.accept();
                                    }
                                }
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
                                fontStyle: Tokens.font.icon.medium
                                fill: driveItem.selected ? 1 : 0
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

                                // Visual Storage Bar (slider track without handle)
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
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                            onClicked: mouse => {
                                if (mouse.button === Qt.MiddleButton) {
                                    if (driveItem.isMounted && driveItem.mountPoint && driveItem.mountPoint.length > 0) {
                                        TabManager.newTab(driveItem.mountPoint);
                                    } else {
                                        DriveManager.mountDevice(driveItem.devicePath, -1);
                                    }
                                } else if (mouse.button === Qt.RightButton) {
                                    let globalPos = mapToItem(null, mouse.x, mouse.y);
                                    root.deviceContextMenuRequested(globalPos.x, globalPos.y, driveItem.devicePath, driveItem.name, driveItem.mountPoint, driveItem.isMounted);
                                } else {
                                    if (driveItem.isMounted && driveItem.mountPoint && driveItem.mountPoint.length > 0) {
                                        if (root.activeTab) {
                                            if (root.activeTab.isSplit && root.activeTab.activePane === 1) {
                                                root.activeTab.splitPath = driveItem.mountPoint;
                                            } else {
                                                root.activeTab.currentPath = driveItem.mountPoint;
                                            }
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
}
