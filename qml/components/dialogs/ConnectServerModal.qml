import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../containers"
import "../controls"
import prism

Item {
    id: root

    property bool expanded: false
    property var activeTab: null

    readonly property list<MenuItem> protocolMenuItems: [
        MenuItem { text: qsTr("SFTP (SSH File Transfer)"); property string scheme: "sftp"; icon: "terminal" },
        MenuItem { text: qsTr("SMB (Windows Share)"); property string scheme: "smb"; icon: "folder_shared" },
        MenuItem { text: qsTr("FTP"); property string scheme: "ftp"; icon: "cloud" },
        MenuItem { text: qsTr("FTPS (FTP over TLS)"); property string scheme: "ftps"; icon: "lock" },
        MenuItem { text: qsTr("NFS (Network File System)"); property string scheme: "nfs"; icon: "storage" },
        MenuItem { text: qsTr("AFP (Apple Filing)"); property string scheme: "afp"; icon: "folder" },
        MenuItem { text: qsTr("WebDAV (HTTP)"); property string scheme: "dav"; icon: "public" },
        MenuItem { text: qsTr("WebDAV TLS (HTTPS)"); property string scheme: "davs"; icon: "https" }
    ]

    function getActiveProtocolItem() {
        for (let i = 0; i < protocolMenuItems.length; i++) {
            if (protocolMenuItems[i].scheme === root.scheme) {
                return protocolMenuItems[i];
            }
        }
        return protocolMenuItems[0];
    }

    property string scheme: "sftp"

    readonly property bool usesShare: scheme === "smb"
    readonly property bool usesCredentials: scheme !== "nfs"

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
        width: Math.min(parent.width - 32, 480)
        height: Math.min(parent.height - 32, formCol.implicitHeight + headerRow.implicitHeight + actionRow.implicitHeight + (errorBanner.visible ? errorBanner.implicitHeight + Tokens.spacing.medium : 0) + Tokens.padding.large * 2 + Tokens.spacing.medium * 2)
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
            id: mainCol
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            // Header
            RowLayout {
                id: headerRow
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

                IconButton {
                    type: ButtonBase.Text
                    icon: "close"
                    onClicked: {
                        if (!NetworkManager.isConnecting) {
                            root.expanded = false;
                        }
                    }
                }
            }

            // Error Banner
            StyledRect {
                id: errorBanner
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

            // Scrollable Form Body
            VerticalFadeFlickable {
                id: flickable
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: formCol.implicitHeight
                contentHeight: formCol.implicitHeight
                clip: true
                fadeAmount: 0.06
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: StyledScrollBar {
                    flickable: flickable
                }

                ColumnLayout {
                    id: formCol
                    width: flickable.width
                    spacing: Tokens.spacing.medium

                    // Protocol Selection as SplitButtonRow
                    SplitButtonRow {
                        Layout.fillWidth: true
                        first: true
                        last: true
                        label: qsTr("Protocol")
                        subtext: qsTr("File transfer protocol")
                        menuItems: root.protocolMenuItems
                        active: root.getActiveProtocolItem()
                        onSelected: item => {
                            if (item && item.scheme) {
                                root.scheme = item.scheme;
                                portInput.text = String(NetworkManager.defaultPort(root.scheme));
                            }
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
                        visible: root.usesCredentials
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
                            text: root.usesShare ? qsTr("Share / Path") : qsTr("Remote Path")
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
                        visible: root.usesCredentials
                        spacing: 4

                        StyledText {
                            text: qsTr("Password / Key Passphrase")
                            font: Tokens.font.label.medium
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        StyledRect {
                            id: passRect
                            Layout.fillWidth: true
                            implicitHeight: 38
                            radius: Tokens.rounding.medium
                            color: Colours.tPalette.m3surfaceContainerHigh
                            property bool showPass: false

                            TextInput {
                                id: passInput
                                echoMode: passRect.showPass ? TextInput.Normal : TextInput.Password
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

                            Item {
                                id: showPassBtn
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 38

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: passRect.showPass ? "visibility_off" : "visibility"
                                    color: Colours.palette.m3onSurfaceVariant
                                    fontStyle: Tokens.font.icon.small
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: passRect.showPass = !passRect.showPass
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
                }
            }

            // Action Buttons
            RowLayout {
                id: actionRow
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.extraSmall
                spacing: Tokens.spacing.small

                Item { Layout.fillWidth: true }

                TextButton {
                    type: ButtonBase.Text
                    text: qsTr("Cancel")
                    onClicked: {
                        if (!NetworkManager.isConnecting) {
                            root.expanded = false;
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
                                const port = parseInt(portInput.text) || NetworkManager.defaultPort(root.scheme);
                                NetworkManager.connectServer(
                                    root.scheme,
                                    hostInput.text.trim(),
                                    port,
                                    root.usesCredentials ? userInput.text.trim() : "",
                                    pathInput.text.trim(),
                                    root.usesCredentials ? passInput.text : "",
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
