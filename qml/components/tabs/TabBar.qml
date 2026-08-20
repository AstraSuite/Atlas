import QtQuick
import QtQuick.Layouts
import "../"

StyledRect {
    id: root

    implicitHeight: 40
    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: tabRow

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.small
        anchors.rightMargin: Tokens.padding.small
        spacing: Tokens.spacing.extraSmall

        ListView {
            id: tabList

            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: ListView.Horizontal
            spacing: Tokens.spacing.extraSmall
            clip: true

            model: TabManager

            delegate: StyledRect {
                id: tabItem

                required property int index
                required property string title
                required property string path
                readonly property bool selected: TabManager.currentIndex === index

                implicitWidth: Math.min(200, Math.max(100, tabContent.implicitWidth + Tokens.padding.medium * 2))
                implicitHeight: 32
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined

                radius: Tokens.rounding.medium
                color: selected ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

                RowLayout {
                    id: tabContent

                    anchors.fill: parent
                    anchors.leftMargin: Tokens.padding.medium
                    anchors.rightMargin: Tokens.padding.small
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "folder"
                        color: tabItem.selected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: tabItem.title
                        color: tabItem.selected ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    Item {
                        implicitWidth: 20
                        implicitHeight: 20
                        visible: TabManager.count > 1
                        z: 2

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "close"
                            fontStyle: Tokens.font.icon.small
                            color: closeHover.containsMouse ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                        }

                        MouseArea {
                            id: closeHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: mouse => {
                                mouse.accepted = true;
                                TabManager.closeTab(tabItem.index);
                            }
                        }
                    }
                }

                StateLayer {
                    anchors.fill: parent
                    z: 1
                    color: tabItem.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    onClicked: TabManager.currentIndex = tabItem.index
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.MiddleButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) {
                            TabManager.closeTab(tabItem.index);
                        }
                    }
                }
            }
        }

        // New Tab (+) Button
        Item {
            implicitWidth: 28
            implicitHeight: 28

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainerHigh

                StateLayer {
                    onClicked: TabManager.newTab()
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "add"
                    color: Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }
            }
        }

        // Split View (F3) Button
        Item {
            implicitWidth: 28
            implicitHeight: 28

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.medium
                color: (TabManager.currentTab && TabManager.currentTab.isSplit) ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainerHigh

                StateLayer {
                    onClicked: TabManager.toggleSplitView()
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "vertical_split"
                    color: (TabManager.currentTab && TabManager.currentTab.isSplit) ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }
            }
        }
    }
}
