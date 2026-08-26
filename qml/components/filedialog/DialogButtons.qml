import QtQuick
import QtQuick.Layouts
import "../"
import "../controls"
import atlas

StyledRect {
    id: root

    required property var dialog
    required property var folder

    function focusSaveName(): void {
        saveNameInput.forceActiveFocus();
        const name = root.dialog.saveName;
        const dot = name.lastIndexOf(".");
        saveNameInput.select(0, dot > 0 ? dot : name.length);
    }

    function commitSave() {
        if (!root.dialog.saveMode)
            return;
        const name = root.dialog.saveName.trim();
        if (name.length === 0 || name.indexOf("/") >= 0)
            return;
        root.dialog.accepted(root.dialog.savePath);
    }

    implicitHeight: inner.implicitHeight + Tokens.padding.medium * 2

    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: inner

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium

        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            visible: root.dialog.saveMode
            spacing: Tokens.spacing.small

            StyledText {
                text: qsTr("Name:")
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: Tokens.rounding.medium
                color: Colours.tPalette.m3surfaceContainerHigh
                border.color: saveNameInput.activeFocus ? Colours.palette.m3primary : "transparent"
                border.width: saveNameInput.activeFocus ? 2 : 0

                TextInput {
                    id: saveNameInput
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.dialog.saveName
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.medium
                    selectByMouse: true
                    clip: true
                    onTextChanged: root.dialog.saveName = text
                    onAccepted: root.commitSave()
                }
            }

            StyledText {
                visible: root.dialog.saveWouldOverwrite
                text: qsTr("already exists")
                color: Colours.palette.m3error
                font: Tokens.font.label.medium
            }
        }

        RowLayout {
        Layout.fillWidth: true
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

                text: {
                    if (!root.dialog) return "";
                    if (root.dialog.directoryOnly) return qsTr("Folders only");
                    let label = root.dialog.filterLabel || qsTr("All Files");
                    if (root.dialog.filters && Array.isArray(root.dialog.filters) && root.dialog.filters.length > 0) {
                        return `${label} (${root.dialog.filters.map(f => f === '*' ? '*.*' : `*.${f}`).join(", ")})`;
                    }
                    return label;
                }
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

        // Select Button
        StyledRect {
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.medium

            implicitWidth: selectText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: selectText.implicitHeight + Tokens.padding.medium * 2

            StateLayer {
                disabled: root.dialog.saveMode
                    ? root.dialog.saveName.trim().length === 0
                    : (root.dialog.multiple && root.folder && root.folder.selectedPaths.length > 0)
                        ? false
                        : !root.dialog.selectionValid
                onClicked: {
                    if (root.dialog.saveMode) {
                        root.commitSave();
                    } else if (root.dialog.multiple && root.folder && root.folder.selectedPaths.length > 0) {
                        root.dialog.acceptedMultiple(root.folder.selectedPaths);
                    } else if (root.dialog.selectionValid) {
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

                text: root.dialog.saveMode
                    ? (root.dialog.saveWouldOverwrite ? qsTr("Overwrite") : qsTr("Save"))
                    : (root.dialog.directoryOnly ? qsTr("Select Folder")
                        : (root.dialog.multiple && root.folder && root.folder.selectedPaths.length > 0
                            ? qsTr("Select %1").arg(root.folder.selectedPaths.length) : qsTr("Select")))
                color: {
                    if (root.dialog.saveMode) {
                        if (root.dialog.saveName.trim().length === 0)
                            return Colours.palette.m3outline;
                        return root.dialog.saveWouldOverwrite ? Colours.palette.m3error : Colours.palette.m3onSurface;
                    }
                return (root.dialog.selectionValid || (root.dialog.multiple && root.folder && root.folder.selectedPaths.length > 0))
                    ? Colours.palette.m3onSurface
                    : Colours.palette.m3outline;
                }
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
}
