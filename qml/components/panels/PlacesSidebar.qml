import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../containers"
import atlas

StyledRect {
    id: root

    required property var activeTab
    property int sidebarWidth: 230

    signal editPlaceRequested(int index, string name, string path, string iconName, bool isCustom)
    signal placeContextMenuRequested(real globalX, real globalY, int index, string name, string path, string iconName, bool isCustom, bool isTrash)
    signal deviceContextMenuRequested(real globalX, real globalY, string devPath, string name, string mountPt, bool isMounted)
    signal filesDropped(var sourceFiles, string targetDir, real mouseX, real mouseY)
    signal managePlacesRequested()
    signal connectServerRequested()

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
                    color: cfgHover.containsMouse ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                    fill: cfgHover.containsMouse ? 1 : 0

                    Behavior on color { CAnim {} }
                    Behavior on fill { Anim { type: Anim.DefaultEffects } }
                }

                MouseArea {
                    id: cfgHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.managePlacesRequested()
                }

                StyledToolTip {
                    text: qsTr("Configure Places")
                    visible: cfgHover.containsMouse
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

                // Section 1: Local Places & Bookmarks
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
                        required property bool isNetwork
                        required property string freeSpaceFormatted

                        visible: !placeItem.isNetwork

                        readonly property bool selected: root.activeTab && (
                            (root.activeTab.isSplit && root.activeTab.activePane === 1)
                                ? root.activeTab.splitPath === path
                                : root.activeTab.currentPath === path
                        )

                        Layout.fillWidth: true
                        implicitHeight: visible ? (placeRow.implicitHeight + Tokens.padding.small * 2) : 0

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

                // Section 2: Network Header & Add Button
                Item {
                    id: netHeader
                    visible: AppController.showNetworkSection
                    Layout.fillWidth: true
                    implicitHeight: visible ? 26 : 0
                    Layout.topMargin: visible ? Tokens.spacing.medium : 0
                    Layout.bottomMargin: visible ? Tokens.spacing.extraSmall : 0

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Network")
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.body.builders.large.weight(Font.Bold).build()
                    }

                    StyledRect {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: Tokens.rounding.full
                        color: srvHover.containsMouse ? Qt.alpha(Colours.palette.m3onSurface, 0.08) : "transparent"

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "add"
                            fontStyle: Tokens.font.icon.small
                            color: srvHover.containsMouse ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                            fill: srvHover.containsMouse ? 1 : 0

                            Behavior on color { CAnim {} }
                            Behavior on fill { Anim { type: Anim.DefaultEffects } }
                        }

                        MouseArea {
                            id: srvHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.connectServerRequested()
                        }

                        StyledToolTip {
                            text: qsTr("Connect to Server")
                            visible: srvHover.containsMouse
                        }
                    }
                }

                // Section 2: Network Items
                Repeater {
                    model: PlacesModel

                    delegate: StyledRect {
                        id: netItem

                        required property int index
                        required property string name
                        required property string path
                        required property string iconName
                        required property bool isDevice
                        required property bool isTrash
                        required property bool isCustom
                        required property bool isNetwork
                        required property string freeSpaceFormatted

                        visible: AppController.showNetworkSection && (netItem.isNetwork === true)

                        readonly property bool selected: root.activeTab && (
                            (root.activeTab.isSplit && root.activeTab.activePane === 1)
                                ? root.activeTab.splitPath === path
                                : root.activeTab.currentPath === path
                        )

                        Layout.fillWidth: true
                        implicitHeight: visible ? (netRow.implicitHeight + Tokens.padding.small * 2) : 0

                        radius: Tokens.rounding.full
                        color: "transparent"

                        Rectangle {
                            anchors.fill: parent
                            radius: Tokens.rounding.full
                            color: Colours.palette.m3secondaryContainer
                            opacity: netItem.selected ? 1.0 : 0.0
                            Behavior on opacity {
                                Anim { type: Anim.FastEffects }
                            }
                        }

                        RowLayout {
                            id: netRow

                            anchors.fill: parent
                            anchors.margins: Tokens.padding.small
                            anchors.leftMargin: Tokens.padding.medium
                            anchors.rightMargin: Tokens.padding.medium
                            spacing: Tokens.spacing.medium

                            MaterialIcon {
                                text: netItem.iconName || "cloud"
                                color: netItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3primary
                                pointSize: AppController.placesIconSize
                                fill: netItem.selected ? 1 : 0

                                Behavior on color { CAnim {} }
                                Behavior on fill { Anim { type: Anim.DefaultEffects } }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: netItem.name
                                color: netItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }
                        }

                        StateLayer {
                            id: netHover
                            anchors.fill: parent
                            radius: Tokens.rounding.full
                            color: netItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                            onClicked: mouse => {
                                if (mouse.button === Qt.MiddleButton) {
                                    TabManager.newTab(netItem.path);
                                } else if (mouse.button === Qt.RightButton) {
                                    let globalPos = mapToItem(null, mouse.x, mouse.y);
                                    root.placeContextMenuRequested(globalPos.x, globalPos.y, netItem.index, netItem.name, netItem.path, netItem.iconName, netItem.isCustom, netItem.isTrash);
                                } else {
                                    if (root.activeTab) {
                                        if (root.activeTab.isSplit && root.activeTab.activePane === 1) {
                                            root.activeTab.splitPath = netItem.path;
                                        } else {
                                            root.activeTab.currentPath = netItem.path;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Section 3: Devices Header
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Tokens.spacing.medium
                    Layout.bottomMargin: Tokens.spacing.extraSmall
                    visible: DriveManager.count > 0
                    text: qsTr("Devices")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.builders.large.weight(Font.Bold).build()
                }

                // Section 3: Devices / Drives List
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
