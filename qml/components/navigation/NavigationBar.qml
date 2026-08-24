import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import atlas

StyledRect {
    id: root

    required property var activeTab
    property int activePane: activeTab ? activeTab.activePane : 0
    property bool isEditingPath: false
    property bool isSearching: false
    property bool isFiltering: false
    property string searchText: ""
    property string filterText: ""
    property var pathSuggestions: []
    property int selectedSuggestionIndex: -1
    property bool showSuggestions: false

    readonly property string ghostCompletionText: {
        if (!root.isEditingPath || !pathInput.text || pathInput.text.length === 0) return "";
        let cur = root.activeTab ? ((root.activePane === 1 && root.activeTab.isSplit) ? root.activeTab.splitPath : root.activeTab.currentPath) : "";
        let comp = FileUtils.getCompletedPath(pathInput.text, cur);
        if (comp.startsWith(pathInput.text) && comp.length > pathInput.text.length) {
            return comp.substring(pathInput.text.length);
        }
        if (root.pathSuggestions.length > 0) {
            let firstSugg = root.pathSuggestions[0].displayPath;
            if (firstSugg.startsWith(pathInput.text) && firstSugg.length > pathInput.text.length) {
                return firstSugg.substring(pathInput.text.length);
            }
        }
        return "";
    }

    function updateSuggestions() {
        if (!isEditingPath) {
            showSuggestions = false;
            return;
        }
        let cur = root.activeTab ? ((root.activePane === 1 && root.activeTab.isSplit) ? root.activeTab.splitPath : root.activeTab.currentPath) : "";
        pathSuggestions = FileUtils.getPathSuggestions(pathInput.text, cur);
        selectedSuggestionIndex = -1;
        showSuggestions = pathSuggestions.length > 0;
    }

    function applySuggestion(index) {
        if (index < 0 || index >= pathSuggestions.length) return;
        let item = pathSuggestions[index];
        pathInput.text = item.displayPath;
        pathInput.cursorPosition = pathInput.text.length;
        if (item.isDir) {
            updateSuggestions();
        } else {
            showSuggestions = false;
        }
    }

    function commitPath(customText) {
        let textToUse = (typeof customText === "string") ? customText : pathInput.text;
        if (selectedSuggestionIndex >= 0 && selectedSuggestionIndex < pathSuggestions.length && (!customText || customText.length === 0)) {
            textToUse = pathSuggestions[selectedSuggestionIndex].displayPath;
        }
        let trimmed = textToUse.trim();
        if (trimmed.startsWith("sftp://") || trimmed.startsWith("smb://") || trimmed.startsWith("ftp://") || trimmed.startsWith("ssh://")) {
            NetworkManager.connectUri(trimmed, "", true);
            showSuggestions = false;
            isEditingPath = false;
            return;
        }
        let proto = AppIntegration.handleCustomProtocol(trimmed);
        if (proto > 0) {
            root.specialProtocolInvoked(proto);
            showSuggestions = false;
            isEditingPath = false;
            return;
        }
        if (root.activeTab && trimmed.length > 0) {
            let cur = (root.activePane === 1 && root.activeTab.isSplit) ? root.activeTab.splitPath : root.activeTab.currentPath;
            let finalPath = FileUtils.expandPath(trimmed, cur);
            if (finalPath.length > 0) {
                if (root.activePane === 1 && root.activeTab.isSplit) {
                    root.activeTab.splitPath = finalPath;
                } else {
                    root.activeTab.currentPath = finalPath;
                }
            }
        }
        showSuggestions = false;
        isEditingPath = false;
    }

    signal togglePreview()
    signal toggleTerminal()
    signal createNewFolder()
    signal createNewFile()
    signal reload()
    signal searchRequested(string query)
    signal filterRequested(string filter)
    signal preferencesRequested()
    signal specialProtocolInvoked(int protocolId)

    implicitHeight: 48
    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.large
    z: (root.isEditingPath && root.showSuggestions) ? 500 : 10

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
        z: 10

        // Back Button
        Item {
            implicitWidth: 32
            implicitHeight: 32

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: (root.activeTab && root.activeTab.canGoBack && backHover.containsMouse) ? Colours.tPalette.m3surfaceContainerHighest : Qt.alpha(Colours.tPalette.m3surfaceContainerHighest, 0)

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

                StyledToolTip {
                    text: qsTr("Back (Alt+Left)")
                    visible: backHover.containsMouse
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
                color: (root.activeTab && root.activeTab.canGoForward && fwdHover.containsMouse) ? Colours.tPalette.m3surfaceContainerHighest : Qt.alpha(Colours.tPalette.m3surfaceContainerHighest, 0)

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

                StyledToolTip {
                    text: qsTr("Forward (Alt+Right)")
                    visible: fwdHover.containsMouse
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
                color: upHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Qt.alpha(Colours.tPalette.m3surfaceContainerHighest, 0)

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

                StyledToolTip {
                    text: qsTr("Up (Alt+Up)")
                    visible: upHover.containsMouse
                }
            }
        }

        // Path & Breadcrumbs Bar / Search Bar
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 30
            z: (root.isEditingPath && root.showSuggestions) ? 500 : 1

            radius: Tokens.rounding.full
            color: Colours.tPalette.m3surfaceContainerHigh
            border.color: (root.isEditingPath || root.isSearching) ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3primary, 0)
            border.width: (root.isEditingPath || root.isSearching) ? 1.5 : 0

            // Normal Breadcrumbs Mode
            Flickable {
                id: crumbFlick

                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.small
                anchors.rightMargin: Tokens.padding.small
                visible: !root.isEditingPath && !root.isSearching

                clip: true
                contentWidth: crumbRow.width
                contentHeight: height
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds

                function pinToEnd(): void {
                    contentX = Math.max(0, contentWidth - width);
                }

                onContentWidthChanged: pinToEnd()
                onWidthChanged: pinToEnd()

                RowLayout {
                    id: crumbRow

                    height: crumbFlick.height
                    width: Math.max(implicitWidth, crumbFlick.width)
                    spacing: Tokens.spacing.extraSmall

                    Repeater {
                        id: breadcrumbRepeater
                        model: {
                            if (!root.activeTab) return [];
                            let current = (root.activePane === 1 && root.activeTab.isSplit) ? root.activeTab.splitPath : root.activeTab.currentPath;
                            if (!current) return [];
                            let home = FileUtils.home;

                            if (current.startsWith("recent:")) {
                                return [{ name: qsTr("Recent"), path: current, icon: "history" }];
                            } else if (current.indexOf("/.local/share/Trash") !== -1 || current.indexOf("trash:") !== -1) {
                                return [{ name: qsTr("Trash"), path: current, icon: "delete" }];
                            } else if (current === home) {
                                return [{ name: qsTr("Home"), path: home, icon: "home" }];
                            } else if (current.startsWith(home + "/")) {
                                let rel = current.substring(home.length + 1);
                                let parts = rel.split("/").filter(s => s.length > 0);
                                let list = [{ name: qsTr("Home"), path: home, icon: "home" }];
                                let accum = home;
                                for (let part of parts) {
                                    accum += "/" + part;
                                    list.push({ name: part, path: accum, icon: "" });
                                }
                                return list;
                            } else {
                                let parts = current.split("/").filter(s => s.length > 0);
                                let list = [{ name: qsTr("Root"), path: "/", icon: "hard_drive" }];
                                let accum = "";
                                for (let part of parts) {
                                    accum += "/" + part;
                                    list.push({ name: part, path: accum, icon: "" });
                                }
                                return list;
                            }
                        }

                        RowLayout {
                            id: crumb
                            required property var modelData
                            required property int index
                            spacing: Tokens.spacing.extraSmall

                            readonly property bool isActiveSegment: crumb.index === (breadcrumbRepeater.count - 1)

                            StyledRect {
                                implicitHeight: 22
                                implicitWidth: crumbContent.implicitWidth + Tokens.padding.small * 2
                                radius: Tokens.rounding.full
                                color: crumbMouse.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Qt.alpha(Colours.tPalette.m3surfaceContainerHighest, 0)

                                MouseArea {
                                    id: crumbMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (crumb.isActiveSegment) {
                                            root.isEditingPath = true;
                                            pathInput.forceActiveFocus();
                                            pathInput.selectAll();
                                        } else if (root.activeTab) {
                                            if (root.activePane === 1 && root.activeTab.isSplit) {
                                                root.activeTab.splitPath = crumb.modelData.path;
                                            } else {
                                                root.activeTab.currentPath = crumb.modelData.path;
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    id: crumbContent
                                    anchors.centerIn: parent
                                    spacing: 4

                                    MaterialIcon {
                                        visible: crumb.modelData.icon.length > 0
                                        text: crumb.modelData.icon
                                        fill: 1
                                        fontStyle: Tokens.font.icon.small
                                        color: crumb.isActiveSegment ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                                    }

                                    StyledText {
                                        text: crumb.modelData.name
                                        color: crumb.isActiveSegment ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                                        font: Tokens.font.body.builders.small.weight(Font.Bold).build()
                                    }
                                }
                            }

                            StyledText {
                                text: "/"
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.builders.small.weight(Font.Bold).build()
                                visible: crumb.index < (breadcrumbRepeater.count - 1)
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
                }
            }

            // Editable Address Bar
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

                Item {
                    id: inputContainer
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextInput {
                        id: pathInput
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.activeTab ? ((root.activePane === 1 && root.activeTab.isSplit) ? root.activeTab.splitPath : root.activeTab.currentPath) : ""
                        color: Colours.palette.m3onSurface
                        selectionColor: Colours.palette.m3primaryContainer
                        selectedTextColor: Colours.palette.m3onPrimaryContainer
                        font: Tokens.font.body.small
                        selectByMouse: true
                        cursorVisible: focus
                        z: 2

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            acceptedButtons: Qt.NoButton
                        }

                        onTextChanged: {
                            if (root.isEditingPath && activeFocus) {
                                root.updateSuggestions();
                            }
                        }

                        onActiveFocusChanged: {
                            if (activeFocus && root.isEditingPath) {
                                root.updateSuggestions();
                            }
                        }

                        Keys.onTabPressed: event => {
                            if (root.ghostCompletionText.length > 0) {
                                pathInput.text = pathInput.text + root.ghostCompletionText;
                                pathInput.cursorPosition = pathInput.text.length;
                                root.updateSuggestions();
                                event.accepted = true;
                                return;
                            }
                            let cur = root.activeTab ? ((root.activePane === 1 && root.activeTab.isSplit) ? root.activeTab.splitPath : root.activeTab.currentPath) : "";
                            let comp = FileUtils.getCompletedPath(pathInput.text, cur);
                            if (comp !== pathInput.text) {
                                pathInput.text = comp;
                                pathInput.cursorPosition = pathInput.text.length;
                                root.updateSuggestions();
                            } else if (root.pathSuggestions.length > 0) {
                                root.showSuggestions = true;
                                root.selectedSuggestionIndex = (root.selectedSuggestionIndex + 1) % root.pathSuggestions.length;
                                pathInput.text = root.pathSuggestions[root.selectedSuggestionIndex].displayPath;
                                pathInput.cursorPosition = pathInput.text.length;
                            }
                            event.accepted = true;
                        }

                        Keys.onRightPressed: event => {
                            if (pathInput.cursorPosition === pathInput.text.length && root.ghostCompletionText.length > 0) {
                                pathInput.text = pathInput.text + root.ghostCompletionText;
                                pathInput.cursorPosition = pathInput.text.length;
                                root.updateSuggestions();
                                event.accepted = true;
                                return;
                            }
                            event.accepted = false;
                        }

                        Keys.onDownPressed: event => {
                            if (root.pathSuggestions.length > 0) {
                                root.showSuggestions = true;
                                root.selectedSuggestionIndex = (root.selectedSuggestionIndex + 1) % root.pathSuggestions.length;
                                event.accepted = true;
                            }
                        }

                        Keys.onUpPressed: event => {
                            if (root.pathSuggestions.length > 0) {
                                root.showSuggestions = true;
                                root.selectedSuggestionIndex = (root.selectedSuggestionIndex - 1 + root.pathSuggestions.length) % root.pathSuggestions.length;
                                event.accepted = true;
                            }
                        }

                        Keys.onEscapePressed: event => {
                            if (root.showSuggestions) {
                                root.showSuggestions = false;
                                event.accepted = true;
                            } else {
                                root.isEditingPath = false;
                            }
                        }

                        onAccepted: {
                            root.commitPath();
                        }
                    }

                    StyledText {
                        id: ghostLabel
                        anchors.left: parent.left
                        anchors.leftMargin: pathInput.contentWidth
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.ghostCompletionText
                        font: pathInput.font
                        color: Colours.palette.m3onSurfaceVariant
                        opacity: 0.45
                        visible: root.ghostCompletionText.length > 0 && pathInput.activeFocus && pathInput.cursorPosition === pathInput.text.length
                        z: 1
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
                        id: clearPathHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pathInput.text = "";
                            root.updateSuggestions();
                        }
                    }

                    StyledToolTip {
                        text: qsTr("Clear")
                        visible: clearPathHover.containsMouse
                    }
                }

                // Dropdown Chevron
                Item {
                    implicitWidth: 22
                    implicitHeight: 22

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: root.showSuggestions ? "expand_less" : "expand_more"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.showSuggestions = !root.showSuggestions;
                            if (root.showSuggestions) root.updateSuggestions();
                        }
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
                        id: acceptPathHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.commitPath();
                        }
                    }

                    StyledToolTip {
                        text: qsTr("Go to location")
                        visible: acceptPathHover.containsMouse
                    }
                }
            }

            // Autocompletion Suggestions Dropdown Popup
            StyledRect {
                id: suggestionsPopup
                visible: root.isEditingPath && root.showSuggestions && root.pathSuggestions.length > 0 && !root.isSearching
                z: 300
                y: parent.height + 4
                anchors.left: parent.left
                width: Math.max(parent.width, 360)
                implicitHeight: Math.min(suggestionsList.contentHeight + Tokens.padding.extraSmall * 2, 240)
                radius: Tokens.rounding.large
                color: Colours.palette.m3surfaceContainerLow
                border.color: Colours.palette.m3outlineVariant
                border.width: 1

                ListView {
                    id: suggestionsList
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.extraSmall
                    clip: true
                    model: root.pathSuggestions
                    spacing: 2

                    ScrollBar.vertical: StyledScrollBar {
                        flickable: suggestionsList
                    }

                    delegate: StyledRect {
                        id: suggItem
                        required property int index
                        required property var modelData

                        width: suggestionsList.width
                        implicitHeight: 32
                        radius: Tokens.rounding.small
                        color: (root.selectedSuggestionIndex === index || suggHover.containsMouse) ? Colours.tPalette.m3surfaceContainerHigh : Qt.alpha(Colours.tPalette.m3surfaceContainerHigh, 0)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Tokens.padding.small
                            anchors.rightMargin: Tokens.padding.small
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                text: suggItem.modelData.icon || (suggItem.modelData.isDir ? "folder" : "description")
                                color: suggItem.modelData.isDir ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: suggItem.modelData.displayPath
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideMiddle
                            }

                            StyledText {
                                visible: suggItem.modelData.isDir
                                text: qsTr("Folder")
                                font: Tokens.font.label.small
                                color: Colours.palette.m3outline
                            }
                        }

                        MouseArea {
                            id: suggHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.applySuggestion(suggItem.index);
                                pathInput.forceActiveFocus();
                            }
                            onDoubleClicked: {
                                root.commitPath(suggItem.modelData.displayPath);
                            }
                        }
                    }
                }
            }


            // Search Bar
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

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor
                        acceptedButtons: Qt.NoButton
                    }

                    onTextChanged: {
                        root.searchText = text;
                        root.searchRequested(text);
                    }

                    Keys.onEscapePressed: {
                        text = "";
                        root.searchText = "";
                        root.isSearching = false;
                        root.searchRequested("");
                        if (typeof splitContainer !== "undefined" && splitContainer) {
                            splitContainer.focusActiveView();
                        }
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
                        id: closeSearchHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = "";
                            root.searchText = "";
                            root.isSearching = false;
                            root.searchRequested("");
                            if (typeof splitContainer !== "undefined" && splitContainer) {
                                splitContainer.focusActiveView();
                            }
                        }
                    }

                    StyledToolTip {
                        text: qsTr("Close search (Esc)")
                        visible: closeSearchHover.containsMouse
                    }
                }
            }
        }

        // Search Toggle Button
        Item {
            implicitWidth: 32
            implicitHeight: 32

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: root.isSearching ? Colours.palette.m3primaryContainer : (searchHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Qt.alpha(Colours.tPalette.m3surfaceContainerHighest, 0))

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

                StyledToolTip {
                    text: root.isSearching ? qsTr("Close search") : qsTr("Search (Ctrl+F)")
                    visible: searchHover.containsMouse
                }
            }
        }

        // Empty Trash Button
        Item {
            implicitWidth: emptyTrashContent.implicitWidth + 24
            implicitHeight: 32
            visible: {
                if (!root.activeTab) return false;
                let p = (root.activePane === 1 && root.activeTab.isSplit) ? root.activeTab.splitPath : root.activeTab.currentPath;
                return p && (p.indexOf("/Trash") !== -1 || p.indexOf("trash:") !== -1);
            }

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: emptyHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Qt.alpha(Colours.tPalette.m3surfaceContainerHighest, 0)

                RowLayout {
                    id: emptyTrashContent
                    anchors.centerIn: parent
                    spacing: 6

                    MaterialIcon {
                        text: "delete"
                        fontStyle: Tokens.font.icon.small
                        color: emptyHover.containsMouse ? Colours.palette.m3error : Colours.palette.m3onSurface
                    }

                    StyledText {
                        text: qsTr("Empty Trash")
                        font: Tokens.font.label.medium
                        color: emptyHover.containsMouse ? Colours.palette.m3error : Colours.palette.m3onSurface
                    }
                }

                MouseArea {
                    id: emptyHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: FileOperations.emptyTrash()
                }

                StyledToolTip {
                    text: qsTr("Empty all items in Trash")
                    visible: emptyHover.containsMouse
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

                // Grid View
                Item {
                    implicitWidth: 32
                    implicitHeight: 32

                    StyledRect {
                        anchors.fill: parent
                        radius: Tokens.rounding.full
                        color: (root.activeTab && root.activeTab.viewMode === 0) ? Colours.palette.m3secondaryContainer : (gridHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : Qt.alpha(Colours.palette.m3secondaryContainer, 0))

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "grid_view"
                            color: (root.activeTab && root.activeTab.viewMode === 0) ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }

                        MouseArea {
                            id: gridHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.activeTab) root.activeTab.viewMode = 0
                        }

                        StyledToolTip {
                            text: qsTr("Icons view (Ctrl+1)")
                            visible: gridHover.containsMouse
                        }
                    }
                }

                // Details / List View
                Item {
                    implicitWidth: 32
                    implicitHeight: 32

                    StyledRect {
                        anchors.fill: parent
                        radius: Tokens.rounding.full
                        color: (root.activeTab && root.activeTab.viewMode === 1) ? Colours.palette.m3secondaryContainer : (listHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : Qt.alpha(Colours.palette.m3secondaryContainer, 0))

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "view_list"
                            color: (root.activeTab && root.activeTab.viewMode === 1) ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }

                        MouseArea {
                            id: listHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.activeTab) root.activeTab.viewMode = 1
                        }

                        StyledToolTip {
                            text: qsTr("Details view (Ctrl+2)")
                            visible: listHover.containsMouse
                        }
                    }
                }

                // Compact View
                Item {
                    implicitWidth: 32
                    implicitHeight: 32

                    StyledRect {
                        anchors.fill: parent
                        radius: Tokens.rounding.full
                        color: (root.activeTab && root.activeTab.viewMode === 2) ? Colours.palette.m3secondaryContainer : (compactHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : Qt.alpha(Colours.palette.m3secondaryContainer, 0))

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "view_compact"
                            color: (root.activeTab && root.activeTab.viewMode === 2) ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }

                        MouseArea {
                            id: compactHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.activeTab) root.activeTab.viewMode = 2
                        }

                        StyledToolTip {
                            text: qsTr("Compact view (Ctrl+3)")
                            visible: compactHover.containsMouse
                        }
                    }
                }
            }
        }


        // Info / Preview Toggle
        Item {
            implicitWidth: 32
            implicitHeight: 32

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: infoHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Qt.alpha(Colours.tPalette.m3surfaceContainerHighest, 0)

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

                StyledToolTip {
                    text: qsTr("Preview panel (F1)")
                    visible: infoHover.containsMouse
                }
            }
        }

        // Settings / Preferences
        Item {
            implicitWidth: 32
            implicitHeight: 32

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: prefsHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Qt.alpha(Colours.tPalette.m3surfaceContainerHighest, 0)


                MaterialIcon {
                    anchors.centerIn: parent
                    text: "settings"
                    color: Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }

                MouseArea {
                    id: prefsHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.preferencesRequested()
                }

                StyledToolTip {
                    text: qsTr("Preferences (Ctrl+,)")
                    visible: prefsHover.containsMouse
                }
            }
        }
    }

    function openSearch(initialChar) {
        isSearching = true;
        if (typeof initialChar === "string" && initialChar.length > 0) {
            searchText = initialChar;
            searchInput.text = initialChar;
            searchRequested(initialChar);
            searchInput.cursorPosition = searchInput.text.length;
        } else {
            searchInput.selectAll();
        }
        searchInput.forceActiveFocus();
    }

    function openAddressEdit() {
        isEditingPath = true;
        pathInput.forceActiveFocus();
        pathInput.selectAll();
    }
}
