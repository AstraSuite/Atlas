import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtMultimedia
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

    // Sound Effects
    SoundEffect {
        id: soundPress
        source: "qrc:/qt/qml/prism/assets/runner/sounds/press.wav"
    }

    SoundEffect {
        id: soundHit
        source: "qrc:/qt/qml/prism/assets/runner/sounds/hit.wav"
    }

    SoundEffect {
        id: soundScore
        source: "qrc:/qt/qml/prism/assets/runner/sounds/reached.wav"
    }

    // Scrim
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.65)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // Dialog Box
    StyledRect {
        id: dialogBox
        anchors.centerIn: parent
        width: Math.min(parent.width - 32, 960)
        height: Math.min(parent.height - 48, 560)
        radius: Tokens.rounding.large
        color: RunnerGame.isNightMode ? "#202124" : "#ffffff"

        layer.enabled: true
        layer.effect: Mask {
            maskSource: maskItem
        }

        scale: root.isOpen ? 1.0 : 0.92

        Behavior on scale {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
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

            // Canvas Game View Area
            Item {
                id: gameContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Canvas {
                    id: gameCanvas
                    anchors.fill: parent
                    focus: true

                    readonly property string spritePath: "qrc:/qt/qml/prism/assets/runner/assets/default_200_percent/200-offline-sprite.png"

                    onPaint: {
                        let ctx = getContext("2d");
                        ctx.save();
                        ctx.clearRect(0, 0, width, height);

                        let bgC = RunnerGame.bgColor;
                        ctx.fillStyle = "rgb(" + bgC + "," + bgC + "," + bgC + ")";
                        ctx.fillRect(0, 0, width, height);

                        if (!isImageLoaded(spritePath)) {
                            loadImage(spritePath);
                            ctx.restore();
                            return;
                        }

                        // 1280 x 720 base viewport scaling
                        let sf = Math.min(width / 1280.0, height / 720.0);
                        let offsetX = (width - 1280 * sf) / 2.0;
                        let offsetY = (height - 720 * sf) / 2.0;

                        ctx.translate(offsetX, offsetY);

                        // Sun / Moon
                        if (bgC < 200) {
                            // Moon
                            ctx.drawImage(spritePath, 1034, 2, 40, 80, 620 * sf, 200 * sf, 40 * sf, 80 * sf);
                            // Stars
                            ctx.drawImage(spritePath, 1274, 39, 18, 17, 200 * sf, 200 * sf, 18 * sf, 17 * sf);
                            ctx.drawImage(spritePath, 1274, 39, 18, 17, 800 * sf, 300 * sf, 18 * sf, 17 * sf);
                        } else {
                            // Sun
                            ctx.drawImage(spritePath, 1074, 2, 80, 80, 600 * sf, 200 * sf, 80 * sf, 80 * sf);
                        }

                        // Clouds
                        let clouds = RunnerGame.clouds;
                        for (let i = 0; i < clouds.length; ++i) {
                            let c = clouds[i];
                            ctx.drawImage(spritePath, 166, 2, 92, 27, c.x * sf, c.y * sf, 92 * sf, 27 * sf);
                        }

                        // Ground continuous segments
                        let go = RunnerGame.groundOffset * sf;
                        ctx.drawImage(spritePath, 2, 104, 2440, 26, go, 520 * sf, 2440 * sf, 26 * sf);
                        ctx.drawImage(spritePath, 2, 104, 2440, 26, go + 2400 * sf, 520 * sf, 2440 * sf, 26 * sf);
                        ctx.drawImage(spritePath, 2, 104, 2440, 26, go + 4800 * sf, 520 * sf, 2440 * sf, 26 * sf);

                        // Obstacles
                        let obstacles = RunnerGame.obstacles;
                        for (let i = 0; i < obstacles.length; ++i) {
                            let obs = obstacles[i];
                            ctx.drawImage(spritePath, obs.sx, obs.sy, obs.sw, obs.sh, obs.x * sf, obs.y * sf, obs.width * sf, obs.height * sf);
                        }

                        // Dino Player
                        let dx = RunnerGame.playerX * sf;
                        let dy = RunnerGame.playerY * sf;
                        let dsx = RunnerGame.dinoSpriteX;
                        let dsy = RunnerGame.dinoSpriteY;
                        let dsw = RunnerGame.dinoSpriteW;
                        let dsh = RunnerGame.dinoSpriteH;

                        if (RunnerGame.isDucking && RunnerGame.state !== 2) {
                            ctx.drawImage(spritePath, dsx, dsy, dsw, dsh, dx, (dy + 30) * sf, dsw * sf, dsh * sf);
                        } else {
                            ctx.drawImage(spritePath, dsx, dsy, dsw, dsh, dx, dy * sf, dsw * sf, dsh * sf);
                        }

                        // Digits rendering helper
                        function drawScore(val, targetX) {
                            let sStr = ("00000" + val).slice(-5);
                            let digitsMap = {
                                '0': 1294, '1': 1316, '2': 1334, '3': 1354, '4': 1374,
                                '5': 1394, '6': 1414, '7': 1434, '8': 1454, '9': 1474
                            };
                            for (let d = 0; d < 5; ++d) {
                                let ch = sStr[d];
                                let sx = digitsMap[ch] || 1294;
                                ctx.drawImage(spritePath, sx, 2, 18, 21, (targetX + d * 20) * sf, 167 * sf, 18 * sf, 21 * sf);
                            }
                        }

                        // High score & Current score
                        if (RunnerGame.highScore > 0) {
                            ctx.drawImage(spritePath, 1494, 2, 38, 21, 955 * sf, 167 * sf, 38 * sf, 21 * sf);
                            drawScore(RunnerGame.highScore, 1010);
                        }
                        drawScore(RunnerGame.score, 1140);

                        // Game Over Panel
                        if (RunnerGame.state === 2) {
                            // "GAME OVER"
                            let goX = (1280 / 2 - 380 / 2) * sf;
                            let goY = (720 / 2 - 21 / 2 - 40) * sf;
                            ctx.drawImage(spritePath, 1295, 29, 380, 21, goX, goY, 380 * sf, 21 * sf);

                            // Restart Icon
                            let rX = (1280 / 2 - 72 / 2) * sf;
                            let rY = (720 / 2 - 64 / 2 + 30) * sf;
                            ctx.drawImage(spritePath, 2, 2, 72, 64, rX, rY, 72 * sf, 64 * sf);
                        }

                        ctx.restore();
                    }

                    Connections {
                        target: RunnerGame
                        function onJumpSoundTriggered() { soundPress.play(); }
                        function onHitSoundTriggered() { soundHit.play(); }
                        function onScoreSoundTriggered() { soundScore.play(); }
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
