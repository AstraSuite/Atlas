import QtQuick
import QtQuick.Layouts
import "../"
import prism

StyledRect {
    id: root

    implicitHeight: 38
    color: Colours.tPalette.m3surfaceContainerLowest

    RowLayout {
        id: tabRow

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.small
        anchors.rightMargin: Tokens.padding.small
        anchors.topMargin: 4
        spacing: Tokens.spacing.extraSmall

        ListView {
            id: tabList

            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: ListView.Horizontal
            spacing: 2
            clip: true

            model: TabManager

            delegate: StyledRect {
                id: tabItem

                required property int index
                required property string title
                required property string path
                readonly property bool selected: TabManager.currentIndex === index

                implicitWidth: Math.min(220, Math.max(120, tabContent.implicitWidth + Tokens.padding.medium * 2))
                anchors.bottom: parent ? parent.bottom : undefined
                anchors.top: parent ? parent.top : undefined

                // Chrome-style top corner rounding, connecting to the NavigationBar below
                topLeftRadius: selected ? Tokens.rounding.medium : Tokens.rounding.small
                topRightRadius: selected ? Tokens.rounding.medium : Tokens.rounding.small
                bottomLeftRadius: 0
                bottomRightRadius: 0

                color: selected ? Colours.tPalette.m3surfaceContainer : (tabHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent")

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
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                mouse.accepted = true;
                                TabManager.closeTab(tabItem.index);
                            }
                        }
                    }
                }

                MouseArea {
                    id: tabHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) {
                            TabManager.closeTab(tabItem.index);
                        } else {
                            TabManager.currentIndex = tabItem.index;
                        }
                    }
                }
            }
        }

        // New Tab (+) Button
        Item {
            implicitWidth: 28
            implicitHeight: 28
            Layout.alignment: Qt.AlignVCenter

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: addHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "add"
                    color: Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }

                MouseArea {
                    id: addHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: TabManager.newTab()
                }
            }
        }
    }
}
