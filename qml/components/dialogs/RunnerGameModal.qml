import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "../"
import prism

Item {
    id: root

    property bool isOpen: false

    function open() {
        isOpen = true;
        RunnerGame.reset();
        gameCanvas.forceActiveFocus();
    }

    function close() {
        isOpen = false;
        RunnerGame.pause();
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
        color: Qt.alpha(Colours.palette.m3scrim, 0.65)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    StyledRect {
        id: dialogBox
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 860)
        height: Math.min(parent.height - 64, 480)
        radius: Tokens.rounding.large
        color: RunnerGame.isNightMode ? "#202124" : Colours.palette.m3surfaceContainerHigh

        layer.enabled: true
        layer.effect: Mask {
            maskSource: maskItem
        }

        scale: root.isOpen ? 1 : 0.88

        Behavior on scale {
            Anim {
                type: Anim.SlowEffects
            }
        }
        Behavior on color {
            CAnim {}
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header Bar
            Item {
                Layout.fillWidth: true
                implicitHeight: 44

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 12

                    MaterialIcon {
                        text: "sports_esports"
                        color: RunnerGame.isNightMode ? "#8ab4f8" : Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        text: qsTr("T-Rex Runner")
                        color: RunnerGame.isNightMode ? "#e8eaed" : Colours.palette.m3onSurface
                        font: Tokens.font.title.small
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledRect {
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: Tokens.rounding.full
                        color: closeBtnHover.containsMouse ? (RunnerGame.isNightMode ? Qt.alpha("#ffffff", 0.12) : Colours.tPalette.m3surfaceContainerHighest) : "transparent"

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "close"
                            color: RunnerGame.isNightMode ? "#e8eaed" : Colours.palette.m3onSurface
                            fontStyle: Tokens.font.icon.small
                        }

                        MouseArea {
                            id: closeBtnHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.close()
                        }
                    }
                }
            }

            // Game Play Area
            Item {
                id: gameContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Rectangle {
                    anchors.fill: parent
                    color: RunnerGame.isNightMode ? "#202124" : "#f7f7f7"
                    Behavior on color {
                        CAnim {}
                    }
                }

                Canvas {
                    id: gameCanvas
                    anchors.centerIn: parent
                    width: Math.min(gameContainer.width - 24, (gameContainer.height - 24) * 4)
                    height: width / 4.0 // 600 x 150 aspect ratio (4:1)
                    focus: true

                    readonly property real scaleFactor: width / 600.0
                    readonly property string spritePath: "qrc:/qt/qml/prism/assets/runner/assets/default_200_percent/200-offline-sprite.png"

                    onPaint: {
                        let ctx = getContext("2d");
                        ctx.save();
                        ctx.clearRect(0, 0, width, height);

                        if (!isImageLoaded(spritePath)) {
                            loadImage(spritePath);
                            ctx.restore();
                            return;
                        }

                        let sf = scaleFactor;

                        // Night mode background tint
                        if (RunnerGame.isNightMode) {
                            ctx.fillStyle = "#202124";
                            ctx.fillRect(0, 0, width, height);
                        }

                        // Draw Clouds
                        let clouds = RunnerGame.clouds;
                        for (let i = 0; i < clouds.length; ++i) {
                            let c = clouds[i];
                            ctx.drawImage(spritePath, 166, 2, 92, 28, c.x * sf, c.y * sf, 46 * sf, 14 * sf);
                        }

                        // Draw Ground Horizon Line
                        let groundY = 125 * sf;
                        let gx = (RunnerGame.groundX % 600) * sf;
                        ctx.drawImage(spritePath, 2, 104, 1200, 24, -gx, groundY, 600 * sf, 12 * sf);
                        ctx.drawImage(spritePath, 2, 104, 1200, 24, 600 * sf - gx, groundY, 600 * sf, 12 * sf);
                        ctx.drawImage(spritePath, 2, 104, 1200, 24, 1200 * sf - gx, groundY, 600 * sf, 12 * sf);

                        // Draw Obstacles
                        let obstacles = RunnerGame.obstacles;
                        for (let i = 0; i < obstacles.length; ++i) {
                            let obs = obstacles[i];
                            let ox = obs.x * sf;
                            let oType = obs.type;
                            let size = obs.size || 1;

                            if (oType === 0) {
                                // Small Cactus
                                let sw = 34 * size;
                                let dw = 17 * size * sf;
                                let dh = 35 * sf;
                                let oy = (128 - 35) * sf;
                                ctx.drawImage(spritePath, 446, 2, sw, 70, ox, oy, dw, dh);
                            } else if (oType === 1) {
                                // Large Cactus
                                let sw = 50 * size;
                                let dw = 25 * size * sf;
                                let dh = 50 * sf;
                                let oy = (128 - 50) * sf;
                                ctx.drawImage(spritePath, 652, 2, sw, 100, ox, oy, dw, dh);
                            } else if (oType === 2) {
                                // Pterodactyl
                                let frame = obs.frame || 0;
                                let sx = (frame === 0) ? 260 : 352;
                                let dw = 46 * sf;
                                let dh = 40 * sf;
                                let oy = (128 - obs.y - 40) * sf;
                                ctx.drawImage(spritePath, sx, 2, 92, 80, ox, oy, dw, dh);
                            }
                        }

                        // Draw T-Rex
                        let py = RunnerGame.playerY;
                        let pFrame = RunnerGame.playerFrame;
                        let isDucking = RunnerGame.isDucking;

                        if (isDucking) {
                            let sx = (pFrame === 4) ? 2324 : 2206;
                            let dw = 59 * sf;
                            let dh = 30 * sf;
                            let px = 40 * sf;
                            let oy = (128 - 28 - py) * sf;
                            ctx.drawImage(spritePath, sx, 34, 118, 60, px, oy, dw, dh);
                        } else {
                            let sx = 1678;
                            if (pFrame === 1) sx = 1766; // Blink
                            else if (pFrame === 0) sx = 1854; // Run Leg 0
                            else if (pFrame === 1 && RunnerGame.state === 1) sx = 1942; // Run Leg 1
                            else if (pFrame === 2) sx = 1678; // Jump
                            else if (pFrame === 5) sx = 2030; // Crashed

                            if (RunnerGame.state === 1) {
                                sx = (pFrame === 0) ? 1854 : (pFrame === 1 ? 1942 : 1678);
                            } else if (RunnerGame.state === 2) {
                                sx = 2030; // Crashed
                            } else if (RunnerGame.state === 0) {
                                sx = (pFrame === 1) ? 1766 : 1678;
                            }

                            let dw = 44 * sf;
                            let dh = 47 * sf;
                            let px = 40 * sf;
                            let oy = (128 - 47 - py) * sf;
                            ctx.drawImage(spritePath, sx, 2, 88, 94, px, oy, dw, dh);
                        }

                        // Draw Scores
                        function drawScoreDigits(scoreVal, targetX, alpha) {
                            let sStr = ("00000" + scoreVal).slice(-5);
                            ctx.save();
                            ctx.globalAlpha = alpha;
                            for (let d = 0; d < 5; ++d) {
                                let digit = parseInt(sStr[d]);
                                let sx = 1294 + digit * 20;
                                ctx.drawImage(spritePath, sx, 2, 20, 24, (targetX + d * 11) * sf, 12 * sf, 10 * sf, 12 * sf);
                            }
                            ctx.restore();
                        }

                        // High Score
                        if (RunnerGame.highScore > 0) {
                            ctx.save();
                            ctx.globalAlpha = 0.55;
                            // "HI " text
                            ctx.drawImage(spritePath, 1494, 2, 40, 24, 460 * sf, 12 * sf, 20 * sf, 12 * sf);
                            ctx.restore();
                            drawScoreDigits(RunnerGame.highScore, 485, 0.55);
                        }

                        // Current Score
                        drawScoreDigits(RunnerGame.score, 545, 1.0);

                        // Draw Game Over & Restart
                        if (RunnerGame.state === 2) {
                            // "GAME OVER" text
                            let goW = 191 * sf;
                            let goH = 11 * sf;
                            let goX = (300 - 191 / 2) * sf;
                            let goY = 45 * sf;
                            ctx.drawImage(spritePath, 1294, 28, 382, 22, goX, goY, goW, goH);

                            // Restart Button
                            let rW = 36 * sf;
                            let rH = 32 * sf;
                            let rX = (300 - 18) * sf;
                            let rY = 70 * sf;
                            ctx.drawImage(spritePath, 2, 2, 72, 64, rX, rY, rW, rH);
                        }

                        ctx.restore();
                    }

                    Connections {
                        target: RunnerGame
                        function onFrameUpdated() {
                            gameCanvas.requestPaint();
                        }
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Space || event.key === Qt.Key_Up) {
                            RunnerGame.jump();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            RunnerGame.setDucking(true);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (RunnerGame.state === 2) {
                                RunnerGame.restart();
                                event.accepted = true;
                            }
                        }
                    }

                    Keys.onReleased: event => {
                        if (event.key === Qt.Key_Down) {
                            RunnerGame.setDucking(false);
                            event.accepted = true;
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            gameCanvas.forceActiveFocus();
                            RunnerGame.jump();
                        }
                    }
                }
            }

            // Controls Hint Footer
            Item {
                Layout.fillWidth: true
                implicitHeight: 36

                StyledText {
                    anchors.centerIn: parent
                    text: qsTr("Press Space or Up to Jump • Down to Duck • Click to Start")
                    color: RunnerGame.isNightMode ? "#9aa0a6" : Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                }
            }
        }
    }

    Item {
        id: maskItem
        width: dialogBox.width
        height: dialogBox.height
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.large
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.isOpen
        onActivated: root.close()
    }
}
