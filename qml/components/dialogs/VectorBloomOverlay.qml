import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import "../"
import atlas

Item {
    id: root

    property bool isOpen: false

    function open() {
        isOpen = true;
        particleCanvas.initParticles();
        particleTimer.restart();
        vectorBloom.restartAnimation();
    }

    function close() {
        isOpen = false;
        particleTimer.stop();
    }

    anchors.fill: parent
    visible: opacity > 0
    opacity: isOpen ? 1 : 0
    z: 9999

    Behavior on opacity {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.72)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Canvas {
        id: particleCanvas
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject

        property var particles: []

        function initParticles() {
            let list = [];
            for (let i = 0; i < 90; i++) {
                list.push({
                    x: Math.random() * width,
                    y: Math.random() * height,
                    size: Math.random() * 2.5 + 0.8,
                    alpha: Math.random() * 0.85 + 0.15,
                    speed: Math.random() * 0.35 + 0.08,
                    twinkleSpeed: Math.random() * 0.035 + 0.01,
                    twinkleDir: Math.random() > 0.5 ? 1 : -1,
                    r: Math.floor(Math.random() * 60 + 195),
                    g: Math.floor(Math.random() * 60 + 200),
                    b: 255
                });
            }
            particles = list;
            requestPaint();
        }

        onPaint: {
            let ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            for (let i = 0; i < particles.length; i++) {
                let p = particles[i];
                ctx.fillStyle = "rgba(" + p.r + ", " + p.g + ", " + p.b + ", " + p.alpha + ")";
                ctx.beginPath();
                ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
                ctx.fill();

                if (p.size > 2.0) {
                    ctx.fillStyle = "rgba(255, 255, 255, " + (p.alpha * 0.8) + ")";
                    ctx.beginPath();
                    ctx.arc(p.x, p.y, p.size * 0.4, 0, Math.PI * 2);
                    ctx.fill();
                }
            }
        }
    }

    Timer {
        id: particleTimer
        interval: 30
        repeat: true
        running: root.isOpen
        onTriggered: {
            for (let i = 0; i < particleCanvas.particles.length; i++) {
                let p = particleCanvas.particles[i];
                p.y -= p.speed;
                if (p.y < 0) {
                    p.y = root.height;
                    p.x = Math.random() * root.width;
                }
                p.alpha += p.twinkleSpeed * p.twinkleDir;
                if (p.alpha > 0.95) {
                    p.alpha = 0.95;
                    p.twinkleDir = -1;
                } else if (p.alpha < 0.15) {
                    p.alpha = 0.15;
                    p.twinkleDir = 1;
                }
            }
            particleCanvas.requestPaint();
        }
    }

    StyledRect {
        id: presentationBox
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 480)
        implicitHeight: boxContent.implicitHeight + 64
        radius: Tokens.rounding.extraLarge
        color: Colours.palette.m3surfaceContainerHigh

        scale: root.isOpen ? 1 : 0.88

        Behavior on scale {
            Anim {
                type: Anim.SlowEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: boxContent
            anchors.fill: parent
            anchors.margins: 32
            spacing: 28

            Item {
                id: vectorBloom
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 200
                implicitHeight: 141.22

                property real blurAmount: 0.0
                property real p1Opacity: 0.0
                property real p2Opacity: 0.0
                property real p3Opacity: 0.0
                property real p1Scale: 0.0
                property real p2Scale: 0.0
                property real p3Scale: 0.0

                function restartAnimation() {
                    introAnim.stop();
                    bloomInner.rotation = 0;
                    bloomInner.scale = 0;
                    bloomInner.opacity = 0;
                    blurAmount = 1.0;
                    p1Opacity = 0.0;
                    p2Opacity = 0.0;
                    p3Opacity = 0.0;
                    p1Scale = 0.0;
                    p2Scale = 0.0;
                    p3Scale = 0.0;
                    introAnim.start();
                }

                Item {
                    id: bloomInner
                    anchors.centerIn: parent
                    width: 128
                    height: 90.38
                    scale: vectorBloom.width / 128
                    transformOrigin: Item.Center

                    property color primaryColor: Colours.palette.m3primary
                    property color secondaryColor: Colours.palette.m3onSurface

                    layer.enabled: vectorBloom.blurAmount > 0.01
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: vectorBloom.blurAmount
                        blurMax: 40
                    }

                    Shape {
                        id: shape1
                        anchors.centerIn: parent
                        width: 128
                        height: 90.38
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            fillColor: bloomInner.primaryColor
                            strokeColor: "transparent"

                            PathSvg {
                                path: AppIntegration.getSystemGeometry(1)
                            }
                        }
                    }

                    Shape {
                        id: shape2
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            fillColor: bloomInner.secondaryColor
                            strokeColor: "transparent"

                            PathSvg {
                                path: AppIntegration.getSystemGeometry(2)
                            }
                        }
                    }

                    Shape {
                        id: accent1
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        opacity: vectorBloom.p1Opacity
                        scale: vectorBloom.p1Scale
                        transformOrigin: Item.Center

                        ShapePath {
                            fillColor: bloomInner.primaryColor
                            strokeColor: "transparent"

                            PathSvg {
                                path: AppIntegration.getSystemGeometry(3)
                            }
                        }
                    }

                    Shape {
                        id: accent2
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        opacity: vectorBloom.p2Opacity
                        scale: vectorBloom.p2Scale
                        transformOrigin: Item.Center

                        ShapePath {
                            fillColor: bloomInner.primaryColor
                            strokeColor: "transparent"

                            PathSvg {
                                path: AppIntegration.getSystemGeometry(4)
                            }
                        }
                    }

                    Shape {
                        id: accent3
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        opacity: vectorBloom.p3Opacity
                        scale: vectorBloom.p3Scale
                        transformOrigin: Item.Center

                        ShapePath {
                            fillColor: bloomInner.primaryColor
                            strokeColor: "transparent"

                            PathSvg {
                                path: AppIntegration.getSystemGeometry(5)
                            }
                        }
                    }
                }

                SequentialAnimation {
                    id: introAnim
                    running: false

                    ParallelAnimation {
                        SequentialAnimation {
                            NumberAnimation {
                                target: bloomInner
                                property: "rotation"
                                from: 0
                                to: 750
                                duration: 1000
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                target: bloomInner
                                property: "rotation"
                                from: 750
                                to: 710
                                duration: 300
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: bloomInner
                                property: "rotation"
                                from: 710
                                to: 725
                                duration: 350
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: bloomInner
                                property: "rotation"
                                from: 725
                                to: 720
                                duration: 250
                                easing.type: Easing.OutQuad
                            }
                            ScriptAction {
                                script: bloomInner.rotation = 0
                            }
                        }

                        SequentialAnimation {
                            NumberAnimation {
                                target: bloomInner
                                property: "scale"
                                from: 0.0
                                to: (vectorBloom.width / 128) * 1.08
                                duration: 1000
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                target: bloomInner
                                property: "scale"
                                from: (vectorBloom.width / 128) * 1.08
                                to: (vectorBloom.width / 128) * 0.96
                                duration: 200
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: bloomInner
                                property: "scale"
                                from: (vectorBloom.width / 128) * 0.96
                                to: (vectorBloom.width / 128)
                                duration: 250
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.05
                            }
                        }

                        NumberAnimation {
                            target: bloomInner
                            property: "opacity"
                            from: 0.0
                            to: 1.0
                            duration: 600
                            easing.type: Easing.InOutQuad
                        }

                        NumberAnimation {
                            target: vectorBloom
                            property: "blurAmount"
                            from: 1.0
                            to: 0.0
                            duration: 900
                            easing.type: Easing.OutCubic
                        }

                        SequentialAnimation {
                            PauseAnimation { duration: 1100 }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: vectorBloom
                                    property: "p1Opacity"
                                    from: 0.0
                                    to: 1.0
                                    duration: 700
                                    easing.type: Easing.InOutQuad
                                }
                                SequentialAnimation {
                                    NumberAnimation {
                                        target: vectorBloom
                                        property: "p1Scale"
                                        from: 0.0
                                        to: 1.08
                                        duration: 500
                                        easing.type: Easing.OutQuad
                                    }
                                    NumberAnimation {
                                        target: vectorBloom
                                        property: "p1Scale"
                                        from: 1.08
                                        to: 1.0
                                        duration: 400
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                            }
                        }

                        SequentialAnimation {
                            PauseAnimation { duration: 1250 }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: vectorBloom
                                    property: "p2Opacity"
                                    from: 0.0
                                    to: 1.0
                                    duration: 700
                                    easing.type: Easing.InOutQuad
                                }
                                SequentialAnimation {
                                    NumberAnimation {
                                        target: vectorBloom
                                        property: "p2Scale"
                                        from: 0.0
                                        to: 1.08
                                        duration: 500
                                        easing.type: Easing.OutQuad
                                    }
                                    NumberAnimation {
                                        target: vectorBloom
                                        property: "p2Scale"
                                        from: 1.08
                                        to: 1.0
                                        duration: 400
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                            }
                        }

                        SequentialAnimation {
                            PauseAnimation { duration: 1400 }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: vectorBloom
                                    property: "p3Opacity"
                                    from: 0.0
                                    to: 1.0
                                    duration: 700
                                    easing.type: Easing.InOutQuad
                                }
                                SequentialAnimation {
                                    NumberAnimation {
                                        target: vectorBloom
                                        property: "p3Scale"
                                        from: 0.0
                                        to: 1.08
                                        duration: 500
                                        easing.type: Easing.OutQuad
                                    }
                                    NumberAnimation {
                                        target: vectorBloom
                                        property: "p3Scale"
                                        from: 1.08
                                        to: 1.0
                                        duration: 400
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                            }
                        }
                    }
                }

                SequentialAnimation {
                    running: root.isOpen
                    loops: Animation.Infinite

                    PauseAnimation { duration: 2500 }

                    ParallelAnimation {
                        SequentialAnimation {
                            loops: Animation.Infinite
                            NumberAnimation {
                                target: accent1
                                property: "y"
                                from: 0; to: -5
                                duration: 2500
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: accent1
                                property: "y"
                                from: -5; to: 0
                                duration: 2500
                                easing.type: Easing.InOutQuad
                            }
                        }

                        SequentialAnimation {
                            loops: Animation.Infinite
                            NumberAnimation {
                                target: accent2
                                property: "y"
                                from: 0; to: 5
                                duration: 3000
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: accent2
                                property: "y"
                                from: 5; to: 0
                                duration: 3000
                                easing.type: Easing.InOutQuad
                            }
                        }

                        SequentialAnimation {
                            loops: Animation.Infinite
                            NumberAnimation {
                                target: accent3
                                property: "y"
                                from: 0; to: -5
                                duration: 2800
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: accent3
                                property: "y"
                                from: -5; to: 0
                                duration: 2800
                                easing.type: Easing.InOutQuad
                            }
                        }

                        SequentialAnimation {
                            loops: Animation.Infinite
                            NumberAnimation {
                                target: vectorBloom
                                property: "p1Scale"
                                from: 1.0; to: 1.08
                                duration: 2500
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: vectorBloom
                                property: "p1Scale"
                                from: 1.08; to: 1.0
                                duration: 2500
                                easing.type: Easing.InOutQuad
                            }
                        }

                        SequentialAnimation {
                            loops: Animation.Infinite
                            NumberAnimation {
                                target: vectorBloom
                                property: "p2Scale"
                                from: 1.0; to: 1.12
                                duration: 3000
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: vectorBloom
                                property: "p2Scale"
                                from: 1.12; to: 1.0
                                duration: 3000
                                easing.type: Easing.InOutQuad
                            }
                        }

                        SequentialAnimation {
                            loops: Animation.Infinite
                            NumberAnimation {
                                target: vectorBloom
                                property: "p3Scale"
                                from: 1.0; to: 1.08
                                duration: 2800
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: vectorBloom
                                property: "p3Scale"
                                from: 1.08; to: 1.0
                                duration: 2800
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: 40

                StyledRect {
                    anchors.centerIn: parent
                    implicitHeight: 38
                    implicitWidth: 120
                    radius: Tokens.rounding.full
                    color: dismissHover.containsMouse ? Colours.palette.m3primaryContainer : Colours.palette.m3secondaryContainer

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Close")
                        font: Tokens.font.label.large
                        color: dismissHover.containsMouse ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSecondaryContainer
                    }

                    MouseArea {
                        id: dismissHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.isOpen
        onActivated: root.close()
    }
}
