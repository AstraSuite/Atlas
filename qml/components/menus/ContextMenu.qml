import QtQuick
import QtQuick.Layouts
import "../"
import atlas

MouseArea {
    id: root

    property bool expanded: false
    property real menuX: 0
    property real menuY: 0
    property var targetItem: null
    property string currentDir: ""
    property bool submenuOpen: false
    property real submenuY: 0
    property var sharingServices: []
    property var customActions: []
    property var activeSubmenuItems: []
    property var displaySubmenuItems: []
    property bool shiftHeld: false

    onActiveSubmenuItemsChanged: {
        if (activeSubmenuItems && activeSubmenuItems.length > 0) {
            displaySubmenuItems = activeSubmenuItems;
        }
    }

    readonly property bool isTrash: currentDir.indexOf("Trash") !== -1 || currentDir.indexOf("trash:") !== -1 || (targetItem && targetItem.isTrashItem)
    readonly property bool isRecent: currentDir.startsWith("recent:")
    readonly property bool isArchive: targetItem && (
        targetItem.name.endsWith(".zip") || targetItem.name.endsWith(".tar.gz") ||
        targetItem.name.endsWith(".tar.xz") || targetItem.name.endsWith(".tar.zst") ||
        targetItem.name.endsWith(".tgz") || targetItem.name.endsWith(".7z") || targetItem.name.endsWith(".rar")
    )
    property var convertFormats: []

    signal actionTriggered(string action, var item)

    onExpandedChanged: {
        submenuOpen = false;
        activeSubmenuItems = [];
        if (expanded) {
            shiftHeld = AppController.shiftPressed();
            sharingServices = AppIntegration.getAvailableSharingServices();
            let selPaths = targetItem ? [targetItem.path] : [];
            let isDir = targetItem ? targetItem.isDir : true;
            let mime = targetItem ? (targetItem.mimeType || "") : "inode/directory";
            customActions = AppIntegration.getCustomActions(currentDir, selPaths, isDir, mime);
            convertFormats = (targetItem && !targetItem.isDir && !targetItem.isTrashItem)
                ? MediaTools.formatsFor(targetItem.path)
                : [];
        }
    }

    anchors.fill: parent
    visible: opacity > 0.01
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: {
        expanded = false;
        submenuOpen = false;
    }

    opacity: expanded ? 1 : 0
    Behavior on opacity { Anim { type: Anim.FastEffects } }

    StyledRect {
        id: menuRect

        x: Math.min(Math.max(8, root.menuX), root.width - width - 8)
        y: Math.min(Math.max(8, root.menuY), root.height - height - 8)

        implicitWidth: menuCol.implicitWidth + Tokens.padding.extraSmall * 2
        implicitHeight: menuCol.implicitHeight + Tokens.padding.extraSmall * 2

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerLow

        scale: root.expanded ? 1.0 : 0.94
        Behavior on scale {
            Anim {
                type: Anim.FastEffects
                easing: Tokens.anim.standard
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: menuCol

            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall
            spacing: 0

            Repeater {
                model: {
                    if (root.isTrash) {
                        if (root.targetItem) {
                            return [
                                { text: qsTr("Restore"), icon: "restore_from_trash", action: "restore" },
                                { isSeparator: true },
                                { text: qsTr("Delete Permanently"), icon: "delete_forever", action: "delete" },
                                { text: qsTr("Properties"), icon: "info", action: "properties" }
                            ];
                        } else {
                            return [
                                { text: qsTr("Empty Trash"), icon: "delete_sweep", action: "emptyTrash" },
                                { isSeparator: true },
                                { text: qsTr("Properties"), icon: "info", action: "propertiesDir" }
                            ];
                        }
                    }

                    if (root.targetItem) {
                        let list = [];

                        // 1. Primary Open / Launch actions
                        if (root.targetItem.isDir) {
                            list.push({ text: qsTr("Open"), icon: "folder_open", action: "open" });
                            list.push({ text: qsTr("Open in New Tab"), icon: "tab", action: "openNewTab" });
                            list.push({ text: qsTr("Open in New Window"), icon: "open_in_new", action: "openNewWindow" });
                            list.push({ text: qsTr("Open in Split View"), icon: "splitscreen", action: "openSplit" });
                            if (AppController.menuShowTerminal) {
                                list.push({ text: qsTr("Open in Terminal"), icon: "terminal", action: "openTerminalItem" });
                            }
                        } else {
                            if (root.targetItem.isImage || root.targetItem.isVideo || FileUtils.isImage(root.targetItem.path) || FileUtils.isVideo(root.targetItem.path)) {
                                list.push({ text: qsTr("Preview (Space)"), icon: "visibility", action: "preview" });
                            }
                            list.push({ text: qsTr("Open"), icon: "open_in_new", action: "open" });
                            list.push({ text: qsTr("Open With..."), icon: "open_with", action: "openWith" });
                        }

                        // Secondary Open Actions (e.g. Open with VS Code / VSCodium)
                        if (AppController.menuShowSecondaryEditor && root.customActions && root.customActions.length > 0) {
                            for (let i = 0; i < root.customActions.length; ++i) {
                                let ca = root.customActions[i];
                                list.push({ text: ca.name, icon: ca.icon || "code", themeIcon: ca.themeIcon === true, action: "custom:" + ca.id });
                            }
                        }

                        list.push({ isSeparator: true });

                        // 2. Organization / Clipboard actions
                        list.push({ text: qsTr("Cut"), icon: "content_cut", action: "cut" });
                        list.push({ text: qsTr("Copy"), icon: "content_copy", action: "copy" });
                        list.push({ text: qsTr("Copy Path"), icon: "link", action: "copyPath" });
                        if (FileOperations.canPaste) {
                            list.push({ text: qsTr("Paste"), icon: "content_paste", action: "paste" });
                        }
                        list.push({ text: qsTr("Rename"), icon: "drive_file_rename_outline", action: "rename" });
                        list.push({ text: qsTr("Duplicate"), icon: "control_point_duplicate", action: "duplicate" });

                        let hasSection3 = false;

                        // 3. Sharing, Upload & External Services (Submenus)
                        if (!root.targetItem.isDir && AppController.menuShowUploadOnline) {
                            if (!hasSection3) {
                                list.push({ isSeparator: true });
                                hasSection3 = true;
                            }
                            list.push({
                                text: qsTr("Upload Online"),
                                icon: "cloud_upload",
                                hasSubmenu: true,
                                submenuItems: [
                                    { text: qsTr("Catbox (Permanent)"), icon: "cloud_upload", action: "uploadCatbox" },
                                    { text: qsTr("Litterbox (1 Hour)"), icon: "timer", action: "uploadLitterbox:1h" },
                                    { text: qsTr("Litterbox (12 Hours)"), icon: "timer", action: "uploadLitterbox:12h" },
                                    { text: qsTr("Litterbox (24 Hours)"), icon: "timer", action: "uploadLitterbox:24h" },
                                    { text: qsTr("Litterbox (72 Hours)"), icon: "timer", action: "uploadLitterbox:72h" }
                                ]
                            });
                        }

                        // Send To Submenu (includes Create Symlink and sharing services)
                        if (AppController.menuShowSendTo) {
                            let sendToList = [];
                            if (AppController.menuShowSymlink) {
                                sendToList.push({ text: qsTr("Create Symlink"), icon: "link", action: "symlink" });
                            }
                            if (root.sharingServices && root.sharingServices.length > 0) {
                                if (sendToList.length > 0) sendToList.push({ isSeparator: true });
                                for (let sIdx = 0; sIdx < root.sharingServices.length; ++sIdx) {
                                    let s = root.sharingServices[sIdx];
                                    sendToList.push({
                                        text: s.name || "",
                                        icon: s.icon || "share",
                                        action: "sendTo:" + s.id
                                    });
                                }
                            }
                            if (sendToList.length > 0) {
                                if (!hasSection3) {
                                    list.push({ isSeparator: true });
                                    hasSection3 = true;
                                }
                                list.push({
                                    text: qsTr("Send To"),
                                    icon: "send",
                                    hasSubmenu: true,
                                    submenuItems: sendToList
                                });
                            }
                        }

                        // Compress / Archive Submenu
                        if (AppController.menuShowCompress) {
                            let compressSubmenu = [];
                            if (root.isArchive) {
                                compressSubmenu.push({ text: qsTr("Extract Here"), icon: "unarchive", action: "extractHere" });
                                compressSubmenu.push({ text: qsTr("Extract to Folder"), icon: "folder_zip", action: "extractTo" });
                                compressSubmenu.push({ isSeparator: true });
                            }
                            compressSubmenu.push({ text: qsTr("Compress as .zip"), icon: "folder_zip", action: "quickCompress:zip" });
                            compressSubmenu.push({ text: qsTr("Compress as .tar.gz"), icon: "archive", action: "quickCompress:tar.gz" });
                            compressSubmenu.push({ text: qsTr("Compress as .tar.xz"), icon: "archive", action: "quickCompress:tar.xz" });
                            compressSubmenu.push({ text: qsTr("Compress as .7z"), icon: "archive", action: "quickCompress:7z" });
                            compressSubmenu.push({ isSeparator: true });
                            compressSubmenu.push({ text: qsTr("Custom Options..."), icon: "tune", action: "compress" });

                            if (!hasSection3) {
                                list.push({ isSeparator: true });
                                hasSection3 = true;
                            }
                            list.push({
                                text: root.isArchive ? qsTr("Archive") : qsTr("Compress"),
                                icon: "archive",
                                hasSubmenu: true,
                                submenuItems: compressSubmenu
                            });
                        }

                        // Media Tools Flyout
                        // Trim is video-only; parameterless ops run immediately;
                        // conversion is offered for any file with a target format.
                        if (!root.targetItem.isDir && !root.targetItem.isTrashItem) {
                            let mt = [];
                            const isAudioFile = root.targetItem.isAudio || FileUtils.isAudio(root.targetItem.path);
                            const isVideoFile = root.targetItem.isVideo || FileUtils.isVideo(root.targetItem.path);
                            const isImageFile = root.targetItem.isImage || FileUtils.isImage(root.targetItem.path);

                            // Everything except conversion goes through ffmpeg
                            if (MediaTools.ffmpegAvailable) {
                                if (isVideoFile)
                                    mt.push({ text: qsTr("Trim / Clip..."), icon: "content_cut", action: "mediaClip" });
                                if (!isAudioFile)
                                    mt.push({ text: qsTr("Aspect Ratio..."), icon: "aspect_ratio", action: "mediaAspect" });

                                if (!isAudioFile) {
                                    mt.push({ isSeparator: true });
                                    mt.push({ text: qsTr("Rotate Right"), icon: "rotate_right", action: "mediaRotate:90" });
                                    mt.push({ text: qsTr("Rotate Left"), icon: "rotate_left", action: "mediaRotate:270" });
                                    mt.push({ text: qsTr("Flip Horizontal"), icon: "flip", action: "mediaFlip:h" });
                                    mt.push({ text: qsTr("Flip Vertical"), icon: "flip", action: "mediaFlip:v" });

                                    if (isImageFile) {
                                        mt.push({ isSeparator: true });
                                        mt.push({ text: qsTr("Circle Crop"), icon: "circle", action: "mediaCircle" });
                                    }
                                }
                            }

                            const srcExt = (root.targetItem.suffix || "").toLowerCase();
                            const formats = root.convertFormats.filter(f => f !== srcExt);
                            if (formats.length > 0) {
                                mt.push({ isSeparator: true });
                                for (let fi = 0; fi < formats.length; ++fi) {
                                    mt.push({
                                        text: qsTr("Convert to .%1").arg(formats[fi]),
                                        icon: "sync_alt",
                                        action: "mediaConvert:" + formats[fi]
                                    });
                                }
                            }

                            if (mt.some(e => !e.isSeparator)) {
                                list.push({
                                    text: qsTr("Media Tools"),
                                    icon: "movie_edit",
                                    hasSubmenu: true,
                                    submenuItems: mt
                                });
                            }
                        }

                        list.push({ isSeparator: true });

                        // 4. Deletion & Properties
                        if (AppController.menuShowDelete) {
                            if (root.shiftHeld) {
                                list.push({ text: qsTr("Delete Permanently"), icon: "delete_forever", action: "delete" });
                            } else {
                                list.push({ text: qsTr("Move to Trash"), icon: "delete", action: "trash" });
                            }
                        }
                        if (root.isRecent) {
                            list.push({ text: qsTr("Remove From Recent"), icon: "playlist_remove", action: "removeFromRecent" });
                        }
                        list.push({ text: qsTr("Properties"), icon: "info", action: "properties" });

                        return list;
                    } else {
                        let blankList = [
                            { text: qsTr("New Folder"), icon: "create_new_folder", action: "newFolder" },
                            { text: qsTr("New Text File"), icon: "note_add", action: "newFile" }
                        ];

                        const templates = FileUtils.templates();
                        if (templates.length > 0) {
                            blankList.push({
                                text: qsTr("New from Template"),
                                icon: "file_copy",
                                hasSubmenu: true,
                                submenuItems: templates.map(t => ({
                                    text: t.name,
                                    icon: t.icon,
                                    action: "newFromTemplate:" + t.path
                                }))
                            });
                        }

                        if (FileOperations.canPaste) {
                            blankList.push({ text: qsTr("Paste"), icon: "content_paste", action: "paste" });
                            if (AppController.menuShowSymlink) {
                                blankList.push({ text: qsTr("Paste as Symlink"), icon: "link", action: "pasteSymlink" });
                            }
                        }

                        blankList.push({ isSeparator: true });

                        blankList.push({ text: qsTr("Copy Path"), icon: "link", action: "copyCurrentDirPath" });
                        blankList.push({ text: qsTr("Add to Bookmarks"), icon: "bookmark_add", action: "bookmark" });
                        if (AppController.menuShowTerminal) {
                            blankList.push({ text: qsTr("Open in Terminal"), icon: "terminal", action: "openTerminal" });
                        }

                        if (root.customActions && root.customActions.length > 0) {
                            for (let i = 0; i < root.customActions.length; ++i) {
                                let ca = root.customActions[i];
                                blankList.push({ text: ca.name, icon: ca.icon || "play_arrow", action: "custom:" + ca.id });
                            }
                        }

                        blankList.push({ text: qsTr("Open Scripts Folder"), icon: "folder_special", action: "openScriptsFolder" });

                        blankList.push({ isSeparator: true });
                        blankList.push({ text: qsTr("Properties"), icon: "info", action: "propertiesDir" });

                        return blankList;
                    }
                }

                Loader {
                    id: entryLoader
                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    sourceComponent: modelData.isSeparator ? separatorComponent : menuItemComponent
                }
            }
        }
    }

    Component {
        id: separatorComponent
        Item {
            Layout.fillWidth: true
            implicitHeight: 7

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.medium
                height: 1
                color: Colours.tPalette.m3outlineVariant
                opacity: 0.4
            }
        }
    }

    Component {
        id: menuItemComponent
        StyledRect {
            id: menuItem

            Layout.fillWidth: true
            implicitWidth: itemRow.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: 36
            radius: Tokens.rounding.medium
            color: (itemHover.containsMouse || (modelData.hasSubmenu && root.submenuOpen && root.activeSubmenuItems === modelData.submenuItems))
                ? Colours.tPalette.m3surfaceContainerHigh
                : "transparent"

            StateLayer {
                id: itemHover
                hoverEnabled: true
                onContainsMouseChanged: {
                    if (modelData.hasSubmenu) {
                        if (containsMouse) {
                            root.activeSubmenuItems = modelData.submenuItems || [];
                            let pos = menuItem.mapToItem(root, 0, 0);
                            root.submenuY = pos.y;
                            root.submenuOpen = true;
                        }
                    } else if (containsMouse) {
                        root.submenuOpen = false;
                        root.activeSubmenuItems = [];
                    }
                }
                onClicked: {
                    if (modelData.hasSubmenu) {
                        root.activeSubmenuItems = modelData.submenuItems || [];
                        let pos = menuItem.mapToItem(root, 0, 0);
                        root.submenuY = pos.y;
                        root.submenuOpen = !root.submenuOpen;
                    } else {
                        root.expanded = false;
                        root.submenuOpen = false;
                        root.activeSubmenuItems = [];
                        root.actionTriggered(modelData.action, root.targetItem);
                    }
                }
            }

            RowLayout {
                id: itemRow
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.medium
                spacing: Tokens.spacing.small

                MaterialIcon {
                    visible: modelData.themeIcon !== true
                    text: modelData.icon || ""
                    color: modelData.action === "delete" || modelData.action === "emptyTrash" ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.small
                }

                CachingIconImage {
                    visible: modelData.themeIcon === true
                    implicitSize: 18
                    source: visible ? FileUtils.iconForName(modelData.icon, "application-x-executable") : ""
                }

                StyledText {
                    Layout.fillWidth: true
                    text: modelData.text || ""
                    font: Tokens.font.body.medium
                    color: modelData.action === "delete" || modelData.action === "emptyTrash" ? Colours.palette.m3error : Colours.palette.m3onSurface
                }

                MaterialIcon {
                    visible: modelData.hasSubmenu === true
                    text: "chevron_right"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.small
                }
            }
        }
    }

    Component {
        id: subMenuItemComponent
        StyledRect {
            id: subMenuItem

            Layout.fillWidth: true
            implicitWidth: subItemRow.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: 36
            radius: Tokens.rounding.medium
            color: subHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : "transparent"

            StateLayer {
                id: subHover
                hoverEnabled: true
                onClicked: {
                    root.expanded = false;
                    root.submenuOpen = false;
                    root.activeSubmenuItems = [];
                    root.actionTriggered(modelData.action, root.targetItem);
                }
            }

            RowLayout {
                id: subItemRow
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.medium
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: modelData.icon || "share"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    Layout.fillWidth: true
                    text: modelData.text || ""
                    font: Tokens.font.body.medium
                    color: Colours.palette.m3onSurface
                }
            }
        }
    }

    // Dynamic Floating Submenu Popup
    StyledRect {
        id: submenuRect

        visible: opacity > 0.005
        z: menuRect.z + 1

        readonly property bool openOnRight: menuRect.x + menuRect.width + width + 8 < root.width
        x: openOnRight ? (menuRect.x + menuRect.width + 4) : Math.max(8, menuRect.x - width - 4)
        y: Math.min(Math.max(8, root.submenuY - 4), root.height - height - 8)

        implicitWidth: submenuCol.implicitWidth + Tokens.padding.extraSmall * 2
        implicitHeight: submenuCol.implicitHeight + Tokens.padding.extraSmall * 2

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerLow

        transformOrigin: openOnRight ? Item.TopLeft : Item.TopRight
        scale: root.submenuOpen ? 1.0 : 0.94
        opacity: root.submenuOpen ? 1.0 : 0.0

        Behavior on y {
            Anim {
                type: Anim.FastEffects
                easing: Tokens.anim.standard
            }
        }
        Behavior on x {
            Anim {
                type: Anim.FastEffects
                easing: Tokens.anim.standard
            }
        }
        Behavior on implicitWidth {
            Anim {
                type: Anim.FastEffects
                easing: Tokens.anim.standard
            }
        }
        Behavior on implicitHeight {
            Anim {
                type: Anim.FastEffects
                easing: Tokens.anim.standard
            }
        }
        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
                easing: Tokens.anim.standard
            }
        }
        Behavior on scale {
            Anim {
                type: Anim.FastEffects
                easing: Tokens.anim.standard
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: submenuCol

            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall
            spacing: 0

            Repeater {
                model: root.displaySubmenuItems

                Loader {
                    id: subEntryLoader
                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    sourceComponent: modelData.isSeparator ? separatorComponent : subMenuItemComponent
                }
            }
        }
    }
}


