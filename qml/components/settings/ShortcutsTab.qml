import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../controls"
import atlas

// Shortcuts management page for the Preferences modal.
Item {
    id: root

    property string query: ""
    property var groups: []
    property bool hasModified: false
    property bool confirmReset: false

    function rebuild() {
        const all = ShortcutManager.shortcuts;
        const q = root.query.trim().toLowerCase();
        const result = [];
        let modified = false;
        let groupIndex = -1;

        for (const s of all) {
            if (q.length > 0) {
                const hay = (s.label + " " + s.description + " "
                             + s.category + " " + s.sequences.join(" ")).toLowerCase();
                if (hay.indexOf(q) === -1)
                    continue;
            }
            if (s.modified)
                modified = true;
            if (groupIndex === -1 || result[groupIndex].name !== s.category) {
                result.push({ name: s.category, items: [] });
                groupIndex = result.length - 1;
            }
            result[groupIndex].items.push(s);
        }

        root.groups = result;
        root.hasModified = modified;
    }

    // Close the recorder when the user leaves this page or closes the modal.
    function abortRecorder() {
        recorder.expanded = false;
    }

    Timer {
        id: resetTimer
        interval: 3000
        onTriggered: root.confirmReset = false
    }

    Component.onCompleted: root.rebuild()

    Connections {
        target: ShortcutManager
        function onShortcutsChanged() { root.rebuild(); }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Tokens.spacing.medium

        // Toolbar: search + reset all
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainerHighest

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.medium
                    anchors.rightMargin: Tokens.padding.small
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "search"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        text: root.query
                        color: Colours.palette.m3onSurface
                        selectionColor: Colours.palette.m3primaryContainer
                        selectedTextColor: Colours.palette.m3onPrimaryContainer
                        font: Tokens.font.body.small
                        selectByMouse: true
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        onTextChanged: root.query = text

                        Keys.onEscapePressed: searchInput.text = ""
                    }

                    IconButton {
                        type: ButtonBase.Text
                        icon: "close"
                        visible: root.query.length > 0
                        onClicked: searchInput.text = ""
                    }
                }
            }

            IconTextButton {
                type: ButtonBase.Tonal
                icon: "restart_alt"
                text: root.confirmReset ? qsTr("Confirm reset") : qsTr("Reset All")
                disabled: !root.hasModified && !root.confirmReset
                Layout.alignment: Qt.AlignVCenter
                onClicked: {
                    if (!root.confirmReset) {
                        root.confirmReset = true;
                        resetTimer.restart();
                        return;
                    }
                    resetTimer.stop();
                    root.confirmReset = false;
                    ShortcutManager.resetAll();
                }
            }
        }

        // Scrollable grouped list
        VerticalFadeFlickable {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: bodyCol.implicitHeight + Tokens.padding.medium
            clip: true
            fadeAmount: 0.08
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: StyledScrollBar {
                flickable: scroll
            }

            ColumnLayout {
                id: bodyCol
                width: scroll.width
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Rebind the global application shortcuts. Keys handled inside the file views (arrow keys, type-ahead) and inside other dialogs are not listed here.")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                    wrapMode: Text.WordWrap
                }

                Repeater {
                    model: root.groups

                    ColumnLayout {
                        required property var modelData

                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            Layout.topMargin: Tokens.spacing.small
                            text: modelData.name
                            color: Colours.palette.m3primary
                            font: Tokens.font.label.large
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Repeater {
                                id: itemsRepeater
                                model: modelData.items

                                ShortcutRow {
                                    required property var modelData
                                    required property int index

                                    Layout.fillWidth: true
                                    first: index === 0
                                    last: index === itemsRepeater.count - 1
                                    actionId: modelData.id
                                    icon: modelData.icon
                                    text: modelData.label
                                    subtext: modelData.description
                                    sequences: modelData.sequences
                                    modified: modelData.modified

                                    onEditRequested: recorder.open(modelData.id, modelData.label, true, modelData.sequences.length > 0)
                                    onAddRequested: recorder.open(modelData.id, modelData.label, false, true)
                                    onRemoveRequested: seq => ShortcutManager.removeSequence(modelData.id, seq)
                                    onResetRequested: ShortcutManager.resetAction(modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    KeyRecorderDialog {
        id: recorder
    }
}