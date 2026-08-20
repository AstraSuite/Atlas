import QtQuick
import QtQuick.Templates as T
import "../"
import prism

T.Slider {
    id: root

    property int radius: Tokens.rounding.full
    property color fgColour: Colours.palette.m3primary
    property color bgColour: Colours.palette.m3secondaryContainer

    implicitWidth: 160
    implicitHeight: 32

    background: StyledRect {
        id: bgRect
        anchors.fill: parent
        radius: root.radius
        color: root.bgColour

        StyledRect {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.visualPosition * (parent.width - handle.width) + handle.width / 2
            radius: root.radius
            color: root.fgColour
        }
    }

    handle: StyledRect {
        id: handle
        x: root.visualPosition * (root.availableWidth - width)
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 24
        implicitHeight: 24
        radius: Tokens.rounding.full
        color: Colours.palette.m3inverseSurface

        MaterialIcon {
            anchors.centerIn: parent
            text: "drag_handle"
            color: Colours.palette.m3inverseOnSurface
            fontStyle: Tokens.font.icon.small
        }
    }
}
