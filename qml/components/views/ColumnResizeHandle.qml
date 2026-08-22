import QtQuick
import "../"
import prism

Item {
    id: root

    property string columnKey: ""
    property int defaultWidth: 100

    anchors.right: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: Tokens.spacing.small
    z: 5

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: parent.height * 0.5
        color: drag.containsMouse || drag.pressed
            ? Colours.palette.m3primary
            : Qt.alpha(Colours.palette.m3outlineVariant, 0.6)
    }

    MouseArea {
        id: drag

        property real originX: 0
        property int originWidth: 0

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.SplitHCursor
        preventStealing: true

        onPressed: event => {
            originX = mapToItem(null, event.x, 0).x;
            originWidth = AppController.detailsColumnWidths[root.columnKey] !== undefined
                ? AppController.detailsColumnWidths[root.columnKey]
                : root.defaultWidth;
        }

        onPositionChanged: event => {
            if (!pressed)
                return;
            const delta = mapToItem(null, event.x, 0).x - originX;
            AppController.setDetailsColumnWidth(root.columnKey, Math.round(originWidth - delta));
        }

        onDoubleClicked: AppController.setDetailsColumnWidth(root.columnKey, root.defaultWidth)
    }
}
