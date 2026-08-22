import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../"
import prism

StyledRect {
    id: root

    required property var activeTab
    property real zoomSize: 80
    property string searchQuery: ""
    readonly property bool isSplit: activeTab && activeTab.isSplit
    readonly property int activePane: activeTab ? activeTab.activePane : 0
    property real splitRatio: 0.5

    property alias mainViewLoader: mainViewLoader
    property alias splitViewLoader: splitViewLoader

    readonly property var currentSelectedPath: {
        let loader = (isSplit && activePane === 1) ? splitViewLoader : mainViewLoader;
        if (loader && loader.item) {
            if (loader.item.selectedPaths && loader.item.selectedPaths.length > 0) {
                return loader.item.selectedPaths[0];
            }
            if (loader.item.currentItem) {
                return loader.item.currentItem.path;
            }
        }
        if (!activeTab) return "";
        return (isSplit && activePane === 1) ? activeTab.splitPath : activeTab.currentPath;
    }
    readonly property var selectedPaths: {
        let loader = (isSplit && activePane === 1) ? splitViewLoader : mainViewLoader;
        if (loader && loader.item && loader.item.selectedPaths) {
            return loader.item.selectedPaths;
        }
        return [];
    }
    readonly property var activeModel: (isSplit && activePane === 1) ? splitModel : mainModel

    Connections {
        target: AppController
        function onDateFormatChanged() {
            if (mainModel) mainModel.refresh();
            if (splitModel) splitModel.refresh();
        }
    }

    signal itemContextMenu(var item, real mouseX, real mouseY)
    signal blankContextMenu(real mouseX, real mouseY)
    signal filesDropped(var sources, string destDir, real mouseX, real mouseY)
    signal createNewFolder()
    signal createNewFile()
    signal itemOpened(var item, int pane)

    color: Colours.tPalette.m3surfaceContainer

    Item {
        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall

        // Left / Main Pane
        StyledRect {
            id: pane1
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.isSplit ? Math.max(120, Math.min(parent.width - 120, (parent.width - resizer.width) * root.splitRatio)) : parent.width

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surface
            clip: true

            // Active Pane Low-Profile Top Accent Bar
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 2
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                height: 3
                radius: 1.5
                color: Colours.palette.m3primary
                visible: root.isSplit && root.activePane === 0
                z: 20
                opacity: 0.95
            }

            FileSystemModel {
                id: mainModel
                path: root.activeTab ? root.activeTab.currentPath : ""
                searchQuery: (root.isSplit && root.activePane === 1) ? "" : root.searchQuery
                showHidden: AppController.showHidden
            }

            Loader {
                id: mainViewLoader
                anchors.fill: parent

                sourceComponent: {
                    let mode = root.activeTab ? root.activeTab.viewMode : 0;
                    if (mode === 1) return detailsComp;
                    if (mode === 2) return compactComp;
                    return gridComp;
                }
            }

            // Nexus-Style Empty State
            EmptyStateView {
                visible: mainModel.count === 0
                path: root.activeTab ? root.activeTab.currentPath : ""
                isSearching: mainModel.isSearching
                searchQuery: (root.isSplit && root.activePane === 1) ? "" : root.searchQuery
                onCreateFolder: {
                    if (root.activeTab) root.activeTab.activePane = 0;
                    root.createNewFolder();
                }
                onCreateFile: {
                    if (root.activeTab) root.activeTab.activePane = 0;
                    root.createNewFile();
                }
            }
        }

        // Resizable Splitter Divider Bar
        Item {
            id: resizer
            visible: root.isSplit
            anchors.left: pane1.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 8
            z: 20

            Rectangle {
                anchors.centerIn: parent
                width: 2
                height: parent.height - 16
                radius: 1
                color: Colours.palette.m3primary
                opacity: (resizeMouse.containsMouse || resizeMouse.drag.active) ? 1.0 : 0.65

                Behavior on opacity { Anim { type: Anim.FastEffects } }
            }

            MouseArea {
                id: resizeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor

                property real startMouseX: 0
                property real startRatio: 0.5

                onPressed: mouse => {
                    startMouseX = mouse.x;
                    startRatio = root.splitRatio;
                }

                onPositionChanged: mouse => {
                    if (pressed) {
                        let totalW = root.width - resizer.width - Tokens.padding.extraSmall * 2;
                        if (totalW > 200) {
                            let currentPos = pane1.width + (mouse.x - startMouseX);
                            let newRatio = currentPos / totalW;
                            root.splitRatio = Math.max(0.15, Math.min(0.85, newRatio));
                        }
                    }
                }
            }
        }

        // Right / Secondary Pane
        StyledRect {
            id: pane2
            visible: root.isSplit
            anchors.left: resizer.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surface
            clip: true

            // Active Pane Low-Profile Top Accent Bar
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 2
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                height: 3
                radius: 1.5
                color: Colours.palette.m3primary
                visible: root.isSplit && root.activePane === 1
                z: 20
                opacity: 0.95
            }

            FileSystemModel {
                id: splitModel
                path: (root.activeTab && root.activeTab.splitPath) ? root.activeTab.splitPath : ""
                searchQuery: (root.isSplit && root.activePane === 1) ? root.searchQuery : ""
                showHidden: AppController.showHidden
            }

            Loader {
                id: splitViewLoader
                anchors.fill: parent

                sourceComponent: {
                    let mode = root.activeTab ? root.activeTab.viewMode : 0;
                    if (mode === 1) return splitDetailsComp;
                    if (mode === 2) return splitCompactComp;
                    return splitGridComp;
                }
            }

            // Secondary Empty State
            EmptyStateView {
                visible: splitModel.count === 0
                path: (root.activeTab && root.activeTab.splitPath) ? root.activeTab.splitPath : ""
                isSearching: splitModel.isSearching
                searchQuery: (root.isSplit && root.activePane === 1) ? root.searchQuery : ""
                onCreateFolder: {
                    if (root.activeTab) root.activeTab.activePane = 1;
                    root.createNewFolder();
                }
                onCreateFile: {
                    if (root.activeTab) root.activeTab.activePane = 1;
                    root.createNewFile();
                }
            }
        }
    }

    // Left Pane Components
    Component {
        id: gridComp
        FileGridView {
            model: mainModel
            activeTab: root.activeTab
            paneIndex: 0
            zoomSize: root.zoomSize
            onOpenItem: item => root.handleOpen(item, 0)
            onItemContextMenu: (item, x, y) => {
                if (root.activeTab) root.activeTab.activePane = 0;
                root.itemContextMenu(item, x, y);
            }
            onBlankContextMenu: (x, y) => {
                if (root.activeTab) root.activeTab.activePane = 0;
                root.blankContextMenu(x, y);
            }
            onFilesDropped: (sources, destDir, x, y) => {
                if (root.activeTab) root.activeTab.activePane = 0;
                root.filesDropped(sources, destDir, x, y);
            }
        }
    }

    Component {
        id: detailsComp
        FileDetailsView {
            model: mainModel
            activeTab: root.activeTab
            paneIndex: 0
            onOpenItem: item => root.handleOpen(item, 0)
            onItemContextMenu: (item, x, y) => {
                if (root.activeTab) root.activeTab.activePane = 0;
                root.itemContextMenu(item, x, y);
            }
            onBlankContextMenu: (x, y) => {
                if (root.activeTab) root.activeTab.activePane = 0;
                root.blankContextMenu(x, y);
            }
            onFilesDropped: (sources, destDir, x, y) => {
                if (root.activeTab) root.activeTab.activePane = 0;
                root.filesDropped(sources, destDir, x, y);
            }
        }
    }

    Component {
        id: compactComp
        FileCompactView {
            model: mainModel
            activeTab: root.activeTab
            paneIndex: 0
            onOpenItem: item => root.handleOpen(item, 0)
            onItemContextMenu: (item, x, y) => {
                if (root.activeTab) root.activeTab.activePane = 0;
                root.itemContextMenu(item, x, y);
            }
            onBlankContextMenu: (x, y) => {
                if (root.activeTab) root.activeTab.activePane = 0;
                root.blankContextMenu(x, y);
            }
            onFilesDropped: (sources, destDir, x, y) => {
                if (root.activeTab) root.activeTab.activePane = 0;
                root.filesDropped(sources, destDir, x, y);
            }
        }
    }

    // Right Pane Components
    Component {
        id: splitGridComp
        FileGridView {
            model: splitModel
            activeTab: root.activeTab
            paneIndex: 1
            zoomSize: root.zoomSize
            onOpenItem: item => root.handleOpen(item, 1)
            onItemContextMenu: (item, x, y) => {
                if (root.activeTab) root.activeTab.activePane = 1;
                root.itemContextMenu(item, x, y);
            }
            onBlankContextMenu: (x, y) => {
                if (root.activeTab) root.activeTab.activePane = 1;
                root.blankContextMenu(x, y);
            }
            onFilesDropped: (sources, destDir, x, y) => {
                if (root.activeTab) root.activeTab.activePane = 1;
                root.filesDropped(sources, destDir, x, y);
            }
        }
    }

    Component {
        id: splitDetailsComp
        FileDetailsView {
            model: splitModel
            activeTab: root.activeTab
            paneIndex: 1
            onOpenItem: item => root.handleOpen(item, 1)
            onItemContextMenu: (item, x, y) => {
                if (root.activeTab) root.activeTab.activePane = 1;
                root.itemContextMenu(item, x, y);
            }
            onBlankContextMenu: (x, y) => {
                if (root.activeTab) root.activeTab.activePane = 1;
                root.blankContextMenu(x, y);
            }
            onFilesDropped: (sources, destDir, x, y) => {
                if (root.activeTab) root.activeTab.activePane = 1;
                root.filesDropped(sources, destDir, x, y);
            }
        }
    }

    Component {
        id: splitCompactComp
        FileCompactView {
            model: splitModel
            activeTab: root.activeTab
            paneIndex: 1
            onOpenItem: item => root.handleOpen(item, 1)
            onItemContextMenu: (item, x, y) => {
                if (root.activeTab) root.activeTab.activePane = 1;
                root.itemContextMenu(item, x, y);
            }
            onBlankContextMenu: (x, y) => {
                if (root.activeTab) root.activeTab.activePane = 1;
                root.blankContextMenu(x, y);
            }
            onFilesDropped: (sources, destDir, x, y) => {
                if (root.activeTab) root.activeTab.activePane = 1;
                root.filesDropped(sources, destDir, x, y);
            }
        }
    }

    function handleOpen(item, pane) {
        if (root.activeTab) root.activeTab.activePane = pane;
        if (!item) return;
        if (item.isDir) {
            if (pane === 1) {
                root.activeTab.splitPath = item.path;
            } else {
                root.activeTab.currentPath = item.path;
            }
        } else {
            root.itemOpened(item, pane);
        }
    }

    function selectAll() {
        let loader = (isSplit && activePane === 1) ? splitViewLoader : mainViewLoader;
        if (activeModel && loader && loader.item) {
            let all = [];
            for (let i = 0; i < activeModel.count; ++i) {
                let e = activeModel.get(i);
                if (e) all.push(e.path);
            }
            loader.item.selectedPaths = all;
        }
    }

    function clearSelection() {
        let loader = (isSplit && activePane === 1) ? splitViewLoader : mainViewLoader;
        if (loader && loader.item) {
            loader.item.selectedPaths = [];
        }
    }

    function invertSelection() {
        let loader = (isSplit && activePane === 1) ? splitViewLoader : mainViewLoader;
        if (activeModel && loader && loader.item) {
            let cur = loader.item.selectedPaths;
            let inverted = [];
            for (let i = 0; i < activeModel.count; ++i) {
                let e = activeModel.get(i);
                if (e && cur.indexOf(e.path) === -1) {
                    inverted.push(e.path);
                }
            }
            loader.item.selectedPaths = inverted;
        }
    }

    function focusActiveView() {
        let loader = (isSplit && activePane === 1) ? splitViewLoader : mainViewLoader;
        if (loader && loader.item) {
            loader.item.forceActiveFocus();
        }
    }

    Component.onCompleted: {
        focusActiveView();
    }
}
