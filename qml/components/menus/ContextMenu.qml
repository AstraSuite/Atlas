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
    readonly property bool isTrash: currentDir.indexOf("Trash") !== -1 || currentDir.indexOf("trash:") !== -1 || (targetItem && targetItem.isTrashItem)
    readonly property bool isArchive: targetItem && (
        targetItem.name.endsWith(".zip") || targetItem.name.endsWith(".tar.gz") ||
        targetItem.name.endsWith(".tar.xz") || targetItem.name.endsWith(".tar.zst") ||
        targetItem.name.endsWith(".tgz") || targetItem.name.endsWith(".7z") || targetItem.name.endsWith(".rar")
    )

    signal actionTriggered(string action, var item)

    anchors.fill: parent
    visible: opacity > 0.01
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: expanded = false

    opacity: expanded ? 1 : 0
    Behavior on opacity { Anim { type: Anim.FastEffects } }

    StyledRect {
        id: menuRect

        x: Math.min(Math.max(8, root.menuX), root.width - width - 8)
        y: Math.min(Math.max(8, root.menuY), root.height - height - 8)

        implicitWidth: Math.max(220, menuCol.implicitWidth + Tokens.padding.extraSmall * 2)
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
                    implicitHeight: 36
                    radius: Tokens.rounding.medium
                    color: itemHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

                    StateLayer {
                        id: itemHover
                        onClicked: {
                            root.expanded = false;
                            root.actionTriggered(menuItem.modelData.action, root.targetItem);
                        }
                    }

                    RowLayout {
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
                    }
                }
            }
        }
    }
}
