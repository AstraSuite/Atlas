import QtQuick
import QtQuick.Layouts
import "../"
import prism

Item {
    id: root

    property string path: ""
    property bool isSearching: false
    property string searchQuery: ""
    readonly property bool isTrash: path.indexOf("/Trash") !== -1 || path.indexOf("trash:") !== -1

    signal createFolder()
    signal createFile()
    signal paste()

    anchors.centerIn: parent
    width: Math.min(420, parent.width - 32)
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: Tokens.spacing.medium

        // Centered Icon Circle
        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 80
            implicitHeight: 80
            radius: Tokens.rounding.full
            color: Colours.tPalette.m3surfaceContainerHigh

            MaterialIcon {
                anchors.centerIn: parent
                text: root.isTrash ? "delete_outline" : (root.isSearching ? "search_off" : "folder_open")
                fontStyle: Tokens.font.icon.extraLarge
                color: root.isTrash ? Colours.palette.m3error : Colours.palette.m3primary
            }
        }

        // Title
        StyledText {
            Layout.fillWidth: true
            text: root.isTrash ? qsTr("Trash is empty") : (root.isSearching ? qsTr("No matching files found") : qsTr("This folder is empty"))
            font: Tokens.font.title.medium
            color: Colours.palette.m3onSurface
            horizontalAlignment: Text.AlignHCenter
        }

        // Subtitle description
        StyledText {
            Layout.fillWidth: true
            text: root.isTrash
                ? qsTr("Items you delete will be safely stored here until you empty the trash.")
                : (root.isSearching
                    ? qsTr("No items matched \"%1\". Try checking spelling or toggling hidden files.").arg(root.searchQuery)
                    : qsTr("Drop files here, or create a new file or directory to get started."))
            font: Tokens.font.body.medium
            color: Colours.palette.m3onSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        // Helpful Action Buttons
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.spacing.medium
            spacing: Tokens.spacing.medium
            visible: !root.isTrash && !root.isSearching

            // New Folder Button
            StyledRect {
                implicitHeight: 42
                implicitWidth: b1Content.implicitWidth + 36
                radius: Tokens.rounding.full
                color: b1Hover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainerHigh

                RowLayout {
                    id: b1Content
                    anchors.centerIn: parent
                    spacing: 8
                    MaterialIcon { text: "create_new_folder"; fontStyle: Tokens.font.icon.small; color: Colours.palette.m3primary }
                    StyledText { text: qsTr("New Folder"); font: Tokens.font.label.large; color: Colours.palette.m3onSurface }
                }

                MouseArea {
                    id: b1Hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.createFolder()
                }
            }

            // New File Button
            StyledRect {
                implicitHeight: 42
                implicitWidth: b2Content.implicitWidth + 36
                radius: Tokens.rounding.full
                color: b2Hover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainerHigh

                RowLayout {
                    id: b2Content
                    anchors.centerIn: parent
                    spacing: 8
                    MaterialIcon { text: "note_add"; fontStyle: Tokens.font.icon.small; color: Colours.palette.m3primary }
                    StyledText { text: qsTr("New File"); font: Tokens.font.label.large; color: Colours.palette.m3onSurface }
                }

                MouseArea {
                    id: b2Hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.createFile()
                }
            }
        }
    }
}
