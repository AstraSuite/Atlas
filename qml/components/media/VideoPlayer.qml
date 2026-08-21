import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import "../"
import prism

Item {
    id: root

    property url source: ""
    property string filePath: ""
    property bool loop: false
    property bool hasStartedPlaying: false

    readonly property bool isPlaying: player.playbackState === MediaPlayer.PlayingState
    readonly property real position: player.position
    readonly property real duration: player.duration
    readonly property real bufferProgress: player.bufferProgress
    property real volume: 1.0
    property bool muted: false

    signal toggleControlsRequested()

    function play() {
        if (player.mediaStatus === MediaPlayer.EndOfMedia || (player.duration > 0 && player.position >= player.duration - 200)) {
            player.setPosition(0);
        }
        player.play();
    }

    function pause() {
        player.pause();
    }

    function togglePlay() {
        if (isPlaying) {
            player.pause();
        } else {
            root.play();
        }
    }

    function seek(posMs) {
        root.hasStartedPlaying = true;
        let targetPos = Math.min(Math.max(0, Math.round(posMs)), Math.max(0, player.duration));
        player.setPosition(targetPos);
    }

    function stepForward(ms) {
        seek(Math.min(duration, position + (ms || 5000)));
    }

    function stepBackward(ms) {
        seek(Math.max(0, position - (ms || 5000)));
    }

    onSourceChanged: {
        hasStartedPlaying = false;
        player.play();
    }

    clip: true

    MediaPlayer {
        id: player
        source: root.source
        loops: root.loop ? MediaPlayer.Infinite : MediaPlayer.Once
        audioOutput: AudioOutput {
            volume: root.muted ? 0.0 : root.volume
        }
        videoOutput: videoOutput

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.EndOfMedia) {
                if (!root.loop) {
                    player.pause();
                }
            }
        }

        onPlaybackStateChanged: {
            if (playbackState === MediaPlayer.PlayingState) {
                root.hasStartedPlaying = true;
            }
        }
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
    }

    // Initial Thumbnail Cover (Visible until first frame playback)
    Image {
        id: thumbnailCover
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        source: root.filePath ? ("image://thumb/" + root.filePath) : ""
        visible: opacity > 0.001
        opacity: root.hasStartedPlaying ? 0.0 : 1.0
        Behavior on opacity { Anim { type: Anim.FastEffects } }
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
