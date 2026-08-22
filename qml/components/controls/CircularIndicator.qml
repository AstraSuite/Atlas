import QtQuick
import QtQuick.Shapes
import "../"
import prism

Item {
    id: root

    property bool running: true
    property real size: 24
    property real strokeWidth: 3
    property color color: Colours.palette.m3primary
    property color trackColor: Qt.alpha(Colours.palette.m3primary, 0.15)
    property bool showTrack: false

    implicitWidth: size
    implicitHeight: size

    visible: opacity > 0.001
    opacity: running ? 1.0 : 0.0
    Behavior on opacity {
        Anim { type: Anim.FastEffects }
    }

    readonly property real arcRadius: Math.max(1, (Math.min(width, height) - strokeWidth) / 2)

    // Indeterminate animation values
    property real startAngle: 0
    property real sweepAngle: 45

    // Track Background (optional)
    Shape {
        id: trackShape
        anchors.fill: parent
        visible: root.showTrack
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.trackColor
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    // Active Indicator Arc
    Shape {
        id: shape
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.color
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: root.startAngle
                sweepAngle: root.sweepAngle
            }
        }
    }

    // Material 3 circular indeterminate animation
    SequentialAnimation {
        running: root.running && root.visible
        loops: Animation.Infinite

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "startAngle"
                from: 0
                to: 360
                duration: 1333
                easing.type: Easing.Linear
            }
            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "sweepAngle"
                    from: 25
                    to: 270
                    duration: 666
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: root
                    property: "sweepAngle"
                    from: 270
                    to: 25
                    duration: 667
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
