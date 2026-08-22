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
    signal operationsRequested()

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

        // Git Branch Chip
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

                StyledToolTip {
                    text: qsTr("Git branch: %1").arg(GitManager.branchName)
                    visible: gitChipHover.containsMouse
                    y: -height - Tokens.padding.extraSmall
                }
            }
        }

        // Compact Zoom Slider with Material Icons
        RowLayout {
            spacing: Tokens.spacing.extraSmall

            Item {
                implicitWidth: zoomSmallIcon.implicitWidth
                implicitHeight: zoomSmallIcon.implicitHeight

                MaterialIcon {
                    id: zoomSmallIcon
                    anchors.centerIn: parent
                    text: "photo_size_select_small"
                    fontStyle: Tokens.font.icon.small
                    color: zoomSlider.value <= 0.1 ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                }

                MouseArea {
                    id: zoomSmallHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        zoomSlider.value = 0.0;
                        root.zoomChanged(48);
                    }
                }

                StyledToolTip {
                    text: qsTr("Small icons")
                    visible: zoomSmallHover.containsMouse
                    y: -height - Tokens.padding.extraSmall
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

            Item {
                implicitWidth: zoomLargeIcon.implicitWidth
                implicitHeight: zoomLargeIcon.implicitHeight

                MaterialIcon {
                    id: zoomLargeIcon
                    anchors.centerIn: parent
                    text: "photo_size_select_large"
                    fontStyle: Tokens.font.icon.small
                    color: zoomSlider.value >= 0.9 ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                }

                MouseArea {
                    id: zoomLargeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        zoomSlider.value = 1.0;
                        root.zoomChanged(180);
                    }
                }

                StyledToolTip {
                    text: qsTr("Large icons")
                    visible: zoomLargeHover.containsMouse
                    y: -height - Tokens.padding.extraSmall
                }
            }
        }

        // Operations / Background Activity Button
        StyledRect {
            implicitWidth: 28
            implicitHeight: 28
            radius: Tokens.rounding.full
            color: opsHover.containsMouse
                ? Colours.tPalette.m3surfaceContainerHighest
                : ((FileOperations.progress.running || CatboxUploader.isUploading) ? Qt.alpha(Colours.palette.m3primary, 0.2) : "transparent")

            MaterialIcon {
                id: opsIcon
                anchors.centerIn: parent
                text: (FileOperations.progress.running || CatboxUploader.isUploading) ? "sync" : "pending_actions"
                color: (FileOperations.progress.running || CatboxUploader.isUploading) ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.small
                rotation: 0

                NumberAnimation {
                    target: opsIcon
                    property: "rotation"
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 1200
                    running: FileOperations.progress.running || CatboxUploader.isUploading
                    onRunningChanged: {
                        if (!running) {
                            opsIcon.rotation = 0;
                        }
                    }
                }
            }

            MouseArea {
                id: opsHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.operationsRequested()
            }

            StyledToolTip {
                text: FileOperations.progress.running ? qsTr("Operations in progress") : qsTr("Operations history")
                visible: opsHover.containsMouse
                y: -height - Tokens.padding.extraSmall
            }
        }
    }
}
