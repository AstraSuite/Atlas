import QtQuick
import QtQuick.Shapes
import "../"
import prism

Item {
    id: root

    property bool running: true
    property real size: 24
    property real strokeWidth: Tokens.padding.extraSmall || 3
    property color color: Colours.palette.m3primary
    property color trackColor: Qt.alpha(Colours.palette.m3secondaryContainer, 0.4)
    property bool showTrack: true

    implicitWidth: size
    implicitHeight: size

    visible: opacity > 0.001
    opacity: running ? 1.0 : 0.0
    Behavior on opacity {
        Anim { type: Anim.FastEffects }
    }

    readonly property real arcRadius: Math.max(1, (Math.min(width, height) - strokeWidth) / 2)

    property real progress: 0
    property real startAngle: 0
    property real sweepAngle: 45

    function getFraction(playtime, start, dur) {
        return Math.max(0, Math.min(1, (playtime - start) / dur));
    }

    function bezierValue(t) {
        // Fast-out slow-in curve matching (0.4, 0.0), (0.2, 1.0), (1.0, 1.0)
        let u = 1 - t;
        return 3 * u * u * t * 0.0 + 3 * u * t * t * 1.0 + t * t * t;
    }

    onProgressChanged: {
        let playtime = progress * 5400;
        let startDeg = 1520 * progress - 20;
        let endDeg = 1520 * progress;

        let expandDelays = [0, 1350, 2700, 4050];
        let collapseDelays = [667, 2017, 3367, 4717];

        for (let i = 0; i < 4; ++i) {
            let fExpand = getFraction(playtime, expandDelays[i], 667);
            endDeg += bezierValue(fExpand) * 250;

            let fCollapse = getFraction(playtime, collapseDelays[i], 667);
            startDeg += bezierValue(fCollapse) * 250;
        }

        root.startAngle = startDeg;
        root.sweepAngle = Math.max(1, endDeg - startDeg);
    }

    NumberAnimation on progress {
        running: root.running && root.visible
        loops: Animation.Infinite
        from: 0
        to: 1
        duration: 5400
        easing.type: Easing.Linear
    }

    // Track Background
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
}

