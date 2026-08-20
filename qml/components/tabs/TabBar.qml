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
        contentWidth: tabsRow.implicitWidth + 40
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
                id: tabRepeater
                model: TabManager

                delegate: Item {
                    id: tabItem

                    required property int index
                    required property string title
                    required property string path
                    readonly property bool selected: TabManager.currentIndex === index

                    implicitWidth: Math.min(220, Math.max(120, tabContent.implicitWidth + 44))
                    anchors.top: parent ? parent.top : undefined
                    anchors.bottom: parent ? parent.bottom : undefined
                    z: tabDragArea.pressed ? 50 : (selected ? 10 : 1)

                    // Tab Opening & Switching Animation
                    scale: 1.0
                    opacity: 1.0

                    Component.onCompleted: {
                        tabItem.scale = 0.7;
                        tabItem.opacity = 0.0;
                        openAnim.start();
                    }

                    ParallelAnimation {
                        id: openAnim
                        NumberAnimation { target: tabItem; property: "scale"; from: 0.7; to: 1.0; duration: 200; easing.type: Easing.OutBack }
                        NumberAnimation { target: tabItem; property: "opacity"; from: 0.0; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
                    }

                    Behavior on scale {
                        Anim { type: Anim.FastSpatial }
                    }

                    Behavior on opacity {
                        Anim { type: Anim.FastEffects }
                    }

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
                        visible: !tabItem.selected && tabDragArea.containsMouse
                        radius: Tokens.rounding.small
                        color: Colours.tPalette.m3surfaceContainerHigh
                    }

                    // Drag & Tab Click Area (Behind content, underneath close button)
                    MouseArea {
                        id: tabDragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                        z: 1

                        drag.target: tabItem
                        drag.axis: Drag.XAxis

                        property real startX: 0
                        property bool dragging: false

                        onPressed: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                TabManager.currentIndex = tabItem.index;
                                startX = tabItem.x;
                                dragging = false;
                            }
                        }

                        onPositionChanged: mouse => {
                            if (pressed && Math.abs(tabItem.x - startX) > 15) {
                                dragging = true;
                            }
                        }

                        onReleased: mouse => {
                            if (mouse.button === Qt.MiddleButton) {
                                TabManager.closeTab(tabItem.index);
                                return;
                            }
                            if (dragging) {
                                let totalItemW = tabItem.width - 6;
                                let shift = tabItem.x - startX;
                                let deltaIdx = Math.round(shift / totalItemW);
                                let newIdx = Math.max(0, Math.min(TabManager.count - 1, tabItem.index + deltaIdx));
                                if (newIdx !== tabItem.index) {
                                    TabManager.moveTab(tabItem.index, newIdx);
                                }
                                tabItem.x = 0;
                                dragging = false;
                            }
                        }
                    }

                    // Tab Content (Icon, Label, Close Button)
                    RowLayout {
                        id: tabContent

                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 12
                        anchors.bottomMargin: 2
                        spacing: Tokens.spacing.small
                        z: 2

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

                        // Close Button with Distinct Circle Hover Highlight
                        StyledRect {
                            id: closeBtn
                            implicitWidth: 24
                            implicitHeight: 24
                            radius: Tokens.rounding.full
                            visible: TabManager.count > 1
                            color: closeMouse.containsMouse ? Qt.alpha(Colours.palette.m3onSurface, 0.12) : "transparent"
                            z: 20

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "close"
                                fontStyle: Tokens.font.icon.small
                                color: closeMouse.containsMouse ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                            }

                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                preventStealing: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    mouse.accepted = true;
                                    TabManager.closeTab(tabItem.index);
                                }
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
