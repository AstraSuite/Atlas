import QtQuick
import QtQuick.Layouts
import "../"

MouseArea {
    id: root

    property bool expanded: false
    property string title: qsTr("New Item")
    property string icon: "create_new_folder"
    property string initialText: ""
    property string placeholder: qsTr("Enter name...")

    signal accepted(string text)
    signal rejected()

    anchors.fill: parent
    visible: expanded
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    z: 100

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
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.medium
                }

                Item {
                    implicitWidth: 24
                    implicitHeight: 24

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "close"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.rejected();
                            root.expanded = false;
                        }
                    }
                }
            }

            // Input Field
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: Tokens.rounding.small
                color: Colours.palette.m3surfaceContainerHighest

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    text: root.initialText
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.medium
                    selectByMouse: true
                    focus: root.expanded

                    onAccepted: {
                        if (text.trim().length > 0) {
                            root.accepted(text.trim());
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
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Item {
                    Layout.fillWidth: true
                }

                // Cancel Button
                StyledRect {
                    implicitWidth: 80
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: "transparent"

                    StateLayer {
                        color: Colours.palette.m3onSurface
                        onClicked: {
                            root.rejected();
                            root.expanded = false;
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Cancel")
                        color: Colours.palette.m3primary
                        font: Tokens.font.label.large
                    }
                }

                // Confirm Button
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
                        text: qsTr("Create")
                        color: Colours.palette.m3onPrimary
                        font: Tokens.font.label.large
                    }
                }
            }
        }
    }
}
