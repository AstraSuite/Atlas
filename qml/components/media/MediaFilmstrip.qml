import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import prism

StyledRect {
    id: root

    property var mediaList: []
    property int currentIndex: -1

    signal itemSelected(int index)

    implicitHeight: 76
    radius: Tokens.rounding.medium
    color: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.85)

    ListView {
        id: filmListView
        anchors.fill: parent
        anchors.margins: 6
        orientation: ListView.Horizontal
        spacing: 8
        clip: true
        model: root.mediaList

        highlightFollowsCurrentItem: true
        currentIndex: root.currentIndex

        delegate: StyledRect {
            id: thumbDelegate
            required property int index
            required property var modelData

            implicitWidth: 64
            implicitHeight: 64
            radius: Tokens.rounding.small
            color: root.currentIndex === index ? Colours.palette.m3primary : (thumbHover.containsMouse ? Colours.palette.m3surfaceContainerHigh : Colours.palette.m3surfaceContainer)

            Rectangle {
                anchors.fill: parent
                anchors.margins: root.currentIndex === index ? 2 : 0
                radius: Tokens.rounding.small
                color: Colours.palette.m3surface
                clip: true

                CachingIconImage {
                    anchors.fill: parent
                    implicitSize: 64
                    source: "image://thumb/" + thumbDelegate.modelData.path
                }
            }

            MouseArea {
                id: thumbHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.itemSelected(thumbDelegate.index)
            }
        }
    }
}
