import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtWebEngine
import "../"
import prism

Item {
    id: root

    property bool isOpen: false

    function open() {
        isOpen = true;
        viewEngine.url = AppIntegration.getGameAssetUrl();
        focusTimer.restart();
    }

    function close() {
        isOpen = false;
        viewEngine.url = "about:blank";
    }

    anchors.fill: parent
    visible: opacity > 0
    opacity: isOpen ? 1 : 0
    z: 9999

    Behavior on opacity {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Timer {
        id: focusTimer
        interval: 80
        repeat: false
        onTriggered: {
            viewEngine.forceActiveFocus();
            viewEngine.runJavaScript("window.focus(); if (document.body) document.body.focus();");
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.65)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    StyledRect {
        id: dialogBox
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 860)
        height: Math.min(parent.height - 64, 480)
        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerHigh

        layer.enabled: true
        layer.effect: Mask {
            maskSource: maskItem
        }

        scale: root.isOpen ? 1 : 0.88

        Behavior on scale {
            Anim {
                type: Anim.SlowEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                viewEngine.forceActiveFocus();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Item {
                Layout.fillWidth: true
                implicitHeight: 44

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 12

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledRect {
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: Tokens.rounding.full
                        color: closeBtnHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Qt.alpha(Colours.tPalette.m3surfaceContainerHighest, 0)

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "close"
                            color: Colours.palette.m3onSurface
                            fontStyle: Tokens.font.icon.small
                        }

                        MouseArea {
                            id: closeBtnHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.close()
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    anchors.fill: parent
                    color: "#f7f7f7"
                }

                WebEngineView {
                    id: viewEngine
                    anchors.fill: parent
                    focus: true
                    settings.localContentCanAccessFileUrls: true
                    settings.localContentCanAccessRemoteUrls: true
                    settings.spatialNavigationEnabled: false
                    settings.showScrollBars: false
                    backgroundColor: "#f7f7f7"

                    onLoadingChanged: loadRequest => {
                        if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                            viewEngine.forceActiveFocus();
                            viewEngine.runJavaScript("window.focus(); if (document.body) document.body.focus();");
                        }
                    }
                }
            }
        }
    }

    Item {
        id: maskItem
        width: dialogBox.width
        height: dialogBox.height
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.large
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.isOpen
        onActivated: root.close()
    }
}
