import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"
import "components/filedialog"

ApplicationWindow {
    id: window

    visible: true
    title: AppController.title
    width: 1000
    height: 600
    minimumWidth: 480
    minimumHeight: 320
    color: Colours.tPalette.m3surface

    function calculateInitialCwd(path) {
        if (!path || path === "")
            return ["Home"];
        
        const home = FileUtils.home;
        if (path === home)
            return ["Home"];
        if (path.startsWith(home + "/")) {
            const rel = path.substring(home.length + 1);
            return ["Home", ...rel.split("/").filter(p => p.length > 0)];
        }
        if (path.startsWith("/")) {
            return ["", ...path.split("/").filter(p => p.length > 0)];
        }
        return ["Home"];
    }

    FileDialog {
        id: fileDialog

        anchors.fill: parent
        title: AppController.title
        filterLabel: AppController.filterLabel
        filters: AppController.filters
        showHidden: AppController.showHidden
        cwd: window.calculateInitialCwd(AppController.initialDirectory)

        onAccepted: path => {
            AppController.accept(path);
        }

        onRejected: {
            AppController.reject();
        }
    }

    onClosing: {
        AppController.reject();
    }
}
