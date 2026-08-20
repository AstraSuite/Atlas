import QtQuick
import QtQuick.Layouts
import "../"

StyledRect {
    id: root

    required property var activeTab
    property bool isEditingPath: false
    property bool isSearching: false
    property bool isFiltering: false
    property string searchText: ""
    property string filterText: ""

    signal togglePreview()
    signal toggleTerminal()
    signal createNewFolder()
    signal createNewFile()
    signal reload()

    implicitHeight: navRow.implicitHeight + Tokens.padding.small * 2
    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: navRow

        anchors.fill: parent
        anchors.margins: Tokens.padding.small
        spacing: Tokens.spacing.extraSmall

        // Back Button
        Item {
            implicitWidth: 32
            implicitHeight: 32

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainerHigh

                StateLayer {
                    disabled: !root.activeTab || !root.activeTab.canGoBack
                    onClicked: if (root.activeTab) root.activeTab.goBack()
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "arrow_back"
                    color: (root.activeTab && root.activeTab.canGoBack) ? Colours.palette.m3onSurface : Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.small
                }
            }
        }

        // Forward Button
        Item {
            implicitWidth: 32
            implicitHeight: 32

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainerHigh

                StateLayer {
                    disabled: !root.activeTab || !root.activeTab.canGoForward
                    onClicked: if (root.activeTab) root.activeTab.goForward()
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "arrow_forward"
                    color: (root.activeTab && root.activeTab.canGoForward) ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.small
                }
            }
        }

        // Up Button
        Item {
            implicitWidth: 32
            implicitHeight: 32

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainerHigh

                StateLayer {
                    onClicked: if (root.activeTab) root.activeTab.goUp()
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "arrow_upward"
                    color: Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }
            }
        }

        // Home Button
        Item {
            implicitWidth: 32
            implicitHeight: 32

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainerHigh

                StateLayer {
                    onClicked: if (root.activeTab) root.activeTab.currentPath = FileUtils.home
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "home"
                    color: Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }
            }
        }

        // Path & Breadcrumbs Bar
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 34

            radius: Tokens.rounding.medium
            color: Colours.tPalette.m3surfaceContainerHigh

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.small
                anchors.rightMargin: Tokens.padding.small
                spacing: Tokens.spacing.extraSmall

                // Breadcrumb View
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !root.isEditingPath

                    RowLayout {
                        anchors.fill: parent
                        spacing: Tokens.spacing.extraSmall

                        Repeater {
                            model: {
                                if (!root.activeTab || !root.activeTab.currentPath) return [];
                                let p = root.activeTab.currentPath;
                                let parts = p.split("/").filter(s => s.length > 0);
                                return ["/"].concat(parts);
                            }

                            RowLayout {
                                id: crumb
                                required property string modelData
                                required property int index
                                spacing: Tokens.spacing.extraSmall

                                StyledRect {
                                    implicitHeight: 26
                                    implicitWidth: crumbText.implicitWidth + Tokens.padding.small * 2
                                    radius: Tokens.rounding.small
                                    color: crumbMouse.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent"

                                    MouseArea {
                                        id: crumbMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (crumb.index === 0) {
                                                root.activeTab.currentPath = "/";
                                            } else {
                                                let p = root.activeTab.currentPath.split("/").filter(s => s.length > 0);
                                                root.activeTab.currentPath = "/" + p.slice(0, crumb.index).join("/");
                                            }
                                        }
                                    }

                                    StyledText {
                                        id: crumbText
                                        anchors.centerIn: parent
                                        text: crumb.modelData === "/" ? "root" : (crumb.index === 1 && crumb.modelData === "home" ? "home" : crumb.modelData)
                                        color: Colours.palette.m3onSurface
                                        font: Tokens.font.body.small
                                    }
                                }

                                StyledText {
                                    text: "/"
                                    color: Colours.palette.m3outline
                                    font: Tokens.font.body.small
                                    visible: crumb.index < (root.activeTab.currentPath.split("/").filter(s => s.length > 0).length)
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.isEditingPath = true;
                                    pathInput.forceActiveFocus();
                                    pathInput.selectAll();
                                }
                            }
                        }
                    }
                }

                // Text Edit Mode (Ctrl+L)
                TextInput {
                    id: pathInput
                    Layout.fillWidth: true
                    visible: root.isEditingPath
                    text: root.activeTab ? root.activeTab.currentPath : ""
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.small
                    selectByMouse: true

                    onAccepted: {
                        if (root.activeTab) root.activeTab.currentPath = text;
                        root.isEditingPath = false;
                    }

                    Keys.onEscapePressed: {
                        root.isEditingPath = false;
                    }
                }

                // Edit Path button (Pencil)
                Item {
                    implicitWidth: 24
                    implicitHeight: 24

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: root.isEditingPath ? "check" : "edit"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.isEditingPath) {
                                if (root.activeTab) root.activeTab.currentPath = pathInput.text;
                                root.isEditingPath = false;
                            } else {
                                root.isEditingPath = true;
                                pathInput.forceActiveFocus();
                                pathInput.selectAll();
                            }
                        }
                    }
                }
            }
        }

        // Search Bar Toggle (Ctrl+F)
        Item {
            implicitWidth: 32
            implicitHeight: 32

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: root.isSearching ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainerHigh

                StateLayer {
                    onClicked: {
                        root.isSearching = !root.isSearching;
                        if (!root.isSearching) root.searchText = "";
                    }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "search"
                    color: root.isSearching ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }
            }
        }

        // View Mode Switcher: Grid (0), Details (1), Compact (2)
        StyledRect {
            implicitHeight: 32
            implicitWidth: viewRow.implicitWidth + Tokens.padding.extraSmall * 2
            radius: Tokens.rounding.full
            color: Colours.tPalette.m3surfaceContainerHigh

            RowLayout {
                id: viewRow
                anchors.fill: parent
                anchors.margins: Tokens.padding.extraSmall
                spacing: 2

                Repeater {
                    model: [
                        { mode: 0, icon: "grid_view" },
                        { mode: 1, icon: "view_list" },
                        { mode: 2, icon: "view_compact" }
                    ]

                    StyledRect {
                        required property int index
                        required property var modelData
                        readonly property bool active: root.activeTab && root.activeTab.viewMode === modelData.mode

                        implicitWidth: 26
                        implicitHeight: 26
                        radius: Tokens.rounding.full
                        color: active ? Colours.palette.m3secondaryContainer : "transparent"

                        StateLayer {
                            onClicked: if (root.activeTab) root.activeTab.viewMode = parent.modelData.mode
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: parent.modelData.icon
                            color: parent.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }
                    }
                }
            }
        }

        // Terminal Toggle (F4)
        Item {
            implicitWidth: 32
            implicitHeight: 32

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainerHigh

                StateLayer {
                    onClicked: root.toggleTerminal()
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "terminal"
                    color: Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }
            }
        }

        // Info / Preview Toggle (F11)
        Item {
            implicitWidth: 32
            implicitHeight: 32

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainerHigh

                StateLayer {
                    onClicked: root.togglePreview()
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "info"
                    color: Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }
            }
        }
    }
}
