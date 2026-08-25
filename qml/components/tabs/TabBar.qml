import QtQuick
import QtQuick.Layouts
import "../"
import atlas

StyledRect {
    id: root

    signal tabContextMenuRequested(int tabIndex, real globalX, real globalY)
    signal filesDropped(var sourceFiles, string targetDir, real globalX, real globalY)

    readonly property bool hasSplit: TabManager.currentTab ? TabManager.currentTab.isSplit : false
    readonly property bool shouldShow: TabManager.count > 1 || hasSplit
    implicitHeight: shouldShow ? 40 : 0
    visible: implicitHeight > 0
    clip: true
    color: "transparent"

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

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
                    required property int activePane
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
                        visible: !tabItem.selected && (tabDragArea.containsMouse || tabDropArea.containsDrag)
                        radius: Tokens.rounding.small
                        color: tabDropArea.containsDrag ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                        Behavior on color {
                            CAnim {}
                        }
                    }

                    // Drag & Click MouseArea for Tab selection & reordering
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
                                if (tabItem.isSplit && TabManager.currentTab) {
                                    let half = tabItem.width / 2;
                                    TabManager.currentTab.activePane = (mouse.x > half) ? 1 : 0;
                                }
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
                                let globalPos = mapToItem(null, mouse.x, mouse.y);
                                root.tabContextMenuRequested(tabItem.index, globalPos.x, globalPos.y);
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

                    // Drag & Drop Target: Drops Files into the Tab's Directory, Opens Tab After Hover Delay
                    DropArea {
                        id: tabDropArea
                        anchors.fill: parent
                        z: 2

                        onEntered: tabOpenTimer.restart()
                        onExited: tabOpenTimer.stop()

                        onDropped: drop => {
                            tabOpenTimer.stop();
                            if (!drop.hasUrls) return;
                            let urls = [];
                            for (let i = 0; i < drop.urls.length; ++i) {
                                urls.push(FileUtils.toLocalFile(drop.urls[i]));
                            }
                            // Left half of a joined split tab targets primary pane, right half secondary
                            let destDir = (tabItem.isSplit && drop.x > tabItem.width / 2) ? tabItem.splitPath : tabItem.path;
                            let filtered = urls.filter(u => u !== destDir);
                            if (filtered.length === 0 || !destDir) return;

                            // QML DropEvent does not expose modifiers, query them from the window system
                            let mods = FileUtils.queryKeyboardModifiers();
                            if (mods & Qt.ShiftModifier && mods & Qt.ControlModifier) {
                                for (let i = 0; i < filtered.length; ++i) {
                                    let name = filtered[i].substring(filtered[i].lastIndexOf('/') + 1);
                                    FileOperations.createSymlink(filtered[i], destDir + "/" + name);
                                }
                            } else if (mods & Qt.ShiftModifier) {
                                FileOperations.moveFiles(filtered, destDir);
                            } else if (mods & Qt.ControlModifier) {
                                FileOperations.copyFiles(filtered, destDir);
                            } else {
                                let globalPos = mapToItem(null, drop.x, drop.y);
                                root.filesDropped(filtered, destDir, globalPos.x, globalPos.y);
                            }
                            drop.accept();

                            // Jump to the tab so the result of the drop is visible
                            TabManager.currentIndex = tabItem.index;
                        }
                    }

                    // Hover-to-Open: Switches to the Tab When a Drag Hovers Over It
                    Timer {
                        id: tabOpenTimer
                        interval: 1000
                        onTriggered: TabManager.currentIndex = tabItem.index
                    }

                    // Single vs Joined Split Tab Content
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
                            id: primaryPaneLayout
                            Layout.fillWidth: true
                            spacing: 4

                            MaterialIcon {
                                text: "folder"
                                color: tabItem.selected
                                    ? (tabItem.isSplit && tabItem.activePane === 1 ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3primary)
                                    : Colours.palette.m3onSurfaceVariant
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: tabItem.title
                                color: tabItem.selected
                                    ? (tabItem.isSplit && tabItem.activePane === 1 ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface)
                                    : Colours.palette.m3onSurfaceVariant
                                font: tabItem.selected && (!tabItem.isSplit || tabItem.activePane === 0)
                                    ? Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                                    : Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            // Close Left / Main Pane Button
                            Item {
                                implicitWidth: 20
                                implicitHeight: 20
                                visible: tabItem.isSplit || TabManager.count > 1
                                z: 20

                                StyledRect {
                                    anchors.fill: parent
                                    radius: Tokens.rounding.full
                                    color: closeHover1.containsMouse ? (tabItem.selected ? Colours.tPalette.m3surfaceContainerHigh : Colours.tPalette.m3surfaceContainerHighest) : Qt.alpha(Colours.tPalette.m3surfaceContainerHigh, 0)

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

                                StyledToolTip {
                                    text: tabItem.isSplit ? qsTr("Close pane") : qsTr("Close tab (Ctrl+W)")
                                    visible: closeHover1.containsMouse
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
                            id: secondaryPaneLayout
                            visible: tabItem.isSplit
                            Layout.fillWidth: true
                            spacing: 4

                            MaterialIcon {
                                text: "folder"
                                color: tabItem.selected
                                    ? (tabItem.activePane === 1 ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant)
                                    : Colours.palette.m3onSurfaceVariant
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: tabItem.splitTitle
                                color: tabItem.selected
                                    ? (tabItem.activePane === 1 ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant)
                                    : Colours.palette.m3onSurfaceVariant
                                font: tabItem.selected && tabItem.activePane === 1
                                    ? Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                                    : Tokens.font.body.small
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
                                    color: closeHover2.containsMouse ? (tabItem.selected ? Colours.tPalette.m3surfaceContainerHigh : Colours.tPalette.m3surfaceContainerHighest) : Qt.alpha(Colours.tPalette.m3surfaceContainerHigh, 0)

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

                                StyledToolTip {
                                    text: qsTr("Close pane")
                                    visible: closeHover2.containsMouse
                                }
                            }
                        }
                    }
                }
            }

            // Sleek Separator Line between rightmost tab and + button
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

            // New Tab Button
            Item {
                width: 36
                height: tabsRow.height
                z: 2

                StyledRect {
                    anchors.centerIn: parent
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: Tokens.rounding.full
                    color: addHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : Qt.alpha(Colours.tPalette.m3surfaceContainerHigh, 0)


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

                    StyledToolTip {
                        text: qsTr("New tab (Ctrl+T)")
                        visible: addHover.containsMouse
                    }
                }
            }
        }
    }
}
