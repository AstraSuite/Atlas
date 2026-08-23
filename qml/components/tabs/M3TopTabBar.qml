import QtQuick
import QtQuick.Layouts
import "../"
import "../containers"

Item {
    id: root

    property var model: []
    property int currentIndex: 0
    signal tabSelected(int index)

    implicitHeight: 64
    implicitWidth: 400

    readonly property int count: root.model ? root.model.length : 0

    RowLayout {
        id: tabsRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 52
        spacing: 0

        Repeater {
            model: root.model

            delegate: Item {
                id: tabBtn
                required property int index
                required property var modelData

                readonly property bool isCurrent: root.currentIndex === tabBtn.index

                Layout.fillWidth: true
                Layout.fillHeight: true

                StateLayer {
                    id: stateLayer
                    anchors.fill: parent
                    radius: Tokens.rounding.medium
                    color: tabBtn.isCurrent ? Colours.palette.m3primary : Colours.palette.m3onSurface
                    onClicked: {
                        if (root.currentIndex !== tabBtn.index) {
                            root.currentIndex = tabBtn.index;
                            root.tabSelected(tabBtn.index);
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - Tokens.padding.medium * 2
                    spacing: 3

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: tabBtn.modelData.icon
                        color: tabBtn.isCurrent ? Colours.palette.m3primary : (stateLayer.containsMouse ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant)
                        fill: tabBtn.isCurrent ? 1 : 0
                        fontStyle: Tokens.font.icon.medium

                        Behavior on color { CAnim {} }
                        Behavior on fill { Anim { type: Anim.DefaultEffects } }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: tabBtn.modelData.label
                        color: tabBtn.isCurrent ? Colours.palette.m3primary : (stateLayer.containsMouse ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant)
                        font: tabBtn.isCurrent
                            ? Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                            : Tokens.font.body.medium

                        Behavior on color { CAnim {} }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: event => {
                        if (event.angleDelta.y < 0) {
                            let nextIdx = Math.min(root.currentIndex + 1, root.count - 1);
                            if (root.currentIndex !== nextIdx) {
                                root.currentIndex = nextIdx;
                                root.tabSelected(nextIdx);
                            }
                        } else if (event.angleDelta.y > 0) {
                            let prevIdx = Math.max(root.currentIndex - 1, 0);
                            if (root.currentIndex !== prevIdx) {
                                root.currentIndex = prevIdx;
                                root.tabSelected(prevIdx);
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: indicator
        anchors.top: tabsRow.bottom
        anchors.topMargin: 4
        implicitHeight: 3

        readonly property real tabWidth: root.count > 0 ? (root.width / root.count) : 0
        implicitWidth: Math.max(tabWidth * 0.45, 56)

        x: tabWidth * root.currentIndex + (tabWidth - implicitWidth) / 2
        clip: true

        StyledRect {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            implicitHeight: parent.implicitHeight * 2
            color: Colours.palette.m3primary
            radius: Tokens.rounding.full
        }

        Behavior on x {
            Anim { type: Anim.DefaultSpatial }
        }
        Behavior on implicitWidth {
            Anim { type: Anim.DefaultSpatial }
        }
    }

    StyledRect {
        id: separator
        anchors.top: indicator.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: 1
        color: Colours.palette.m3outlineVariant
    }
}
