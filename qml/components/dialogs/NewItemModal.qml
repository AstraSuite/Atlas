import QtQuick
import QtQuick.Layouts
import "../"
import prism

MouseArea {
    id: root

    property bool expanded: false
    property string title: qsTr("New Item")
    property string icon: "note_add"
    property string initialText: ""

    signal accepted(string text)

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

    onExpandedChanged: {
        if (expanded) {
            input.text = initialText;
            input.forceActiveFocus();
            input.selectAll();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.4)
    }

    StyledRect {
        id: modalCard

        anchors.centerIn: parent
        implicitWidth: 380
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

            // Header (no close button)
            RowLayout {
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: root.icon
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.title
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.medium
                }
            }

            // Input Field
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 42
                radius: Tokens.rounding.small
                color: Colours.palette.m3surfaceContainerHighest

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    text: root.initialText
                    color: Colours.palette.m3onSurface
                    selectionColor: Colours.palette.m3primaryContainer
                    selectedTextColor: Colours.palette.m3onPrimaryContainer
                    font: Tokens.font.body.medium
                    selectByMouse: true
                    cursorVisible: focus

                    onAccepted: {
                        if (text.trim().length > 0) {
                            root.accepted(text.trim());
                            root.expanded = false;
                        }
                    }
                }
            }

            // Action Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

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

                // OK / Create Button
                StyledRect {
                    implicitWidth: 80
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3primary

                    StateLayer {
                        color: Colours.palette.m3onPrimary
                        onClicked: {
                            if (input.text.trim().length > 0) {
                                root.accepted(input.text.trim());
                                root.expanded = false;
                            }
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("OK")
                        color: Colours.palette.m3onPrimary
                        font: Tokens.font.label.large
                    }
                }
            }
        }
    }
}
