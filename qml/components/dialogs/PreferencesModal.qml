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
            }

            // Category Navigation Tabs
            M3TopTabBar {
                Layout.fillWidth: true
                currentIndex: root.currentCategory
                model: [
                    { label: qsTr("General"), icon: "tune" },
                    { label: qsTr("View & Sorting"), icon: "grid_view" },
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
                    width: contentArea.width * 3
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

                            // Startup mode buttons
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                Repeater {
                                    model: [
                                        { id: "home", label: qsTr("Home Directory"), icon: "home" },
                                        { id: "last", label: qsTr("Previous Session"), icon: "history" },
                                        { id: "custom", label: qsTr("Custom Path"), icon: "folder" }
                                    ]

                                    StyledRect {
                                        id: startModeCard
                                        required property int index
                                        required property var modelData

                                        Layout.fillWidth: true
                                        implicitHeight: 44
                                        radius: Tokens.rounding.medium
                                        readonly property bool isSelected: (startModeCard.modelData.id === "custom" && AppController.defaultStartupDirectory !== "home" && AppController.defaultStartupDirectory !== "last") || (AppController.defaultStartupDirectory === startModeCard.modelData.id)
                                        color: isSelected
                                            ? Colours.palette.m3primaryContainer
                                            : (startModeHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer)

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6

                                            MaterialIcon {
                                                text: startModeCard.modelData.icon
                                                color: startModeCard.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                                                fontStyle: Tokens.font.icon.small
                                            }

                                            StyledText {
                                                text: startModeCard.modelData.label
                                                color: startModeCard.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                                font: Tokens.font.body.small
                                                elide: Text.ElideRight
                                            }
                                        }

                                        MouseArea {
                                            id: startModeHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (startModeCard.modelData.id === "custom") {
                                                    if (AppController.defaultStartupDirectory === "home" || AppController.defaultStartupDirectory === "last") {
                                                        AppController.defaultStartupDirectory = FileUtils.home;
                                                    }
                                                } else {
                                                    AppController.defaultStartupDirectory = startModeCard.modelData.id;
                                                }
                                            }
                                        }
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

                            // Hidden files toggle card
                            StyledRect {
                                Layout.fillWidth: true
                                implicitHeight: 56
                                radius: Tokens.rounding.large
                                color: hideHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Tokens.padding.medium
                                    anchors.rightMargin: Tokens.padding.medium
                                    spacing: Tokens.spacing.medium

                                    MaterialIcon {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: AppController.showHidden ? "visibility" : "visibility_off"
                                        color: AppController.showHidden ? Colours.palette.m3primary : Colours.palette.m3outline
                                        fontStyle: Tokens.font.icon.medium
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 2

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: qsTr("Show Hidden Files and Folders")
                                            color: Colours.palette.m3onSurface
                                            font: Tokens.font.body.small
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: qsTr("Display hidden dotfiles in views (Ctrl+H)")
                                            color: Colours.palette.m3onSurfaceVariant
                                            font: Tokens.font.label.small
                                            elide: Text.ElideRight
                                        }
                                    }

                                    StyledCheckBox {
                                        Layout.alignment: Qt.AlignVCenter
                                        checked: AppController.showHidden
                                        onToggled: val => AppController.showHidden = val
                                    }
                                }

                                MouseArea {
                                    id: hideHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: AppController.showHidden = !AppController.showHidden
                                }
                            }

                            // Confirm permanent delete toggle card
                            StyledRect {
                                Layout.fillWidth: true
                                implicitHeight: 56
                                radius: Tokens.rounding.large
                                color: confirmDelHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Tokens.padding.medium
                                    anchors.rightMargin: Tokens.padding.medium
                                    spacing: Tokens.spacing.medium

                                    MaterialIcon {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: "delete_forever"
                                        color: AppController.confirmPermanentDelete ? Colours.palette.m3primary : Colours.palette.m3outline
                                        fontStyle: Tokens.font.icon.medium
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 2

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: qsTr("Confirm Permanent Deletion")
                                            color: Colours.palette.m3onSurface
                                            font: Tokens.font.body.small
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: qsTr("Ask before deleting files without using the trash (Shift+Delete)")
                                            color: Colours.palette.m3onSurfaceVariant
                                            font: Tokens.font.label.small
                                            elide: Text.ElideRight
                                        }
                                    }

                                    StyledCheckBox {
                                        Layout.alignment: Qt.AlignVCenter
                                        checked: AppController.confirmPermanentDelete
                                        onToggled: val => AppController.confirmPermanentDelete = val
                                    }
                                }

                                MouseArea {
                                    id: confirmDelHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: AppController.confirmPermanentDelete = !AppController.confirmPermanentDelete
                                }
                            }

                            // Single-click toggle card
                            StyledRect {
                                Layout.fillWidth: true
                                implicitHeight: 56
                                radius: Tokens.rounding.large
                                color: singleHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Tokens.padding.medium
                                    anchors.rightMargin: Tokens.padding.medium
                                    spacing: Tokens.spacing.medium

                                    MaterialIcon {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: "mouse"
                                        color: AppController.singleClick ? Colours.palette.m3primary : Colours.palette.m3outline
                                        fontStyle: Tokens.font.icon.medium
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 2

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: qsTr("Single-Click Activation")
                                            color: Colours.palette.m3onSurface
                                            font: Tokens.font.body.small
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: qsTr("Single click opens files; hover over items to select")
                                            color: Colours.palette.m3onSurfaceVariant
                                            font: Tokens.font.label.small
                                            elide: Text.ElideRight
                                        }
                                    }

                                    StyledCheckBox {
                                        Layout.alignment: Qt.AlignVCenter
                                        checked: AppController.singleClick
                                        onToggled: val => AppController.singleClick = val
                                    }
                                }

                                MouseArea {
                                    id: singleHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: AppController.singleClick = !AppController.singleClick
                                }
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

                                    StyledRect {
                                        implicitWidth: 80
                                        implicitHeight: 32
                                        radius: Tokens.rounding.full
                                        color: reloadBtnHover.containsMouse ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHighest
                                        Layout.alignment: Qt.AlignVCenter

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 4
                                            MaterialIcon {
                                                text: "refresh"
                                                color: Colours.palette.m3primary
                                                fontStyle: Tokens.font.icon.small
                                            }
                                            StyledText {
                                                text: qsTr("Reload")
                                                color: Colours.palette.m3primary
                                                font: Tokens.font.label.small
                                            }
                                        }

                                        MouseArea {
                                            id: reloadBtnHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: PapirusWatcher.reload()
                                        }
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
                                text: qsTr("Default View Mode")
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                            }

                            // View mode selection
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                Repeater {
                                    model: [
                                        { mode: 0, label: qsTr("Grid View"), icon: "grid_view" },
                                        { mode: 1, label: qsTr("Details View"), icon: "view_list" },
                                        { mode: 2, label: qsTr("Compact View"), icon: "view_stream" }
                                    ]

                                    StyledRect {
                                        id: viewCard
                                        required property int index
                                        required property var modelData

                                        Layout.fillWidth: true
                                        implicitHeight: 44
                                        radius: Tokens.rounding.medium
                                        readonly property bool isSelected: AppController.defaultViewMode === viewCard.modelData.mode
                                        color: isSelected
                                            ? Colours.palette.m3primaryContainer
                                            : (viewHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer)

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6

                                            MaterialIcon {
                                                text: viewCard.modelData.icon
                                                color: viewCard.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                                                fontStyle: Tokens.font.icon.small
                                            }

                                            StyledText {
                                                text: viewCard.modelData.label
                                                color: viewCard.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                                font: Tokens.font.body.small
                                                elide: Text.ElideRight
                                            }
                                        }

                                        MouseArea {
                                            id: viewHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: AppController.defaultViewMode = viewCard.modelData.mode
                                        }
                                    }
                                }
                            }

                            Item { implicitHeight: 4 }

                            StyledText {
                                text: qsTr("Places Sidebar Icon Size")
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                            }

                            // Places Sidebar Icon Size Selection
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                Repeater {
                                    model: [
                                        { size: 16, label: qsTr("Small (16px)"), icon: "photo_size_select_small" },
                                        { size: 20, label: qsTr("Medium (20px)"), icon: "photo_size_select_large" },
                                        { size: 24, label: qsTr("Large (24px)"), icon: "crop_free" },
                                        { size: 32, label: qsTr("X-Large (32px)"), icon: "fullscreen" }
                                    ]

                                    StyledRect {
                                        id: sizeCard
                                        required property int index
                                        required property var modelData

                                        Layout.fillWidth: true
                                        implicitHeight: 44
                                        radius: Tokens.rounding.medium
                                        readonly property bool isSelected: AppController.placesIconSize === sizeCard.modelData.size
                                        color: isSelected
                                            ? Colours.palette.m3primaryContainer
                                            : (sizeHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer)

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6

                                            MaterialIcon {
                                                text: sizeCard.modelData.icon
                                                color: sizeCard.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                                                fontStyle: Tokens.font.icon.small
                                            }

                                            StyledText {
                                                text: sizeCard.modelData.label
                                                color: sizeCard.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                                font: Tokens.font.body.small
                                                elide: Text.ElideRight
                                            }
                                        }

                                        MouseArea {
                                            id: sizeHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: AppController.placesIconSize = sizeCard.modelData.size
                                        }
                                    }
                                }
                            }

                            Item { implicitHeight: 4 }

                            StyledText {
                                text: qsTr("Sorting & Organization")
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.large
                            }

                            // Sort By Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                Repeater {
                                    model: [
                                        { field: 0, label: qsTr("Name") },
                                        { field: 1, label: qsTr("Size") },
                                        { field: 2, label: qsTr("Date") },
                                        { field: 3, label: qsTr("Type") }
                                    ]

                                    StyledRect {
                                        id: sortCard
                                        required property int index
                                        required property var modelData

                                        Layout.fillWidth: true
                                        implicitHeight: 38
                                        radius: Tokens.rounding.medium
                                        readonly property bool isSelected: AppController.defaultSortField === sortCard.modelData.field
                                        color: isSelected
                                            ? Colours.palette.m3primaryContainer
                                            : (sortHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer)

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: sortCard.modelData.label
                                            color: sortCard.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                            font: Tokens.font.body.small
                                            elide: Text.ElideRight
                                        }

                                        MouseArea {
                                            id: sortHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: AppController.defaultSortField = sortCard.modelData.field
                                        }
                                    }
                                }
                            }

                            // Sort Order & Folders First
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.small

                                // Ascending / Descending
                                StyledRect {
                                    Layout.fillWidth: true
                                    implicitHeight: 44
                                    radius: Tokens.rounding.medium
                                    color: orderHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 8

                                        MaterialIcon {
                                            text: AppController.defaultSortOrder === 0 ? "arrow_upward" : "arrow_downward"
                                            color: Colours.palette.m3primary
                                            fontStyle: Tokens.font.icon.small
                                        }

                                        StyledText {
                                            text: AppController.defaultSortOrder === 0 ? qsTr("Order: Ascending") : qsTr("Order: Descending")
                                            color: Colours.palette.m3onSurface
                                            font: Tokens.font.body.small
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: orderHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: AppController.defaultSortOrder = (AppController.defaultSortOrder === 0 ? 1 : 0)
                                    }
                                }

                                // Show Folders First
                                StyledRect {
                                    Layout.fillWidth: true
                                    implicitHeight: 44
                                    radius: Tokens.rounding.medium
                                    color: dirsHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 8

                                        MaterialIcon {
                                            text: "folder"
                                            color: AppController.showDirsFirst ? Colours.palette.m3primary : Colours.palette.m3outline
                                            fontStyle: Tokens.font.icon.small
                                        }

                                        StyledText {
                                            text: qsTr("Folders First: ") + (AppController.showDirsFirst ? qsTr("Yes") : qsTr("No"))
                                            color: Colours.palette.m3onSurface
                                            font: Tokens.font.body.small
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: dirsHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: AppController.showDirsFirst = !AppController.showDirsFirst
                                    }
                                }
                            }

                            Item { implicitHeight: Tokens.padding.small }
                        }
                    }

                    // --- TAB 2: Custom Scripts & Tools ---
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
                            StyledRect {
                                Layout.fillWidth: true
                                implicitHeight: 70
                                radius: Tokens.rounding.large
                                color: scriptHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Tokens.padding.medium
                                    spacing: Tokens.spacing.medium

                                    MaterialIcon {
                                        text: "folder_special"
                                        color: Colours.palette.m3primary
                                        fontStyle: Tokens.font.icon.large
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: qsTr("Open Scripts Folder")
                                            color: Colours.palette.m3onSurface
                                            font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: qsTr("~/.local/share/prism/scripts/ (Also supports Nautilus scripts)")
                                            color: Colours.palette.m3onSurfaceVariant
                                            font: Tokens.font.label.small
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MaterialIcon {
                                        text: "open_in_new"
                                        color: Colours.palette.m3onSurfaceVariant
                                        fontStyle: Tokens.font.icon.small
                                    }
                                }

                                MouseArea {
                                    id: scriptHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        AppIntegration.openScriptsFolder();
                                    }
                                }
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
                StyledRect {
                    implicitWidth: 90
                    implicitHeight: 38
                    radius: Tokens.rounding.full
                    color: cancelHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Cancel")
                        color: Colours.palette.m3primary
                        font: Tokens.font.label.large
                    }

                    MouseArea {
                        id: cancelHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.expanded = false
                    }

                    StyledToolTip {
                        text: qsTr("Cancel")
                        visible: cancelHover.containsMouse
                    }
                }

                // Done Button
                StyledRect {
                    implicitWidth: 96
                    implicitHeight: 38
                    radius: Tokens.rounding.full
                    color: doneHover.containsMouse ? Colours.palette.m3primaryContainer : Colours.palette.m3primary

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Done")
                        color: doneHover.containsMouse ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onPrimary
                        font: Tokens.font.label.large
                    }

                    MouseArea {
                        id: doneHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.expanded = false
                    }

                    StyledToolTip {
                        text: qsTr("Done")
                        visible: doneHover.containsMouse
                    }
                }
            }
        }
    }
}
