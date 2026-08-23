import QtQuick
import QtQuick.Layouts
import "../"
import "../controls"
import prism

MouseArea {
    id: root

    property bool expanded: false
    property var targetPaths: []

    signal confirmed(var paths)

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
            root.targetPaths = [];
            if (typeof splitContainer !== "undefined" && splitContainer) {
                splitContainer.focusActiveView();
            }
        }
    }

    function accept(): void {
        const paths = root.targetPaths;
        root.expanded = false;
        if (paths.length > 0) {
            root.confirmed(paths);
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.4)
    }

    StyledRect {
        id: modalCard

        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 440)
        height: Math.min(parent.height - 32, modalCol.implicitHeight + Tokens.padding.large * 2)
        implicitWidth: Math.min(parent.width - 48, 440)
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
                    text: "delete_forever"
                    color: Colours.palette.m3error
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Delete permanently")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.medium
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.targetPaths.length === 1 ? qsTr("\"%1\" will be deleted permanently. This cannot be undone.").arg(root.targetPaths.length > 0 ? root.targetPaths[0].split("/").pop() : "") : qsTr("%n items will be deleted permanently. This cannot be undone.", "", root.targetPaths.length)
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.medium
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Item {
                    Layout.fillWidth: true
                }

                TextButton {
                    type: ButtonBase.Text
                    text: qsTr("Cancel")
                    onClicked: root.expanded = false
                }

                TextButton {
                    type: ButtonBase.Filled
                    activeColour: Colours.palette.m3error
                    activeOnColour: Colours.palette.m3onError
                    inactiveColour: Colours.palette.m3error
                    inactiveOnColour: Colours.palette.m3onError
                    text: qsTr("Delete")
                    onClicked: root.accept()
                }
            }
        }
    }

    Keys.onReturnPressed: root.accept()
    Keys.onEnterPressed: root.accept()
}
