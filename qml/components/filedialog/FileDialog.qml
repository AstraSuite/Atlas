import QtQuick
import QtQuick.Layouts
import "../"

StyledRect {
    id: root

    property var cwd: ["Home"]
    property string filterLabel: "All files"
    property var filters: ["*"]
    property string title: qsTr("Select a file")
    property bool showHidden: false

    signal accepted(string path)
    signal rejected()

    readonly property bool selectionValid: {
        const file = folderContents.currentItem?.modelData;
        if (!file)
            return false;
        if (file.isDir)
            return false;
        if (filters.includes("*"))
            return true;
        return filters.includes(file.suffix.toLowerCase()) || filters.includes(file.suffix);
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
