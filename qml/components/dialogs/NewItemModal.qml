import QtQuick
import QtQuick.Layouts
import "../"

MouseArea {
    id: root

    property bool expanded: false
    property string title: qsTr("Create New Folder")
    property string initialText: ""
    property string icon: "create_new_folder"

    signal accepted(string text)
    signal rejected()

    anchors.fill: parent
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined

    opacity: expanded ? 1 : 0
    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    onClicked: {
        root.rejected();
        root.expanded = false;
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.4)
    }

    StyledRect {
        id: dialogCard

        anchors.centerIn: parent
        implicitWidth: 380
        implicitHeight: cardCol.implicitHeight + Tokens.padding.large * 2

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerHigh

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: cardCol

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
                    font: Tokens.font.title.medium
                    color: Colours.palette.m3onSurface
                }
            }

            // Text Input Box
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Tokens.rounding.medium
                color: Colours.tPalette.m3surfaceContainer

                TextInput {
                    id: inputField

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small
                    anchors.leftMargin: Tokens.padding.medium
                    anchors.rightMargin: Tokens.padding.medium
                    verticalAlignment: TextInput.AlignVCenter

                    text: root.initialText
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.medium
                    selectByMouse: true

                    onAccepted: {
                        if (text.trimmed().length > 0) {
                            root.accepted(text.trimmed());
                            root.expanded = false;
                        }
                    }

                    Keys.onEscapePressed: {
                        root.rejected();
                        root.expanded = false;
                    }
                }
            }

            // Buttons
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: Tokens.spacing.small

                // Cancel Button
                StyledRect {
                    implicitWidth: 90
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: Colours.tPalette.m3surfaceContainer

                    StateLayer {
                        onClicked: {
                            root.rejected();
                            root.expanded = false;
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Cancel")
                        font: Tokens.font.label.large
                        color: Colours.palette.m3onSurface
                    }
                }

                // Confirm / Create Button
                StyledRect {
                    implicitWidth: 90
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3primary

                    StateLayer {
                        onClicked: {
                            if (inputField.text.trimmed().length > 0) {
                                root.accepted(inputField.text.trimmed());
                                root.expanded = false;
                            }
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Confirm")
                        font: Tokens.font.label.large
                        color: Colours.palette.m3onPrimary
                    }
                }
            }
        }
    }

    onExpandedChanged: {
        if (expanded) {
            inputField.text = root.initialText;
            inputField.forceActiveFocus();
            inputField.selectAll();
        }
    }
}
