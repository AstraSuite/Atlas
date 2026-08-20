import QtQuick
import QtQuick.Templates as T
import "../"
import prism

T.Slider {
    id: root

    property int radius: Tokens.rounding.full
    property bool interactionOnMove: true
    readonly property bool dragging: mouse.pressed

    property color fgColour: enabled ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3onSurface, 0.38)
    property color bgColour: enabled ? Colours.palette.m3secondaryContainer : Qt.alpha(Colours.palette.m3onSurface, 0.1)

    property real pos: visualPosition
    property real filledWidth

    signal interaction(real v)
    signal released(real v)

    Component.onCompleted: filledWidth = Qt.binding(() => (width - handle.implicitWidth - handle.anchors.leftMargin) * pos)

    implicitWidth: 80
    implicitHeight: 8

    contentItem: Item {
        anchors.fill: parent

        StyledRect {
            id: remaining

            anchors.left: handle.right
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.spacing.extraSmall

            implicitHeight: 6
            opacity: Math.min(width, 10) / 10

            radius: root.radius
            color: root.bgColour
        }

        StyledRect {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 2

            implicitWidth: 4
            implicitHeight: 4
            opacity: remaining.opacity

            radius: Tokens.rounding.full
            color: root.fgColour
        }

        StyledRect {
            id: handle

            anchors.left: filled.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 2

            implicitWidth: 3
            implicitHeight: mouse.pressed ? 18 : 14

            radius: Tokens.rounding.full
            color: root.fgColour

            Behavior on implicitHeight {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        StyledRect {
            id: filled

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            implicitWidth: root.filledWidth
            implicitHeight: 6

            radius: root.radius
            color: root.fgColour
        }
    }

    Binding {
        id: posBinding

        target: root
        property: "pos"
        value: Math.min(Math.max(mouse.pressStartPos + mouse.dragMovement, 0), 1)
        when: mouse.pressed
    }

    MouseArea {
        id: mouse

        property real pressStartX
        property real pressStartPos
        property real dragMovement

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        preventStealing: true
        implicitHeight: 18

        onPressed: e => {
            widthBehavior.enabled = false;
            pressStartX = e.x;
            pressStartPos = root.visualPosition;
            const clickPos = Math.min(Math.max(e.x / width, 0), 1);
            const actualVal = root.from + clickPos * (root.to - root.from);
            root.value = actualVal;
            root.interaction(actualVal);
        }
        onPositionChanged: e => {
            dragMovement = (e.x - pressStartX) / width;
            const curPos = Math.min(Math.max(pressStartPos + dragMovement, 0), 1);
            const actualVal = root.from + curPos * (root.to - root.from);
            root.value = actualVal;
            if (root.interactionOnMove)
                root.interaction(actualVal);
        }
        onReleased: e => {
            const clickPos = e.x / width;
            const finalPos = mouse.dragMovement !== 0 ? posBinding.value : Math.min(Math.max(clickPos, 0), 1);
            const actualVal = root.from + finalPos * (root.to - root.from);
            root.value = actualVal;
            root.interaction(actualVal);
            root.released(actualVal);
            widthBehavior.enabled = true;
            dragMovement = 0;
        }
    }

    Behavior on filledWidth {
        id: widthBehavior

        Anim {}
    }
}
