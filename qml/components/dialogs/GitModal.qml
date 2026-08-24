import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../controls"
import atlas

MouseArea {
    id: root

    property bool expanded: false
    property int currentTab: 0 // 0 = Branches & Actions, 1 = Commits History

    anchors.fill: parent
    visible: opacity > 0.001
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: expanded = false
    onWheel: wheel => wheel.accepted = true

    opacity: expanded ? 1.0 : 0.0
    Behavior on opacity { Anim { type: Anim.FastEffects } }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.45)
    }

    StyledRect {
        id: dialog

        anchors.centerIn: parent
        width: Math.min(parent.width - 64, 580)
        height: Math.min(parent.height - 64, 600)
        implicitWidth: 580
        implicitHeight: 600

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

            // Header Title with current branch & Action buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "fork_right"
                    fontStyle: Tokens.font.icon.medium
                    color: Colours.palette.m3tertiary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.rightMargin: Tokens.spacing.small
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Git Repository")
                        font: Tokens.font.title.medium
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: GitManager.branchName.length > 0
                        text: qsTr("Current branch: %1").arg(GitManager.branchName)
                        font: Tokens.font.label.medium
                        color: Colours.palette.m3tertiary
                        elide: Text.ElideMiddle
                    }
                }

                // Pull Button
                IconTextButton {
                    type: ButtonBase.Tonal
                    icon: "download"
                    text: qsTr("Pull")
                    onClicked: GitManager.pull()
                }

                // Fetch Button
                IconTextButton {
                    type: ButtonBase.Tonal
                    icon: "sync"
                    text: qsTr("Fetch")
                    onClicked: GitManager.fetch()
                }
            }

            // Status message indicator banner
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 28
                visible: GitManager.lastStatusMessage.length > 0 || GitManager.isOperating
                radius: Tokens.rounding.small
                color: Qt.alpha(Colours.palette.m3tertiary, 0.15)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 6

                    MaterialIcon {
                        text: GitManager.isOperating ? "autorenew" : "info"
                        fontStyle: Tokens.font.icon.small
                        color: Colours.palette.m3tertiary
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: GitManager.lastStatusMessage
                        font: Tokens.font.label.small
                        color: Colours.palette.m3tertiary
                        elide: Text.ElideRight
                    }
                }
            }

            // Segmented Switcher
            SlidingSelector {
                Layout.fillWidth: true
                activeColor: Colours.palette.m3tertiaryContainer
                activeOnColor: Colours.palette.m3onTertiaryContainer
                inactiveColor: Colours.tPalette.m3surfaceContainerHigh
                model: [
                    { tab: 0, label: qsTr("Branches (%1)").arg(GitManager.branches.length), icon: "fork_right" },
                    { tab: 1, label: qsTr("Recent Commits (%1)").arg(GitManager.commits.length), icon: "history" }
                ]
                valueKey: "tab"
                currentValue: root.currentTab
                onSelected: val => root.currentTab = val
            }

            // Tab 0: Branches List
            ListView {
                id: branchesList
                visible: root.currentTab === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                model: GitManager.branches

                delegate: StyledRect {
                    id: branchItem
                    required property string modelData
                    readonly property bool isCurrent: modelData === GitManager.branchName

                    width: branchesList.width
                    implicitHeight: 40
                    radius: Tokens.rounding.small
                    color: isCurrent ? Qt.alpha(Colours.palette.m3tertiary, 0.18) : (bHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        MaterialIcon {
                            text: branchItem.isCurrent ? "check_circle" : "fork_right"
                            fontStyle: Tokens.font.icon.small
                            color: branchItem.isCurrent ? Colours.palette.m3tertiary : Colours.palette.m3outline
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: branchItem.modelData
                            font: Tokens.font.body.medium
                            color: branchItem.isCurrent ? Colours.palette.m3tertiary : Colours.palette.m3onSurface
                        }

                        StyledText {
                            visible: branchItem.isCurrent
                            text: qsTr("HEAD")
                            font: Tokens.font.label.small
                            color: Colours.palette.m3tertiary
                        }
                    }

                    MouseArea {
                        id: bHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!branchItem.isCurrent) {
                                GitManager.switchBranch(branchItem.modelData);
                            }
                        }
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    width: parent.width - Tokens.padding.large * 2
                    visible: branchesList.count === 0
                    text: qsTr("No branches found in this repository")
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.small
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

            }

            // Tab 1: Commits History Feed
            ListView {
                id: commitsList
                visible: root.currentTab === 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: GitManager.commits

                delegate: StyledRect {
                    id: commitItem
                    required property var modelData

                    width: commitsList.width
                    implicitHeight: commitCol.implicitHeight + 12
                    radius: Tokens.rounding.small
                    color: Colours.tPalette.m3surfaceContainerHigh

                    ColumnLayout {
                        id: commitCol
                        anchors.fill: parent
                        anchors.margins: 6
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            StyledRect {
                                implicitHeight: 20
                                implicitWidth: hashText.implicitWidth + 8
                                radius: Tokens.rounding.full
                                color: Qt.alpha(Colours.palette.m3primary, 0.15)

                                StyledText {
                                    id: hashText
                                    anchors.centerIn: parent
                                    text: commitItem.modelData.hash || ""
                                    font: Tokens.font.mono.small
                                    color: Colours.palette.m3primary
                                }
                            }

                            StyledText {
                                text: commitItem.modelData.author || ""
                                font: Tokens.font.label.small
                                color: Colours.palette.m3outline
                            }

                            Item { Layout.fillWidth: true }

                            StyledText {
                                text: commitItem.modelData.time || ""
                                font: Tokens.font.label.small
                                color: Colours.palette.m3outline
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: commitItem.modelData.subject || ""
                            font: Tokens.font.body.medium
                            color: Colours.palette.m3onSurface
                            wrapMode: Text.Wrap
                        }
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    width: parent.width - Tokens.padding.large * 2
                    visible: commitsList.count === 0
                    text: qsTr("No commits yet")
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.small
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

            }

            // Close Button
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
