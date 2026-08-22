import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../controls"
import prism

Item {
    id: root

    property bool expanded: false
    property var activeTab: null

    signal connected(string path)

    anchors.fill: parent
    visible: opacity > 0.01
    opacity: expanded ? 1.0 : 0.0
    enabled: expanded

    Behavior on opacity {
        Anim { type: Anim.FastEffects }
    }

    Connections {
        target: NetworkManager
        function onConnectionFinished(success, localPath, errorMsg) {
            if (success && localPath.length > 0) {
                root.expanded = false;
                root.connected(localPath);
                if (root.activeTab) {
                    root.activeTab.currentPath = localPath;
                }
            }
        }
    }

    // Scrim / Backdrop
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.45)

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (!NetworkManager.isConnecting) {
                    root.expanded = false;
                }
            }
        }
    }

    // Dialog Card
    StyledRect {
        id: card
        anchors.centerIn: parent
        implicitWidth: 440
        implicitHeight: dialogCol.implicitHeight + Tokens.padding.large * 2
        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainer

        scale: root.expanded ? 1.0 : 0.94
        Behavior on scale {
            Anim {
                type: Anim.FastEffects
                easing: Tokens.anim.standard
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: dialogCol
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "cloud"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    text: qsTr("Connect to Server")
                    font: Tokens.font.title.medium
                    color: Colours.palette.m3onSurface
                    Layout.fillWidth: true
                }

                StyledRect {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: Tokens.rounding.full
                    color: closeHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "close"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!NetworkManager.isConnecting) {
                                root.expanded = false;
                            }
                        }
                    }
                }
            }

            // Error Banner
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: errorText.implicitHeight + Tokens.padding.small * 2
                radius: Tokens.rounding.medium
                color: Colours.palette.m3errorContainer
                visible: NetworkManager.lastError.length > 0

                StyledText {
                    id: errorText
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small
                    text: NetworkManager.lastError
                    color: Colours.palette.m3onErrorContainer
                    font: Tokens.font.body.small
                    wrapMode: Text.Wrap
                }
            }

            // Server / Host & Port
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    StyledText {
                        text: qsTr("Server / Host")
                        font: Tokens.font.label.medium
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: Tokens.rounding.medium
                        color: Colours.tPalette.m3surfaceContainerHigh

                        TextInput {
                            id: hostInput
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.small
                            verticalAlignment: TextInput.AlignVCenter
                            font: Tokens.font.body.medium
                            color: Colours.palette.m3onSurface
                            selectByMouse: true
                            clip: true

                            Text {
                                text: qsTr("e.g. 192.168.1.100 or server.com")
                                visible: !parent.text && !parent.activeFocus
                                color: Colours.palette.m3outline
                                font: parent.font
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                ColumnLayout {
                    implicitWidth: 80
                    spacing: 4

                    StyledText {
                        text: qsTr("Port")
                        font: Tokens.font.label.medium
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: Tokens.rounding.medium
                        color: Colours.tPalette.m3surfaceContainerHigh

                        TextInput {
                            id: portInput
                            text: "22"
                            anchors.fill: parent
                            anchors.margins: Tokens.padding.small
                            verticalAlignment: TextInput.AlignVCenter
                            font: Tokens.font.body.medium
                            color: Colours.palette.m3onSurface
                            selectByMouse: true
                            validator: IntValidator { bottom: 1; top: 65535 }
                        }
                    }
                }
            }

            // Username
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: qsTr("Username")
                    font: Tokens.font.label.medium
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Tokens.rounding.medium
                    color: Colours.tPalette.m3surfaceContainerHigh

                    TextInput {
                        id: userInput
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        verticalAlignment: TextInput.AlignVCenter
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurface
                        selectByMouse: true
                        clip: true

                        Text {
                            text: qsTr("Optional username")
                            visible: !parent.text && !parent.activeFocus
                            color: Colours.palette.m3outline
                            font: parent.font
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // Remote Directory Path
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: qsTr("Remote Path")
                    font: Tokens.font.label.medium
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Tokens.rounding.medium
                    color: Colours.tPalette.m3surfaceContainerHigh

                    TextInput {
                        id: pathInput
                        text: "/"
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        verticalAlignment: TextInput.AlignVCenter
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurface
                        selectByMouse: true
                        clip: true
                    }
                }
            }

            // Password
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: qsTr("Password / Key Passphrase")
                    font: Tokens.font.label.medium
                    color: Colours.palette.m3onSurfaceVariant
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Tokens.rounding.medium
                    color: Colours.tPalette.m3surfaceContainerHigh

                    TextInput {
                        id: passInput
                        echoMode: showPass ? TextInput.Normal : TextInput.Password
                        anchors.left: parent.left
                        anchors.right: showPassBtn.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: Tokens.padding.small
                        verticalAlignment: TextInput.AlignVCenter
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurface
                        selectByMouse: true
                        clip: true

                        Text {
                            text: qsTr("Optional or required password")
                            visible: !parent.text && !parent.activeFocus
                            color: Colours.palette.m3outline
                            font: parent.font
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    property bool showPass: false

                    Item {
                        id: showPassBtn
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 38

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: parent.parent.showPass ? "visibility_off" : "visibility"
                            color: Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.parent.showPass = !parent.parent.showPass
                        }
                    }
                }
            }

            // Remember Bookmark Checkbox
            StyledCheckBox {
                id: bookmarkCheck
                text: qsTr("Remember in Places sidebar")
                checked: true
            }

            // Action Buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                spacing: Tokens.spacing.small

                Item { Layout.fillWidth: true }

                StyledRect {
                    implicitWidth: 90
                    implicitHeight: 38
                    radius: Tokens.rounding.full
                    color: cancelHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Cancel")
                        font: Tokens.font.label.large
                        color: Colours.palette.m3primary
                    }

                    MouseArea {
                        id: cancelHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!NetworkManager.isConnecting) {
                                root.expanded = false;
                            }
                        }
                    }
                }

                StyledRect {
                    implicitWidth: connectRow.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: 38
                    radius: Tokens.rounding.full
                    color: hostInput.text.trim().length > 0 ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3primary, 0.4)

                    RowLayout {
                        id: connectRow
                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall

                        CircularIndicator {
                            size: 16
                            strokeWidth: 2
                            color: Colours.palette.m3onPrimary
                            running: NetworkManager.isConnecting
                            visible: running
                        }

                        StyledText {
                            text: NetworkManager.isConnecting ? qsTr("Connecting...") : qsTr("Connect")
                            font: Tokens.font.label.large
                            color: Colours.palette.m3onPrimary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: hostInput.text.trim().length > 0 && !NetworkManager.isConnecting ? Qt.PointingHandCursor : undefined
                        onClicked: {
                            if (hostInput.text.trim().length > 0 && !NetworkManager.isConnecting) {
                                let port = parseInt(portInput.text) || 22;
                                NetworkManager.connectSftp(
                                    hostInput.text.trim(),
                                    port,
                                    userInput.text.trim(),
                                    pathInput.text.trim(),
                                    passInput.text,
                                    bookmarkCheck.checked
                                );
                            }
                        }
                    }
                }
            }
        }
    }
}
