import QtQuick
import QtQuick.Layouts
import "../"
import atlas

MouseArea {
    id: root

    property bool expanded: false
    property real menuX: 0
    property real menuY: 0
    property int targetIndex: -1
    property string targetName: ""
    property string targetPath: ""
    property string targetIcon: "folder"
    property bool isCustom: false
    property bool isTrash: false
    property bool isDevice: false
    property bool isMounted: false
    property string devicePath: ""
    property bool submenuOpen: false
    property real submenuY: 0

    signal editRequested(int index, string name, string path, string iconName, bool isCustom)
    signal emptyTrashRequested()
    signal manageRequested()

    function openForPlace(x, y, idx, name, path, iconName, custom, trash) {
        menuX = x;
        menuY = y;
        targetIndex = idx;
        targetName = name;
        targetPath = path;
        targetIcon = iconName;
        isCustom = custom;
        isTrash = trash;
        isDevice = false;
        devicePath = "";
        submenuOpen = false;
        expanded = true;
    }

    function openForDevice(x, y, devPath, name, mountPt, mounted) {
        menuX = x;
        menuY = y;
        devicePath = devPath;
        targetName = name;
        targetPath = mountPt;
        isMounted = mounted;
        isDevice = true;
        isCustom = false;
        isTrash = false;
        submenuOpen = false;
        expanded = true;
    }

    anchors.fill: parent
    z: 999
    visible: opacity > 0.01
    enabled: expanded
    hoverEnabled: expanded
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: {
        expanded = false;
        submenuOpen = false;
    }

    opacity: expanded ? 1.0 : 0.0
    Behavior on opacity { Anim { type: Anim.FastEffects } }

    StyledRect {
        id: menuCard

        x: Math.min(Math.max(8, root.menuX), root.width - width - 8)
        y: Math.min(Math.max(8, root.menuY), root.height - height - 8)

        implicitWidth: menuCol.implicitWidth + Tokens.padding.extraSmall * 2
        implicitHeight: menuCol.implicitHeight + Tokens.padding.extraSmall * 2

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerLow

        scale: root.expanded ? 1.0 : 0.94
        Behavior on scale { Anim { type: Anim.FastEffects; easing: Tokens.anim.standard } }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: menuCol
            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall
            spacing: 0

            Repeater {
                model: {
                    if (root.isTrash) {
                        return [
                            { text: qsTr("Open"), icon: "delete", action: "open" },
                            { text: qsTr("Open in New Tab"), icon: "tab", action: "openTab" },
                            { text: qsTr("Open in New Window"), icon: "open_in_new", action: "openWindow" },
                            { text: qsTr("Empty Trash"), icon: "delete_sweep", action: "emptyTrash" },
                            { text: qsTr("Places Icon Size"), icon: "photo_size_select_large", action: "iconSize", hasSubmenu: true }
                        ];
                    }

                    if (root.isDevice) {
                        let list = [];
                        if (root.isMounted) {
                            list.push({ text: qsTr("Open"), icon: "folder_open", action: "open" });
                            list.push({ text: qsTr("Open in New Tab"), icon: "tab", action: "openTab" });
                            list.push({ text: qsTr("Open in New Window"), icon: "open_in_new", action: "openWindow" });
                            list.push({ text: qsTr("Open in Split View"), icon: "splitscreen", action: "openSplit" });
                            list.push({ text: qsTr("Open in Terminal"), icon: "terminal", action: "openTerminal" });
                            list.push({ text: qsTr("Unmount"), icon: "eject", action: "unmount" });
                            list.push({ text: qsTr("Eject & Power Off"), icon: "power_settings_new", action: "eject" });
                        } else {
                            list.push({ text: qsTr("Mount & Open"), icon: "hard_drive", action: "mount" });
                            list.push({ text: qsTr("Mount in New Tab"), icon: "tab", action: "mountTab" });
                            list.push({ text: qsTr("Eject & Power Off"), icon: "power_settings_new", action: "eject" });
                        }
                        list.push({ text: qsTr("Hide from Sidebar"), icon: "visibility_off", action: "hideDevice" });
                        list.push({ text: qsTr("Places Icon Size"), icon: "photo_size_select_large", action: "iconSize", hasSubmenu: true });
                        list.push({ text: qsTr("Manage Places & Devices..."), icon: "tune", action: "manage" });
                        return list;
                    }

                    let list = [
                        { text: qsTr("Open"), icon: "folder_open", action: "open" },
                        { text: qsTr("Open in New Tab"), icon: "tab", action: "openTab" },
                        { text: qsTr("Open in New Window"), icon: "open_in_new", action: "openWindow" },
                        { text: qsTr("Open in Split View"), icon: "splitscreen", action: "openSplit" },
                        { text: qsTr("Open in Terminal"), icon: "terminal", action: "openTerminal" },
                        { text: qsTr("Edit Place..."), icon: "edit", action: "edit" },
                        { text: qsTr("Hide from Sidebar"), icon: "bookmark_remove", action: "remove" },
                        { text: qsTr("Places Icon Size"), icon: "photo_size_select_large", action: "iconSize", hasSubmenu: true },
                        { text: qsTr("Manage Places & Devices..."), icon: "tune", action: "manage" }
                    ];

                    return list;
                }

                StyledRect {
                    id: menuItem
                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    implicitWidth: itemRow.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: 36
                    radius: Tokens.rounding.medium
                    color: (itemHover.containsMouse || (menuItem.modelData.hasSubmenu && root.submenuOpen)) ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

                    RowLayout {
                        id: itemRow
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.medium
                        anchors.rightMargin: Tokens.padding.medium
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            text: menuItem.modelData.icon
                            fontStyle: Tokens.font.icon.small
                            color: menuItem.modelData.action === "remove" || menuItem.modelData.action === "emptyTrash" || menuItem.modelData.action === "unmount"
                                ? Colours.palette.m3error
                                : Colours.palette.m3onSurfaceVariant
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: menuItem.modelData.text
                            font: Tokens.font.body.medium
                            color: menuItem.modelData.action === "remove" || menuItem.modelData.action === "emptyTrash"
                                ? Colours.palette.m3error
                                : Colours.palette.m3onSurface
                        }

                        MaterialIcon {
                            visible: menuItem.modelData.hasSubmenu === true
                            text: "chevron_right"
                            color: Colours.palette.m3outline
                            fontStyle: Tokens.font.icon.small
                        }
                    }

                    MouseArea {
                        id: itemHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: {
                            if (menuItem.modelData.hasSubmenu) {
                                if (containsMouse) {
                                    root.submenuY = menuItem.y + menuCard.y;
                                    root.submenuOpen = true;
                                }
                            } else if (containsMouse) {
                                root.submenuOpen = false;
                            }
                        }
                        onClicked: {
                            if (menuItem.modelData.hasSubmenu) {
                                root.submenuY = menuItem.y + menuCard.y;
                                root.submenuOpen = !root.submenuOpen;
                                return;
                            }

                            root.expanded = false;
                            root.submenuOpen = false;
                            let act = menuItem.modelData.action;

                            if (act === "open") {
                                if (TabManager.currentTab) {
                                    TabManager.currentTab.currentPath = root.targetPath;
                                }
                            } else if (act === "openTab") {
                                TabManager.newTab(root.targetPath, false);
                            } else if (act === "openWindow") {
                                AppIntegration.openNewWindow(root.targetPath);
                            } else if (act === "openSplit") {
                                if (TabManager.currentTab) {
                                    TabManager.currentTab.splitPath = root.targetPath;
                                    TabManager.currentTab.isSplit = true;
                                }
                            } else if (act === "openTerminal") {
                                AppIntegration.openInTerminal(root.targetPath);
                            } else if (act === "edit") {
                                root.editRequested(root.targetIndex, root.targetName, root.targetPath, root.targetIcon, root.isCustom);
                            } else if (act === "remove") {
                                PlacesModel.removePlace(root.targetIndex);
                            } else if (act === "emptyTrash") {
                                root.emptyTrashRequested();
                            } else if (act === "unmount") {
                                DriveManager.unmountDevice(root.devicePath);
                            } else if (act === "eject") {
                                DriveManager.ejectDevice(root.devicePath);
                            } else if (act === "mount") {
                                DriveManager.mountDevice(root.devicePath, TabManager.currentIndex);
                            } else if (act === "mountTab") {
                                DriveManager.mountDevice(root.devicePath, -1);
                            } else if (act === "hideDevice") {
                                DriveManager.hideDevice(root.devicePath);
                            } else if (act === "manage") {
                                root.manageRequested();
                            }
                        }
                    }
                }
            }
        }
    }

    // Places Icon Size Submenu Floating Popup
    StyledRect {
        id: sizeSubmenuRect

        visible: root.submenuOpen
        z: menuCard.z + 1

        x: (menuCard.x + menuCard.width + 160 < root.width) ? (menuCard.x + menuCard.width + 4) : Math.max(8, menuCard.x - width - 4)
        y: Math.min(Math.max(8, root.submenuY), root.height - height - 8)

        implicitWidth: sizeSubmenuCol.implicitWidth + Tokens.padding.extraSmall * 2
        implicitHeight: sizeSubmenuCol.implicitHeight + Tokens.padding.extraSmall * 2

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerLow

        scale: root.submenuOpen ? 1.0 : 0.94
        opacity: root.submenuOpen ? 1.0 : 0.0
        Behavior on opacity { Anim { type: Anim.FastEffects } }
        Behavior on scale { Anim { type: Anim.FastEffects; easing: Tokens.anim.standard } }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: sizeSubmenuCol

            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall
            spacing: 0

            Repeater {
                model: [
                    { label: qsTr("Small (16px)"), size: 16 },
                    { label: qsTr("Medium (20px)"), size: 20 },
                    { label: qsTr("Large (24px)"), size: 24 },
                    { label: qsTr("Extra Large (32px)"), size: 32 }
                ]

                StyledRect {
                    id: sizeItem

                    required property int index
                    required property var modelData

                    readonly property bool isCurrent: AppController.placesIconSize === modelData.size

                    Layout.fillWidth: true
                    implicitWidth: sizeRow.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: 36
                    radius: Tokens.rounding.medium
                    color: isCurrent
                        ? Colours.palette.m3primaryContainer
                        : (subHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent")

                    RowLayout {
                        id: sizeRow
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.medium
                        anchors.rightMargin: Tokens.padding.medium
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            text: sizeItem.isCurrent ? "check" : "radio_button_unchecked"
                            color: sizeItem.isCurrent ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: sizeItem.modelData.label
                            font: Tokens.font.body.medium
                            color: sizeItem.isCurrent ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                        }
                    }

                    MouseArea {
                        id: subHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            AppController.placesIconSize = sizeItem.modelData.size;
                            root.submenuOpen = false;
                            root.expanded = false;
                        }
                    }
                }
            }
        }
    }
}
