import QtQuick
import QtQuick.Layouts
import "../"
import prism

MouseArea {
    id: root

    property bool expanded: false
    property int targetIndex: -1
    property string placeName: ""
    property string placePath: ""
    property string selectedIcon: "bookmark"
    property bool isCustom: true

    signal accepted(int index, string name, string iconName)
    signal removeRequested(int index)

    anchors.fill: parent
    visible: opacity > 0.001
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    z: 100

    opacity: expanded ? 1.0 : 0.0
    Behavior on opacity {
        Anim {
            type: Anim.FastEffects
        }
    }

    onClicked: root.expanded = false

    Keys.onEscapePressed: root.expanded = false

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.4)
    }

    StyledRect {
        id: modalCard

        anchors.centerIn: parent
        implicitWidth: 440
        implicitHeight: modalCol.implicitHeight + Tokens.padding.large * 2

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerHigh

        scale: root.expanded ? 1.0 : 0.94

        Behavior on scale {
            Anim {
                type: Anim.FastEffects
                easing: Tokens.anim.standard
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: modalCol

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            // Header (no close button, only icon and title)
            RowLayout {
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: root.selectedIcon
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Edit Place")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.medium
                }
            }

            // Path indicator
            StyledText {
                Layout.fillWidth: true
                text: root.placePath
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
                elide: Text.ElideMiddle
            }

            // Name Input Field
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: qsTr("Name")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: Tokens.rounding.small
                    color: Colours.palette.m3surfaceContainerHighest

                    TextInput {
                        id: nameInput
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        text: root.placeName
                        color: Colours.palette.m3onSurface
                        selectionColor: Colours.palette.m3primaryContainer
                        selectedTextColor: Colours.palette.m3onPrimaryContainer
                        font: Tokens.font.body.medium
                        selectByMouse: true
                        cursorVisible: focus

                        onAccepted: root.save()
                    }
                }
            }

            // Icon Picker
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    text: qsTr("Icon")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            "folder", "bookmark", "star", "favorite", "home",
                            "sports_esports", "terminal", "code", "description",
                            "image", "music_note", "video_library", "file_download",
                            "work", "cloud", "lock", "sell", "storage"
                        ]

                        StyledRect {
                            id: iconTile

                            required property string modelData

                            implicitWidth: 36
                            implicitHeight: 36
                            radius: Tokens.rounding.small
                            color: root.selectedIcon === modelData ? Colours.palette.m3primaryContainer : (tileHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent")

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: iconTile.modelData
                                color: root.selectedIcon === iconTile.modelData ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                fontStyle: Tokens.font.icon.small
                            }

                            MouseArea {
                                id: tileHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedIcon = iconTile.modelData
                            }
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Colours.palette.m3outlineVariant
            }

            // Action Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                // Remove Button
                StyledRect {
                    implicitWidth: removeRow.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: removeHover.containsMouse ? Qt.alpha(Colours.palette.m3error, 0.12) : "transparent"

                    RowLayout {
                        id: removeRow
                        anchors.centerIn: parent
                        spacing: 4

                        MaterialIcon {
                            text: "delete"
                            color: Colours.palette.m3error
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            text: qsTr("Remove")
                            color: Colours.palette.m3error
                            font: Tokens.font.label.large
                        }
                    }

                    MouseArea {
                        id: removeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.removeRequested(root.targetIndex);
                            root.expanded = false;
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                // Cancel Button
                StyledRect {
                    implicitWidth: 70
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: "transparent"

                    StateLayer {
                        color: Colours.palette.m3onSurface
                        onClicked: root.expanded = false
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Cancel")
                        color: Colours.palette.m3primary
                        font: Tokens.font.label.large
                    }
                }

                // Save Button
                StyledRect {
                    implicitWidth: 80
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3primary

                    StateLayer {
                        color: Colours.palette.m3onPrimary
                        onClicked: root.save()
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Save")
                        color: Colours.palette.m3onPrimary
                        font: Tokens.font.label.large
                    }
                }
            }
        }
    }

    function save() {
        let n = nameInput.text.trim();
        if (n.length === 0) n = placeName;
        root.accepted(targetIndex, n, selectedIcon);
        root.expanded = false;
    }
}
