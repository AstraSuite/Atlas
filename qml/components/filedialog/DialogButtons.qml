import QtQuick
import QtQuick.Layouts
import "../"
import "../controls"

StyledRect {
    id: root

    required property var dialog
    required property var folder

    implicitHeight: inner.implicitHeight + Tokens.padding.medium * 2

    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium

        spacing: Tokens.spacing.small

        StyledText {
            text: root.dialog.directoryOnly ? qsTr("Type:") : qsTr("Filter:")
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: Tokens.spacing.medium

            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.medium

            StyledText {
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight

                text: root.dialog.directoryOnly
                    ? qsTr("Folders only")
                    : `${root.dialog.filterLabel} (${root.dialog.filters.map(f => f === '*' ? '*.*' : `*.${f}`).join(", ")})`
            }
        }

        // Compact Zoom Slider
        RowLayout {
            spacing: Tokens.spacing.extraSmall
            Layout.rightMargin: Tokens.spacing.small

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
                        root.dialog.zoomLevel = 48;
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
                value: (root.dialog.zoomLevel - 48) / (180 - 48)
                onMoved: {
                    root.dialog.zoomLevel = Math.round(48 + value * (180 - 48));
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
                        root.dialog.zoomLevel = 180;
                    }
                }

                StyledToolTip {
                    text: qsTr("Large icons")
                    visible: zoomLargeHover.containsMouse
                    y: -height - Tokens.padding.extraSmall
                }
            }
        }

        StyledRect {
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.medium

            implicitWidth: selectText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: selectText.implicitHeight + Tokens.padding.medium * 2

            StateLayer {
                disabled: !root.dialog.selectionValid
                onClicked: {
                    if (root.dialog.selectionValid) {
                        if (root.dialog.directoryOnly) {
                            if (root.folder && root.folder.currentItem && root.folder.currentItem.modelData && root.folder.currentItem.modelData.isDir) {
                                root.dialog.accepted(root.folder.currentItem.modelData.path);
                            } else {
                                root.dialog.accepted(root.dialog.currentPath);
                            }
                        } else if (root.folder && root.folder.currentItem && root.folder.currentItem.modelData) {
                            root.dialog.accepted(root.folder.currentItem.modelData.path);
                        }
                    }
                }
            }

            StyledText {
                id: selectText

                anchors.centerIn: parent
                anchors.margins: Tokens.padding.medium

                text: root.dialog.directoryOnly ? qsTr("Select Folder") : qsTr("Select")
                color: root.dialog.selectionValid ? Colours.palette.m3onSurface : Colours.palette.m3outline
            }
        }

        StyledRect {
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.medium

            implicitWidth: cancelText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: cancelText.implicitHeight + Tokens.padding.medium * 2

            StateLayer {
                onClicked: {
                    root.dialog.rejected();
                }
            }

            StyledText {
                id: cancelText

                anchors.centerIn: parent
                anchors.margins: Tokens.padding.medium

                text: qsTr("Cancel")
            }
        }
    }
}
