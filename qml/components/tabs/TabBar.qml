import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../"
import prism

StyledRect {
    id: root

    implicitHeight: 38
    color: Colours.tPalette.m3surfaceContainerLowest

    RowLayout {
        id: tabRow

        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: Tokens.padding.small
        anchors.topMargin: 4
        spacing: Tokens.spacing.extraSmall

        ListView {
            id: tabList

            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: ListView.Horizontal
            spacing: 0
            clip: false

            model: TabManager

            delegate: Item {
                id: tabItem

                required property int index
                required property string title
                required property string path
                readonly property bool selected: TabManager.currentIndex === index

                implicitWidth: Math.min(220, Math.max(120, tabContent.implicitWidth + Tokens.padding.medium * 2))
                anchors.bottom: parent ? parent.bottom : undefined
                anchors.top: parent ? parent.top : undefined
                z: selected ? 10 : 1

                // Left outer concave fillet curve
                Shape {
                    anchors.right: tabBackground.left
                    anchors.bottom: parent.bottom
                    width: 8
                    height: 8
                    visible: tabItem.selected
                    layer.enabled: true

                    ShapePath {
                        fillColor: Colours.tPalette.m3surfaceContainer
                        strokeColor: "transparent"
                        startX: 8; startY: 0
                        PathArc {
                            x: 0; y: 8
                            radiusX: 8; radiusY: 8
                            direction: PathArc.Counterclockwise
                        }
                        PathLine { x: 8; y: 8 }
                    }
                }

                // Right outer concave fillet curve
                Shape {
                    anchors.left: tabBackground.right
                    anchors.bottom: parent.bottom
                    width: 8
                    height: 8
                    visible: tabItem.selected
                    layer.enabled: true

                    ShapePath {
                        fillColor: Colours.tPalette.m3surfaceContainer
                        strokeColor: "transparent"
                        startX: 0; startY: 0
                        PathArc {
                            x: 8; y: 8
                            radiusX: 8; radiusY: 8
                            direction: PathArc.Clockwise
                        }
                        PathLine { x: 0; y: 8 }
                    }
                }

                // Main Tab Body
                StyledRect {
                    id: tabBackground
                    anchors.fill: parent

                    topLeftRadius: tabItem.selected ? 8 : Tokens.rounding.small
                    topRightRadius: tabItem.selected ? 8 : Tokens.rounding.small
                    bottomLeftRadius: 0
                    bottomRightRadius: 0

                    color: tabItem.selected ? Colours.tPalette.m3surfaceContainer : (tabHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent")

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
            Layout.leftMargin: 8

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
