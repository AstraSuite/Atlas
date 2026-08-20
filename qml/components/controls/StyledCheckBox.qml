import QtQuick
import QtQuick.Layouts
import "../"
import "../../"

Item {
    id: root

    property bool checked: false
    property string text: ""

    signal toggled(bool checked)
    signal clicked()

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Math.max(36, rowLayout.implicitHeight)
    opacity: root.enabled ? 1.0 : 0.38

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        // Checkbox Touch / Hover Target & Box
        Item {
            implicitWidth: 36
            implicitHeight: 36
            Layout.alignment: Qt.AlignVCenter

            // State Layer (Circular Hover / Ripple Circle - 36x36)
            Rectangle {
                anchors.centerIn: parent
                width: 36
                height: 36
                radius: 18
                color: root.checked ? Colours.palette.m3primary : Colours.palette.m3onSurface
                opacity: checkArea.containsMouse ? (root.checked ? 0.12 : 0.08) : 0.0

                Behavior on opacity {
                    Anim { type: Anim.FastEffects }
                }
                Behavior on color {
                    CAnim {}
                }
            }

            // M3 Box Container (18x18 with 2px radius)
            Rectangle {
                id: box
                anchors.centerIn: parent
                width: 18
                height: 18
                radius: 2
                color: "transparent"
                border.color: root.checked
                    ? Colours.palette.m3primary
                    : (checkArea.containsMouse ? Colours.palette.m3onSurface : Colours.palette.m3outline)
                border.width: 2

                Behavior on border.color {
                    CAnim {}
                }

                // Checked fill background
                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: Colours.palette.m3primary
                    opacity: root.checked ? 1.0 : 0.0
                    Behavior on opacity {
                        Anim { type: Anim.FastEffects }
                    }
                }

                // Checkmark Icon
                MaterialIcon {
                    id: checkIcon
                    anchors.centerIn: parent
                    text: "check"
                    fontStyle.pixelSize: 14
                    color: Colours.palette.m3onPrimary
                    scale: root.checked ? 1.0 : 0.2
                    opacity: root.checked ? 1.0 : 0.0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.4
                        }
                    }
                    Behavior on opacity {
                        Anim { type: Anim.FastEffects }
                    }
                }
            }
        }

        // Optional Text Label
        StyledText {
            id: label
            visible: root.text.length > 0
            text: root.text
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurface
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: checkArea
        anchors.fill: parent
        hoverEnabled: root.enabled
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            root.checked = !root.checked;
            root.toggled(root.checked);
            root.clicked();
        }
    }
}
