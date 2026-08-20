import QtQuick
import QtQuick.Layouts
import "../"

MouseArea {
    id: root

    property bool expanded: false
    property real menuX: 0
    property real menuY: 0
    property var targetItem: null
    property string currentDir: ""

    signal actionTriggered(string action, var item)

    anchors.fill: parent
    visible: expanded
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: expanded = false

    opacity: expanded ? 1 : 0
    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    StyledRect {
        id: menuRect

        x: Math.min(Math.max(8, root.menuX), root.width - width - 8)
        y: Math.min(Math.max(8, root.menuY), root.height - height - 8)

        implicitWidth: Math.max(220, menuCol.implicitWidth + Tokens.padding.extraSmall * 2)
        implicitHeight: menuCol.implicitHeight + Tokens.padding.extraSmall * 2

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerLow

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
                    if (root.targetItem) {
                        return [
                            { text: qsTr("Open"), icon: "open_in_new", action: "open" },
                            { text: qsTr("Cut"), icon: "content_cut", action: "cut" },
                            { text: qsTr("Copy"), icon: "content_copy", action: "copy" },
                            { text: qsTr("Paste"), icon: "content_paste", action: "paste", visible: FileOperations.canPaste },
                            { text: qsTr("Rename"), icon: "drive_file_rename_outline", action: "rename" },
                            { text: qsTr("Duplicate"), icon: "control_point_duplicate", action: "duplicate" },
                            { text: qsTr("Move to Trash"), icon: "delete", action: "trash" },
                            { text: qsTr("Properties"), icon: "info", action: "properties" }
                        ];
                    } else {
                        return [
                            { text: qsTr("New Folder"), icon: "create_new_folder", action: "newFolder" },
                            { text: qsTr("New Text File"), icon: "note_add", action: "newFile" },
                            { text: qsTr("Paste"), icon: "content_paste", action: "paste", visible: FileOperations.canPaste },
                            { text: qsTr("Add to Bookmarks"), icon: "bookmark_add", action: "bookmark" },
                            { text: qsTr("Open in Terminal"), icon: "terminal", action: "terminal" },
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
                            color: Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: menuItem.modelData.text
                            color: Colours.palette.m3onSurface
                            font: Tokens.font.body.small
                        }
                    }
                }
            }
        }
    }
}
