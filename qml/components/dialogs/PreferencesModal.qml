import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../containers"
import "../controls"
import "../tabs"
import prism

MouseArea {
    id: root

    property bool expanded: false
    property int currentCategory: 0

    anchors.fill: parent
    visible: opacity > 0.001
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    z: 110

    opacity: expanded ? 1.0 : 0.0
    Behavior on opacity { Anim { type: Anim.FastEffects } }

    onClicked: root.expanded = false
    onWheel: wheel => wheel.accepted = true
    Keys.onEscapePressed: root.expanded = false

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.45)
    }

    StyledRect {
        id: modalCard

        anchors.centerIn: parent
        width: Math.min(parent.width - 32, 580)
        height: Math.min(parent.height - 32, 560)
        implicitWidth: 580
        implicitHeight: 560

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerHigh

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
            onWheel: wheel => wheel.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "settings"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    text: qsTr("Preferences")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.builders.large.weight(Font.Bold).build()
                    Layout.fillWidth: true
                }

                IconButton {
                    type: ButtonBase.Text
                    icon: "close"
                    onClicked: root.expanded = false
                }
            }

            // Category Navigation Tabs
            M3TopTabBar {
                Layout.fillWidth: true
                currentIndex: root.currentCategory
                model: [
                    { label: qsTr("General"), icon: "tune" },
                    { label: qsTr("View & Sorting"), icon: "grid_view" },
                    { label: qsTr("Context Menu"), icon: "menu" },
                    { label: qsTr("Scripts & Tools"), icon: "terminal" }
                ]
                onTabSelected: index => root.currentCategory = index
            }

            // Sliding Content Area
            Item {
                id: contentArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Row {
                    id: pagesRow
                    width: contentArea.width * 4
                    height: contentArea.height
                    x: -root.currentCategory * contentArea.width

                    Behavior on x {
                        Anim {
                            type: Anim.DefaultSpatial
                        }
                    }

                    // --- TAB 0: General & Startup ---
                    VerticalFadeFlickable {
                        id: tab0Flickable
                        width: contentArea.width
                        height: contentArea.height
                        contentWidth: width
                        contentHeight: tab0Col.implicitHeight + Tokens.padding.medium
                        clip: true
                        fadeAmount: 0.08
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: StyledScrollBar {
                            flickable: tab0Flickable
                        }

                        ColumnLayout {
                            id: tab0Col
                            width: tab0Flickable.width
                            spacing: Tokens.spacing.medium

                            StyledText {
                                text: qsTr("Startup Location")
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                            }

                            SplitButtonRow {
                                first: true
                                last: !(AppController.defaultStartupDirectory !== "home" && AppController.defaultStartupDirectory !== "last")
                                icon: "home"
                                text: qsTr("Startup Directory")
                                subtext: qsTr("Initial directory opened on application launch")
                                model: [
                                    { id: "home", label: qsTr("Home Directory"), icon: "home" },
                                    { id: "last", label: qsTr("Previous Session"), icon: "history" },
                                    { id: "custom", label: qsTr("Custom Path"), icon: "folder" }
                                ]
                                valueKey: "id"
                                currentValue: (AppController.defaultStartupDirectory === "home" || AppController.defaultStartupDirectory === "last") ? AppController.defaultStartupDirectory : "custom"
                                onSelected: (val) => {
                                    if (val === "custom") {
                                        if (AppController.defaultStartupDirectory === "home" || AppController.defaultStartupDirectory === "last") {
                                            AppController.defaultStartupDirectory = FileUtils.home;
                                        }
                                    } else {
                                        AppController.defaultStartupDirectory = val;
                                    }
                                }
                            }

                            // Custom path input
                            StyledRect {
                                visible: AppController.defaultStartupDirectory !== "home" && AppController.defaultStartupDirectory !== "last"
                                Layout.fillWidth: true
                                implicitHeight: 42
                                radius: Tokens.rounding.medium
                                color: Colours.tPalette.m3surfaceContainerHighest

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Tokens.padding.medium
                                    anchors.rightMargin: Tokens.padding.small
                                    spacing: Tokens.spacing.small

                                    MaterialIcon {
                                        text: "folder"
                                        color: Colours.palette.m3primary
                                        fontStyle: Tokens.font.icon.small
                                    }

                                    TextInput {
                                        id: customPathInput
                                        Layout.fillWidth: true
                                        text: AppController.defaultStartupDirectory
                                        color: Colours.palette.m3onSurface
                                        font: Tokens.font.body.small
                                        selectByMouse: true
                                        onEditingFinished: {
                                            if (text.trim().length > 0) {
                                                AppController.defaultStartupDirectory = text.trim();
                                            }
                                        }
                                    }
                                }
                            }

                            Item { implicitHeight: 4 }

                            StyledText {
                                text: qsTr("File Display & Navigation")
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                ToggleRow {
                                    first: true
                                    icon: "visibility"
                                    text: qsTr("Show Hidden Files and Folders")
                                    subtext: qsTr("Display hidden dotfiles in views (Ctrl+H)")
                                    checked: AppController.showHidden
                                    onToggled: val => AppController.showHidden = val
                                }

                                ToggleRow {
                                    icon: "delete_forever"
                                    text: qsTr("Confirm Permanent Deletion")
                                    subtext: qsTr("Ask before deleting files without using the trash (Shift+Delete)")
                                    checked: AppController.confirmPermanentDelete
                                    onToggled: val => AppController.confirmPermanentDelete = val
                                }

                                ToggleRow {
                                    icon: "image"
                                    text: qsTr("Show Thumbnails")
                                    subtext: qsTr("Preview images and videos instead of generic icons")
                                    checked: AppController.thumbnailsEnabled
                                    onToggled: val => AppController.thumbnailsEnabled = val
                                }

                                ToggleRow {
                                    last: true
                                    icon: "mouse"
                                    text: qsTr("Single-Click Activation")
                                    subtext: qsTr("Single click opens files; hover over items to select")
                                    checked: AppController.singleClick
                                    onToggled: val => AppController.singleClick = val
                                }
                            }

                            Item { implicitHeight: 4 }

                            StyledText {
                                text: qsTr("Thumbnail Generation")
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                                opacity: AppController.thumbnailsEnabled ? 1 : 0.4
                            }

                            SplitButtonRow {
                                first: true
                                last: true
                                icon: "image"
                                text: qsTr("Thumbnail Size Limit")
                                subtext: qsTr("Maximum file size for preview thumbnail generation")
                                enabled: AppController.thumbnailsEnabled
                                opacity: enabled ? 1 : 0.4
                                model: [
                                    { mb: 10, label: qsTr("10 MB") },
                                    { mb: 100, label: qsTr("100 MB") },
                                    { mb: 1024, label: qsTr("1 GB") },
                                    { mb: 0, label: qsTr("No limit") }
                                ]
                                valueKey: "mb"
                                currentValue: AppController.thumbnailMaxMb
                                onSelected: val => AppController.thumbnailMaxMb = val
                            }

                            Item { implicitHeight: 4 }

                            StyledText {
                                text: qsTr("Theme & Icons")
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                            }

                            // Papirus Folders hot reload card
                            StyledRect {
                                Layout.fillWidth: true
                                implicitHeight: 56
                                radius: Tokens.rounding.large
                                color: Colours.tPalette.m3surfaceContainer

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Tokens.padding.medium
                                    anchors.rightMargin: Tokens.padding.medium
                                    spacing: Tokens.spacing.medium

                                    MaterialIcon {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: "folder_special"
                                        color: Colours.palette.m3primary
                                        fontStyle: Tokens.font.icon.medium
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 2

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: qsTr("Papirus Folders")
                                            color: Colours.palette.m3onSurface
                                            font: Tokens.font.body.small
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: qsTr("Active folder color: %1 • Hot reload active").arg(PapirusWatcher.currentColor)
                                            color: Colours.palette.m3onSurfaceVariant
                                            font: Tokens.font.label.small
                                            elide: Text.ElideRight
                                        }
                                    }

                                    IconTextButton {
                                        type: ButtonBase.Tonal
                                        icon: "refresh"
                                        text: qsTr("Reload")
                                        Layout.alignment: Qt.AlignVCenter
                                        onClicked: PapirusWatcher.reload()
                                    }
                                }
                            }

                            Item { implicitHeight: Tokens.padding.small }
                        }
                    }

                    // --- TAB 1: View & Sorting Defaults ---
                    VerticalFadeFlickable {
                        id: tab1Flickable
                        width: contentArea.width
                        height: contentArea.height
                        contentWidth: width
                        contentHeight: tab1Col.implicitHeight + Tokens.padding.medium
                        clip: true
                        fadeAmount: 0.08
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: StyledScrollBar {
                            flickable: tab1Flickable
                        }

                        ColumnLayout {
                            id: tab1Col
                            width: tab1Flickable.width
                            spacing: Tokens.spacing.medium

                            StyledText {
                                text: qsTr("Layout & View Mode")
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                            }

                            SplitButtonRow {
                                first: true
                                last: true
                                icon: "grid_view"
                                text: qsTr("Default View Mode")
                                subtext: qsTr("Initial view layout when opening directories")
                                model: [
                                    { mode: 0, label: qsTr("Grid View"), icon: "grid_view" },
                                    { mode: 1, label: qsTr("Details View"), icon: "view_list" },
                                    { mode: 2, label: qsTr("Compact View"), icon: "view_stream" }
                                ]
                                valueKey: "mode"
                                currentValue: AppController.defaultViewMode
                                onSelected: val => AppController.defaultViewMode = val
                            }

                            Item { implicitHeight: 4 }

                            StyledText {
                                text: qsTr("Details View Columns")
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                ButtonRowItem {
                                    first: true
                                    icon: "straighten"
                                    text: qsTr("Size")
                                    checked: AppController.showSizeColumn
                                    onClicked: AppController.showSizeColumn = !AppController.showSizeColumn
                                }

                                ButtonRowItem {
                                    icon: "category"
                                    text: qsTr("Type")
                                    checked: AppController.showTypeColumn
                                    onClicked: AppController.showTypeColumn = !AppController.showTypeColumn
                                }

                                ButtonRowItem {
                                    icon: "schedule"
                                    text: qsTr("Date Modified")
                                    checked: AppController.showDateColumn
                                    onClicked: AppController.showDateColumn = !AppController.showDateColumn
                                }

                                ButtonRowItem {
                                    last: true
                                    icon: "lock"
                                    text: qsTr("Permissions")
                                    checked: AppController.showPermissionsColumn
                                    onClicked: AppController.showPermissionsColumn = !AppController.showPermissionsColumn
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: qsTr("The name column is always shown")
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }

                            Item { implicitHeight: 4 }

                            StyledText {
                                text: qsTr("Date & Time")
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                            }

                            SplitButtonRow {
                                first: true
                                last: true
                                icon: "calendar_month"
                                text: qsTr("Date Format")
                                subtext: qsTr("Format: %1").arg(FileUtils.formatDateTime(new Date(), AppController.dateFormat))
                                model: [
                                    { mode: 1, label: qsTr("ISO (YYYY-MM-DD)"), icon: "calendar_month" },
                                    { mode: 0, label: qsTr("Short (MM/DD/YY)"), icon: "schedule" },
                                    { mode: 2, label: qsTr("Long (Date Time)"), icon: "event_note" }
                                ]
                                valueKey: "mode"
                                currentValue: AppController.dateFormat
                                onSelected: val => AppController.dateFormat = val
                            }

                            Item { implicitHeight: 4 }

                            StyledText {
                                text: qsTr("Sidebar Navigation")
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                SplitButtonRow {
                                    first: true
                                    icon: "photo_size_select_small"
                                    text: qsTr("Sidebar Icon Size")
                                    subtext: qsTr("Size of icons in the navigation sidebar")
                                    model: [
                                        { size: 16, label: qsTr("Small (16px)"), icon: "photo_size_select_small" },
                                        { size: 20, label: qsTr("Medium (20px)"), icon: "photo_size_select_large" },
                                        { size: 24, label: qsTr("Large (24px)"), icon: "crop_free" },
                                        { size: 32, label: qsTr("X-Large (32px)"), icon: "fullscreen" }
                                    ]
                                    valueKey: "size"
                                    currentValue: AppController.placesIconSize
                                    onSelected: val => AppController.placesIconSize = val
                                }

                                ToggleRow {
                                    last: true
                                    icon: "cloud"
                                    text: qsTr("Show Network Section")
                                    subtext: qsTr("Display remote servers and network locations in sidebar")
                                    checked: AppController.showNetworkSection
                                    onToggled: val => AppController.showNetworkSection = val
                                }
                            }

                            Item { implicitHeight: 4 }

                            StyledText {
                                text: qsTr("Sorting & Organization")
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                SplitButtonRow {
                                    first: true
                                    icon: "sort"
                                    text: qsTr("Default Sort Field")
                                    subtext: qsTr("Primary criterion for sorting file entries")
                                    model: [
                                        { field: 0, label: qsTr("Name"), icon: "sort_by_alpha" },
                                        { field: 1, label: qsTr("Size"), icon: "straighten" },
                                        { field: 2, label: qsTr("Date"), icon: "schedule" },
                                        { field: 3, label: qsTr("Type"), icon: "category" }
                                    ]
                                    valueKey: "field"
                                    currentValue: AppController.defaultSortField
                                    onSelected: val => AppController.defaultSortField = val
                                }

                                RowButton {
                                    icon: AppController.defaultSortOrder === 0 ? "arrow_upward" : "arrow_downward"
                                    text: qsTr("Sort Direction")
                                    subtext: AppController.defaultSortOrder === 0 ? qsTr("Ascending (A to Z, oldest first)") : qsTr("Descending (Z to A, newest first)")
                                    onClicked: AppController.defaultSortOrder = (AppController.defaultSortOrder === 0 ? 1 : 0)
                                }

                                ToggleRow {
                                    last: true
                                    icon: "folder"
                                    text: qsTr("Folders First")
                                    subtext: qsTr("Always display folders above files when sorting")
                                    checked: AppController.showDirsFirst
                                    onToggled: val => AppController.showDirsFirst = val
                                }
                            }

                            Item { implicitHeight: Tokens.padding.small }
                        }
                    }

                    // --- TAB 2: Context Menu Customization ---
                    VerticalFadeFlickable {
                        id: tab2Flickable
                        width: contentArea.width
                        height: contentArea.height
                        contentWidth: width
                        contentHeight: tab2Col.implicitHeight + Tokens.padding.medium
                        clip: true
                        fadeAmount: 0.08
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: StyledScrollBar {
                            flickable: tab2Flickable
                        }

                        ColumnLayout {
                            id: tab2Col
                            width: tab2Flickable.width
                            spacing: Tokens.spacing.medium

                            StyledText {
                                text: qsTr("Context Menu Visibility")
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                            }

                            StyledText {
                                text: qsTr("Customize which items and submenus appear in right-click context menus.")
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.small
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                // Secondary Code Editor Toggle
                                ToggleRow {
                                    first: true
                                    icon: "code"
                                    text: qsTr("Secondary Code Editor")
                                    subtext: qsTr("Show detected editor like VS Code or VSCodium under Open")
                                    checked: AppController.menuShowSecondaryEditor
                                    onToggled: val => AppController.menuShowSecondaryEditor = val
                                }

                                // Upload Online Toggle
                                ToggleRow {
                                    icon: "cloud_upload"
                                    text: qsTr("Upload Online")
                                    subtext: qsTr("Upload directly to Catbox and Litterbox")
                                    checked: AppController.menuShowUploadOnline
                                    onToggled: val => AppController.menuShowUploadOnline = val
                                }

                                // Send To Submenu Toggle
                                ToggleRow {
                                    icon: "send"
                                    text: qsTr("Send To Submenu")
                                    subtext: qsTr("Include sharing destinations and external targets")
                                    checked: AppController.menuShowSendTo
                                    onToggled: val => AppController.menuShowSendTo = val
                                }

                                // Compress & Archive Toggle
                                ToggleRow {
                                    icon: "archive"
                                    text: qsTr("Compress & Archive")
                                    subtext: qsTr("Archive presets and extraction tools")
                                    checked: AppController.menuShowCompress
                                    onToggled: val => AppController.menuShowCompress = val
                                }

                                // Create Symlink Toggle
                                ToggleRow {
                                    icon: "link"
                                    text: qsTr("Symlinks")
                                    subtext: qsTr("Show Create Symlink and Paste as Symlink")
                                    checked: AppController.menuShowSymlink
                                    onToggled: val => AppController.menuShowSymlink = val
                                }

                                // Open in Terminal Toggle
                                ToggleRow {
                                    icon: "terminal"
                                    text: qsTr("Open in Terminal")
                                    subtext: qsTr("Launch default terminal emulator in directory")
                                    checked: AppController.menuShowTerminal
                                    onToggled: val => AppController.menuShowTerminal = val
                                }

                                // Permanent Delete Toggle
                                ToggleRow {
                                    last: true
                                    icon: "delete"
                                    text: qsTr("Delete Actions")
                                    subtext: qsTr("Show Move to Trash and Delete Permanently")
                                    checked: AppController.menuShowDelete
                                    onToggled: val => AppController.menuShowDelete = val
                                }
                            }

                            Item { implicitHeight: Tokens.padding.small }
                        }
                    }

                    // --- TAB 3: Custom Scripts & Tools ---
                    VerticalFadeFlickable {
                        id: tab3Flickable
                        width: contentArea.width
                        height: contentArea.height
                        contentWidth: width
                        contentHeight: tab3Col.implicitHeight + Tokens.padding.medium
                        clip: true
                        fadeAmount: 0.08
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: StyledScrollBar {
                            flickable: tab3Flickable
                        }

                        ColumnLayout {
                            id: tab3Col
                            width: tab3Flickable.width
                            spacing: Tokens.spacing.medium

                            StyledText {
                                text: qsTr("Custom Context Actions & Scripts")
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                            }

                            StyledText {
                                text: qsTr("Prism supports custom scripts and action entries in your context menu. Place executable scripts in the scripts directory to run custom commands with selected files.")
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.small
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            // Open Scripts Directory Card
                            RowButton {
                                first: true
                                last: true
                                icon: "folder_special"
                                text: qsTr("Open Scripts Folder")
                                subtext: qsTr("~/.local/share/prism/scripts/ (Also supports Nautilus scripts)")
                                trailingIcon: "open_in_new"
                                onClicked: AppIntegration.openScriptsFolder()
                            }

                            Item { implicitHeight: Tokens.padding.small }
                        }
                    }
                }
            }

            // Bottom Action Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Item { Layout.fillWidth: true }

                // Cancel Button
                TextButton {
                    type: ButtonBase.Text
                    text: qsTr("Cancel")
                    onClicked: root.expanded = false
                }

                // Done Button
                TextButton {
                    type: ButtonBase.Filled
                    text: qsTr("Done")
                    onClicked: root.expanded = false
                }
            }
        }
    }
}
