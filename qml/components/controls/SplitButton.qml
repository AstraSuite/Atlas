import QtQuick
import QtQuick.Layouts
import "../"
import prism

Row {
    id: root

    enum Type {
        Filled,
        Tonal
    }

    property real horizontalPadding: Tokens.padding.medium
    property real verticalPadding: Tokens.padding.small
    property int type: SplitButton.Filled
    property bool disabled: false
    property string icon: ""
    property string text: ""

    property color colour: type === SplitButton.Filled ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer
    property color textColour: type === SplitButton.Filled ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
    property color disabledColour: Qt.alpha(Colours.palette.m3onSurface, 0.1)
    property color disabledTextColour: Qt.alpha(Colours.palette.m3onSurface, 0.38)

    signal clicked()
    signal menuTriggered()

    spacing: 1

    StyledRect {
        radius: implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
        topRightRadius: 4
        bottomRightRadius: 4
        color: root.disabled ? root.disabledColour : root.colour

        implicitWidth: textRow.implicitWidth + root.horizontalPadding * 2
        implicitHeight: expandBtn.implicitHeight

        StateLayer {
            id: stateLayer
            anchors.fill: parent
            topRightRadius: parent.topRightRadius
            bottomRightRadius: parent.bottomRightRadius
            color: root.textColour
            disabled: root.disabled
            onClicked: root.clicked()
        }

        RowLayout {
            id: textRow
            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            MaterialIcon {
                id: iconLabel
                visible: root.icon.length > 0
                Layout.alignment: Qt.AlignVCenter
                text: root.icon
                color: root.disabled ? root.disabledTextColour : root.textColour
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                id: label
                Layout.alignment: Qt.AlignVCenter
                text: root.text
                color: root.disabled ? root.disabledTextColour : root.textColour
                font: Tokens.font.label.large
            }
        }
    }

    StyledRect {
        id: expandBtn
        radius: implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
        topLeftRadius: 4
        bottomLeftRadius: 4
        color: root.disabled ? root.disabledColour : root.colour

        implicitWidth: 32
        implicitHeight: 36

        StateLayer {
            id: expandStateLayer
            anchors.fill: parent
            topLeftRadius: parent.topLeftRadius
            bottomLeftRadius: parent.bottomLeftRadius
            color: root.textColour
            disabled: root.disabled
            onClicked: root.menuTriggered()
        }

        MaterialIcon {
            id: expandIcon
            anchors.centerIn: parent
            text: "expand_more"
            color: root.disabled ? root.disabledTextColour : root.textColour
            fontStyle: Tokens.font.icon.small
        }
    }
}
