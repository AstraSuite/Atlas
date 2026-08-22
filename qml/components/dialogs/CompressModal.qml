import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import prism

MouseArea {
    id: root

    property bool expanded: false
    property var sourcePaths: []
    property string defaultName: "archive"
    property string selectedFormat: "zip"

    signal accepted(var sources, string destPath, string format)

    anchors.fill: parent
    visible: opacity > 0.001
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    z: 100

    opacity: expanded ? 1.0 : 0.0
    Behavior on opacity { Anim { type: Anim.FastEffects } }

    onClicked: root.expanded = false
    onWheel: wheel => wheel.accepted = true
    Keys.onEscapePressed: root.expanded = false

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.45)
    }

    StyledRect {
        id: modalCard

        anchors.centerIn: parent
        width: Math.min(parent.width - 32, 420)
        height: Math.min(parent.height - 32, modalCol.implicitHeight + Tokens.padding.large * 2)
        implicitWidth: 420
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

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "archive"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    text: qsTr("Compress Files")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.builders.large.weight(Font.Bold).build()
                    Layout.fillWidth: true
                }
            }

            // Name Input
            StyledText {
                text: qsTr("Archive Name")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Tokens.rounding.small
                color: Colours.tPalette.m3surfaceContainer
                clip: true

                TextInput {
                    id: nameInput
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small
                    anchors.leftMargin: 12
                    text: root.defaultName
                    color: Colours.palette.m3onSurface
                    selectionColor: Colours.palette.m3primaryContainer
                    selectedTextColor: Colours.palette.m3onPrimaryContainer
                    font: Tokens.font.body.medium
                    selectByMouse: true
                    cursorVisible: activeFocus
                    clip: true
                    verticalAlignment: TextInput.AlignVCenter
                }
            }

            // Format Selection
            StyledText {
                text: qsTr("Archive Format")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Repeater {
                    model: [
                        { label: ".zip", format: "zip" },
                        { label: ".tar.gz", format: "tar.gz" },
                        { label: ".tar.xz", format: "tar.xz" },
                        { label: ".tar.zst", format: "tar.zst" },
                        { label: ".7z", format: "7z" }
                    ]

                    delegate: StyledRect {
                        id: fmtChip
                        required property int index
                        required property var modelData

                        implicitWidth: fmtRow.implicitWidth + 24
                        implicitHeight: 34
                        radius: Tokens.rounding.full
                        color: root.selectedFormat === modelData.format
                            ? Colours.palette.m3primaryContainer
                            : (chipHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer)

                        RowLayout {
                            id: fmtRow
                            anchors.centerIn: parent
                            spacing: 4

                            StyledText {
                                text: fmtChip.modelData.label
                                font: Tokens.font.label.large
                                color: root.selectedFormat === fmtChip.modelData.format ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                            }
                        }

                        MouseArea {
                            id: chipHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedFormat = fmtChip.modelData.format
                        }
                    }
                }
            }

            // Buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                spacing: Tokens.spacing.small

                Item { Layout.fillWidth: true }

                StyledRect {
                    implicitWidth: 90
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: cancelHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Cancel")
                        color: Colours.palette.m3primary
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

                StyledRect {
                    implicitWidth: 110
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: compressBtnHover.containsMouse ? Colours.palette.m3primaryContainer : Colours.palette.m3primary

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Compress")
                        color: compressBtnHover.containsMouse ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onPrimary
                        font: Tokens.font.label.large
                    }

                    MouseArea {
                        id: compressBtnHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.expanded = false;
                            let parentDir = "";
                            if (root.sourcePaths.length > 0) {
                                parentDir = FileUtils.shortenHome(root.sourcePaths[0]).replace(/\/[^\/]+$/, "");
                            }
                            let dest = nameInput.text.trim();
                            if (!dest.endsWith("." + root.selectedFormat)) {
                                dest += "." + root.selectedFormat;
                            }
                            root.accepted(root.sourcePaths, dest, root.selectedFormat);
                        }
                    }
                }
            }
        }
    }
}
