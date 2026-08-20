import QtQuick
import QtQuick.Controls
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
    property string iconSearchQuery: ""
    property var displayedIcons: []

    signal accepted(int index, string name, string iconName)
    signal removeRequested(int index)

    onExpandedChanged: {
        if (expanded) {
            iconSearchQuery = "";
            iconSearchInput.text = "";
            updateIcons();
        }
    }

    function updateIcons() {
        displayedIcons = IconCatalog.search(iconSearchQuery, 0);
    }

    anchors.fill: parent
    visible: opacity > 0.001
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    z: 100

    opacity: expanded ? 1.0 : 0.0
    Behavior on opacity { Anim { type: Anim.FastEffects } }

    onClicked: root.expanded = false
    Keys.onEscapePressed: root.expanded = false

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.45)
    }

    StyledRect {
        id: modalCard

        anchors.centerIn: parent
        implicitWidth: 480
        implicitHeight: 560

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerHigh

        scale: root.expanded ? 1.0 : 0.94
        Behavior on scale { Anim { type: Anim.FastEffects; easing: Tokens.anim.standard } }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: modalCol
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            // Header with current selected icon preview
            RowLayout {
                spacing: Tokens.spacing.small

                StyledRect {
                    implicitWidth: 40
                    implicitHeight: 40
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3primaryContainer

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: root.selectedIcon
                        color: Colours.palette.m3onPrimaryContainer
                        fontStyle: Tokens.font.icon.medium
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: qsTr("Edit Place")
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.title.medium
                    }

                    StyledText {
                        text: root.placePath
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.small
                        elide: Text.ElideMiddle
                    }
                }
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
                    implicitHeight: 40
                    radius: Tokens.rounding.small
                    color: Colours.palette.m3surfaceContainerHighest

                    TextInput {
                        id: nameInput
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        anchors.leftMargin: 12
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

            // Icon Search & Picker
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Choose Icon (%1 of %2 available)").arg(root.displayedIcons.length).arg(IconCatalog.totalIcons)
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.medium
                    }
                }

                // Icon Search Field
                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3surfaceContainerHighest

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        MaterialIcon {
                            text: "search"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        TextInput {
                            id: iconSearchInput
                            Layout.fillWidth: true
                            color: Colours.palette.m3onSurface
                            font: Tokens.font.body.medium
                            clip: true
                            selectByMouse: true
                            onTextChanged: {
                                root.iconSearchQuery = text;
                                root.updateIcons();
                            }

                            Text {
                                anchors.fill: parent
                                text: qsTr("Search 3,700+ Material Symbols...")
                                color: Colours.palette.m3outline
                                font: parent.font
                                visible: !iconSearchInput.text && !iconSearchInput.activeFocus
                            }
                        }

                        MaterialIcon {
                            visible: iconSearchInput.text.length > 0
                            text: "close"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3onSurfaceVariant
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    iconSearchInput.text = "";
                                    root.iconSearchQuery = "";
                                    root.updateIcons();
                                }
                            }
                        }
                    }
                }

                // Scrollable Icons Grid
                StyledRect {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Tokens.rounding.medium
                    color: Colours.palette.m3surfaceContainerLowest
                    clip: true

                    GridView {
                        id: iconGrid
                        anchors.fill: parent
                        anchors.margins: 6
                        cellWidth: 42
                        cellHeight: 42
                        clip: true
                        model: root.displayedIcons

                        ScrollBar.vertical: StyledScrollBar {
                            flickable: iconGrid
                        }

                        delegate: StyledRect {
                            id: iconTile
                            required property string modelData

                            width: 38
                            height: 38
                            radius: Tokens.rounding.small
                            color: root.selectedIcon === modelData
                                ? Colours.palette.m3primaryContainer
                                : (tileHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent")

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
                opacity: 0.5
            }

            // Action Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                // Remove Button
                StyledRect {
                    visible: root.isCustom
                    implicitWidth: removeRow.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: removeHover.containsMouse ? Qt.alpha(Colours.palette.m3error, 0.15) : "transparent"

                    RowLayout {
                        id: removeRow
                        anchors.centerIn: parent
                        spacing: 6

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

                Item { Layout.fillWidth: true }

                // Cancel Button
                StyledRect {
                    implicitWidth: cancelText.implicitWidth + Tokens.padding.large * 2
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: cancelHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent"

                    StyledText {
                        id: cancelText
                        anchors.centerIn: parent
                        text: qsTr("Cancel")
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.label.large
                    }

                    MouseArea {
                        id: cancelHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.expanded = false
                    }
                }

                // Save Button
                StyledRect {
                    implicitWidth: saveText.implicitWidth + Tokens.padding.large * 2
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: saveHover.containsMouse ? Qt.lighter(Colours.palette.m3primary, 1.1) : Colours.palette.m3primary

                    StyledText {
                        id: saveText
                        anchors.centerIn: parent
                        text: qsTr("Save")
                        color: Colours.palette.m3onPrimary
                        font: Tokens.font.label.large
                    }

                    MouseArea {
                        id: saveHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.save()
                    }
                }
            }
        }
    }

    function save() {
        let name = nameInput.text.trim();
        if (name.length === 0) name = root.placeName;
        root.accepted(root.targetIndex, name, root.selectedIcon);
        root.expanded = false;
    }
}
