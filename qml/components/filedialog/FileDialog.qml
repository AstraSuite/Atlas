import QtQuick
import QtQuick.Layouts
import atlas
import "../"

StyledRect {
    id: root

    property var cwd: ["Home"]
    readonly property string currentPath: cwdToPath(cwd)
    property string initialDirectory: AppController.initialDirectory
    property string filterLabel: AppController.filterLabel
    property var filters: AppController.filters
    property string title: AppController.title || qsTr("Select a file")
    property bool showHidden: AppController.showHidden
    property bool directoryOnly: AppController.directoryOnly
    readonly property bool saveMode: AppController.saveMode
    property string saveName: AppController.suggestedName
    readonly property string savePath: currentPath === "/" ? "/" + saveName : currentPath + "/" + saveName
    readonly property bool saveWouldOverwrite: saveMode && saveName.length > 0 && AppController.fileExists(savePath)
    property real zoomLevel: 80

    signal accepted(string path)
    signal rejected()

    function pathToCwd(fullPath) {
        if (!fullPath || fullPath === "") return ["Home"];
        let home = FileUtils.home;
        if (fullPath === home) return ["Home"];
        if (fullPath.startsWith(home + "/")) {
            let sub = fullPath.substring(home.length + 1).split("/").filter(s => s.length > 0);
            return ["Home"].concat(sub);
        }
        let parts = fullPath.split("/").filter(s => s.length > 0);
        return [""].concat(parts);
    }

    function cwdToPath(cwdArr) {
        if (!cwdArr || cwdArr.length === 0) return FileUtils.home;
        if (cwdArr[0] === "Home") {
            if (cwdArr.length === 1) return FileUtils.home;
            return FileUtils.home + "/" + cwdArr.slice(1).join("/");
        } else if (cwdArr[0] === "") {
            return "/" + cwdArr.slice(1).join("/");
        } else {
            return cwdArr.join("/");
        }
    }

    readonly property bool selectionValid: {
        const file = folderContents.currentItem?.modelData;
        if (directoryOnly) {
            return true;
        }
        if (!file)
            return false;
        if (file.isDir)
            return false;
        if (filters.includes("*"))
            return true;
        return filters.includes(file.suffix.toLowerCase()) || filters.includes(file.suffix);
    }

    Component.onCompleted: {
        if (AppController.initialDirectory && AppController.initialDirectory.length > 0) {
            cwd = pathToCwd(AppController.initialDirectory);
        }
    }

    Connections {
        target: AppController
        function onInitialDirectoryChanged() {
            if (AppController.initialDirectory && AppController.initialDirectory.length > 0) {
                root.cwd = root.pathToCwd(AppController.initialDirectory);
            }
        }
    }

    Connections {
        target: DriveManager
        function onDeviceMounted(mountPoint, tabIndex) {
            if (mountPoint && mountPoint.length > 0) {
                root.cwd = root.pathToCwd(mountPoint);
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        context: Qt.ApplicationShortcut
        onActivated: root.rejected()
    }

    Shortcut {
        sequence: "Ctrl+H"
        enabled: root.visible
        context: Qt.ApplicationShortcut
        onActivated: root.showHidden = !root.showHidden
    }

    Shortcut {
        sequence: "Alt+."
        enabled: root.visible
        context: Qt.ApplicationShortcut
        onActivated: root.showHidden = !root.showHidden
    }

    Shortcut {
        sequence: "Alt+Up"
        enabled: root.visible
        context: Qt.ApplicationShortcut
        onActivated: {
            if (root.cwd.length > 1) {
                root.cwd = root.cwd.slice(0, root.cwd.length - 1);
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+="
        enabled: root.visible
        context: Qt.ApplicationShortcut
        onActivated: root.zoomLevel = Math.min(180, root.zoomLevel + 16)
    }

    Shortcut {
        sequence: "Ctrl++"
        enabled: root.visible
        context: Qt.ApplicationShortcut
        onActivated: root.zoomLevel = Math.min(180, root.zoomLevel + 16)
    }

    Shortcut {
        sequence: "Ctrl+-"
        enabled: root.visible
        context: Qt.ApplicationShortcut
        onActivated: root.zoomLevel = Math.max(48, root.zoomLevel - 16)
    }

    Shortcut {
        sequence: "Ctrl+0"
        enabled: root.visible
        context: Qt.ApplicationShortcut
        onActivated: root.zoomLevel = 80
    }

    implicitWidth: 1000
    implicitHeight: 600
    color: Colours.tPalette.m3surface

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            Layout.fillHeight: true
            dialog: root
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            HeaderBar {
                Layout.fillWidth: true
                dialog: root
            }

            FolderContents {
                id: folderContents

                Layout.fillWidth: true
                Layout.fillHeight: true
                dialog: root
            }

            DialogButtons {
                Layout.fillWidth: true
                dialog: root
                folder: folderContents
            }
        }
    }
}
