import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../controls"
import prism

MouseArea {
    id: root

    property bool expanded: false
    onExpandedChanged: {
        if (!expanded && typeof splitContainer !== "undefined" && splitContainer) {
            splitContainer.focusActiveView();
        }
    }
    property string currentFilePath: ""
    property var mediaList: []
    property int currentIndex: -1
    property bool showControls: true
    property bool showFilmstrip: false

    readonly property var currentMediaItem: (currentIndex >= 0 && currentIndex < mediaList.length) ? mediaList[currentIndex] : null
    readonly property bool isImage: currentMediaItem ? (currentMediaItem.isImage || FileUtils.isImage(currentFilePath)) : false
    readonly property bool isVideo: currentMediaItem ? (currentMediaItem.isVideo || FileUtils.isVideo(currentFilePath)) : false

    function openFile(filePath, directoryModel) {
        currentFilePath = filePath;
        let list = [];
        let curIdx = -1;

        if (directoryModel) {
            for (let i = 0; i < directoryModel.count; ++i) {
                let item = directoryModel.get(i);
                if (item && !item.isDir && (item.isImage || item.isVideo)) {
                    list.push(item);
                    if (item.path === filePath) {
                        curIdx = list.length - 1;
                    }
                }
            }
        }

        if (list.length === 0) {
            list = [{
                name: FileUtils.baseName(filePath),
                path: filePath,
                isImage: FileUtils.isImage(filePath),
                isVideo: FileUtils.isVideo(filePath)
            }];
            curIdx = 0;
        }

        mediaList = list;
        currentIndex = curIdx >= 0 ? curIdx : 0;
        expanded = true;
        activityTimer.restart();
    }

    function showNext() {
        if (mediaList.length > 1) {
            currentIndex = (currentIndex + 1) % mediaList.length;
            currentFilePath = mediaList[currentIndex].path;
            activityTimer.restart();
        }
    }

    function showPrevious() {
        if (mediaList.length > 1) {
            currentIndex = (currentIndex - 1 + mediaList.length) % mediaList.length;
            currentFilePath = mediaList[currentIndex].path;
            activityTimer.restart();
        }
    }

    function formatTime(ms) {
        if (!ms || isNaN(ms)) return "00:00";
        let totalSec = Math.floor(ms / 1000);
        let min = Math.floor(totalSec / 60);
        let sec = totalSec % 60;
        let hr = Math.floor(min / 60);
        min = min % 60;
        let secStr = sec < 10 ? "0" + sec : "" + sec;
        let minStr = min < 10 ? "0" + min : "" + min;
        if (hr > 0) {
            return `${hr}:${minStr}:${secStr}`;
        }
        return `${minStr}:${secStr}`;
    }

    anchors.fill: parent
    visible: opacity > 0.001
    enabled: expanded
    hoverEnabled: expanded
    z: 200

    opacity: expanded ? 1.0 : 0.0
    Behavior on opacity { Anim { type: Anim.FastEffects } }

    onClicked: activityTimer.restart()
    onPositionChanged: {
        showControls = true;
        activityTimer.restart();
    }

    Timer {
        id: activityTimer
        interval: 3000
        running: root.expanded && root.showControls && !controlHover.containsMouse
        onTriggered: {
            if (root.isVideo && videoPlayer.isPlaying) {
                root.showControls = false;
            }
        }
    }

    // Scrim / Backdrop Background
    Rectangle {
        anchors.fill: parent
        color: Colours.palette.m3scrim
        opacity: 0.94
    }

    // Main Content Area
    Item {
        anchors.fill: parent

        // Image Viewer Canvas
        ImageViewer {
            id: imageViewer
            anchors.fill: parent
            source: root.isImage ? Qt.resolvedUrl("file://" + root.currentFilePath) : ""
            visible: root.isImage
            onToggleControlsRequested: root.showControls = !root.showControls
        }

        // Video Player Canvas
        VideoPlayer {
            id: videoPlayer
            anchors.fill: parent
            source: root.isVideo ? Qt.resolvedUrl("file://" + root.currentFilePath) : ""
            filePath: root.currentFilePath
            visible: root.isVideo
            onToggleControlsRequested: root.showControls = !root.showControls
        }
    }

    // Navigation Arrow Buttons
    StyledRect {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.medium
        implicitWidth: 44
        implicitHeight: 44
        radius: Tokens.rounding.full
        color: leftBtnHover.containsMouse ? Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.8) : Qt.alpha(Colours.palette.m3surfaceContainer, 0.4)
        visible: root.mediaList.length > 1 && root.showControls
        opacity: root.showControls ? 1.0 : 0.0
        Behavior on opacity { Anim { type: Anim.FastEffects } }

        MaterialIcon {
            anchors.centerIn: parent
            text: "chevron_left"
            fontStyle: Tokens.font.icon.medium
            color: Colours.palette.m3onSurface
        }

        MouseArea {
            id: leftBtnHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.showPrevious()
        }
    }

    StyledRect {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Tokens.padding.medium
        implicitWidth: 44
        implicitHeight: 44
        radius: Tokens.rounding.full
        color: rightBtnHover.containsMouse ? Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.8) : Qt.alpha(Colours.palette.m3surfaceContainer, 0.4)
        visible: root.mediaList.length > 1 && root.showControls
        opacity: root.showControls ? 1.0 : 0.0
        Behavior on opacity { Anim { type: Anim.FastEffects } }

        MaterialIcon {
            anchors.centerIn: parent
            text: "chevron_right"
            fontStyle: Tokens.font.icon.medium
            color: Colours.palette.m3onSurface
        }

        MouseArea {
            id: rightBtnHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.showNext()
        }
    }

    // Top Header Bar
    StyledRect {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: 56
        color: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.75)
        opacity: root.showControls ? 1.0 : 0.0
        Behavior on opacity { Anim { type: Anim.FastEffects } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            StyledRect {
                implicitWidth: 36
                implicitHeight: 36
                radius: Tokens.rounding.full
                color: closeHover.containsMouse ? Colours.palette.m3surfaceContainerHigh : "transparent"

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "arrow_back"
                    color: Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.medium
                }

                MouseArea {
                    id: closeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.expanded = false
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: root.currentMediaItem ? root.currentMediaItem.name : FileUtils.baseName(root.currentFilePath)
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                StyledText {
                    text: `${root.currentIndex + 1} of ${root.mediaList.length}`
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                    visible: root.mediaList.length > 1
                }
            }

            // Image specific actions
            RowLayout {
                visible: root.isImage
                spacing: Tokens.spacing.extraSmall

                StyledRect {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: zoomInHover.containsMouse ? Colours.palette.m3surfaceContainerHigh : "transparent"

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "zoom_in"
                        color: Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.small
                    }
                    MouseArea {
                        id: zoomInHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: imageViewer.zoomIn()
                    }
                }

                StyledRect {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: zoomOutHover.containsMouse ? Colours.palette.m3surfaceContainerHigh : "transparent"

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "zoom_out"
                        color: Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.small
                    }
                    MouseArea {
                        id: zoomOutHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: imageViewer.zoomOut()
                    }
                }

                StyledRect {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: resetZoomHover.containsMouse ? Colours.palette.m3surfaceContainerHigh : "transparent"

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "aspect_ratio"
                        color: Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.small
                    }
                    MouseArea {
                        id: resetZoomHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: imageViewer.resetZoom()
                    }
                }

                StyledRect {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: rotateHover.containsMouse ? Colours.palette.m3surfaceContainerHigh : "transparent"

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "rotate_right"
                        color: Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.small
                    }
                    MouseArea {
                        id: rotateHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: imageViewer.rotateClockwise()
                    }
                }
            }

            // Open In Default External App
            StyledRect {
                implicitWidth: 36
                implicitHeight: 36
                radius: Tokens.rounding.full
                color: extHover.containsMouse ? Colours.palette.m3surfaceContainerHigh : "transparent"

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "open_in_new"
                    color: Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }
                MouseArea {
                    id: extHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AppIntegration.openWithDefault(root.currentFilePath)
                }
            }

            // Fullscreen Toggle
            StyledRect {
                implicitWidth: 36
                implicitHeight: 36
                radius: Tokens.rounding.full
                color: fsHover.containsMouse ? Colours.palette.m3surfaceContainerHigh : "transparent"

                MaterialIcon {
                    anchors.centerIn: parent
                    text: window.visibility === Window.FullScreen ? "fullscreen_exit" : "fullscreen"
                    color: Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }
                MouseArea {
                    id: fsHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        window.visibility = (window.visibility === Window.FullScreen ? Window.Windowed : Window.FullScreen);
                    }
                }
            }
        }
    }

    // Bottom Floating Control Bar
    StyledRect {
        id: bottomControls
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.padding.medium + (filmstrip.visible ? (filmstrip.height + Tokens.padding.small) : 0)
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: root.isVideo ? Math.min(parent.width - 40, 560) : 48
        implicitHeight: 48
        radius: Tokens.rounding.full
        color: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.85)
        visible: (root.isVideo || root.mediaList.length > 1)
        opacity: root.showControls ? 1.0 : 0.0
        Behavior on opacity { Anim { type: Anim.FastEffects } }
        Behavior on implicitWidth { Anim { type: Anim.FastSpatial } }
        Behavior on anchors.bottomMargin { Anim { type: Anim.FastSpatial } }

        MouseArea {
            id: controlHover
            anchors.fill: parent
            hoverEnabled: true
            onEntered: activityTimer.stop()
            onExited: activityTimer.restart()
        }

        // Full Playback Row
        RowLayout {
            id: controlsRow
            visible: root.isVideo
            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.small

            // Play / Pause
            StyledRect {
                implicitWidth: 36
                implicitHeight: 36
                radius: Tokens.rounding.full
                color: playBtnHover.containsMouse ? Colours.palette.m3primaryContainer : Colours.palette.m3primary

                MaterialIcon {
                    anchors.centerIn: parent
                    text: videoPlayer.isPlaying ? "pause" : "play_arrow"
                    fontStyle: Tokens.font.icon.medium
                    color: playBtnHover.containsMouse ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onPrimary
                }
                MouseArea {
                    id: playBtnHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: videoPlayer.togglePlay()
                }
            }

            // Video Seek Bar & Timestamps
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    text: root.formatTime(videoPlayer.position)
                    font: Tokens.font.mono.small
                    color: Colours.palette.m3onSurface
                    Layout.preferredWidth: 44
                    horizontalAlignment: Text.AlignRight
                }

                StyledSlider {
                    id: videoSlider
                    Layout.fillWidth: true
                    implicitHeight: 8
                    from: 0
                    to: Math.max(1, videoPlayer.duration)
                    value: videoPlayer.position

                    onInteraction: v => {
                        videoPlayer.seek(v);
                    }
                }

                StyledText {
                    text: root.formatTime(videoPlayer.duration)
                    font: Tokens.font.mono.small
                    color: Colours.palette.m3onSurfaceVariant
                    Layout.preferredWidth: 44
                    horizontalAlignment: Text.AlignLeft
                }
            }

            // Volume Controls
            RowLayout {
                spacing: 4

                MaterialIcon {
                    text: videoPlayer.muted || videoPlayer.volume === 0 ? "volume_off" : (videoPlayer.volume > 0.5 ? "volume_up" : "volume_down")
                    fontStyle: Tokens.font.icon.small
                    color: Colours.palette.m3onSurface

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: videoPlayer.muted = !videoPlayer.muted
                    }
                }

                StyledSlider {
                    implicitWidth: 60
                    implicitHeight: 6
                    from: 0.0
                    to: 1.0
                    value: videoPlayer.volume
                    onInteraction: v => {
                        videoPlayer.volume = v;
                        videoPlayer.muted = false;
                    }
                }
            }

            // Loop Toggle
            StyledRect {
                implicitWidth: 32
                implicitHeight: 32
                radius: Tokens.rounding.full
                color: videoPlayer.loop ? Colours.palette.m3primaryContainer : (loopHover.containsMouse ? Colours.palette.m3surfaceContainerHigh : "transparent")

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "repeat"
                    fontStyle: Tokens.font.icon.small
                    color: videoPlayer.loop ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                }
                MouseArea {
                    id: loopHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: videoPlayer.loop = !videoPlayer.loop
                }
            }

            // Filmstrip Toggle
            StyledRect {
                implicitWidth: 32
                implicitHeight: 32
                radius: Tokens.rounding.full
                color: root.showFilmstrip ? Colours.palette.m3primaryContainer : (filmHover.containsMouse ? Colours.palette.m3surfaceContainerHigh : "transparent")
                visible: root.mediaList.length > 1

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "photo_library"
                    fontStyle: Tokens.font.icon.small
                    color: root.showFilmstrip ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                }
                MouseArea {
                    id: filmHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showFilmstrip = !root.showFilmstrip
                }
            }
        }

        // Single Centered Gallery Button
        StyledRect {
            anchors.centerIn: parent
            width: 36
            height: 36
            radius: Tokens.rounding.full
            visible: !root.isVideo && root.mediaList.length > 1
            color: root.showFilmstrip ? Colours.palette.m3primaryContainer : (filmHoverImg.containsMouse ? Colours.palette.m3surfaceContainerHigh : "transparent")

            MaterialIcon {
                anchors.centerIn: parent
                text: "photo_library"
                fontStyle: Tokens.font.icon.small
                color: root.showFilmstrip ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
            }
            MouseArea {
                id: filmHoverImg
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.showFilmstrip = !root.showFilmstrip
            }
        }
    }

    // Bottom Filmstrip Carousel
    MediaFilmstrip {
        id: filmstrip
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.medium
        mediaList: root.mediaList
        currentIndex: root.currentIndex
        active: root.showFilmstrip && root.mediaList.length > 1
        showControls: root.showControls
        onItemSelected: idx => {
            root.currentIndex = idx;
            root.currentFilePath = root.mediaList[idx].path;
            activityTimer.restart();
        }
    }

    // Keyboard Shortcuts inside Media Viewer
    Shortcut {
        enabled: root.expanded
        sequence: "Space"
        onActivated: {
            if (root.isVideo) {
                videoPlayer.togglePlay();
            } else {
                root.expanded = false;
            }
        }
    }

    Shortcut {
        enabled: root.expanded
        sequence: "Left"
        onActivated: root.showPrevious()
    }

    Shortcut {
        enabled: root.expanded
        sequence: "Right"
        onActivated: root.showNext()
    }

    Shortcut {
        enabled: root.expanded
        sequence: "Escape"
        onActivated: root.expanded = false
    }

    Shortcut {
        enabled: root.expanded
        sequence: "R"
        onActivated: {
            if (root.isImage) imageViewer.rotateClockwise();
        }
    }

    Shortcut {
        enabled: root.expanded
        sequence: "F"
        onActivated: window.visibility = (window.visibility === Window.FullScreen ? Window.Windowed : Window.FullScreen)
    }
}
