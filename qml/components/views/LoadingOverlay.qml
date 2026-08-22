import QtQuick
import "../"
import prism

Item {
    id: root

    property bool active: false
    property bool shown: false

    anchors.fill: parent
    z: 30
    visible: active || opacity > 0.01
    opacity: shown ? 1 : 0

    Behavior on opacity {
        Anim {
            type: Anim.FastEffects
        }
    }

    onActiveChanged: {
        if (active) {
            delay.restart();
        } else {
            delay.stop();
            root.shown = false;
        }
    }

    Timer {
        id: delay
        interval: 250
        onTriggered: root.shown = root.active
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.active
        acceptedButtons: Qt.AllButtons
        cursorShape: root.shown ? Qt.BusyCursor : Qt.ArrowCursor
        onWheel: wheel => wheel.accepted = true
    }

    StyledRect {
        anchors.centerIn: parent
        implicitWidth: 64
        implicitHeight: 64
        radius: Tokens.rounding.full
        color: Colours.tPalette.m3surfaceContainerHigh

        MaterialIcon {
            id: spinner
            anchors.centerIn: parent
            text: "progress_activity"
            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.large

            RotationAnimator on rotation {
                running: root.shown
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
            }
        }
    }
}
