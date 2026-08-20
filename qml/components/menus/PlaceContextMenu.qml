import QtQuick
import QtQuick.Layouts
import "../"
import prism

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

    signal editRequested(int index, string name, string path, string iconName, bool isCustom)
    signal emptyTrashRequested()

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
        expanded = true;
    }

    anchors.fill: parent
    z: 999
    visible: opacity > 0.01
    enabled: expanded
    hoverEnabled: expanded
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: expanded = false

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
                            { text: qsTr("Empty Trash"), icon: "delete_sweep", action: "emptyTrash" }
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
                        return list;
                    }

                    let list = [
                        { text: qsTr("Open"), icon: "folder_open", action: "open" },
                        { text: qsTr("Open in New Tab"), icon: "tab", action: "openTab" },
                        { text: qsTr("Open in New Window"), icon: "open_in_new", action: "openWindow" },
                        { text: qsTr("Open in Split View"), icon: "splitscreen", action: "openSplit" },
                        { text: qsTr("Open in Terminal"), icon: "terminal", action: "openTerminal" },
                        { text: qsTr("Edit Place..."), icon: "edit", action: "edit" }
                    ];

                    if (root.isCustom) {
                        list.push({ text: qsTr("Remove from Places"), icon: "bookmark_remove", action: "remove" });
                    }

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
                    color: itemHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

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
                    }

                    MouseArea {
                        id: itemHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.expanded = false;
                            let act = menuItem.modelData.action;

                            if (act === "open") {
                                if (TabManager.currentTab) {
                                    TabManager.currentTab.currentPath = root.targetPath;
                                }
                            } else if (act === "openTab") {
                                TabManager.newTab(root.targetPath);
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
                            }
                        }
                    }
                }
            }
        }
    }
}
