import QtQuick
import QtQuick.Layouts
import "../"
import prism

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
    signal searchRequested(string query)
    signal filterRequested(string filter)

    implicitHeight: 48
    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.large

    // Square off bottom corners so only top-left and top-right are rounded
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.radius
        color: root.color
        z: -1
    }

    RowLayout {
        id: navRow

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.extraSmall

        // Back Button
        Item {
            implicitWidth: 32
            implicitHeight: 32

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: (root.activeTab && root.activeTab.canGoBack && backHover.containsMouse) ? Colours.tPalette.m3surfaceContainerHighest : "transparent"

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "arrow_back"
                    color: (root.activeTab && root.activeTab.canGoBack) ? Colours.palette.m3onSurface : Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.small
                }

                MouseArea {
                    id: backHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: (root.activeTab && root.activeTab.canGoBack) ? Qt.PointingHandCursor : undefined
                    onClicked: if (root.activeTab && root.activeTab.canGoBack) root.activeTab.goBack()
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
                color: (root.activeTab && root.activeTab.canGoForward && fwdHover.containsMouse) ? Colours.tPalette.m3surfaceContainerHighest : "transparent"

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "arrow_forward"
                    color: (root.activeTab && root.activeTab.canGoForward) ? Colours.palette.m3onSurface : Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.small
                }

                MouseArea {
                    id: fwdHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: (root.activeTab && root.activeTab.canGoForward) ? Qt.PointingHandCursor : undefined
                    onClicked: if (root.activeTab && root.activeTab.canGoForward) root.activeTab.goForward()
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
                color: upHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent"

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "arrow_upward"
                    color: Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }

                MouseArea {
                    id: upHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.activeTab) root.activeTab.goUp()
                }
            }
        }

        // Favorite / Bookmark Toggle Button
        Item {
            implicitWidth: 32
            implicitHeight: 32

            readonly property bool isFav: root.activeTab ? PlacesModel.isBookmarked(root.activeTab.currentPath) : false

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: parent.isFav ? Colours.palette.m3primaryContainer : (favHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent")

                MaterialIcon {
                    anchors.centerIn: parent
                    text: parent.parent.isFav ? "star" : "star_outline"
                    fill: parent.parent.isFav ? 1 : 0
                    color: parent.parent.isFav ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }

                MouseArea {
                    id: favHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.activeTab && root.activeTab.currentPath.length > 0) {
                            PlacesModel.toggleBookmark(root.activeTab.currentPath);
                        }
                    }
                }
            }
        }

        // Path & Breadcrumbs Bar / Search Bar
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 36

            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainerHigh
            border.color: (root.isEditingPath || root.isSearching) ? Colours.palette.m3primary : "transparent"
            border.width: (root.isEditingPath || root.isSearching) ? 1.5 : 0

            // Normal Breadcrumbs Mode
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.small
                anchors.rightMargin: Tokens.padding.small
                spacing: Tokens.spacing.extraSmall
                visible: !root.isEditingPath && !root.isSearching

                Repeater {
                    model: {
                        if (!root.activeTab || !root.activeTab.currentPath) return [];
                        let current = root.activeTab.currentPath;
                        let home = FileUtils.home;
                        
                        if (current === home) {
                            return [{ name: qsTr("Home"), path: home, isHome: true }];
                        } else if (current.startsWith(home + "/")) {
                            let rel = current.substring(home.length + 1);
                            let parts = rel.split("/").filter(s => s.length > 0);
                            let list = [{ name: qsTr("Home"), path: home, isHome: true }];
                            let accum = home;
                            for (let part of parts) {
                                accum += "/" + part;
                                list.push({ name: part, path: accum, isHome: false });
                            }
                            return list;
                        } else {
                            let parts = current.split("/").filter(s => s.length > 0);
                            let list = [{ name: "/", path: "/", isHome: false }];
                            let accum = "";
                            for (let part of parts) {
                                accum += "/" + part;
                                list.push({ name: part, path: accum, isHome: false });
                            }
                            return list;
                        }
                    }

                    RowLayout {
                        id: crumb
                        required property var modelData
                        required property int index
                        spacing: Tokens.spacing.extraSmall

                        StyledRect {
                            implicitHeight: 26
                            implicitWidth: crumbContent.implicitWidth + Tokens.padding.small * 2
                            radius: Tokens.rounding.small
                            color: crumbMouse.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent"

                            MouseArea {
                                id: crumbMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.activeTab) {
                                        root.activeTab.currentPath = crumb.modelData.path;
                                    }
                                }
                            }

                            RowLayout {
                                id: crumbContent
                                anchors.centerIn: parent
                                spacing: 4

                                MaterialIcon {
                                    visible: crumb.modelData.isHome
                                    text: "home"
                                    fontStyle: Tokens.font.icon.small
                                    color: Colours.palette.m3onSurface
                                }

                                StyledText {
                                    text: crumb.modelData.name
                                    color: Colours.palette.m3onSurface
                                    font: Tokens.font.body.small
                                }
                            }
                        }

                        StyledText {
                            text: "/"
                            color: Colours.palette.m3outline
                            font: Tokens.font.body.small
                            visible: crumb.index < (parent.parent.count - 1)
                        }
                    }
                }

                // Clickable blank area to edit path
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor
                        onClicked: {
                            root.isEditingPath = true;
                            pathInput.forceActiveFocus();
                            pathInput.selectAll();
                        }
                    }
                }

                // Edit Path Pencil Icon
                Item {
                    implicitWidth: 24
                    implicitHeight: 24

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "edit"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.small
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.isEditingPath = true;
                            pathInput.forceActiveFocus();
                            pathInput.selectAll();
                        }
                    }
                }
            }

            // Editable Address Bar (Ctrl+L)
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.small
                anchors.rightMargin: Tokens.padding.small
                visible: root.isEditingPath && !root.isSearching
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "folder"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.small
                }

                TextInput {
                    id: pathInput
                    Layout.fillWidth: true
                    text: root.activeTab ? root.activeTab.currentPath : ""
                    color: Colours.palette.m3onSurface
                    selectionColor: Colours.palette.m3primaryContainer
                    selectedTextColor: Colours.palette.m3onPrimaryContainer
                    font: Tokens.font.body.small
                    selectByMouse: true
                    cursorVisible: focus

                    onAccepted: {
                        if (root.activeTab && text.trim().length > 0) {
                            root.activeTab.currentPath = text.trim();
                        }
                        root.isEditingPath = false;
                    }

                    Keys.onEscapePressed: {
                        root.isEditingPath = false;
                    }
                }

                // Clear Button
                Item {
                    implicitWidth: 22
                    implicitHeight: 22

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "backspace"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pathInput.text = ""
                    }
                }

                // Dropdown Chevron
                Item {
                    implicitWidth: 22
                    implicitHeight: 22

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "expand_more"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                // Accept Button
                Item {
                    implicitWidth: 22
                    implicitHeight: 22

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "check"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.activeTab && pathInput.text.trim().length > 0) {
                                root.activeTab.currentPath = pathInput.text.trim();
                            }
                            root.isEditingPath = false;
                        }
                    }
                }
            }

            // Search Bar (Ctrl+F)
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.small
                visible: root.isSearching
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "search"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.small
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.small
                    selectByMouse: true
                    cursorVisible: focus
                    text: root.searchText

                    onTextChanged: {
                        root.searchText = text;
                        root.searchRequested(text);
                    }

                    Keys.onEscapePressed: {
                        text = "";
                        root.searchText = "";
                        root.isSearching = false;
                        root.searchRequested("");
                    }
                }

                Item {
                    implicitWidth: 24
                    implicitHeight: 24

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "close"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = "";
                            root.searchText = "";
                            root.isSearching = false;
                            root.searchRequested("");
                        }
                    }
                }
            }
        }

        // Search Toggle Button (Ctrl+F)
        Item {
            implicitWidth: 32
            implicitHeight: 32

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: root.isSearching ? Colours.palette.m3primaryContainer : (searchHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent")

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "search"
                    color: root.isSearching ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }

                MouseArea {
                    id: searchHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.isSearching = !root.isSearching;
                        if (root.isSearching) {
                            searchInput.forceActiveFocus();
                        } else {
                            searchInput.text = "";
                            root.searchText = "";
                            root.searchRequested("");
                        }
                    }
                }
            }
        }

        // View Mode Switcher
        StyledRect {
            implicitHeight: 32
            implicitWidth: 32 * 3 + 4
            radius: Tokens.rounding.full
            color: Colours.tPalette.m3surfaceContainerHigh

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // Grid View (0)
                Item {
                    implicitWidth: 32
                    implicitHeight: 32

                    StyledRect {
                        anchors.fill: parent
                        radius: Tokens.rounding.full
                        color: (root.activeTab && root.activeTab.viewMode === 0) ? Colours.palette.m3secondaryContainer : "transparent"

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "grid_view"
                            color: (root.activeTab && root.activeTab.viewMode === 0) ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.activeTab) root.activeTab.viewMode = 0
                        }
                    }
                }

                // Details / List View (1)
                Item {
                    implicitWidth: 32
                    implicitHeight: 32

                    StyledRect {
                        anchors.fill: parent
                        radius: Tokens.rounding.full
                        color: (root.activeTab && root.activeTab.viewMode === 1) ? Colours.palette.m3secondaryContainer : "transparent"

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "view_list"
                            color: (root.activeTab && root.activeTab.viewMode === 1) ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.activeTab) root.activeTab.viewMode = 1
                        }
                    }
                }

                // Compact View (2)
                Item {
                    implicitWidth: 32
                    implicitHeight: 32

                    StyledRect {
                        anchors.fill: parent
                        radius: Tokens.rounding.full
                        color: (root.activeTab && root.activeTab.viewMode === 2) ? Colours.palette.m3secondaryContainer : "transparent"

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "view_compact"
                            color: (root.activeTab && root.activeTab.viewMode === 2) ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.activeTab) root.activeTab.viewMode = 2
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
                color: termHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent"

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "terminal"
                    color: Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }

                MouseArea {
                    id: termHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleTerminal()
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
                color: infoHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent"

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "info"
                    color: Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }

                MouseArea {
                    id: infoHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.togglePreview()
                }
            }
        }
    }

    function openSearch() {
        isSearching = true;
        searchInput.forceActiveFocus();
        searchInput.selectAll();
    }

    function openAddressEdit() {
        isEditingPath = true;
        pathInput.forceActiveFocus();
        pathInput.selectAll();
    }
}
