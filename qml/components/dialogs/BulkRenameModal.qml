import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../controls"
import prism

MouseArea {
    id: root

    property bool expanded: false
    property var targets: []

    property string mode: "replace"
    property string findText: ""
    property string replaceText: ""
    property string pattern: "#"
    property int startAt: 1

    readonly property var preview: {
        const result = [];
        const taken = {};
        let counter = root.startAt;

        for (let i = 0; i < root.targets.length; i++) {
            const original = root.targets[i].name;
            const dot = original.lastIndexOf(".");
            const isDir = root.targets[i].isDir;
            const base = (!isDir && dot > 0) ? original.substring(0, dot) : original;
            const suffix = (!isDir && dot > 0) ? original.substring(dot) : "";

            let name;
            if (root.mode === "replace") {
                name = root.findText.length > 0 ? original.split(root.findText).join(root.replaceText) : original;
            } else {
                const digits = (root.pattern.match(/#+/) || ["#"])[0];
                let number = String(counter++);
                while (number.length < digits.length)
                    number = "0" + number;
                name = root.pattern.replace(/#+/, number).split("{name}").join(base) + suffix;
            }

            name = name.trim();

            let problem = "";
            if (name.length === 0)
                problem = qsTr("empty");
            else if (name.indexOf("/") >= 0)
                problem = qsTr("contains a slash");
            else if (taken[name])
                problem = qsTr("used twice");
            taken[name] = true;

            result.push({ from: original, to: name, problem: problem, changed: name !== original });
        }
        return result;
    }

    readonly property int changedCount: root.preview.filter(entry => entry.changed && entry.problem.length === 0).length
    readonly property bool hasProblem: root.preview.some(entry => entry.problem.length > 0)

    signal applied(var names)

    anchors.fill: parent
    visible: opacity > 0.001
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    z: 100

    opacity: expanded ? 1.0 : 0.0
    Behavior on opacity {
        Anim {
            type: Anim.FastEffects
        }
    }

    onClicked: root.expanded = false
    onWheel: wheel => wheel.accepted = true

    Keys.onEscapePressed: root.expanded = false

    onExpandedChanged: {
        if (expanded) {
            root.mode = "replace";
            root.findText = "";
            root.replaceText = "";
            root.pattern = "#";
            root.startAt = 1;
            findInput.text = "";
            replaceInput.text = "";
            patternInput.text = "#";
            startInput.text = "1";
            findInput.forceActiveFocus();
        } else if (typeof splitContainer !== "undefined" && splitContainer) {
            splitContainer.focusActiveView();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.4)
    }

    StyledRect {
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 560)
        height: Math.min(parent.height - 32, modalCol.implicitHeight + Tokens.padding.large * 2)
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

            RowLayout {
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "drive_file_rename_outline"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.targets.length === 1
                        ? qsTr("Rename 1 item")
                        : qsTr("Rename %1 items").arg(root.targets.length)
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.medium
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Repeater {
                    model: [
                        { key: "replace", label: qsTr("Find and Replace") },
                        { key: "number", label: qsTr("Numbered") }
                    ]

                    delegate: StyledRect {
                        id: modeCard

                        required property var modelData
                        readonly property bool isSelected: root.mode === modelData.key

                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: Tokens.rounding.medium
                        color: isSelected
                            ? Colours.palette.m3primaryContainer
                            : (modeHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer)

                        StyledText {
                            anchors.centerIn: parent
                            text: modeCard.modelData.label
                            color: modeCard.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                            font: Tokens.font.label.large
                        }

                        MouseArea {
                            id: modeHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.mode = modeCard.modelData.key
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.mode === "replace"
                spacing: Tokens.spacing.small

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: Tokens.rounding.small
                    color: Colours.palette.m3surfaceContainerHighest
                    border.color: findInput.activeFocus ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outlineVariant, 0.5)
                    border.width: findInput.activeFocus ? 2 : 1
                    clip: true

                    TextInput {
                        id: findInput
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        verticalAlignment: TextInput.AlignVCenter
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.body.medium
                        selectByMouse: true
                        onTextChanged: root.findText = text

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !parent.text
                            text: qsTr("Find")
                            color: Colours.palette.m3outline
                            font: parent.font
                        }
                    }
                }

                MaterialIcon {
                    text: "arrow_forward"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.small
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: Tokens.rounding.small
                    color: Colours.palette.m3surfaceContainerHighest
                    border.color: replaceInput.activeFocus ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outlineVariant, 0.5)
                    border.width: replaceInput.activeFocus ? 2 : 1
                    clip: true

                    TextInput {
                        id: replaceInput
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        verticalAlignment: TextInput.AlignVCenter
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.body.medium
                        selectByMouse: true
                        onTextChanged: root.replaceText = text

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !parent.text
                            text: qsTr("Replace with")
                            color: Colours.palette.m3outline
                            font: parent.font
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.mode === "number"
                spacing: Tokens.spacing.small

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: Tokens.rounding.small
                    color: Colours.palette.m3surfaceContainerHighest
                    border.color: patternInput.activeFocus ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outlineVariant, 0.5)
                    border.width: patternInput.activeFocus ? 2 : 1
                    clip: true

                    TextInput {
                        id: patternInput
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        text: "#"
                        verticalAlignment: TextInput.AlignVCenter
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.body.medium
                        selectByMouse: true
                        onTextChanged: root.pattern = text
                    }
                }

                StyledRect {
                    implicitWidth: 90
                    implicitHeight: 42
                    radius: Tokens.rounding.small
                    color: Colours.palette.m3surfaceContainerHighest
                    border.color: startInput.activeFocus ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outlineVariant, 0.5)
                    border.width: startInput.activeFocus ? 2 : 1
                    clip: true

                    TextInput {
                        id: startInput
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        text: "1"
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignHCenter
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.body.medium
                        selectByMouse: true
                        validator: IntValidator { bottom: 0; top: 999999 }
                        onTextChanged: root.startAt = parseInt(text) || 0
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.mode === "number"
                text: qsTr("# becomes the counter, repeat it to pad with zeros. {name} inserts the current name. The extension is kept.")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.Wrap
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(220, Math.max(64, root.preview.length * 26 + Tokens.padding.small * 2))
                radius: Tokens.rounding.medium
                color: Colours.tPalette.m3surfaceContainer
                clip: true

                ListView {
                    id: previewList
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small
                    model: root.preview
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: StyledScrollBar {
                        flickable: previewList
                    }

                    delegate: RowLayout {
                        required property var modelData

                        width: previewList.width
                        height: 26
                        spacing: Tokens.spacing.small

                        StyledText {
                            Layout.preferredWidth: (parent.width - 40) / 2
                            text: modelData.from
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                            elide: Text.ElideMiddle
                        }

                        MaterialIcon {
                            text: "arrow_forward"
                            color: Colours.palette.m3outline
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.problem.length > 0 ? qsTr("%1 (%2)").arg(modelData.to).arg(modelData.problem) : modelData.to
                            color: modelData.problem.length > 0
                                ? Colours.palette.m3error
                                : (modelData.changed ? Colours.palette.m3primary : Colours.palette.m3outline)
                            font: Tokens.font.body.small
                            elide: Text.ElideMiddle
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: root.hasProblem
                        ? qsTr("Resolve the highlighted names to continue")
                        : (root.changedCount === 1
                            ? qsTr("1 name will change")
                            : qsTr("%1 names will change").arg(root.changedCount))
                    color: root.hasProblem ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledRect {
                    implicitWidth: 70
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: "transparent"

                    StateLayer {
                        color: Colours.palette.m3onSurface
                        onClicked: root.expanded = false
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Cancel")
                        color: Colours.palette.m3primary
                        font: Tokens.font.label.large
                    }
                }

                StyledRect {
                    implicitWidth: 90
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    opacity: (!root.hasProblem && root.changedCount > 0) ? 1.0 : 0.4
                    color: Colours.palette.m3primary

                    StateLayer {
                        color: Colours.palette.m3onPrimary
                        onClicked: {
                            if (root.hasProblem || root.changedCount === 0)
                                return;
                            root.applied(root.preview.map(entry => entry.to));
                            root.expanded = false;
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Rename")
                        color: Colours.palette.m3onPrimary
                        font: Tokens.font.label.large
                    }
                }
            }
        }
    }
}
