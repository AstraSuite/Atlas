import QtQuick
import QtQuick.Layouts
import "../"
import "../controls"
import atlas

ConnectedRect {
    id: root

    property string actionId: ""
    property string icon: ""
    property alias text: label.text
    property alias subtext: subLabel.text
    // Current effective bindings for this action (portable QKeySequence strings).
    property var sequences: []
    property bool modified: false

    signal editRequested()
    signal addRequested()
    signal resetRequested()
    signal removeRequested(string sequence)

    Layout.fillWidth: true
    implicitHeight: Math.max(56, row.implicitHeight + Tokens.padding.small * 2)

    StateLayer {
        anchors.fill: parent
        radius: parent.radius
        onClicked: root.editRequested()
    }

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.small

        spacing: Tokens.spacing.medium

        MaterialIcon {
            id: iconLabel
            visible: root.icon.length > 0
            text: root.icon
            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.medium
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                id: label
                Layout.fillWidth: true
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurface
                elide: Text.ElideRight
            }

            StyledText {
                id: subLabel
                Layout.fillWidth: true
                visible: text.length > 0
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        // Key chips (click a chip to remove that binding)
        Flow {
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: Math.max(120, root.width * 0.3)
            spacing: 4
            visible: root.sequences.length > 0

            Repeater {
                model: root.sequences

                StyledRect {
                    required property string modelData

                    implicitHeight: 22
                    implicitWidth: chipLabel.implicitWidth + Tokens.padding.small * 2
                    radius: Tokens.rounding.full
                    color: Colours.tPalette.m3surfaceContainerHighest

                    StyledText {
                        id: chipLabel
                        anchors.centerIn: parent
                        text: modelData
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }

                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.removeRequested(modelData)
                    }

                    StyledToolTip {
                        text: qsTr("Remove %1").arg(modelData)
                        visible: chipMouse.containsMouse
                    }
                }
            }
        }

        IconButton {
            type: ButtonBase.Text
            icon: "edit"
            Layout.alignment: Qt.AlignVCenter
            onClicked: root.editRequested()

            StyledToolTip {
                text: qsTr("Record")
                visible: parent.hovered
            }
        }

        IconButton {
            type: ButtonBase.Text
            icon: "add"
            Layout.alignment: Qt.AlignVCenter
            onClicked: root.addRequested()

            StyledToolTip {
                text: qsTr("Add shortcut")
                visible: parent.hovered
            }
        }

        IconButton {
            type: ButtonBase.Text
            icon: "restart_alt"
            Layout.alignment: Qt.AlignVCenter
            visible: root.modified
            opacity: root.modified ? 1 : 0
            onClicked: root.resetRequested()

            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }

            StyledToolTip {
                text: qsTr("Restore default")
                visible: parent.hovered
            }
        }
    }
}