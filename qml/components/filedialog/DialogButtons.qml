import QtQuick
import QtQuick.Layouts
import "../"
import "../controls"
import prism

StyledRect {
    id: root

    required property var dialog
    required property var folder

    property bool uploadingFromDialog: false

    Connections {
        target: CatboxUploader
        function onUploadFinished(success, result, path) {
            if (root.uploadingFromDialog) {
                root.uploadingFromDialog = false;
                if (success) {
                    // Successfully uploaded and copied to clipboard;
                    // Exit file chooser without returning the local file path
                    root.dialog.rejected();
                }
            }
        }
    }

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

        // Upload to Catbox Button (for file chooser mode)
        StyledRect {
            visible: !root.dialog.directoryOnly
            color: uploadHover.containsMouse ? Colours.palette.m3tertiaryContainer : Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.medium

            implicitWidth: uploadRow.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: uploadRow.implicitHeight + Tokens.padding.medium * 2

            readonly property bool canUpload: root.dialog.selectionValid &&
                root.folder && root.folder.currentItem && root.folder.currentItem.modelData &&
                !root.folder.currentItem.modelData.isDir && !CatboxUploader.isUploading

            RowLayout {
                id: uploadRow
                anchors.centerIn: parent
                spacing: 6

                MaterialIcon {
                    text: "cloud_upload"
                    color: (root.uploadingFromDialog && CatboxUploader.isUploading)
                        ? Colours.palette.m3primary
                        : (parent.parent.canUpload ? Colours.palette.m3primary : Colours.palette.m3outline)
                    fontStyle: Tokens.font.icon.small

                    RotationAnimation on rotation {
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1200
                        running: root.uploadingFromDialog && CatboxUploader.isUploading
                    }
                }

                StyledText {
                    id: uploadText
                    text: (root.uploadingFromDialog && CatboxUploader.isUploading)
                        ? qsTr("Uploading (%1%)...").arg(Math.round(CatboxUploader.uploadProgress * 100))
                        : qsTr("Upload to Catbox")
                    color: parent.parent.canUpload ? Colours.palette.m3onSurface : Colours.palette.m3outline
                }
            }

            StateLayer {
                id: uploadHover
                disabled: !parent.canUpload
                onClicked: {
                    if (parent.canUpload) {
                        let path = root.folder.currentItem.modelData.path;
                        root.uploadingFromDialog = true;
                        CatboxUploader.uploadFile(path);
                    }
                }
            }

            StyledToolTip {
                text: qsTr("Upload selected file directly to Catbox and copy link to clipboard")
                visible: uploadHover.containsMouse
            }
        }

        // Select Button
        StyledRect {
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.medium

            implicitWidth: selectText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: selectText.implicitHeight + Tokens.padding.medium * 2

            StateLayer {
                disabled: !root.dialog.selectionValid || CatboxUploader.isUploading
                onClicked: {
                    if (root.dialog.selectionValid && !CatboxUploader.isUploading) {
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
                color: root.dialog.selectionValid && !CatboxUploader.isUploading ? Colours.palette.m3onSurface : Colours.palette.m3outline
            }
        }

        // Cancel Button
        StyledRect {
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.medium

            implicitWidth: cancelText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: cancelText.implicitHeight + Tokens.padding.medium * 2

            StateLayer {
                onClicked: {
                    if (CatboxUploader.isUploading) {
                        CatboxUploader.cancelUpload();
                    }
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
