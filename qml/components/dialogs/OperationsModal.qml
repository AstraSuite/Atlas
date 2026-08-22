import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../containers"
import prism

Item {
    id: root

    property bool expanded: false

    Connections {
        target: FileOperations
        function onCompletedTasksChanged() {
            root.expanded = true;
        }
    }

    Connections {
        target: CatboxUploader
        function onUploadStarted(filePath) {
            root.expanded = true;
        }
    }

    anchors.fill: parent
    z: 100

    StyledRect {
        id: modalCard

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: Tokens.padding.large
        anchors.bottomMargin: 46
        implicitWidth: 440
        implicitHeight: 400

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerHigh

        visible: opacity > 0.001
        enabled: root.expanded
        opacity: root.expanded ? 1.0 : 0.0
        scale: root.expanded ? 1.0 : 0.94
        transformOrigin: Item.BottomRight
        Behavior on opacity { Anim { type: Anim.FastEffects } }
        Behavior on scale {
            Anim {
                type: Anim.FastEffects
                easing: Tokens.anim.standard
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => mouse.accepted = true
            onWheel: wheel => wheel.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "pending_actions"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    text: qsTr("Operations & Background Tasks")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.builders.large.weight(Font.Bold).build()
                    Layout.fillWidth: true
                }
            }

            // Operations List / Status Area
            VerticalFadeFlickable {
                id: flickable
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: tasksCol.implicitHeight
                clip: true

                ScrollBar.vertical: StyledScrollBar {
                    flickable: flickable
                }

                Column {
                    id: tasksCol
                    width: flickable.width
                    spacing: Tokens.spacing.small

                    // Active Operation Card
                    StyledRect {
                        width: tasksCol.width
                        height: activeCol.implicitHeight + Tokens.padding.medium * 2
                        radius: Tokens.rounding.medium
                        color: Colours.tPalette.m3surfaceContainer
                        visible: FileOperations.progress.running || CatboxUploader.isUploading

                        ColumnLayout {
                            id: activeCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Tokens.padding.medium
                            spacing: Tokens.spacing.small

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                MaterialIcon {
                                    id: activeSyncIcon
                                    text: CatboxUploader.isUploading ? "cloud_upload" : "sync"
                                    color: Colours.palette.m3primary
                                    fontStyle: Tokens.font.icon.small
                                    rotation: 0

                                    NumberAnimation {
                                        target: activeSyncIcon
                                        property: "rotation"
                                        loops: Animation.Infinite
                                        from: 0
                                        to: 360
                                        duration: 1200
                                        running: FileOperations.progress.running || CatboxUploader.isUploading
                                        onRunningChanged: {
                                            if (!running) {
                                                activeSyncIcon.rotation = 0;
                                            }
                                        }
                                    }
                                }

                                StyledText {
                                    text: CatboxUploader.isUploading
                                        ? (qsTr("Uploading %1 to Catbox (%2%)").arg(CatboxUploader.currentFileName).arg(Math.round(CatboxUploader.uploadProgress * 100)))
                                        : (FileOperations.progress.statusText || qsTr("In progress..."))
                                    color: Colours.palette.m3onSurface
                                    font: Tokens.font.body.small
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                StyledRect {
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    radius: Tokens.rounding.full
                                    color: cancelHover.containsMouse ? Colours.palette.m3errorContainer : "transparent"

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "cancel"
                                        color: cancelHover.containsMouse ? Colours.palette.m3onErrorContainer : Colours.palette.m3error
                                        fontStyle: Tokens.font.icon.small
                                    }

                                    MouseArea {
                                        id: cancelHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (CatboxUploader.isUploading) {
                                                CatboxUploader.cancelUpload();
                                            }
                                            FileOperations.cancelOperation();
                                        }
                                    }
                                }
                            }

                            // Progress Bar
                            StyledRect {
                                Layout.fillWidth: true
                                implicitHeight: 6
                                radius: Tokens.rounding.full
                                color: Qt.alpha(Colours.palette.m3outline, 0.25)
                                clip: true

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: Math.max(6, parent.width * Math.min(1.0, Math.max(0.0, CatboxUploader.isUploading ? CatboxUploader.uploadProgress : FileOperations.progress.progress)))
                                    radius: Tokens.rounding.full
                                    color: Colours.palette.m3primary

                                    Behavior on width {
                                        Anim { type: Anim.FastEffects }
                                    }
                                }
                            }

                            StyledText {
                                text: CatboxUploader.isUploading ? CatboxUploader.currentFileName : (FileOperations.progress.currentItem || "")
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                                elide: Text.ElideMiddle
                                visible: text.length > 0
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Completed Tasks Section
                    StyledText {
                        text: qsTr("Recent Operations")
                        color: Colours.palette.m3primary
                        font: Tokens.font.label.medium
                        visible: FileOperations.completedTasks.length > 0
                        width: tasksCol.width
                    }

                    Repeater {
                        model: FileOperations.completedTasks

                        delegate: StyledRect {
                            id: completedItem
                            required property int index
                            required property var modelData

                            width: tasksCol.width
                            height: compCol.implicitHeight + Tokens.padding.small * 2
                            radius: Tokens.rounding.medium
                            color: Colours.tPalette.m3surfaceContainer

                            ColumnLayout {
                                id: compCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Tokens.padding.small
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Tokens.spacing.small

                                    MaterialIcon {
                                        text: completedItem.modelData.success ? "check_circle" : "error"
                                        color: completedItem.modelData.success ? Colours.palette.m3primary : Colours.palette.m3error
                                        fontStyle: Tokens.font.icon.small
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: completedItem.modelData.message || ""
                                        color: Colours.palette.m3onSurface
                                        font: Tokens.font.body.small
                                        wrapMode: Text.WrapAnywhere
                                    }

                                    StyledText {
                                        text: completedItem.modelData.time || ""
                                        color: Colours.palette.m3onSurfaceVariant
                                        font: Tokens.font.label.small
                                    }
                                }

                                // Quick action chips for URL (e.g. Catbox uploads)
                                RowLayout {
                                    visible: Boolean(completedItem.modelData.url && completedItem.modelData.url.length > 0)
                                    spacing: Tokens.spacing.extraSmall
                                    Layout.leftMargin: 24

                                    StyledRect {
                                        implicitWidth: copyChipRow.implicitWidth + Tokens.padding.medium * 2
                                        implicitHeight: 28
                                        radius: Tokens.rounding.full
                                        color: copyChipHover.containsMouse ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                                        RowLayout {
                                            id: copyChipRow
                                            anchors.centerIn: parent
                                            spacing: 4

                                            MaterialIcon {
                                                text: "content_copy"
                                                fontStyle: Tokens.font.icon.small
                                                color: Colours.palette.m3primary
                                            }

                                            StyledText {
                                                text: qsTr("Copy Link")
                                                font: Tokens.font.label.small
                                                color: Colours.palette.m3primary
                                            }
                                        }

                                        MouseArea {
                                            id: copyChipHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                FileOperations.copyTextToClipboard(completedItem.modelData.url);
                                            }
                                        }
                                    }

                                    StyledRect {
                                        implicitWidth: openChipRow.implicitWidth + Tokens.padding.medium * 2
                                        implicitHeight: 28
                                        radius: Tokens.rounding.full
                                        color: openChipHover.containsMouse ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                                        RowLayout {
                                            id: openChipRow
                                            anchors.centerIn: parent
                                            spacing: 4

                                            MaterialIcon {
                                                text: "open_in_new"
                                                fontStyle: Tokens.font.icon.small
                                                color: Colours.palette.m3onSurfaceVariant
                                            }

                                            StyledText {
                                                text: qsTr("Open Link")
                                                font: Tokens.font.label.small
                                                color: Colours.palette.m3onSurfaceVariant
                                            }
                                        }

                                        MouseArea {
                                            id: openChipHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                AppIntegration.openWithDefault(completedItem.modelData.url);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Empty / Idle State
                    StyledRect {
                        width: tasksCol.width
                        height: 120
                        radius: Tokens.rounding.medium
                        color: Colours.tPalette.m3surfaceContainer
                        visible: !FileOperations.progress.running && !CatboxUploader.isUploading && FileOperations.completedTasks.length === 0

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: Tokens.spacing.extraSmall

                            MaterialIcon {
                                Layout.alignment: Qt.AlignHCenter
                                text: "check_circle"
                                color: Colours.palette.m3primary
                                fontStyle: Tokens.font.icon.large
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: qsTr("No background operations active")
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.small
                            }
                        }
                    }
                }
            }

            // Bottom Actions
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledRect {
                    visible: FileOperations.completedTasks.length > 0
                    implicitWidth: 80
                    implicitHeight: 34
                    radius: Tokens.rounding.full
                    color: clearHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Clear")
                        color: Colours.palette.m3primary
                        font: Tokens.font.label.medium
                    }

                    MouseArea {
                        id: clearHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: FileOperations.clearCompletedTasks()
                    }
                }

                Item { Layout.fillWidth: true }

                StyledRect {
                    implicitWidth: 80
                    implicitHeight: 34
                    radius: Tokens.rounding.full
                    color: doneHover.containsMouse ? Colours.palette.m3primaryContainer : Colours.palette.m3primary

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Close")
                        color: doneHover.containsMouse ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onPrimary
                        font: Tokens.font.label.medium
                    }

                    MouseArea {
                        id: doneHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.expanded = false
                    }
                }
            }
        }
    }
}
