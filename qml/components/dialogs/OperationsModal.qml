import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../containers"
import prism

MouseArea {
    id: root

    property bool expanded: false

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

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.large
        implicitWidth: 440
        implicitHeight: 400

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
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "pending_actions"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    text: qsTr("Operations & Background Tasks")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.builders.large.weight(Font.Bold).build()
                    Layout.fillWidth: true
                }

                StyledRect {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: Tokens.rounding.full
                    color: closeHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent"

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "close"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.expanded = false
                    }
                }
            }

            // Operations List / Status Area
            VerticalFadeFlickable {
                id: flickable
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: tasksCol.implicitHeight
                clip: true

                ScrollBar.vertical: StyledScrollBar {
                    flickable: flickable
                }

                ColumnLayout {
                    id: tasksCol
                    width: flickable.width
                    spacing: Tokens.spacing.small

                    // Active Operation Card
                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: activeCol.implicitHeight + Tokens.padding.medium * 2
                        radius: Tokens.rounding.medium
                        color: Colours.tPalette.m3surfaceContainer
                        visible: FileOperations.progress.running

                        ColumnLayout {
                            id: activeCol
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                MaterialIcon {
                                    text: "sync"
                                    color: Colours.palette.m3primary
                                    fontStyle: Tokens.font.icon.small

                                    RotationAnimation on rotation {
                                        loops: Animation.Infinite
                                        from: 0
                                        to: 360
                                        duration: 1200
                                        running: FileOperations.progress.running
                                    }
                                }

                                StyledText {
                                    text: FileOperations.progress.statusText || qsTr("In progress...")
                                    color: Colours.palette.m3onSurface
                                    font: Tokens.font.body.small
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                StyledRect {
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    radius: Tokens.rounding.full
                                    color: cancelHover.containsMouse ? Colours.palette.m3errorContainer : "transparent"

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "cancel"
                                        color: cancelHover.containsMouse ? Colours.palette.m3onErrorContainer : Colours.palette.m3error
                                        fontStyle: Tokens.font.icon.small
                                    }

                                    MouseArea {
                                        id: cancelHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: FileOperations.cancelOperation()
                                    }
                                }
                            }

                            // Progress Bar
                            StyledRect {
                                Layout.fillWidth: true
                                implicitHeight: 6
                                radius: Tokens.rounding.full
                                color: Qt.alpha(Colours.palette.m3outline, 0.25)
                                clip: true

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: Math.max(6, parent.width * Math.min(1.0, Math.max(0.0, FileOperations.progress.progress)))
                                    radius: Tokens.rounding.full
                                    color: Colours.palette.m3primary

                                    Behavior on width {
                                        Anim { type: Anim.FastEffects }
                                    }
                                }
                            }

                            StyledText {
                                text: FileOperations.progress.currentItem || ""
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                                elide: Text.ElideMiddle
                                visible: text.length > 0
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Empty / Idle State
                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 120
                        radius: Tokens.rounding.medium
                        color: Colours.tPalette.m3surfaceContainer
                        visible: !FileOperations.progress.running

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Tokens.spacing.extraSmall

                            MaterialIcon {
                                Layout.alignment: Qt.AlignHCenter
                                text: "check_circle"
                                color: Colours.palette.m3primary
                                fontStyle: Tokens.font.icon.large
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: qsTr("No background operations active")
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.small
                            }
                        }
                    }
                }
            }

            // Bottom Actions
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Item { Layout.fillWidth: true }

                StyledRect {
                    implicitWidth: 80
                    implicitHeight: 34
                    radius: Tokens.rounding.full
                    color: doneHover.containsMouse ? Colours.palette.m3primaryContainer : Colours.palette.m3primary

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Close")
                        color: doneHover.containsMouse ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onPrimary
                        font: Tokens.font.label.medium
                    }

                    MouseArea {
                        id: doneHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.expanded = false
                    }
                }
            }
        }
    }
}
