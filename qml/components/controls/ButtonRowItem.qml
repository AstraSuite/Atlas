import QtQuick
import QtQuick.Layouts
import "../"
import "../containers"
import prism

ConnectedRect {
    id: root

    property string icon: ""
    property string text: ""
    property bool checked: false
    property bool disabled: false

    signal clicked()

    horizontal: true
    Layout.fillWidth: true
    implicitHeight: 40

    color: root.checked
        ? Colours.palette.m3primaryContainer
        : (itemHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer)

    Behavior on color {
        Anim { type: Anim.FastEffects }
    }

    StateLayer {
        anchors.fill: parent
        topLeftRadius: parent.topLeftRadius
        topRightRadius: parent.topRightRadius
        bottomLeftRadius: parent.bottomLeftRadius
        bottomRightRadius: parent.bottomRightRadius
        color: root.checked ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
        disabled: root.disabled
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 6

        MaterialIcon {
            visible: root.icon.length > 0
            text: root.icon
            fontStyle: Tokens.font.icon.small
            color: root.checked ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            text: root.text
            font: Tokens.font.body.small
            color: root.checked ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: itemHover
        anchors.fill: parent
        hoverEnabled: !root.disabled
        cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: if (!root.disabled) root.clicked()
    }
}
