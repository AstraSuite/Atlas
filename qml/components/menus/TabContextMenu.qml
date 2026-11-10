import QtQuick
import QtQuick.Layouts
import "../"
import atlas

MouseArea {
    id: root

    property bool expanded: false
    property real menuX: 0
    property real menuY: 0
    property int targetTabIndex: -1

    function open(x, y, idx) {
        menuX = x;
        menuY = y;
        targetTabIndex = idx;
        expanded = true;
    }

    anchors.fill: parent
    z: 999
    visible: opacity > 0.01
    enabled: expanded
    hoverEnabled: expanded
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: expanded = false

    opacity: expanded ? 1.0 : 0.0
    Behavior on opacity { Anim { type: Anim.FastEffects } }

    LazyContent {
        expanded: root.expanded
        sourceComponent: Item {
            StyledRect {
                id: menuCard

                x: Math.min(Math.max(8, root.menuX), root.width - width - 8)
                y: Math.min(Math.max(8, root.menuY), root.height - height - 8)

                implicitWidth: menuCol.implicitWidth + (Colours.tty ? 0 : Tokens.padding.extraSmall * 2)
                implicitHeight: menuCol.implicitHeight + (Colours.tty ? 26 : Tokens.padding.extraSmall * 2)

                radius: Tokens.rounding.large
                color: Colours.palette.m3surfaceContainerLow

                scale: root.expanded ? 1.0 : 0.94
                Behavior on scale { Anim { type: Anim.FastEffects; easing: Tokens.anim.standard } }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => mouse.accepted = true
                }

                TtyBox {
                    anchors.fill: parent
                    title: qsTr("tab")
                }

                ColumnLayout {
                    id: menuCol
                    anchors.fill: parent
                    anchors.margins: Colours.tty ? 0 : Tokens.padding.extraSmall
                    anchors.topMargin: Colours.tty ? 18 : Tokens.padding.extraSmall
                    anchors.bottomMargin: Colours.tty ? 8 : Tokens.padding.extraSmall
                    spacing: 0

                    // Split Tab Side-by-Side
                    StyledRect {
                        Layout.fillWidth: true
                        implicitWidth: mi1Row.implicitWidth + 24
                        implicitHeight: Colours.tty ? 26 : 36
                        radius: Tokens.rounding.medium
                        color: !Colours.tty && (mi1Hover.containsMouse) ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

                        TtyMenuRow {
                            anchors.fill: parent
                            visible: Colours.tty
                            text: qsTr("Split Tab Side-by-Side")
                            hovered: mi1Hover.containsMouse
                            shortcut: "view.split"
                        }

                        RowLayout {
                            id: mi1Row
                            visible: !Colours.tty
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8
                            MaterialIcon { text: "splitscreen"; fontStyle: Tokens.font.icon.small; color: Colours.palette.m3onSurfaceVariant }
                            StyledText { text: qsTr("Split Tab Side-by-Side"); font: Tokens.font.body.medium; color: Colours.palette.m3onSurface }
                        }

                        MouseArea {
                            id: mi1Hover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.expanded = false;
                                TabManager.splitTabWith(root.targetTabIndex, "");
                            }
                        }
                    }

                    // Duplicate Tab
                    StyledRect {
                        Layout.fillWidth: true
                        implicitWidth: mi2Row.implicitWidth + 24
                        implicitHeight: Colours.tty ? 26 : 36
                        radius: Tokens.rounding.medium
                        color: !Colours.tty && (mi2Hover.containsMouse) ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

                        TtyMenuRow {
                            anchors.fill: parent
                            visible: Colours.tty
                            text: qsTr("Duplicate Tab")
                            hovered: mi2Hover.containsMouse
                        }

                        RowLayout {
                            id: mi2Row
                            visible: !Colours.tty
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8
                            MaterialIcon { text: "content_copy"; fontStyle: Tokens.font.icon.small; color: Colours.palette.m3onSurfaceVariant }
                            StyledText { text: qsTr("Duplicate Tab"); font: Tokens.font.body.medium; color: Colours.palette.m3onSurface }
                        }

                        MouseArea {
                            id: mi2Hover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.expanded = false;
                                TabManager.duplicateTab(root.targetTabIndex);
                            }
                        }
                    }

                    // Close Tab
                    StyledRect {
                        Layout.fillWidth: true
                        implicitWidth: mi3Row.implicitWidth + 24
                        implicitHeight: Colours.tty ? 26 : 36
                        radius: Tokens.rounding.medium
                        color: !Colours.tty && (mi3Hover.containsMouse) ? Colours.tPalette.m3surfaceContainerHigh : "transparent"
                        visible: TabManager.count > 1

                        TtyMenuRow {
                            anchors.fill: parent
                            visible: Colours.tty
                            text: qsTr("Close Tab")
                            hovered: mi3Hover.containsMouse
                            danger: true
                            shortcut: "tabs.close"
                        }

                        RowLayout {
                            id: mi3Row
                            visible: !Colours.tty
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8
                            MaterialIcon { text: "close"; fontStyle: Tokens.font.icon.small; color: Colours.palette.m3error }
                            StyledText { text: qsTr("Close Tab"); font: Tokens.font.body.medium; color: Colours.palette.m3error }
                        }

                        MouseArea {
                            id: mi3Hover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.expanded = false;
                                TabManager.closeTab(root.targetTabIndex);
                            }
                        }
                    }
                }
            }
        }
    }
}
