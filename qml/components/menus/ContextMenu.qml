import QtQuick
import QtQuick.Layouts
import "../"
import prism

MouseArea {
    id: root

    property bool expanded: false
    property real menuX: 0
    property real menuY: 0
    property var targetItem: null
    property string currentDir: ""
    property bool submenuOpen: false
    property real submenuY: 0
    property var sharingServices: []

    readonly property bool isTrash: currentDir.indexOf("Trash") !== -1 || currentDir.indexOf("trash:") !== -1 || (targetItem && targetItem.isTrashItem)
    readonly property bool isArchive: targetItem && (
        targetItem.name.endsWith(".zip") || targetItem.name.endsWith(".tar.gz") ||
        targetItem.name.endsWith(".tar.xz") || targetItem.name.endsWith(".tar.zst") ||
        targetItem.name.endsWith(".tgz") || targetItem.name.endsWith(".7z") || targetItem.name.endsWith(".rar")
    )

    signal actionTriggered(string action, var item)

    onExpandedChanged: {
        submenuOpen = false;
        if (expanded) {
            sharingServices = AppIntegration.getAvailableSharingServices();
        }
    }

    anchors.fill: parent
    visible: opacity > 0.01
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: {
        expanded = false;
        submenuOpen = false;
    }

    opacity: expanded ? 1 : 0
    Behavior on opacity { Anim { type: Anim.FastEffects } }

    StyledRect {
        id: menuRect

        x: Math.min(Math.max(8, root.menuX), root.width - width - 8)
        y: Math.min(Math.max(8, root.menuY), root.height - height - 8)

        implicitWidth: menuCol.implicitWidth + Tokens.padding.extraSmall * 2
        implicitHeight: menuCol.implicitHeight + Tokens.padding.extraSmall * 2

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerLow

        scale: root.expanded ? 1.0 : 0.94
        Behavior on scale {
            Anim {
                type: Anim.FastEffects
                easing: Tokens.anim.standard
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
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
                        if (root.targetItem) {
                            return [
                                { text: qsTr("Restore"), icon: "restore_from_trash", action: "restore" },
                                { text: qsTr("Delete Permanently"), icon: "delete_forever", action: "delete" },
                                { text: qsTr("Properties"), icon: "info", action: "properties" }
                            ];
                        } else {
                            return [
                                { text: qsTr("Empty Trash"), icon: "delete_sweep", action: "emptyTrash" },
                                { text: qsTr("Properties"), icon: "info", action: "propertiesDir" }
                            ];
                        }
                    }

                    if (root.targetItem) {
                        let list = [];
                        if (root.targetItem.isDir) {
                            list.push({ text: qsTr("Open"), icon: "folder_open", action: "open" });
                            list.push({ text: qsTr("Open in New Tab"), icon: "tab", action: "openNewTab" });
                            list.push({ text: qsTr("Open in New Window"), icon: "open_in_new", action: "openNewWindow" });
                            list.push({ text: qsTr("Open in Split View"), icon: "splitscreen", action: "openSplit" });
                            list.push({ text: qsTr("Open in Terminal"), icon: "terminal", action: "openTerminalItem" });
                        } else {
                            if (root.targetItem.isImage || root.targetItem.isVideo || FileUtils.isImage(root.targetItem.path) || FileUtils.isVideo(root.targetItem.path)) {
                                list.push({ text: qsTr("Preview (Space)"), icon: "visibility", action: "preview" });
                            }
                            list.push({ text: qsTr("Open"), icon: "open_in_new", action: "open" });
                            list.push({ text: qsTr("Open With..."), icon: "open_with", action: "openWith" });
                        }

                        if (root.isArchive) {
                            list.push({ text: qsTr("Extract Here"), icon: "unarchive", action: "extractHere" });
                            list.push({ text: qsTr("Extract to Folder"), icon: "folder_zip", action: "extractTo" });
                        }

                        list.push({ text: qsTr("Compress..."), icon: "archive", action: "compress" });
                        list.push({ text: qsTr("Cut"), icon: "content_cut", action: "cut" });
                        list.push({ text: qsTr("Copy"), icon: "content_copy", action: "copy" });
                        list.push({ text: qsTr("Copy Path"), icon: "link", action: "copyPath" });
                        list.push({ text: qsTr("Send To"), icon: "send", action: "sendTo", hasSubmenu: true });
                        list.push({ text: qsTr("Paste"), icon: "content_paste", action: "paste", visible: FileOperations.canPaste });
                        list.push({ text: qsTr("Create Symlink"), icon: "link", action: "symlink" });
                        list.push({ text: qsTr("Rename"), icon: "drive_file_rename_outline", action: "rename" });
                        list.push({ text: qsTr("Duplicate"), icon: "control_point_duplicate", action: "duplicate" });
                        list.push({ text: qsTr("Move to Trash"), icon: "delete", action: "trash" });
                        list.push({ text: qsTr("Properties"), icon: "info", action: "properties" });

                        return list;
                    } else {
                        return [
                            { text: qsTr("New Folder"), icon: "create_new_folder", action: "newFolder" },
                            { text: qsTr("New Text File"), icon: "note_add", action: "newFile" },
                            { text: qsTr("Paste"), icon: "content_paste", action: "paste", visible: FileOperations.canPaste },
                            { text: qsTr("Paste as Symlink"), icon: "link", action: "pasteSymlink", visible: FileOperations.canPaste },
                            { text: qsTr("Copy Path"), icon: "link", action: "copyCurrentDirPath" },
                            { text: qsTr("Add to Bookmarks"), icon: "bookmark_add", action: "bookmark" },
                            { text: qsTr("Open in Terminal"), icon: "terminal", action: "openTerminal" },
                            { text: qsTr("Properties"), icon: "info", action: "propertiesDir" }
                        ];
                    }
                }

                StyledRect {
                    id: menuItem

                    required property int index
                    required property var modelData
                    visible: modelData.visible !== false

                    Layout.fillWidth: true
                    implicitWidth: itemRow.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: 36
                    radius: Tokens.rounding.medium
                    color: (itemHover.containsMouse || (modelData.hasSubmenu && root.submenuOpen)) ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

                    StateLayer {
                        id: itemHover
                        hoverEnabled: true
                        onContainsMouseChanged: {
                            if (menuItem.modelData.hasSubmenu) {
                                if (containsMouse) {
                                    root.submenuY = menuItem.y + menuRect.y;
                                    root.submenuOpen = true;
                                }
                            } else if (containsMouse) {
                                root.submenuOpen = false;
                            }
                        }
                        onClicked: {
                            if (menuItem.modelData.hasSubmenu) {
                                root.submenuY = menuItem.y + menuRect.y;
                                root.submenuOpen = !root.submenuOpen;
                            } else {
                                root.expanded = false;
                                root.submenuOpen = false;
                                root.actionTriggered(menuItem.modelData.action, root.targetItem);
                            }
                        }
                    }

                    RowLayout {
                        id: itemRow
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.medium
                        anchors.rightMargin: Tokens.padding.medium
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            text: menuItem.modelData.icon
                            color: menuItem.modelData.action === "delete" || menuItem.modelData.action === "emptyTrash" ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: menuItem.modelData.text
                            font: Tokens.font.body.medium
                            color: menuItem.modelData.action === "delete" || menuItem.modelData.action === "emptyTrash" ? Colours.palette.m3error : Colours.palette.m3onSurface
                        }

                        MaterialIcon {
                            visible: menuItem.modelData.hasSubmenu === true
                            text: "chevron_right"
                            color: Colours.palette.m3outline
                            fontStyle: Tokens.font.icon.small
                        }
                    }
                }
            }
        }
    }

    // Send To Submenu Floating Popup
    StyledRect {
        id: submenuRect

        visible: root.submenuOpen && root.sharingServices && root.sharingServices.length > 0
        z: menuRect.z + 1

        x: (menuRect.x + menuRect.width + 180 < root.width) ? (menuRect.x + menuRect.width + 4) : Math.max(8, menuRect.x - width - 4)
        y: Math.min(Math.max(8, root.submenuY), root.height - height - 8)

        implicitWidth: submenuCol.implicitWidth + Tokens.padding.extraSmall * 2
        implicitHeight: submenuCol.implicitHeight + Tokens.padding.extraSmall * 2

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
            id: submenuCol

            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall
            spacing: 0

            Repeater {
                model: root.sharingServices

                StyledRect {
                    id: subMenuItem

                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    implicitWidth: subItemRow.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: 36
                    radius: Tokens.rounding.medium
                    color: subHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

                    StateLayer {
                        id: subHover
                        hoverEnabled: true
                        onClicked: {
                            root.expanded = false;
                            root.submenuOpen = false;
                            root.actionTriggered("sendTo:" + subMenuItem.modelData.id, root.targetItem);
                        }
                    }

                    RowLayout {
                        id: subItemRow
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.medium
                        anchors.rightMargin: Tokens.padding.medium
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            text: subMenuItem.modelData.icon || "share"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: subMenuItem.modelData.name || ""
                            font: Tokens.font.body.medium
                            color: Colours.palette.m3onSurface
                        }
                    }
                }
            }
        }
    }
}
