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
    property int selectedIndex: -1
    property var selectedApp: (selectedIndex >= 0 && selectedIndex < filteredApps.length) ? filteredApps[selectedIndex] : null

    readonly property var filteredApps: {
        if (!filterText) return appsList;
        return appsList.filter(app => {
            let n = (app.name || "").toLowerCase();
            let c = (app.comment || "").toLowerCase();
            return n.indexOf(filterText) !== -1 || c.indexOf(filterText) !== -1;
        });
    }

    onExpandedChanged: {
        if (expanded && targetPath) {
            appsList = MimeService.getApplicationsForFile(targetPath);
            filterText = "";
            filterInput.text = "";
            selectedIndex = (appsList.length > 0) ? 0 : -1;
        } else {
            selectedIndex = -1;
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
        implicitWidth: 480
        implicitHeight: 540

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
                        onTextChanged: {
                            root.filterText = text.toLowerCase();
                            root.selectedIndex = (root.filteredApps.length > 0) ? 0 : -1;
                        }

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
                spacing: 6

                model: root.filteredApps

                delegate: StyledRect {
                    id: appItem
                    required property int index
                    required property var modelData

                    readonly property bool isSelected: root.selectedIndex === index

                    width: appListView.width
                    implicitHeight: 52
                    radius: Tokens.rounding.medium
                    color: isSelected
                        ? Colours.palette.m3secondaryContainer
                        : (appHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Item {
                            implicitWidth: 28
                            implicitHeight: 28
                            Layout.alignment: Qt.AlignVCenter

                            CachingIconImage {
                                anchors.fill: parent
                                implicitSize: 28
                                source: FileUtils.iconForName(appItem.modelData.icon, "application-x-executable")
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                Layout.fillWidth: true
                                text: appItem.modelData.name || ""
                                font: Tokens.font.body.medium
                                color: appItem.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: appItem.modelData.comment || appItem.modelData.exec || ""
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurfaceVariant
                                elide: Text.ElideRight
                            }
                        }

                        StyledRect {
                            visible: appItem.modelData.isRecommended === true
                            implicitHeight: 22
                            implicitWidth: recText.implicitWidth + 14
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
                            root.selectedIndex = appItem.index;
                        }
                        onDoubleClicked: {
                            root.selectedIndex = appItem.index;
                            if (alwaysDefaultCheck.checked) {
                                MimeService.setDefaultApp(FileUtils.mimeTypeForFile(root.targetPath), appItem.modelData.id);
                                if (typeof propertiesModal !== "undefined" && propertiesModal && propertiesModal.expanded) {
                                    propertiesModal.updateDefaultApp();
                                }
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
                Layout.topMargin: Tokens.spacing.extraSmall
                Layout.bottomMargin: Tokens.spacing.extraSmall
                text: qsTr("Always use this application for this file type")
            }

            // Bottom Action Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledRect {
                    visible: root.selectedApp !== null
                    implicitHeight: 38
                    implicitWidth: setDefaultText.implicitWidth + 24
                    radius: Tokens.rounding.full
                    color: setDefHover.containsMouse ? Qt.alpha(Colours.palette.m3primary, 0.25) : Qt.alpha(Colours.palette.m3primary, 0.12)

                    StyledText {
                        id: setDefaultText
                        anchors.centerIn: parent
                        text: qsTr("Set as Default")
                        font: Tokens.font.label.large
                        color: Colours.palette.m3primary
                    }

                    MouseArea {
                        id: setDefHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.selectedApp) {
                                MimeService.setDefaultApp(FileUtils.mimeTypeForFile(root.targetPath), root.selectedApp.id);
                                if (typeof propertiesModal !== "undefined" && propertiesModal && propertiesModal.expanded) {
                                    propertiesModal.updateDefaultApp();
                                }
                                root.expanded = false;
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledRect {
                    implicitHeight: 38
                    implicitWidth: 84
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

                StyledRect {
                    enabled: root.selectedApp !== null
                    opacity: enabled ? 1.0 : 0.5
                    implicitHeight: 38
                    implicitWidth: 84
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3primary

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Open")
                        font: Tokens.font.label.large
                        color: Colours.palette.m3onPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: root.selectedApp !== null
                        cursorShape: root.selectedApp !== null ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (root.selectedApp) {
                                if (alwaysDefaultCheck.checked) {
                                    MimeService.setDefaultApp(FileUtils.mimeTypeForFile(root.targetPath), root.selectedApp.id);
                                    if (typeof propertiesModal !== "undefined" && propertiesModal && propertiesModal.expanded) {
                                        propertiesModal.updateDefaultApp();
                                    }
                                }
                                MimeService.openWith(root.targetPath, root.selectedApp.path);
                                root.expanded = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
