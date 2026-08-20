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
                    required property bool isSplit
                    required property string splitTitle
                    required property string splitPath
                    readonly property bool selected: TabManager.currentIndex === index

                    implicitWidth: isSplit ? Math.min(360, Math.max(240, tabContent.implicitWidth + 50)) : Math.min(220, Math.max(120, tabContent.implicitWidth + 44))
                    anchors.top: parent ? parent.top : undefined
                    anchors.bottom: parent ? parent.bottom : undefined
                    z: tabDragArea.pressed ? 50 : (selected ? 10 : 1)

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

                    // Drag & Click MouseArea for Tab selection & reordering (z: 1)
                    MouseArea {
                        id: tabDragArea
                        anchors.fill: parent
                        z: 1
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor

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
                            if (mouse.button === Qt.RightButton) {
                                tabMenu.openMenu(mapToItem(root, mouse.x, mouse.y).x, mapToItem(root, mouse.x, mouse.y).y, tabItem.index);
                                return;
                            }
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

                    // Single vs Joined Split Tab Content (z: 10)
                    RowLayout {
                        id: tabContent
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 14
                        anchors.bottomMargin: 2
                        spacing: 6
                        z: 10

                        // Primary Pane
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

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

                            // Close Left / Main Pane Button (z: 20)
                            Item {
                                implicitWidth: 20
                                implicitHeight: 20
                                visible: tabItem.isSplit || TabManager.count > 1
                                z: 20

                                StyledRect {
                                    anchors.fill: parent
                                    radius: Tokens.rounding.full
                                    color: closeHover1.containsMouse ? (tabItem.selected ? Colours.tPalette.m3surfaceContainerHigh : Colours.tPalette.m3surfaceContainerHighest) : "transparent"

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "close"
                                        fontStyle: Tokens.font.icon.small
                                        color: closeHover1.containsMouse ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                                    }
                                }

                                MouseArea {
                                    id: closeHover1
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    preventStealing: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mouse => {
                                        mouse.accepted = true;
                                        if (tabItem.isSplit) {
                                            TabManager.closeSplitPane(tabItem.index, 0);
                                        } else {
                                            TabManager.closeTab(tabItem.index);
                                        }
                                    }
                                }
                            }
                        }

                        // Split Tab Joined Divider
                        Rectangle {
                            visible: tabItem.isSplit
                            implicitWidth: 1
                            implicitHeight: 14
                            color: Colours.palette.m3outlineVariant
                            opacity: 0.6
                        }

                        // Secondary Split Pane
                        RowLayout {
                            visible: tabItem.isSplit
                            Layout.fillWidth: true
                            spacing: 4

                            MaterialIcon {
                                text: "folder"
                                color: tabItem.selected ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: tabItem.splitTitle
                                color: tabItem.selected ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            // Close Secondary Pane Button
                            Item {
                                implicitWidth: 20
                                implicitHeight: 20
                                z: 20

                                StyledRect {
                                    anchors.fill: parent
                                    radius: Tokens.rounding.full
                                    color: closeHover2.containsMouse ? (tabItem.selected ? Colours.tPalette.m3surfaceContainerHigh : Colours.tPalette.m3surfaceContainerHighest) : "transparent"

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "close"
                                        fontStyle: Tokens.font.icon.small
                                        color: closeHover2.containsMouse ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                                    }
                                }

                                MouseArea {
                                    id: closeHover2
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    preventStealing: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mouse => {
                                        mouse.accepted = true;
                                        TabManager.closeSplitPane(tabItem.index, 1);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Sleek Separator Line between rightmost tab and + button (media_1787207500035.png)
            Item {
                width: 14
                height: tabsRow.height

                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: 16
                    color: Colours.palette.m3outlineVariant
                    opacity: 0.6
                }
            }

            // New Tab (+) Button
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

    // Tab Context Menu
    MouseArea {
        id: tabMenu
        anchors.fill: parent
        z: 999
        visible: menuRect.opacity > 0.01
        enabled: visible
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: menuRect.expanded = false

        property real menuX: 0
        property real menuY: 0
        property int targetTabIndex: -1

        function openMenu(x, y, idx) {
            menuX = x;
            menuY = y;
            targetTabIndex = idx;
            menuRect.expanded = true;
        }

        StyledRect {
            id: menuRect
            property bool expanded: false
            x: Math.min(Math.max(8, tabMenu.menuX), root.width - width - 8)
            y: Math.min(Math.max(8, tabMenu.menuY), root.height - height - 8)
            implicitWidth: 200
            implicitHeight: tabMenuCol.implicitHeight + Tokens.padding.extraSmall * 2
            radius: Tokens.rounding.large
            color: Colours.palette.m3surfaceContainerLow
            opacity: expanded ? 1 : 0
            scale: expanded ? 1 : 0.94

            Behavior on opacity { Anim { type: Anim.FastEffects } }
            Behavior on scale { Anim { type: Anim.FastEffects } }

            ColumnLayout {
                id: tabMenuCol
                anchors.fill: parent
                anchors.margins: Tokens.padding.extraSmall
                spacing: 0

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 34
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
                            menuRect.expanded = false;
                            TabManager.splitTabWith(tabMenu.targetTabIndex, "");
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 34
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
                            menuRect.expanded = false;
                            TabManager.duplicateTab(tabMenu.targetTabIndex);
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 34
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
                            menuRect.expanded = false;
                            TabManager.closeTab(tabMenu.targetTabIndex);
                        }
                    }
                }
            }
        }
    }
}
