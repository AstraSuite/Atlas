import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../controls"
import atlas

MouseArea {
    id: root

    property bool expanded: false
    property string sourcePath: ""
    property string tool: "clip"
    property string selectedFormat: "png"

    readonly property int kind: MediaTools.kindFor(sourcePath)
    readonly property bool isImage: kind === 0
    readonly property bool isVideo: kind === 1
    readonly property bool isAudio: kind === 2

    readonly property var tools: {
        let list = [];
        if (isVideo)
            list.push({ label: qsTr("Clip"), icon: "content_cut", key: "clip" });
        list.push({ label: qsTr("Convert"), icon: "sync_alt", key: "convert" });
        if (!isAudio)
            list.push({ label: qsTr("Rotate"), icon: "rotate_right", key: "rotate" });
        if (isImage)
            list.push({ label: qsTr("Circle"), icon: "circle", key: "circle" });
        if (!isAudio)
            list.push({ label: qsTr("Aspect"), icon: "aspect_ratio", key: "aspect" });
        return list;
    }

    signal accepted(string path)

    function parseTime(str) {
        if (!str || str.trim().length === 0)
            return NaN;
        const parts = str.trim().split(":");
        if (parts.length > 3)
            return NaN;
        let secs = 0;
        for (let i = 0; i < parts.length; ++i) {
            const v = Number(parts[i].trim());
            if (!isFinite(v) || v < 0)
                return NaN;
            secs = secs * 60 + v;
        }
        return secs;
    }

    function openFor(path, preferredTool) {
        sourcePath = path;
        selectedFormat = "";
        startTimeInput.text = "";
        endTimeInput.text = "";
        const fmts = MediaTools.formatsFor(path);
        selectedFormat = fmts.length > 0 ? fmts[0] : "";

        const keys = tools.map(t => t.key);
        if (preferredTool && keys.indexOf(preferredTool) !== -1)
            tool = preferredTool;
        else
            tool = keys.length > 0 ? keys[0] : "clip";

        expanded = true;
    }

    anchors.fill: parent
    visible: opacity > 0.001
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    z: 100

    opacity: expanded ? 1.0 : 0.0
    Behavior on opacity { Anim { type: Anim.FastEffects } }

    onClicked: root.expanded = false
    onWheel: wheel => wheel.accepted = true
    Keys.onEscapePressed: root.expanded = false

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.45)
    }

    StyledRect {
        id: modalCard

        anchors.centerIn: parent
        width: Math.min(parent.width - 32, 440)
        height: Math.min(parent.height - 32, modalCol.implicitHeight + Tokens.padding.large * 2)
        implicitWidth: 440
        implicitHeight: modalCol.implicitHeight + Tokens.padding.large * 2

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerHigh

        scale: root.expanded ? 1.0 : 0.94
        Behavior on scale {
            Anim {
                type: Anim.FastEffects
                easing: Tokens.anim.standard
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
            onWheel: wheel => wheel.accepted = true
        }

        ColumnLayout {
            id: modalCol
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "movie_edit"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: qsTr("Media Tools")
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.body.builders.large.weight(Font.Bold).build()
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.maximumWidth: modalCard.width - 120
                        text: root.sourcePath.split("/").pop()
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.medium
                        elide: Text.ElideMiddle
                    }
                }
            }

            // ffmpeg missing warning
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: warnRow.implicitHeight + Tokens.padding.small * 2
                radius: Tokens.rounding.small
                color: Qt.alpha(Colours.palette.m3errorContainer, 0.5)
                visible: !MediaTools.ffmpegAvailable

                RowLayout {
                    id: warnRow
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "warning"
                        color: Colours.palette.m3error
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        text: qsTr("ffmpeg was not found on this system. Install ffmpeg to use media tools.")
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.label.medium
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            // Tool Selector
            SlidingSelector {
                id: toolSelector
                Layout.fillWidth: true
                buttonHeight: 38
                model: root.tools.map(t => ({ label: t.label, icon: t.icon, key: t.key }))
                valueKey: "key"
                currentValue: root.tool
                onSelected: val => root.tool = val
            }

            // Clip Section
            ColumnLayout {
                visible: root.tool === "clip"
                spacing: Tokens.spacing.small
                Layout.fillWidth: true

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: qsTr("Trim range")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.medium
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: {
                            const dur = MediaTools.durationFor(root.sourcePath);
                            return dur.length > 0 ? qsTr("Duration: %1").arg(dur) : "";
                        }
                        visible: text.length > 0
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.medium
                    }
                }

                RowLayout {
                    spacing: Tokens.spacing.small

                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: Tokens.rounding.small
                        color: Colours.tPalette.m3surfaceContainer
                        clip: true

                        TextInput {
                            id: startTimeInput
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.small
                            anchors.leftMargin: 12
                            color: Colours.palette.m3onSurface
                            selectionColor: Colours.palette.m3primaryContainer
                            selectedTextColor: Colours.palette.m3onPrimaryContainer
                            font: Tokens.font.body.medium
                            selectByMouse: true
                            cursorVisible: activeFocus
                            clip: true
                            verticalAlignment: TextInput.AlignVCenter
                        }

                        StyledText {
                            visible: startTimeInput.text.length === 0 && !startTimeInput.activeFocus
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            verticalAlignment: Text.AlignVCenter
                            text: qsTr("Start (e.g. 0:05)")
                            color: Colours.palette.m3outline
                            font: Tokens.font.body.medium
                        }
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: Tokens.rounding.small
                        color: Colours.tPalette.m3surfaceContainer
                        clip: true

                        TextInput {
                            id: endTimeInput
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.small
                            anchors.leftMargin: 12
                            color: Colours.palette.m3onSurface
                            selectionColor: Colours.palette.m3primaryContainer
                            selectedTextColor: Colours.palette.m3onPrimaryContainer
                            font: Tokens.font.body.medium
                            selectByMouse: true
                            cursorVisible: activeFocus
                            clip: true
                            verticalAlignment: TextInput.AlignVCenter
                        }

                        StyledText {
                            visible: endTimeInput.text.length === 0 && !endTimeInput.activeFocus
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            verticalAlignment: Text.AlignVCenter
                            text: qsTr("End (e.g. 1:30)")
                            color: Colours.palette.m3outline
                            font: Tokens.font.body.medium
                        }
                    }
                }
            }

            // Convert Section
            ColumnLayout {
                visible: root.tool === "convert"
                spacing: Tokens.spacing.small
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Target format")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                }

                SlidingSelector {
                    Layout.fillWidth: true
                    buttonHeight: 38
                    model: MediaTools.formatsFor(root.sourcePath).map(f => ({ label: "." + f, key: f }))
                    valueKey: "key"
                    currentValue: root.selectedFormat
                    onSelected: val => root.selectedFormat = val
                }
            }

            // Rotate Section
            ColumnLayout {
                visible: root.tool === "rotate"
                spacing: Tokens.spacing.small
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Transform")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                }

                SlidingSelector {
                    id: rotateSelector
                    Layout.fillWidth: true
                    buttonHeight: 38
                    model: [
                        { label: "90° CW", icon: "rotate_right", key: "cw" },
                        { label: "90° CCW", icon: "rotate_left", key: "ccw" },
                        { label: "180°", icon: "restart_alt", key: "half" },
                        { label: qsTr("Flip H"), icon: "flip", key: "hflip" },
                        { label: qsTr("Flip V"), icon: "flip", key: "vflip" }
                    ]
                    valueKey: "key"
                    currentValue: "cw"
                    onSelected: val => currentValue = val
                }
            }

            // Circle Crop Section
            StyledText {
                visible: root.tool === "circle"
                text: qsTr("Crops the image to an inscribed circle with transparent corners. The result is saved as a PNG next to the original.")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.medium
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            // Aspect Ratio Section
            ColumnLayout {
                visible: root.tool === "aspect"
                spacing: Tokens.spacing.small
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Aspect ratio")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                }

                SlidingSelector {
                    id: ratioSelector
                    Layout.fillWidth: true
                    buttonHeight: 38
                    model: [
                        { label: "16:9", key: "16x9" },
                        { label: "9:16", key: "9x16" },
                        { label: "4:3", key: "4x3" },
                        { label: "1:1", key: "1x1" },
                        { label: "3:2", key: "3x2" },
                        { label: "21:9", key: "21x9" }
                    ]
                    valueKey: "key"
                    currentValue: "16x9"
                    onSelected: val => currentValue = val
                }

                SlidingSelector {
                    id: aspectModeSelector
                    Layout.fillWidth: true
                    buttonHeight: 38
                    model: [
                        { label: qsTr("Crop to fit"), icon: "crop", key: "crop" },
                        { label: qsTr("Pad to fit"), icon: "padding", key: "pad" }
                    ]
                    valueKey: "key"
                    currentValue: "crop"
                    onSelected: val => currentValue = val
                }
            }

            Item {
                Layout.fillHeight: true
                visible: modalCol.height < modalCol.implicitHeight
            }

            // Buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                spacing: Tokens.spacing.small

                Item { Layout.fillWidth: true }

                TextButton {
                    type: ButtonBase.Text
                    text: qsTr("Cancel")
                    onClicked: root.expanded = false
                }

                IconTextButton {
                    id: applyButton
                    type: ButtonBase.Filled
                    icon: MediaTools.busy ? "" : "check"
                    text: qsTr("Apply")
                    enabled: !MediaTools.busy && MediaTools.ffmpegAvailable && root.kind !== 3
                    onClicked: {
                        const src = root.sourcePath;
                        if (!src)
                            return;

                        if (root.tool === "clip") {
                            const startSecs = root.parseTime(startTimeInput.text);
                            const endRaw = endTimeInput.text.trim();
                            let endSecs = NaN;
                            if (endRaw.length > 0) {
                                endSecs = root.parseTime(endRaw);
                            } else {
                                const durStr = MediaTools.durationFor(src);
                                if (durStr.length > 0) {
                                    const durParts = durStr.split(":");
                                    endSecs = 0;
                                    for (let i = 0; i < durParts.length; ++i)
                                        endSecs = endSecs * 60 + Number(durParts[i]);
                                }
                            }
                            if (isNaN(startSecs) || isNaN(endSecs) || endSecs <= startSecs) {
                                FileOperations.addCompletedTask(false, qsTr("Invalid trim range"));
                                return;
                            }
                            MediaTools.clipVideo(src, startSecs, endSecs);
                        } else if (root.tool === "convert") {
                            MediaTools.convertMedia(src, root.selectedFormat);
                        } else if (root.tool === "rotate") {
                            const mode = rotateSelector.currentValue;
                            if (mode === "cw")
                                MediaTools.rotateMedia(src, 90);
                            else if (mode === "ccw")
                                MediaTools.rotateMedia(src, 270);
                            else if (mode === "half")
                                MediaTools.rotateMedia(src, 180);
                            else if (mode === "hflip")
                                MediaTools.flipMedia(src, true);
                            else if (mode === "vflip")
                                MediaTools.flipMedia(src, false);
                        } else if (root.tool === "circle") {
                            MediaTools.circleCrop(src);
                        } else if (root.tool === "aspect") {
                            const parts = ratioSelector.currentValue.split("x");
                            MediaTools.setAspectRatio(src, Number(parts[0]), Number(parts[1]), aspectModeSelector.currentValue === "crop");
                        }

                        root.expanded = false;
                    }
                }

                CircularIndicator {
                    size: 22
                    strokeWidth: 2
                    color: Colours.palette.m3primary
                    running: MediaTools.busy
                    visible: running
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}
