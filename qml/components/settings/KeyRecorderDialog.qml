import QtQuick
import QtQuick.Layouts
import "../"
import "../controls"
import atlas

// Modal key-recorder used by the Shortcuts settings tab. While open it sets
// ShortcutManager.recording so every AppShortcut is disabled and cannot steal
// the keystroke being captured.
MouseArea {
    id: root

    property bool expanded: false
    property string actionId: ""
    property string actionLabel: ""
    property bool replaceMode: true     // true = replace all bindings, false = append one
    property bool hasBindings: false    // the action currently has bindings

    // "listening" | "confirm" | "conflict"
    property string state: "listening"
    property string capturedSequence: ""
    property var pendingConflicts: []   // [{id,label,sequences}]
    property bool captureIsBare: false

    anchors.fill: parent
    visible: opacity > 0.001
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    z: 120

    opacity: expanded ? 1.0 : 0.0
    Behavior on opacity {
        Anim {
            type: Anim.FastEffects
        }
    }

    onClicked: root.cancel()
    onWheel: wheel => wheel.accepted = true

    function open(id, label, replace, has) {
        root.actionId = id;
        root.actionLabel = label;
        root.replaceMode = replace;
        root.hasBindings = has;
        root.expanded = true;
    }

    // Esc: a captured conflict/bare-key state goes back to listening, otherwise close.
    function cancel() {
        if (root.state !== "listening") {
            root.resetCapture();
        } else {
            root.expanded = false;
        }
    }

    function resetCapture() {
        root.capturedSequence = "";
        root.pendingConflicts = [];
        root.captureIsBare = false;
        root.state = "listening";
        root.forceActiveFocus();
    }

    function applyCaptured() {
        if (root.capturedSequence.length === 0)
            return;
        if (root.replaceMode) {
            ShortcutManager.setSequences(root.actionId, [root.capturedSequence]);
        } else {
            ShortcutManager.addSequence(root.actionId, root.capturedSequence);
        }
        root.expanded = false;
    }

    function handleKey(key, modifiers) {
        const s = ShortcutManager.sequenceFromKey(key, modifiers);
        if (s.length === 0)
            return; // modifier-only or unknown press; keep listening

        root.capturedSequence = s;
        root.captureIsBare = ShortcutManager.isBareKey(s);

        const conflicts = ShortcutManager.conflicts(root.actionId, [s]);
        if (conflicts.length > 0) {
            root.pendingConflicts = conflicts;
            root.state = "conflict";
        } else if (root.captureIsBare) {
            // Bare printable keys would steal typing; require an explicit confirm.
            root.state = "confirm";
        } else {
            root.state = "listening";
            root.applyCaptured();
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.cancel();
            event.accepted = true;
            return;
        }
        root.handleKey(event.key, event.modifiers);
        event.accepted = true;
    }

    Keys.onReleased: event => event.accepted = true

    onExpandedChanged: {
        ShortcutManager.recording = expanded;
        if (expanded) {
            root.resetCapture();
        } else {
            root.capturedSequence = "";
            root.pendingConflicts = [];
            root.state = "listening";
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.45)
    }

    StyledRect {
        id: modalCard

        anchors.centerIn: parent
        width: Math.min(parent.width - 64, 480)
        height: Math.min(parent.height - 64, cardCol.implicitHeight + Tokens.padding.large * 2)
        implicitWidth: Math.min(parent.width - 64, 480)
        implicitHeight: cardCol.implicitHeight + Tokens.padding.large * 2

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
            id: cardCol

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "keyboard"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Assign Shortcut")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.medium
                }

                IconButton {
                    type: ButtonBase.Text
                    icon: "close"
                    onClicked: root.cancel()
                }
            }

            // Which action is being edited
            RowButton {
                Layout.fillWidth: true
                icon: "keyboard"
                text: root.actionLabel
                subtext: root.replaceMode
                    ? qsTr("Replace the shortcuts for this action")
                    : qsTr("Add another shortcut for this action")
            }

            // Capture box
            StyledRect {
                id: captureBox

                Layout.fillWidth: true
                implicitHeight: 72
                radius: Tokens.rounding.large
                color: root.state === "listening"
                    ? Colours.tPalette.m3surfaceContainerHighest
                    : Colours.palette.m3secondaryContainer

                property color captureColour: root.state === "listening"
                    ? Colours.palette.m3onSurfaceVariant
                    : Colours.palette.m3onSecondaryContainer

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: root.state === "listening" ? "play_arrow" : "check_circle"
                        color: captureBox.captureColour
                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        text: {
                            if (root.state === "listening")
                                return qsTr("Press the key combination…");
                            if (root.state === "conflict")
                                return root.capturedSequence;
                            return root.capturedSequence;
                        }
                        color: captureBox.captureColour
                        font: Tokens.font.body.builders.large.weight(Font.DemiBold).build()
                    }
                }
            }

            // Bare-key hint
            StyledText {
                Layout.fillWidth: true
                visible: root.state === "confirm"
                text: qsTr("This combination has no modifier. It will only trigger when no text field is focused.")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }

            // Listening hint
            StyledText {
                Layout.fillWidth: true
                visible: root.state === "listening"
                text: qsTr("Press Esc to cancel.")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }

            // Conflict list
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.state === "conflict"
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    text: qsTr("Already assigned to:")
                    color: Colours.palette.m3error
                    font: Tokens.font.label.large
                }

                Repeater {
                    model: root.pendingConflicts

                    RowLayout {
                        required property var modelData

                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "warning"
                            color: Colours.palette.m3error
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.label
                            color: Colours.palette.m3onSurface
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: modelData.sequences.join("  ")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                        }
                    }
                }

                StyledText {
                    text: qsTr("Replacing will move this combination to the action being configured.")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                    wrapMode: Text.WordWrap
                }
            }

            // Footer buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Item { Layout.fillWidth: true }

                TextButton {
                    type: ButtonBase.Text
                    text: qsTr("Clear")
                    visible: root.state === "listening" && root.replaceMode && root.hasBindings
                    onClicked: {
                        ShortcutManager.setSequences(root.actionId, []);
                        root.expanded = false;
                    }
                }

                TextButton {
                    type: ButtonBase.Text
                    text: qsTr("Cancel")
                    onClicked: root.cancel()
                }

                TextButton {
                    type: ButtonBase.Filled
                    text: qsTr("Assign")
                    visible: root.state === "confirm"
                    onClicked: root.applyCaptured()
                }

                TextButton {
                    type: ButtonBase.Filled
                    text: qsTr("Replace")
                    visible: root.state === "conflict"
                    onClicked: {
                        ShortcutManager.reassign(root.actionId, root.capturedSequence);
                        root.expanded = false;
                    }
                }
            }
        }
    }
}