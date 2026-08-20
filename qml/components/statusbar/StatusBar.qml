import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../"
import "../controls"
import prism

StyledRect {
    id: root

    required property var activeModel
    property var activeTab: null
    property int selectedCount: 0
    property string selectedSizeFormatted: ""
    property real zoomLevel: 80
    signal zoomChanged(real level)
    signal gitRequested()

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

        // Git Branch Chip (no outline, sits in bottom panel)
        Item {
            implicitWidth: gitChipContent.implicitWidth + 20
            implicitHeight: 26
            visible: GitManager.isGitRepo && GitManager.branchName.length > 0

            Binding {
                target: GitManager
                property: "currentPath"
                value: root.activeTab ? root.activeTab.currentPath : ""
            }

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: gitChipHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Qt.alpha(Colours.palette.m3tertiary, 0.15)

                RowLayout {
                    id: gitChipContent
                    anchors.centerIn: parent
                    spacing: 6

                    MaterialIcon {
                        text: "fork_right"
                        fontStyle: Tokens.font.icon.small
                        color: Colours.palette.m3tertiary
                    }

                    StyledText {
                        text: GitManager.branchName
                        font: Tokens.font.label.small
                        color: Colours.palette.m3tertiary
                    }
                }

                MouseArea {
                    id: gitChipHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.gitRequested()
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // Compact Zoom Slider with Material Icons
        RowLayout {
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                text: "photo_size_select_small"
                fontStyle: Tokens.font.icon.small
                color: zoomSlider.value <= 0.1 ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        zoomSlider.value = 0.0;
                        root.zoomChanged(48);
                    }
                }
            }

            StyledSlider {
                id: zoomSlider
                implicitWidth: 80
                implicitHeight: 8
                from: 0.0
                to: 1.0
                value: (root.zoomLevel - 48) / (180 - 48)

                onInteraction: v => {
                    let level = 48 + v * (180 - 48);
                    root.zoomChanged(level);
                }
            }

            MaterialIcon {
                text: "photo_size_select_large"
                fontStyle: Tokens.font.icon.small
                color: zoomSlider.value >= 0.9 ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        zoomSlider.value = 1.0;
                        root.zoomChanged(180);
                    }
                }
            }
        }
    }
}
