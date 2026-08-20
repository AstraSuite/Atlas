import QtQuick
import QtQuick.Layouts
import "../"
import prism

StyledRect {
    id: root

    implicitHeight: 40
    color: "transparent"

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 4
        anchors.bottomMargin: 0
        contentWidth: tabsRow.implicitWidth + 20
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        clip: false

        Row {
            id: tabsRow
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: -6

            Repeater {
                model: TabManager

                delegate: Item {
                    id: tabItem

                    required property int index
                    required property string title
                    required property string path
                    readonly property bool selected: TabManager.currentIndex === index

                    implicitWidth: Math.min(220, Math.max(120, tabContent.implicitWidth + 40))
                    anchors.top: parent ? parent.top : undefined
                    anchors.bottom: parent ? parent.bottom : undefined
                    z: selected ? 10 : 1

                    // Active Tab Google Chrome Continuous Shape with Antialiased Fillets
                    Canvas {
                        id: activeTabShape
                        anchors.fill: parent
                        visible: tabItem.selected
                        antialiasing: true
                        smooth: true

                        Connections {
                            target: Colours.palette
                            function onM3surfaceContainerChanged() { activeTabShape.requestPaint(); }
                        }

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);

                            var r = 10;
                            var w = width;
                            var h = height;

                            ctx.fillStyle = Colours.tPalette.m3surfaceContainer;
                            ctx.beginPath();

                            // Bottom-left concave swoop
                            ctx.moveTo(0, h);
                            ctx.quadraticCurveTo(r, h, r, h - r);

                            // Left vertical edge to top-left rounded corner
                            ctx.lineTo(r, r);
                            ctx.quadraticCurveTo(r, 0, r + 8, 0);

                            // Top edge to top-right rounded corner
                            ctx.lineTo(w - r - 8, 0);
                            ctx.quadraticCurveTo(w - r, 0, w - r, r);

                            // Right vertical edge to bottom-right concave swoop
                            ctx.lineTo(w - r, h - r);
                            ctx.quadraticCurveTo(w - r, h, w, h);

                            // Base line
                            ctx.lineTo(0, h);
                            ctx.closePath();
                            ctx.fill();
                        }

                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                    }

                    // Inactive Tab Background
                    StyledRect {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        anchors.bottomMargin: 4
                        visible: !tabItem.selected && tabHover.containsMouse
                        radius: Tokens.rounding.small
                        color: Colours.tPalette.m3surfaceContainerHigh
                    }

                    // Tab Content (Icon, Label, Close Button)
                    RowLayout {
                        id: tabContent

                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 16
                        anchors.bottomMargin: 2
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
                            z: 20

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

            // New Tab (+) Button IMMEDIATELY next to the rightmost tab
            Item {
                width: 36
                height: tabsRow.height
                z: 2

                StyledRect {
                    anchors.centerIn: parent
                    implicitWidth: 28
                    implicitHeight: 28
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
}
