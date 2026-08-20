import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import "../"
import prism

Item {
    id: root

    property url source: ""
    readonly property bool isPlaying: player.playbackState === MediaPlayer.PlayingState
    readonly property real position: player.position
    readonly property real duration: player.duration
    readonly property real bufferProgress: player.bufferProgress
    property real volume: 1.0
    property bool muted: false

    signal toggleControlsRequested()

    function play() {
        player.play();
    }

    function pause() {
        player.pause();
    }

    function togglePlay() {
        if (isPlaying) {
            player.pause();
        } else {
            player.play();
        }
    }

    function seek(posMs) {
        player.setPosition(posMs);
    }

    function stepForward(ms) {
        seek(Math.min(duration, position + (ms || 5000)));
    }

    function stepBackward(ms) {
        seek(Math.max(0, position - (ms || 5000)));
    }

    clip: true

    MediaPlayer {
        id: player
        source: root.source
        audioOutput: AudioOutput {
            volume: root.muted ? 0.0 : root.volume
        }
        videoOutput: videoOutput
        Component.onCompleted: play()
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
    }

    // Video Tap / Double-Click Area
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            root.togglePlay();
        }

        onDoubleClicked: {
            root.toggleControlsRequested();
        }

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                root.volume = Math.min(1.0, root.volume + 0.05);
            } else if (wheel.angleDelta.y < 0) {
                root.volume = Math.max(0.0, root.volume - 0.05);
            }
        }
    }

    // Large Center Play/Pause Ripple Indicator on toggle
    Item {
        anchors.centerIn: parent
        implicitWidth: 72
        implicitHeight: 72
        opacity: playFadeAnim.running ? 1.0 : 0.0
        scale: playFadeAnim.running ? 1.0 : 0.7

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.full
            color: Qt.alpha(Colours.palette.m3scrim, 0.6)

            MaterialIcon {
                anchors.centerIn: parent
                text: root.isPlaying ? "play_arrow" : "pause"
                color: Colours.palette.m3onPrimary
                fontStyle: Tokens.font.icon.large
            }
        }

        ParallelAnimation {
            id: playFadeAnim
            NumberAnimation { property: "scale"; from: 0.7; to: 1.1; duration: 300; easing.type: Easing.OutBack }
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 400; easing.type: Easing.InQuad }
        }
    }

    Connections {
        target: player
        function onPlaybackStateChanged() {
            playFadeAnim.restart();
        }
    }
}
