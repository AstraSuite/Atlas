import QtQuick
import QtQuick.Layouts
import "../"
import prism

StyledRect {
    id: root

    required property var activeTab
    property real zoomSize: 80
    property string searchQuery: ""
    readonly property var currentSelectedPath: {
        if (mainViewLoader && mainViewLoader.item && mainViewLoader.item.currentItem) {
            return mainViewLoader.item.currentItem.path;
        }
        return activeTab ? activeTab.currentPath : "";
    }

    signal itemContextMenu(var item, real mouseX, real mouseY)
    signal blankContextMenu(real mouseX, real mouseY)

    color: Colours.tPalette.m3surfaceContainer

    StyledRect {
        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surface

        FileSystemModel {
            id: mainModel
            path: root.activeTab ? root.activeTab.currentPath : ""
            searchQuery: root.searchQuery
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
    }

    Component {
        id: gridComp
        FileGridView {
            model: mainModel
            activeTab: root.activeTab
            zoomSize: root.zoomSize
            onOpenItem: item => root.handleOpen(item)
            onItemContextMenu: (item, x, y) => root.itemContextMenu(item, x, y)
            onBlankContextMenu: (x, y) => root.blankContextMenu(x, y)
        }
    }

    Component {
        id: detailsComp
        FileDetailsView {
            model: mainModel
            activeTab: root.activeTab
            onOpenItem: item => root.handleOpen(item)
            onItemContextMenu: (item, x, y) => root.itemContextMenu(item, x, y)
            onBlankContextMenu: (x, y) => root.blankContextMenu(x, y)
        }
    }

    Component {
        id: compactComp
        FileCompactView {
            model: mainModel
            activeTab: root.activeTab
            onOpenItem: item => root.handleOpen(item)
            onItemContextMenu: (item, x, y) => root.itemContextMenu(item, x, y)
            onBlankContextMenu: (x, y) => root.blankContextMenu(x, y)
        }
    }

    function handleOpen(item) {
        if (!item) return;
        if (item.isDir) {
            root.activeTab.currentPath = item.path;
        } else {
            AppIntegration.openWithDefault(item.path);
        }
    }
}
