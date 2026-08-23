import QtQuick
import QtQuick.Layouts
import "../"
import "../containers"
import prism

ConnectedRect {
    id: root

    property alias icon: iconLabel.text
    property alias text: label.text
    property alias subtext: subLabel.text
    property alias model: splitBtn.model
    property alias currentValue: splitBtn.currentValue
    property alias valueKey: splitBtn.valueKey
    property alias labelKey: splitBtn.labelKey
    property alias iconKey: splitBtn.iconKey
    property alias disabled: splitBtn.disabled
    property color iconColor: Colours.palette.m3onSurfaceVariant

    readonly property alias splitButton: splitBtn

    signal selected(var value, int index)

    Layout.fillWidth: true
    implicitHeight: Math.max(56, row.implicitHeight + Tokens.padding.medium * 2)

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large
        spacing: Tokens.spacing.medium

        MaterialIcon {
            id: iconLabel
            visible: text.length > 0
            color: root.iconColor
            fontStyle: Tokens.font.icon.medium
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            StyledText {
                id: label
                Layout.fillWidth: true
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurface
                elide: Text.ElideRight
            }

            StyledText {
                id: subLabel
                Layout.fillWidth: true
                visible: text.length > 0
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        SplitButton {
            id: splitBtn
            Layout.alignment: Qt.AlignVCenter
            onSelected: (val, idx) => root.selected(val, idx)
        }
    }
}
