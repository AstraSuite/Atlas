import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtMultimedia
import "../"
import atlas

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

    // Sound Effects - Created lazily so Qt Multimedia only initializes when the game opens
    Loader {
        id: soundsLoader
        active: root.isOpen

        sourceComponent: Item {
            property alias press: soundPress
            property alias hit: soundHit
            property alias score: soundScore

            SoundEffect {
                id: soundPress
                source: "qrc:/qt/qml/atlas/assets/runner/sounds/press.wav"
            }

            SoundEffect {
                id: soundHit
                source: "qrc:/qt/qml/atlas/assets/runner/sounds/hit.wav"
            }

            SoundEffect {
                id: soundScore
                source: "qrc:/qt/qml/atlas/assets/runner/sounds/reached.wav"
            }
        }
    }

    // Modal Scrim
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.65)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // Modal Dialog Box
    StyledRect {
        id: dialogBox
        anchors.centerIn: parent
        width: Math.min(parent.width - 32, 920)
        height: Math.min(parent.height - 48, 520)
        radius: Tokens.rounding.large
        color: RunnerGame.isNightMode ? "#202124" : "#f7f7f7"
        border.width: 1
        border.color: RunnerGame.isNightMode ? Qt.alpha("#8ab4f8", 0.35) : Qt.alpha("#000000", 0.12)
        clip: true

        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSpreadAtMin: 1
            maskThresholdMin: 0.5
            maskSource: maskSourceItem
        }

        scale: root.isOpen ? 1.0 : 0.92

        Behavior on scale {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header Bar
            Item {
                Layout.fillWidth: true
                implicitHeight: 48

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 16

                    MaterialIcon {
                        text: "sports_esports"
                        color: RunnerGame.isNightMode ? "#8ab4f8" : "#5f6368"
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        text: qsTr("T-Rex Runner")
                        color: RunnerGame.isNightMode ? "#e8eaed" : "#202124"
                        font: Tokens.font.title.small
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Item {
                        implicitWidth: 32
                        implicitHeight: 32

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "close"
                            color: RunnerGame.isNightMode ? "#e8eaed" : "#5f6368"
                            fontStyle: Tokens.font.icon.small
                        }

                        StateLayer {
                            radius: Tokens.rounding.full
                            color: RunnerGame.isNightMode ? "#ffffff" : Colours.palette.m3onSurface
                            onClicked: root.close()
                        }
                    }
                }
            }

            // Game Playfield Area
            Item {
                id: gameContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Canvas {
                    id: gameCanvas
                    anchors.fill: parent
                    focus: true

                    readonly property string normalSprite: "qrc:/qt/qml/atlas/assets/runner/assets/default_200_percent/200-offline-sprite.png"
                    readonly property string invertedSprite: "qrc:/qt/qml/atlas/assets/runner/assets/default_200_percent/200-offline-sprite-inverted.png"
                    readonly property string currentSprite: RunnerGame.isNightMode ? invertedSprite : normalSprite

                    onPaint: {
                        let ctx = getContext("2d");
                        ctx.save();
                        ctx.clearRect(0, 0, width, height);

                        if (!isImageLoaded(normalSprite)) loadImage(normalSprite);
                        if (!isImageLoaded(invertedSprite)) loadImage(invertedSprite);
                        if (!isImageLoaded(currentSprite)) {
                            ctx.restore();
                            return;
                        }

                        // Responsive scaling centered in the canvas
                        let sf = Math.min(width / 600.0, height / 150.0);
                        let offsetX = (width - 600 * sf) / 2.0;
                        let offsetY = (height - 150 * sf) / 2.0;

                        ctx.translate(offsetX, offsetY);

                        let intro = RunnerGame.introProgress;
                        let isWaiting = (RunnerGame.state === 0);
                        let isPlaying = (RunnerGame.state === 1);
                        let isCrashed = (RunnerGame.state === 2);

                        // Night Mode Stars & Moon
                        if (RunnerGame.isNightMode) {
                            ctx.drawImage(currentSprite, 954, 2, 40, 80, 500 * sf, 15 * sf, 20 * sf, 40 * sf);
                            let stars = RunnerGame.stars;
                            for (let i = 0; i < stars.length; ++i) {
                                let st = stars[i];
                                ctx.drawImage(currentSprite, 1276, 2, 18, 18, st.x * sf, st.y * sf, 9 * sf, 9 * sf);
                            }
                        }

                        // Clouds
                        if (!isWaiting) {
                            let clouds = RunnerGame.clouds;
                            for (let i = 0; i < clouds.length; ++i) {
                                let c = clouds[i];
                                ctx.drawImage(currentSprite, 166, 2, 92, 28, c.x * sf, c.y * sf, 46 * sf, 14 * sf);
                            }
                        }

                        // Ground Horizon Segments
                        let groundY = 127 * sf;
                        ctx.save();
                        if (isWaiting) {
                            ctx.beginPath();
                            ctx.rect(0, 0, 44 * sf, 150 * sf);
                            ctx.clip();
                        } else if (intro < 1.0) {
                            ctx.beginPath();
                            let visW = 44.0 + (600.0 - 44.0) * intro;
                            ctx.rect(0, 0, visW * sf, 150 * sf);
                            ctx.clip();
                        }

                        let segs = RunnerGame.groundSegments;
                        for (let i = 0; i < segs.length; ++i) {
                            let seg = segs[i];
                            ctx.drawImage(currentSprite, seg.sourceX, 104, 1200, 24, seg.x * sf, groundY, 600 * sf, 12 * sf);
                        }
                        ctx.restore();

                        // Obstacles
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
                                let oy = (140 - 35) * sf;
                                ctx.drawImage(currentSprite, 446, 2, sw, 70, ox, oy, dw, dh);
                            } else if (oType === 1) {
                                // Large Cactus
                                let sw = 50 * size;
                                let dw = 25 * size * sf;
                                let dh = 50 * sf;
                                let oy = (140 - 50) * sf;
                                ctx.drawImage(currentSprite, 652, 2, sw, 100, ox, oy, dw, dh);
                            } else if (oType === 2) {
                                // Pterodactyl
                                let frame = obs.frame || 0;
                                let sx = (frame === 0) ? 260 : 352;
                                let dw = 46 * sf;
                                let dh = 40 * sf;
                                let oy = obs.y * sf;
                                ctx.drawImage(currentSprite, sx, 2, 92, 80, ox, oy, dw, dh);
                            }
                        }

                        // T-Rex Character
                        let tX = RunnerGame.playerX * sf;
                        let tY = RunnerGame.playerY * sf;
                        let pFrame = RunnerGame.playerFrame;
                        let isDucking = RunnerGame.isDucking;

                        if (isDucking && !isCrashed) {
                            let sx = (pFrame === 4) ? 2321 : 2203;
                            let dw = 59 * sf;
                            let dh = 29 * sf;
                            let oy = (RunnerGame.playerY + 18) * sf;
                            ctx.drawImage(currentSprite, sx, 36, 118, 58, tX, oy, dw, dh);
                        } else {
                            let sx = 1678;
                            if (isCrashed) {
                                sx = 2030; // Crashed eyes
                            } else if (isPlaying) {
                                if (RunnerGame.isJumping) {
                                    sx = 1678;
                                } else {
                                    sx = (pFrame === 0) ? 1854 : 1942;
                                }
                            } else if (isWaiting) {
                                sx = (pFrame === 1) ? 1766 : 1678;
                            }

                            let dw = 44 * sf;
                            let dh = 47 * sf;
                            ctx.drawImage(currentSprite, sx, 2, 88, 94, tX, tY, dw, dh);
                        }

                        // Score & High Score
                        function drawScoreDigits(scoreVal, targetX, alpha) {
                            let sStr = ("00000" + scoreVal).slice(-5);
                            ctx.save();
                            ctx.globalAlpha = alpha;
                            for (let d = 0; d < 5; ++d) {
                                let digit = parseInt(sStr[d]);
                                let sx = 1294 + digit * 20;
                                ctx.drawImage(currentSprite, sx, 2, 20, 24, (targetX + d * 11) * sf, 12 * sf, 10 * sf, 12 * sf);
                            }
                            ctx.restore();
                        }

                        if (!isWaiting || RunnerGame.score > 0 || RunnerGame.highScore > 0) {
                            if (RunnerGame.highScore > 0) {
                                ctx.save();
                                ctx.globalAlpha = 0.55;
                                ctx.drawImage(currentSprite, 1494, 2, 40, 24, 460 * sf, 12 * sf, 20 * sf, 12 * sf);
                                ctx.restore();
                                drawScoreDigits(RunnerGame.highScore, 485, 0.55);
                            }

                            drawScoreDigits(RunnerGame.score, 545, 1.0);
                        }

                        // Game Over Panel
                        if (isCrashed) {
                            let goW = 191 * sf;
                            let goH = 11 * sf;
                            let goX = (300 - 191 / 2) * sf;
                            let goY = 40 * sf;
                            ctx.drawImage(currentSprite, 1294, 28, 382, 22, goX, goY, goW, goH);

                            let rW = 36 * sf;
                            let rH = 32 * sf;
                            let rX = (300 - 18) * sf;
                            let rY = 65 * sf;
                            ctx.drawImage(currentSprite, 2, 2, 72, 64, rX, rY, rW, rH);
                        }

                        ctx.restore();
                    }

                    Connections {
                        target: RunnerGame
                        function onJumpSoundTriggered() { if (soundsLoader.item) soundsLoader.item.press.play(); }
                        function onHitSoundTriggered() { if (soundsLoader.item) soundsLoader.item.hit.play(); }
                        function onScoreSoundTriggered() { if (soundsLoader.item) soundsLoader.item.score.play(); }
                        function onFrameUpdated() { gameCanvas.requestPaint(); }
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
                        if (event.key === Qt.Key_Space || event.key === Qt.Key_Up) {
                            RunnerGame.endJump();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
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
                implicitHeight: 40

                StyledText {
                    anchors.centerIn: parent
                    text: RunnerGame.state === 0
                        ? qsTr("Press Space to Play")
                        : (RunnerGame.state === 2 ? qsTr("Press Space or Enter to Restart") : qsTr("Space / Up: Jump • Down: Duck"))
                    color: RunnerGame.isNightMode ? "#9aa0a6" : "#5f6368"
                    font: Tokens.font.label.medium
                }
            }
        }
    }

    Item {
        id: maskSourceItem
        x: -10000
        y: -10000
        width: dialogBox.width
        height: dialogBox.height
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.large
            color: "black"
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.isOpen
        onActivated: root.close()
    }
}
