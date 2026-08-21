import QtQuick
import QtQuick.Controls
import "../"
import prism

Item {
    id: root

    property url source: ""
    property real zoomScale: 1.0
    property real rotationAngle: 0
    property bool isLoaded: img.status === Image.Ready

    signal toggleControlsRequested()

    function zoomIn() {
        zoomScale = Math.min(8.0, zoomScale * 1.25);
    }

    function zoomOut() {
        zoomScale = Math.max(0.1, zoomScale / 1.25);
    }

    function resetZoom() {
        zoomScale = 1.0;
        flickable.contentX = (flickable.contentWidth - flickable.width) / 2;
        flickable.contentY = (flickable.contentHeight - flickable.height) / 2;
    }

    function rotateClockwise() {
        rotationAngle = (rotationAngle + 90) % 360;
    }

    function rotateCounterClockwise() {
        rotationAngle = (rotationAngle + 270) % 360;
    }

    clip: true

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: Math.max(width, imageContainer.width * root.zoomScale)
        contentHeight: Math.max(height, imageContainer.height * root.zoomScale)
        boundsBehavior: Flickable.StopAtBounds
        interactive: root.zoomScale > 1.05

        Item {
            id: imageContainer
            width: flickable.width
            height: flickable.height
            anchors.centerIn: parent
            scale: root.zoomScale

            Behavior on scale {
                Anim { type: Anim.FastEffects }
            }

            Image {
                id: img
                anchors.fill: parent
                source: root.source
                cache: false
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                mipmap: true
                rotation: root.rotationAngle

                Behavior on rotation {
                    RotationAnimation {
                        duration: 200
                        direction: RotationAnimation.Shortest
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    // Interactive MouseArea for Pan, Zoom, and Double-Click
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true

        property real lastX: 0
        property real lastY: 0
        property bool dragging: false

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                root.zoomIn();
            } else if (wheel.angleDelta.y < 0) {
                root.zoomOut();
            }
        }

        onDoubleClicked: mouse => {
            if (root.zoomScale > 1.1) {
                root.resetZoom();
            } else {
                root.zoomScale = 2.0;
            }
        }

        onPressed: mouse => {
            lastX = mouse.x;
            lastY = mouse.y;
            dragging = true;
        }

        onPositionChanged: mouse => {
            if (dragging && root.zoomScale > 1.0) {
                let dx = mouse.x - lastX;
                let dy = mouse.y - lastY;
                flickable.contentX = Math.max(0, Math.min(flickable.contentWidth - flickable.width, flickable.contentX - dx));
                flickable.contentY = Math.max(0, Math.min(flickable.contentHeight - flickable.height, flickable.contentY - dy));
                lastX = mouse.x;
                lastY = mouse.y;
            }
        }

        onReleased: dragging = false

        onClicked: mouse => {
            if (!dragging) {
                root.toggleControlsRequested();
            }
        }
    }

    // Loading Indicator
    Item {
        anchors.centerIn: parent
        visible: img.status === Image.Loading
        implicitWidth: 48
        implicitHeight: 48

        MaterialIcon {
            anchors.centerIn: parent
            text: "progress_activity"
            fontStyle: Tokens.font.icon.large
            color: Colours.palette.m3primary

            RotationAnimation on rotation {
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 1000
                running: img.status === Image.Loading
            }
        }
    }
}
