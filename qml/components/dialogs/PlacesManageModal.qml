import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../containers"
import prism

MouseArea {
    id: root

    property bool expanded: false

    signal editPlaceRequested(int index, string name, string path, string iconName, bool isCustom)

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
        implicitWidth: 500
        implicitHeight: 560

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
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "bookmarks"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    text: qsTr("Manage Places & Devices")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.builders.large.weight(Font.Bold).build()
                    Layout.fillWidth: true
                }

                StyledRect {
                    implicitWidth: 32
                    implicitHeight: 32
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

            // Places List
            StyledText {
                text: qsTr("Places & Bookmarks")
                color: Colours.palette.m3primary
                font: Tokens.font.label.large
            }

            VerticalFadeListView {
                id: placesList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                model: PlacesModel

                ScrollBar.vertical: StyledScrollBar {
                    flickable: placesList
                }

                delegate: StyledRect {
                    id: placeRowCard
                    required property int index
                    required property string name
                    required property string path
                    required property string iconName
                    required property bool isCustom

                    width: placesList.width
                    implicitHeight: 44
                    radius: Tokens.rounding.medium
                    color: rowHoverArea.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.medium
                        anchors.rightMargin: Tokens.padding.small
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            text: placeRowCard.iconName
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            StyledText {
                                text: placeRowCard.name
                                color: Colours.palette.m3onSurface
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: placeRowCard.path
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }
                        }

                        // Reorder Up
                        StyledRect {
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: Tokens.rounding.full
                            color: upHover.containsMouse ? Colours.palette.m3surfaceContainerHigh : "transparent"
                            enabled: placeRowCard.index > 0
                            opacity: enabled ? 1.0 : 0.3

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "keyboard_arrow_up"
                                color: Colours.palette.m3onSurface
                                fontStyle: Tokens.font.icon.small
                            }

                            MouseArea {
                                id: upHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: placeRowCard.index > 0 ? Qt.PointingHandCursor : undefined
                                onClicked: PlacesModel.movePlace(placeRowCard.index, placeRowCard.index - 1)
                            }
                        }

                        // Reorder Down
                        StyledRect {
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: Tokens.rounding.full
                            color: downHover.containsMouse ? Colours.palette.m3surfaceContainerHigh : "transparent"
                            enabled: placeRowCard.index < PlacesModel.count - 1
                            opacity: enabled ? 1.0 : 0.3

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "keyboard_arrow_down"
                                color: Colours.palette.m3onSurface
                                fontStyle: Tokens.font.icon.small
                            }

                            MouseArea {
                                id: downHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: placeRowCard.index < PlacesModel.count - 1 ? Qt.PointingHandCursor : undefined
                                onClicked: PlacesModel.movePlace(placeRowCard.index, placeRowCard.index + 1)
                            }
                        }

                        // Edit Button
                        StyledRect {
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: Tokens.rounding.full
                            color: editHover.containsMouse ? Colours.palette.m3surfaceContainerHigh : "transparent"

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "edit"
                                color: Colours.palette.m3onSurface
                                fontStyle: Tokens.font.icon.small
                            }

                            MouseArea {
                                id: editHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.expanded = false;
                                    root.editPlaceRequested(placeRowCard.index, placeRowCard.name, placeRowCard.path, placeRowCard.iconName, placeRowCard.isCustom);
                                }
                            }
                        }

                        // Delete / Unpin Button (for custom places)
                        StyledRect {
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: Tokens.rounding.full
                            color: delHover.containsMouse ? Colours.palette.m3errorContainer : "transparent"
                            visible: placeRowCard.isCustom

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "delete"
                                color: delHover.containsMouse ? Colours.palette.m3onErrorContainer : Colours.palette.m3error
                                fontStyle: Tokens.font.icon.small
                            }

                            MouseArea {
                                id: delHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: PlacesModel.removeBookmark(placeRowCard.index)
                            }
                        }
                    }

                    MouseArea {
                        id: rowHoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }

            // Bottom Done Button
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight

                Item { Layout.fillWidth: true }

                StyledRect {
                    implicitWidth: 100
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: doneHover.containsMouse ? Colours.palette.m3primaryContainer : Colours.palette.m3primary

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Done")
                        color: doneHover.containsMouse ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onPrimary
                        font: Tokens.font.label.large
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
