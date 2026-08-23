import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../controls"
import prism

MouseArea {
    id: root

    property bool expanded: false
    property string targetPath: ""
    property int currentTab: 0
    property string hashToCompare: ""
    property string defaultAppName: ""

    function updateDefaultApp() {
        if (targetPath && !meta.isDir) {
            let app = MimeService.getDefaultAppForFile(targetPath);
            if (app && app.name) {
                defaultAppName = app.name;
            } else {
                defaultAppName = "";
            }
        } else {
            defaultAppName = "";
        }
    }

    onExpandedChanged: {
        if (expanded && targetPath) {
            meta.path = targetPath;
            currentTab = 0;
            hashToCompare = "";
            updateDefaultApp();
        }
    }

    FileMetadata {
        id: meta
        path: root.targetPath
    }

    anchors.fill: parent
    visible: opacity > 0.001
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: expanded = false
    onWheel: wheel => wheel.accepted = true

    opacity: expanded ? 1 : 0
    Behavior on opacity { Anim { type: Anim.FastEffects } }

    Rectangle {
        anchors.fill: parent
        color: Colours.palette.m3scrim
        opacity: 0.45
    }

    StyledRect {
        id: dialog

        anchors.centerIn: parent
        width: Math.min(parent.width - 32, 480)
        height: Math.min(parent.height - 32, 560)
        implicitWidth: 480
        implicitHeight: 560

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainer

        scale: root.expanded ? 1.0 : 0.94
        Behavior on scale { Anim { type: Anim.FastEffects; easing: Tokens.anim.standard } }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => mouse.accepted = true
            onWheel: wheel => wheel.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            // Header Title
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: meta.isDir ? "folder" : "description"
                    fontStyle: Tokens.font.icon.medium
                    color: Colours.palette.m3primary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: meta.name
                    font: Tokens.font.title.medium
                    color: Colours.palette.m3onSurface
                    elide: Text.ElideMiddle
                }
            }

            // Tab Bar Switcher
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainerHigh

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    StyledRect {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Tokens.rounding.full
                        color: root.currentTab === 0 ? Colours.palette.m3secondaryContainer : "transparent"

                        StyledText {
                            anchors.centerIn: parent
                            text: qsTr("General")
                            font: Tokens.font.label.medium
                            color: root.currentTab === 0 ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTab = 0
                        }
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Tokens.rounding.full
                        color: root.currentTab === 1 ? Colours.palette.m3secondaryContainer : "transparent"

                        StyledText {
                            anchors.centerIn: parent
                            text: qsTr("Permissions")
                            font: Tokens.font.label.medium
                            color: root.currentTab === 1 ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTab = 1
                        }
                    }

                    StyledRect {
                        visible: !meta.isDir
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Tokens.rounding.full
                        color: root.currentTab === 2 ? Colours.palette.m3secondaryContainer : "transparent"

                        StyledText {
                            anchors.centerIn: parent
                            text: qsTr("Checksums")
                            font: Tokens.font.label.medium
                            color: root.currentTab === 2 ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentTab = 2;
                                if (!meta.md5) meta.calculateChecksums();
                            }
                        }
                    }
                }
            }

            // Tab 0: General
            ColumnLayout {
                visible: root.currentTab === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    StyledText { Layout.preferredWidth: 110; text: qsTr("Type:"); font: Tokens.font.label.medium; color: Colours.palette.m3onSurfaceVariant }
                    StyledText { Layout.fillWidth: true; text: meta.mimeDescription || (meta.isDir ? qsTr("Folder") : meta.mimeType); font: Tokens.font.body.medium; color: Colours.palette.m3onSurface; elide: Text.ElideRight }
                }
                RowLayout {
                    Layout.fillWidth: true
                    StyledText { Layout.preferredWidth: 110; text: qsTr("Location:"); font: Tokens.font.label.medium; color: Colours.palette.m3onSurfaceVariant }
                    StyledText { Layout.fillWidth: true; text: meta.path; font: Tokens.font.body.small; color: Colours.palette.m3onSurface; elide: Text.ElideMiddle }
                }
                RowLayout {
                    Layout.fillWidth: true
                    StyledText { Layout.preferredWidth: 110; text: meta.isDir ? qsTr("Contents:") : qsTr("Size:"); font: Tokens.font.label.medium; color: Colours.palette.m3onSurfaceVariant }
                    StyledText { Layout.fillWidth: true; text: meta.isDir ? qsTr("%1 items").arg(meta.itemCount) : meta.formattedSize; font: Tokens.font.body.medium; color: Colours.palette.m3onSurface }
                }
                RowLayout {
                    visible: meta.imageDimensions.length > 0
                    Layout.fillWidth: true
                    StyledText { Layout.preferredWidth: 110; text: qsTr("Dimensions:"); font: Tokens.font.label.medium; color: Colours.palette.m3onSurfaceVariant }
                    StyledText { Layout.fillWidth: true; text: meta.imageDimensions; font: Tokens.font.body.medium; color: Colours.palette.m3onSurface }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Colours.palette.m3outlineVariant; opacity: 0.5 }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText { Layout.preferredWidth: 110; text: qsTr("Created:"); font: Tokens.font.label.medium; color: Colours.palette.m3onSurfaceVariant }
                    StyledText { Layout.fillWidth: true; text: meta.formattedCreated; font: Tokens.font.body.small; color: Colours.palette.m3onSurface }
                }
                RowLayout {
                    Layout.fillWidth: true
                    StyledText { Layout.preferredWidth: 110; text: qsTr("Modified:"); font: Tokens.font.label.medium; color: Colours.palette.m3onSurfaceVariant }
                    StyledText { Layout.fillWidth: true; text: meta.formattedModified; font: Tokens.font.body.small; color: Colours.palette.m3onSurface }
                }
                RowLayout {
                    Layout.fillWidth: true
                    StyledText { Layout.preferredWidth: 110; text: qsTr("Accessed:"); font: Tokens.font.label.medium; color: Colours.palette.m3onSurfaceVariant }
                    StyledText { Layout.fillWidth: true; text: meta.formattedAccessed; font: Tokens.font.body.small; color: Colours.palette.m3onSurface }
                }

                RowLayout {
                    visible: !meta.isDir
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.preferredWidth: 110
                        text: qsTr("Open With:")
                        font: Tokens.font.label.medium
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        MaterialIcon {
                            text: "apps"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3primary
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.defaultAppName.length > 0 ? root.defaultAppName : qsTr("System Default")
                            font: Tokens.font.body.medium
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                        }

                        StyledRect {
                            implicitHeight: 28
                            implicitWidth: changeText.implicitWidth + 20
                            radius: Tokens.rounding.full
                            color: changeHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainerHigh

                            StyledText {
                                id: changeText
                                anchors.centerIn: parent
                                text: qsTr("Change...")
                                font: Tokens.font.label.small
                                color: Colours.palette.m3primary
                            }

                            MouseArea {
                                id: changeHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof openWithModal !== "undefined" && openWithModal) {
                                        openWithModal.targetPath = root.targetPath;
                                        openWithModal.expanded = true;
                                    }
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // Tab 1: Permissions
            ColumnLayout {
                visible: root.currentTab === 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    StyledText { Layout.preferredWidth: 100; text: qsTr("Owner:"); font: Tokens.font.label.medium; color: Colours.palette.m3onSurfaceVariant }
                    StyledText { text: meta.owner; font: Tokens.font.body.medium; color: Colours.palette.m3onSurface }
                }
                RowLayout {
                    Layout.fillWidth: true
                    StyledText { Layout.preferredWidth: 100; text: qsTr("Group:"); font: Tokens.font.label.medium; color: Colours.palette.m3onSurfaceVariant }
                    StyledText { text: meta.group; font: Tokens.font.body.medium; color: Colours.palette.m3onSurface }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Colours.palette.m3outlineVariant; opacity: 0.5 }

                // Checkbox Matrix: Read / Write / Exec
                GridLayout {
                    columns: 4
                    columnSpacing: 16
                    rowSpacing: 8

                    Item { width: 60 }
                    StyledText { text: qsTr("Read"); font: Tokens.font.label.small; color: Colours.palette.m3onSurfaceVariant }
                    StyledText { text: qsTr("Write"); font: Tokens.font.label.small; color: Colours.palette.m3onSurfaceVariant }
                    StyledText { text: qsTr("Execute"); font: Tokens.font.label.small; color: Colours.palette.m3onSurfaceVariant }

                    StyledText { text: qsTr("Owner"); font: Tokens.font.label.small; color: Colours.palette.m3onSurfaceVariant }
                    StyledCheckBox { id: uR; checked: meta.permissions.length >= 3 && meta.permissions[0] === 'r' }
                    StyledCheckBox { id: uW; checked: meta.permissions.length >= 3 && meta.permissions[1] === 'w' }
                    StyledCheckBox { id: uX; checked: meta.permissions.length >= 3 && meta.permissions[2] === 'x' }

                    StyledText { text: qsTr("Group"); font: Tokens.font.label.small; color: Colours.palette.m3onSurfaceVariant }
                    StyledCheckBox { id: gR; checked: meta.permissions.length >= 6 && meta.permissions[3] === 'r' }
                    StyledCheckBox { id: gW; checked: meta.permissions.length >= 6 && meta.permissions[4] === 'w' }
                    StyledCheckBox { id: gX; checked: meta.permissions.length >= 6 && meta.permissions[5] === 'x' }

                    StyledText { text: qsTr("Others"); font: Tokens.font.label.small; color: Colours.palette.m3onSurfaceVariant }
                    StyledCheckBox { id: oR; checked: meta.permissions.length >= 9 && meta.permissions[6] === 'r' }
                    StyledCheckBox { id: oW; checked: meta.permissions.length >= 9 && meta.permissions[7] === 'w' }
                    StyledCheckBox { id: oX; checked: meta.permissions.length >= 9 && meta.permissions[8] === 'x' }
                }

                TextButton {
                    Layout.alignment: Qt.AlignRight
                    type: ButtonBase.Tonal
                    text: qsTr("Apply Permissions")
                    onClicked: meta.applyPermissions(uR.checked, uW.checked, uX.checked, gR.checked, gW.checked, gX.checked, oR.checked, oW.checked, oX.checked)
                }

                Item { Layout.fillHeight: true }
            }

            // Tab 2: Checksums & Hash Validator
            ColumnLayout {
                visible: root.currentTab === 2
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        Layout.fillWidth: true
                        text: meta.checksumsLoading ? qsTr("Calculating checksums...") : qsTr("Cryptographic Hashes")
                        font: Tokens.font.title.small
                        color: Colours.palette.m3onSurface
                    }

                    IconTextButton {
                        type: ButtonBase.Tonal
                        icon: "sync"
                        text: qsTr("Recalculate")
                        onClicked: meta.calculateChecksums()
                    }
                }

                // MD5
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    StyledText { text: "MD5"; font: Tokens.font.label.small; color: Colours.palette.m3onSurfaceVariant }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        StyledText {
                            Layout.fillWidth: true
                            text: meta.md5 || "..."
                            font: Tokens.font.mono.small
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideMiddle
                        }
                        MaterialIcon {
                            text: "content_copy"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3outline
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: FileOperations.copyTextToClipboard(meta.md5)
                            }
                        }
                    }
                }

                // SHA-1
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    StyledText { text: "SHA-1"; font: Tokens.font.label.small; color: Colours.palette.m3onSurfaceVariant }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        StyledText {
                            Layout.fillWidth: true
                            text: meta.sha1 || "..."
                            font: Tokens.font.mono.small
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideMiddle
                        }
                        MaterialIcon {
                            text: "content_copy"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3outline
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: FileOperations.copyTextToClipboard(meta.sha1)
                            }
                        }
                    }
                }

                // SHA-256
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    StyledText { text: "SHA-256"; font: Tokens.font.label.small; color: Colours.palette.m3onSurfaceVariant }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        StyledText {
                            Layout.fillWidth: true
                            text: meta.sha256 || "..."
                            font: Tokens.font.mono.small
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideMiddle
                        }
                        MaterialIcon {
                            text: "content_copy"
                            fontStyle: Tokens.font.icon.small
                            color: Colours.palette.m3outline
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: FileOperations.copyTextToClipboard(meta.sha256)
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Colours.palette.m3outlineVariant; opacity: 0.5 }

                // Hash Comparator / Validator
                StyledText { text: qsTr("Verify Hash Match:"); font: Tokens.font.label.medium; color: Colours.palette.m3onSurface }
                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: Tokens.rounding.small
                    color: Colours.tPalette.m3surfaceContainerHigh

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        TextInput {
                            id: compareInput
                            Layout.fillWidth: true
                            color: Colours.palette.m3onSurface
                            font: Tokens.font.mono.small
                            clip: true
                            selectByMouse: true
                            onTextChanged: root.hashToCompare = text.trim().toLowerCase()

                            Text {
                                anchors.fill: parent
                                text: qsTr("Paste expected hash here...")
                                color: Colours.palette.m3outline
                                font: parent.font
                                visible: !compareInput.text && !compareInput.activeFocus
                            }
                        }

                        // Match Result Indicator
                        RowLayout {
                            visible: root.hashToCompare.length > 0
                            spacing: 4
                            readonly property bool isMatch: root.hashToCompare === meta.md5 || root.hashToCompare === meta.sha1 || root.hashToCompare === meta.sha256

                            MaterialIcon {
                                text: parent.isMatch ? "check_circle" : "cancel"
                                color: parent.isMatch ? "#4caf50" : Colours.palette.m3error
                                fontStyle: Tokens.font.icon.small
                            }
                            StyledText {
                                text: parent.isMatch ? qsTr("Match") : qsTr("Mismatch")
                                font: Tokens.font.label.small
                                color: parent.isMatch ? "#4caf50" : Colours.palette.m3error
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // Bottom Close Button
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight

                TextButton {
                    type: ButtonBase.Text
                    text: qsTr("Close")
                    onClicked: root.expanded = false
                }
            }
        }
    }
}
