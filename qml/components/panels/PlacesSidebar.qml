import QtQuick
import QtQuick.Layouts
import "../"

StyledRect {
    id: root

    required property var activeTab
    property int sidebarWidth: 230

    implicitWidth: sidebarWidth
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.extraSmall

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.padding.extraSmall / 2
            Layout.bottomMargin: Tokens.spacing.medium
            text: qsTr("Places")
            color: Colours.palette.m3onSurface
            font: Tokens.font.body.builders.large.weight(Font.Bold).build()
        }

        ListView {
            id: placesList

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Tokens.spacing.extraSmall
            clip: true

            model: PlacesModel

            delegate: StyledRect {
                id: placeItem

                required property int index
                required property string name
                required property string path
                required property string iconName
                required property bool isDevice
                required property bool isTrash
                required property bool isCustom
                required property string freeSpaceFormatted

                readonly property bool selected: root.activeTab && root.activeTab.currentPath === path

                Layout.fillWidth: true
                width: placesList.width
                implicitHeight: placeRow.implicitHeight + Tokens.padding.medium * 2

                radius: Tokens.rounding.full
                color: selected ? Colours.palette.m3secondaryContainer : "transparent"

                RowLayout {
                    id: placeRow

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.large
                    anchors.rightMargin: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: placeItem.iconName
                        color: placeItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.medium
                        fill: placeItem.selected ? 1 : 0
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: placeItem.name
                            color: placeItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: placeItem.freeSpaceFormatted.length > 0
                            text: placeItem.freeSpaceFormatted
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    // Remove custom bookmark button
                    Item {
                        implicitWidth: 20
                        implicitHeight: 20
                        visible: placeItem.isCustom && itemCloseMouse.containsMouse
                        z: 2

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "close"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3error
                        }

                        MouseArea {
                            id: itemCloseMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: mouse => {
                                mouse.accepted = true;
                                PlacesModel.removeBookmark(placeItem.index);
                            }
                        }
                    }
                }

                StateLayer {
                    anchors.fill: parent
                    z: 1
                    color: placeItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    onClicked: {
                        if (root.activeTab) {
                            root.activeTab.currentPath = placeItem.path;
                        }
                    }
                }
            }
        }
    }
}
