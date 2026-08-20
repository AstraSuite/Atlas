import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../"
import "../controls"
import prism

StyledRect {
    id: root

    required property var activeModel
    property int selectedCount: 0
    property string selectedSizeFormatted: ""
    property real zoomLevel: 80
    signal zoomChanged(real level)

    implicitHeight: statusRow.implicitHeight + Tokens.padding.extraSmall * 2
    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: statusRow

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        // Item Count
        StyledText {
            text: root.activeModel ? qsTr("%1 items").arg(root.activeModel.count) : ""
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.medium
        }

        // Selected summary
        StyledText {
            visible: root.selectedCount > 0
            text: qsTr("•  %1 selected %2").arg(root.selectedCount).arg(root.selectedSizeFormatted.length > 0 ? `(${root.selectedSizeFormatted})` : "")
            color: Colours.palette.m3primary
            font: Tokens.font.label.medium
        }

        Item {
            Layout.fillWidth: true
        }

        // Zoom Icons Slider with Material Icons
        RowLayout {
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "photo_size_select_small"
                fontStyle: Tokens.font.icon.small
                color: zoomSlider.value <= 60 ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        zoomSlider.value = 48;
                        root.zoomChanged(48);
                    }
                }
            }

            StyledSlider {
                id: zoomSlider
                implicitWidth: 120
                implicitHeight: 24
                from: 48
                to: 180
                value: root.zoomLevel
                onMoved: root.zoomChanged(value)
            }

            MaterialIcon {
                text: "photo_size_select_large"
                fontStyle: Tokens.font.icon.small
                color: zoomSlider.value >= 160 ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        zoomSlider.value = 180;
                        root.zoomChanged(180);
                    }
                }
            }

            StyledText {
                text: `${Math.round((zoomSlider.value / 80) * 100)}%`
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
            }
        }
    }
}
