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

    readonly property list<MenuItem> startupItems: [
        MenuItem {
            text: qsTr("Home Directory")
        },
        MenuItem {
            text: qsTr("Previous Session")
        },
        MenuItem {
            text: qsTr("Custom Path")
        }
    ]
    readonly property var startupValues: ["home", "last", "custom"]

    function startupIndex() {
        const v = AppController.defaultStartupDirectory;
        if (v === "home")
            return 0;
        if (v === "last")
            return 1;
        return 2;
    }

    readonly property list<MenuItem> thumbSizeItems: [
        MenuItem {
            text: qsTr("10 MB")
        },
        MenuItem {
            text: qsTr("100 MB")
        },
        MenuItem {
            text: qsTr("1 GB")
        },
        MenuItem {
            text: qsTr("No limit")
        }
    ]
    readonly property var thumbSizeValues: [10, 100, 1024, 0]

    readonly property list<MenuItem> viewModeItems: [
        MenuItem {
            text: qsTr("Grid View")
        },
        MenuItem {
            text: qsTr("Details View")
        },
        MenuItem {
            text: qsTr("Compact View")
        }
    ]
    readonly property var viewModeValues: [0, 1, 2]

    readonly property list<MenuItem> dateFormatItems: [
        MenuItem {
            text: qsTr("ISO (YYYY-MM-DD)")
        },
        MenuItem {
            text: qsTr("Short (MM/DD/YY)")
        },
        MenuItem {
            text: qsTr("Long (Date Time)")
        },
        MenuItem {
            text: qsTr("Custom")
        }
    ]
    // Order matches dateFormatItems: ISO, Short, Long
    readonly property var dateFormatValues: [1, 0, 2, 3]

    readonly property list<MenuItem> iconSizeItems: [
        MenuItem {
            text: qsTr("Small (16px)")
        },
        MenuItem {
            text: qsTr("Medium (20px)")
        },
        MenuItem {
            text: qsTr("Large (24px)")
        },
        MenuItem {
            text: qsTr("X-Large (32px)")
        }
    ]
    readonly property var iconSizeValues: [16, 20, 24, 32]

    readonly property list<MenuItem> sortFieldItems: [
        MenuItem {
            text: qsTr("Name")
        },
        MenuItem {
            text: qsTr("Size")
        },
        MenuItem {
            text: qsTr("Date")
        },
        MenuItem {
            text: qsTr("Type")
        }
    ]
    readonly property var sortFieldValues: [0, 1, 2, 3]

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
        width: Math.min(parent.width - 64, 760)
        height: Math.min(parent.height - 64, 660)
        implicitWidth: 760
        implicitHeight: 660

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
            spacing: Tokens.spacing.large

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
                                Layout.topMargin: Tokens.spacing.small
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                            }

                            SplitButtonRow {
                                first: true
                                last: !(AppController.defaultStartupDirectory !== "home" && AppController.defaultStartupDirectory !== "last")
                                label: qsTr("Startup Directory")
                                subtext: qsTr("Initial directory opened on application launch")
                                menuItems: root.startupItems
                                active: root.startupItems[root.startupIndex()]
                                onSelected: item => {
                                    const v = root.startupValues[root.startupItems.indexOf(item)];
                                    if (v === "custom") {
                                        if (AppController.defaultStartupDirectory === "home" || AppController.defaultStartupDirectory === "last") {
                                            AppController.defaultStartupDirectory = FileUtils.home;
                                        }
                                    } else {
                                        AppController.defaultStartupDirectory = v;
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
                                Layout.topMargin: Tokens.spacing.small
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
                                    icon: "tab_duplicate"
                                    text: qsTr("Restore Tabs on Startup")
                                    subtext: qsTr("Reopen the tabs that were open when the window was last closed")
                                    checked: AppController.restoreTabs
                                    onToggled: checked => AppController.restoreTabs = checked
                                }

                                ToggleRow {
                                    icon: "delete"
                                    text: qsTr("Confirm Move to Trash")
                                    subtext: qsTr("Ask before moving files to the trash")
                                    checked: AppController.confirmMoveToTrash
                                    onToggled: checked => AppController.confirmMoveToTrash = checked
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
                                Layout.topMargin: Tokens.spacing.small
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                                opacity: AppController.thumbnailsEnabled ? 1 : 0.4
                            }

                            SplitButtonRow {
                                first: true
                                last: true
                                label: qsTr("Thumbnail Size Limit")
                                subtext: qsTr("Maximum file size for preview thumbnail generation")
                                enabled: AppController.thumbnailsEnabled
                                opacity: enabled ? 1 : 0.4
                                menuItems: root.thumbSizeItems
                                active: root.thumbSizeItems[Math.max(0, root.thumbSizeValues.indexOf(AppController.thumbnailMaxMb))]
                                onSelected: item => AppController.thumbnailMaxMb = root.thumbSizeValues[root.thumbSizeItems.indexOf(item)]
                            }

                            Item { implicitHeight: 4 }

                            StyledText {
                                text: qsTr("Theme & Icons")
                                Layout.topMargin: Tokens.spacing.small
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
                                Layout.topMargin: Tokens.spacing.small
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                            }

                            SplitButtonRow {
                                first: true
                                last: true
                                label: qsTr("Default View Mode")
                                subtext: qsTr("Initial view layout when opening directories")
                                menuItems: root.viewModeItems
                                active: root.viewModeItems[Math.max(0, root.viewModeValues.indexOf(AppController.defaultViewMode))]
                                onSelected: item => AppController.defaultViewMode = root.viewModeValues[root.viewModeItems.indexOf(item)]
                            }

                            Item { implicitHeight: 4 }

                            StyledText {
                                text: qsTr("Details View Columns")
                                Layout.topMargin: Tokens.spacing.small
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
                                Layout.topMargin: Tokens.spacing.small
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                            }

                            SplitButtonRow {
                                first: true
                                last: AppController.dateFormat !== 3
                                label: qsTr("Date Format")
                                subtext: qsTr("Format: %1").arg(FileUtils.formatDateTime(new Date(), AppController.dateFormat))
                                menuItems: root.dateFormatItems
                                active: root.dateFormatItems[Math.max(0, root.dateFormatValues.indexOf(AppController.dateFormat))]
                                onSelected: item => AppController.dateFormat = root.dateFormatValues[root.dateFormatItems.indexOf(item)]
                            }

                            StyledRect {
                                visible: AppController.dateFormat === 3
                                Layout.fillWidth: true
                                implicitHeight: 42
                                topLeftRadius: Tokens.rounding.extraSmall
                                topRightRadius: Tokens.rounding.extraSmall
                                bottomLeftRadius: Tokens.rounding.large
                                bottomRightRadius: Tokens.rounding.large
                                color: Colours.tPalette.m3surfaceContainer

                                TextInput {
                                    id: customDateInput
                                    anchors.fill: parent
                                    anchors.leftMargin: Tokens.padding.largeIncreased
                                    anchors.rightMargin: Tokens.padding.largeIncreased
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: AppController.customDateFormat
                                    color: Colours.palette.m3onSurface
                                    font: Tokens.font.body.small
                                    selectByMouse: true
                                    clip: true
                                    onEditingFinished: AppController.customDateFormat = text
                                }
                            }

                            Item { implicitHeight: 4 }

                            StyledText {
                                text: qsTr("Sidebar Navigation")
                                Layout.topMargin: Tokens.spacing.small
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                SplitButtonRow {
                                    first: true
                                    label: qsTr("Sidebar Icon Size")
                                    subtext: qsTr("Size of icons in the navigation sidebar")
                                    menuItems: root.iconSizeItems
                                    active: root.iconSizeItems[Math.max(0, root.iconSizeValues.indexOf(AppController.placesIconSize))]
                                    onSelected: item => AppController.placesIconSize = root.iconSizeValues[root.iconSizeItems.indexOf(item)]
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
                                Layout.topMargin: Tokens.spacing.small
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                SplitButtonRow {
                                    first: true
                                    label: qsTr("Default Sort Field")
                                    subtext: qsTr("Primary criterion for sorting file entries")
                                    menuItems: root.sortFieldItems
                                    active: root.sortFieldItems[Math.max(0, root.sortFieldValues.indexOf(AppController.defaultSortField))]
                                    onSelected: item => AppController.defaultSortField = root.sortFieldValues[root.sortFieldItems.indexOf(item)]
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
                                Layout.topMargin: Tokens.spacing.small
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
                                Layout.topMargin: Tokens.spacing.small
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

            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.extraSmall
                implicitHeight: 1
                color: Qt.alpha(Colours.palette.m3outlineVariant, 0.6)
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
