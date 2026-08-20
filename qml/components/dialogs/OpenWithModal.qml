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
    property var appsList: []
    property string filterText: ""

    onExpandedChanged: {
        if (expanded && targetPath) {
            appsList = MimeService.getApplicationsForFile(targetPath);
            filterText = "";
            filterInput.text = "";
        }
    }

    anchors.fill: parent
    visible: opacity > 0.001
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: expanded = false

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
        implicitWidth: 460
        implicitHeight: 520

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainer

        scale: root.expanded ? 1.0 : 0.94
        Behavior on scale { Anim { type: Anim.FastEffects; easing: Tokens.anim.standard } }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => mouse.accepted = true
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
                    text: "open_with"
                    fontStyle: Tokens.font.icon.medium
                    color: Colours.palette.m3primary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Open With...")
                    font: Tokens.font.title.medium
                    color: Colours.palette.m3onSurface
                }
            }

            // Search filter input
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainerHigh

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    MaterialIcon {
                        text: "search"
                        fontStyle: Tokens.font.icon.small
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    TextInput {
                        id: filterInput
                        Layout.fillWidth: true
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.body.medium
                        clip: true
                        selectByMouse: true
                        onTextChanged: root.filterText = text.toLowerCase()

                        Text {
                            anchors.fill: parent
                            text: qsTr("Search applications...")
                            color: Colours.palette.m3outline
                            font: parent.font
                            visible: !filterInput.text && !filterInput.activeFocus
                        }
                    }
                }
            }

            // Applications List
            ListView {
                id: appListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4

                model: {
                    if (!root.filterText) return root.appsList;
                    return root.appsList.filter(app => {
                        let n = (app.name || "").toLowerCase();
                        let c = (app.comment || "").toLowerCase();
                        return n.indexOf(root.filterText) !== -1 || c.indexOf(root.filterText) !== -1;
                    });
                }

                delegate: StyledRect {
                    id: appItem
                    required property int index
                    required property var modelData

                    width: appListView.width
                    implicitHeight: 48
                    radius: Tokens.rounding.small
                    color: appHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        MaterialIcon {
                            text: "apps"
                            fontStyle: Tokens.font.icon.medium
                            color: appItem.modelData.isRecommended ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: appItem.modelData.name || ""
                                font: Tokens.font.body.medium
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }

                            StyledText {
                                text: appItem.modelData.comment || appItem.modelData.exec || ""
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                                elide: Text.ElideRight
                            }
                        }

                        StyledRect {
                            visible: appItem.modelData.isRecommended
                            implicitHeight: 20
                            implicitWidth: recText.implicitWidth + 12
                            radius: Tokens.rounding.full
                            color: Qt.alpha(Colours.palette.m3primary, 0.15)

                            StyledText {
                                id: recText
                                anchors.centerIn: parent
                                text: qsTr("Recommended")
                                font: Tokens.font.label.small
                                color: Colours.palette.m3primary
                            }
                        }
                    }

                    MouseArea {
                        id: appHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (alwaysDefaultCheck.checked) {
                                MimeService.setDefaultApp(FileUtils.mimeTypeForFile(root.targetPath), appItem.modelData.id);
                            }
                            MimeService.openWith(root.targetPath, appItem.modelData.path);
                            root.expanded = false;
                        }
                    }
                }
            }

            // Always use as default checkbox
            StyledCheckBox {
                id: alwaysDefaultCheck
                Layout.fillWidth: true
                text: qsTr("Always use this application for this file type")
            }

            // Bottom Buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                spacing: Tokens.spacing.small

                StyledRect {
                    implicitHeight: 36
                    implicitWidth: 80
                    radius: Tokens.rounding.full
                    color: cancelHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Cancel")
                        font: Tokens.font.label.large
                        color: Colours.palette.m3onSurface
                    }

                    MouseArea {
                        id: cancelHover
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
