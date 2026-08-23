import QtQuick
import QtQuick.Layouts
import "../"
import "../controls"
import prism

MouseArea {
    id: root

    property bool expanded: false
    property string title: qsTr("New Item")
    property string icon: "note_add"
    property string initialText: ""
    property string targetRenamePath: ""
    property string templateSource: ""

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
    onWheel: wheel => wheel.accepted = true

    Keys.onEscapePressed: root.expanded = false

    onExpandedChanged: {
        if (expanded) {
            input.text = initialText;
            input.forceActiveFocus();
            let lastDot = initialText.lastIndexOf('.');
            if (lastDot > 0 && (root.title === qsTr("Rename") || root.title === "Rename" || initialText.indexOf("untitled") !== -1)) {
                input.select(0, lastDot);
            } else {
                input.selectAll();
            }
        } else {
            input.focus = false;
            targetRenamePath = "";
            templateSource = "";
            if (typeof splitContainer !== "undefined" && splitContainer) {
                splitContainer.focusActiveView();
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.4)
    }

    StyledRect {
        id: modalCard

        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 440)
        height: Math.min(parent.height - 32, modalCol.implicitHeight + Tokens.padding.large * 2)
        implicitWidth: Math.min(parent.width - 48, 440)
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
            onWheel: wheel => wheel.accepted = true
        }

        ColumnLayout {
            id: modalCol

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            // Header
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
                border.color: input.activeFocus ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outlineVariant, 0.5)
                border.width: input.activeFocus ? 2 : 1
                clip: true

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    acceptedButtons: Qt.NoButton
                }

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
                    clip: true
                    verticalAlignment: TextInput.AlignVCenter

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

                TextButton {
                    type: ButtonBase.Text
                    text: qsTr("Cancel")
                    onClicked: root.expanded = false
                }

                TextButton {
                    type: ButtonBase.Filled
                    text: qsTr("OK")
                    disabled: input.text.trim().length === 0
                    onClicked: {
                        if (input.text.trim().length > 0) {
                            root.accepted(input.text.trim());
                            root.expanded = false;
                        }
                    }
                }
            }
        }
    }
}
