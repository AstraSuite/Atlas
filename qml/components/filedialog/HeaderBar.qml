import QtQuick
import QtQuick.Layouts
import "../"

StyledRect {
    id: root

    required property var dialog

    implicitWidth: inner.implicitWidth + Tokens.padding.medium * 2
    implicitHeight: inner.implicitHeight + Tokens.padding.medium * 2

    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.small

        Item {
            implicitWidth: implicitHeight
            implicitHeight: upIcon.implicitHeight + Tokens.padding.small

            StateLayer {
                id: upFolderHover
                radius: Tokens.rounding.medium
                disabled: root.dialog.cwd.length <= 1
                onClicked: {
                    if (root.dialog.cwd.length > 1) {
                        let newCwd = root.dialog.cwd.slice(0, root.dialog.cwd.length - 1);
                        root.dialog.cwd = newCwd;
                    }
                }
            }

            MaterialIcon {
                id: upIcon

                anchors.centerIn: parent
                text: "drive_folder_upload"
                color: root.dialog.cwd.length <= 1 ? Colours.palette.m3outline : Colours.palette.m3onSurface
                grade: 200
            }

            StyledToolTip {
                text: qsTr("Go up")
                visible: upFolderHover.containsMouse && !upFolderHover.disabled
            }
        }

        StyledRect {
            Layout.fillWidth: true

            radius: Tokens.rounding.medium
            color: Colours.tPalette.m3surfaceContainerHigh

            implicitHeight: pathComponents.implicitHeight + pathComponents.anchors.margins * 2

            RowLayout {
                id: pathComponents

                anchors.fill: parent
                anchors.margins: Tokens.padding.extraSmall / 2
                anchors.leftMargin: 0

                spacing: Tokens.spacing.small

                Repeater {
                    model: root.dialog.cwd

                    RowLayout {
                        id: folder

                        required property string modelData
                        required property int index

                        spacing: 0

                        Loader {
                            Layout.rightMargin: Tokens.spacing.small
                            active: folder.index > 0
                            sourceComponent: StyledText {
                                text: "/"
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.builders.small.weight(Font.Bold).build()
                            }
                        }

                        Item {
                            implicitWidth: (homeIcon.active ? homeIcon.implicitWidth : (rootIcon.active ? rootIcon.implicitWidth : 0)) + ((homeIcon.active || rootIcon.active) ? Tokens.padding.extraSmall : 0) + folderName.implicitWidth + Tokens.padding.medium * 2
                            implicitHeight: folderName.implicitHeight + Tokens.padding.small

                            Loader {
                                anchors.fill: parent
                                active: folder.index < root.dialog.cwd.length - 1
                                sourceComponent: StateLayer {
                                    onClicked: {
                                        root.dialog.cwd = root.dialog.cwd.slice(0, folder.index + 1);
                                    }

                                    radius: Tokens.rounding.medium
                                }
                            }

                            Loader {
                                id: homeIcon

                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Tokens.padding.medium

                                active: folder.index === 0 && folder.modelData === "Home"
                                sourceComponent: MaterialIcon {
                                    text: "home"
                                    color: root.dialog.cwd.length === 1 ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                                    fill: 1
                                }
                            }

                            Loader {
                                id: rootIcon

                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Tokens.padding.medium

                                active: folder.index === 0 && folder.modelData === ""
                                sourceComponent: MaterialIcon {
                                    text: "hard_drive"
                                    color: root.dialog.cwd.length === 1 ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                                    fill: 1
                                }
                            }

                            StyledText {
                                id: folderName

                                anchors.left: homeIcon.active ? homeIcon.right : (rootIcon.active ? rootIcon.right : parent.left)
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: (homeIcon.active || rootIcon.active) ? Tokens.padding.extraSmall : Tokens.padding.medium

                                text: (folder.index === 0 && folder.modelData === "") ? qsTr("Root") : folder.modelData
                                color: folder.index < root.dialog.cwd.length - 1 ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface
                                font: Tokens.font.body.builders.small.weight(Font.Bold).build()
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }

        // Hidden files toggle
        Item {
            implicitWidth: implicitHeight
            implicitHeight: hiddenIcon.implicitHeight + Tokens.padding.small

            StateLayer {
                id: hiddenHover
                radius: Tokens.rounding.medium
                onClicked: {
                    root.dialog.showHidden = !root.dialog.showHidden;
                }
            }

            MaterialIcon {
                id: hiddenIcon

                anchors.centerIn: parent
                text: root.dialog.showHidden ? "visibility" : "visibility_off"
                color: root.dialog.showHidden ? Colours.palette.m3primary : Colours.palette.m3outline
                fill: root.dialog.showHidden ? 1 : 0
            }

            StyledToolTip {
                text: root.dialog.showHidden ? qsTr("Hide hidden files (Ctrl+H)") : qsTr("Show hidden files (Ctrl+H)")
                visible: hiddenHover.containsMouse
            }
        }
    }
}
