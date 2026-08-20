import QtQuick
import QtQuick.Layouts
import "../"
import prism

MouseArea {
    id: root

    property bool expanded: false
    property real menuX: 0
    property real menuY: 0
    property var sourceFiles: []
    property string targetDir: ""

    signal actionTriggered(string action, var sources, string dest)

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
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: menuCol

            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall
            spacing: 2

            Repeater {
                model: [
                    { text: qsTr("Move Here"), icon: "drive_file_move", shortcut: "Shift", action: "move" },
                    { text: qsTr("Copy Here"), icon: "content_copy", shortcut: "Ctrl", action: "copy" },
                    { text: qsTr("Link Here"), icon: "link", shortcut: "Ctrl+Shift", action: "link" },
                    { isSeparator: true },
                    { text: qsTr("Move Into New Folder"), icon: "create_new_folder", action: "moveNewFolder" },
                    { isSeparator: true },
                    { text: qsTr("Cancel"), icon: "close", shortcut: "Esc", action: "cancel" }
                ]

                delegate: Item {
                    id: menuItem

                    required property int index
                    required property var modelData

                    implicitWidth: isSeparator ? 160 : (itemRow.implicitWidth + 32)
                    implicitHeight: isSeparator ? 9 : 36
                    Layout.fillWidth: true

                    readonly property bool isSeparator: modelData.isSeparator === true

                    // Separator line
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 8
                        height: 1
                        color: Qt.alpha(Colours.palette.m3outlineVariant, 0.4)
                        visible: menuItem.isSeparator
                    }

                    // Clickable Menu Row
                    StyledRect {
                        anchors.fill: parent
                        radius: Tokens.rounding.small
                        visible: !menuItem.isSeparator
                        color: itemHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

                        RowLayout {
                            id: itemRow
                            anchors.fill: parent
                            anchors.leftMargin: Tokens.padding.small
                            anchors.rightMargin: Tokens.padding.small
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                text: menuItem.modelData.icon || ""
                                color: itemHover.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                text: menuItem.modelData.text || ""
                                color: Colours.palette.m3onSurface
                                font: Tokens.font.body.small
                                Layout.fillWidth: true
                            }

                            StyledText {
                                visible: menuItem.modelData.shortcut ? true : false
                                text: menuItem.modelData.shortcut || ""
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                Layout.alignment: Qt.AlignRight
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
                                if (act === "move") {
                                    FileOperations.moveFiles(root.sourceFiles, root.targetDir);
                                } else if (act === "copy") {
                                    FileOperations.copyFiles(root.sourceFiles, root.targetDir);
                                } else if (act === "link") {
                                    for (let i = 0; i < root.sourceFiles.length; ++i) {
                                        let src = root.sourceFiles[i];
                                        let fileName = src.substring(src.lastIndexOf('/') + 1);
                                        let linkPath = root.targetDir + "/" + fileName;
                                        FileOperations.createSymlink(src, linkPath);
                                    }
                                } else if (act === "moveNewFolder") {
                                    root.actionTriggered("moveNewFolder", root.sourceFiles, root.targetDir);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
