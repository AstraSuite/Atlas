import QtQuick
import QtQuick.Layouts
import "../"
import "../controls"
import atlas

MouseArea {
    id: root

    property bool expanded: false
    property string targetPath: ""

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
            root.forceActiveFocus();
        } else {
            root.targetPath = "";
            if (typeof splitContainer !== "undefined" && splitContainer) {
                splitContainer.focusActiveView();
            }
        }
    }

    function open(path: string): void {
        root.targetPath = path;
        root.expanded = true;
    }

    function run(inTerminal: bool): void {
        const path = root.targetPath;
        root.expanded = false;
        if (path.length > 0) {
            AppIntegration.runExecutable(path, inTerminal);
        }
    }

    function display(): void {
        const path = root.targetPath;
        root.expanded = false;
        if (path.length > 0) {
            AppIntegration.openWithDefault(path);
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.4)
    }

    StyledRect {
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 460)
        height: Math.min(parent.height - 32, modalCol.implicitHeight + Tokens.padding.large * 2)
        implicitWidth: Math.min(parent.width - 48, 460)
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

            RowLayout {
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "terminal"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Run this file?")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.medium
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("\"%1\" is executable. Run it as a program, or open it to look at its contents?")
                    .arg(root.targetPath.split("/").pop())
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.medium
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                TextButton {
                    type: ButtonBase.Text
                    text: qsTr("Open")
                    onClicked: root.display()
                }

                Item {
                    Layout.fillWidth: true
                }

                TextButton {
                    type: ButtonBase.Tonal
                    text: qsTr("In Terminal")
                    onClicked: root.run(true)
                }

                TextButton {
                    type: ButtonBase.Filled
                    text: qsTr("Run")
                    onClicked: root.run(false)
                }
            }
        }
    }

    Keys.onReturnPressed: root.run(false)
    Keys.onEnterPressed: root.run(false)
}
