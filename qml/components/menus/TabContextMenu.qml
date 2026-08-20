import QtQuick
import QtQuick.Layouts
import "../"
import prism

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

    StyledRect {
        id: menuCard

        x: Math.min(Math.max(8, root.menuX), root.width - width - 8)
        y: Math.min(Math.max(8, root.menuY), root.height - height - 8)

        implicitWidth: 220
        implicitHeight: menuCol.implicitHeight + Tokens.padding.extraSmall * 2

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerLow

        scale: root.expanded ? 1.0 : 0.94
        Behavior on scale { Anim { type: Anim.FastEffects; easing: Tokens.anim.standard } }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: menuCol
            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall
            spacing: 0

            // Split Tab Side-by-Side
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: Tokens.rounding.medium
                color: mi1Hover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

                RowLayout {
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
                implicitHeight: 36
                radius: Tokens.rounding.medium
                color: mi2Hover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

                RowLayout {
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
                implicitHeight: 36
                radius: Tokens.rounding.medium
                color: mi3Hover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent"
                visible: TabManager.count > 1

                RowLayout {
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
