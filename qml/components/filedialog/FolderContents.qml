import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import atlas
import "../"
import "../containers"

Item {
    id: root

    required property var dialog
    readonly property var currentItem: view.currentItem
    readonly property real zoomSize: root.dialog.zoomLevel
    property var selectedPaths: []

    FileSystemModel {
        id: fsModel
        path: root.dialog.currentPath
        showHidden: root.dialog.showHidden
        caseSensitiveSort: AppController.caseSensitiveSort
        showDirsFirst: AppController.showDirsFirst
        onPathChanged: {
            view.currentIndex = -1;
            root.selectedPaths = [];
        }
    }

    StyledRect {
        anchors.fill: parent
        color: Colours.tPalette.m3surfaceContainer

        layer.enabled: true
        layer.effect: Mask {
            maskSource: mask
            maskInverted: true
        }
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall
            radius: Tokens.rounding.medium
        }
    }

    Loader {
        anchors.centerIn: parent

        opacity: view.count === 0 ? 1 : 0
        active: opacity > 0

        sourceComponent: ColumnLayout {
            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "scan_delete"
                color: Colours.palette.m3outline
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.Medium).build()
            }

            StyledText {
                text: qsTr("This folder is empty")
                color: Colours.palette.m3outline
                font: Tokens.font.body.builders.large.weight(Font.Medium).build()
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: viewLoader
        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall + Tokens.padding.medium

        sourceComponent: root.dialog.viewMode === 1 ? detailsViewComp : (root.dialog.viewMode === 2 ? compactViewComp : gridViewComp)
    }

    Component {
        id: gridViewComp
        VerticalFadeGridView {
            id: gridView

            cellWidth: Math.max(144, root.zoomSize + 48)
            cellHeight: root.zoomSize + 84

            clip: true
            focus: true
            currentIndex: -1
            interactive: true
            boundsBehavior: Flickable.DragAndOvershootBounds
            maximumFlickVelocity: 5000
            flickDeceleration: 5000

            WheelHandler {
                target: null
                acceptedModifiers: Qt.ControlModifier
                onWheel: event => {
                    if (event.angleDelta.y > 0) {
                        root.dialog.zoomLevel = Math.min(180, root.dialog.zoomLevel + 16);
                    } else if (event.angleDelta.y < 0) {
                        root.dialog.zoomLevel = Math.max(48, root.dialog.zoomLevel - 16);
                    }
                    event.accepted = true;
                }
            }

            Keys.onEscapePressed: currentIndex = -1

            Keys.onReturnPressed: root.triggerAcceptOrOpen()
            Keys.onEnterPressed: root.triggerAcceptOrOpen()

            Keys.onPressed: event => {
                if (event.matches(StandardKey.ZoomIn) || (event.modifiers === Qt.ControlModifier && (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal))) {
                    root.dialog.zoomLevel = Math.min(180, root.dialog.zoomLevel + 16);
                    event.accepted = true;
                    return;
                } else if (event.matches(StandardKey.ZoomOut) || (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_Minus)) {
                    root.dialog.zoomLevel = Math.max(48, root.dialog.zoomLevel - 16);
                    event.accepted = true;
                    return;
                } else if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_0) {
                    root.dialog.zoomLevel = 80;
                    event.accepted = true;
                    return;
                }

                if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                    if (gridView.currentIndex <= 0 && fsModel.count > 0) {
                        gridView.currentIndex = 0;
                    } else {
                        gridView.moveCurrentIndexLeft();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                    if (gridView.currentIndex === -1 && fsModel.count > 0) {
                        gridView.currentIndex = 0;
                    } else {
                        gridView.moveCurrentIndexRight();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    if (gridView.currentIndex === -1 && fsModel.count > 0) {
                        gridView.currentIndex = 0;
                    } else {
                        gridView.moveCurrentIndexUp();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    if (gridView.currentIndex === -1 && fsModel.count > 0) {
                        gridView.currentIndex = 0;
                    } else {
                        gridView.moveCurrentIndexDown();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Backspace) {
                    if (root.dialog.cwd.length > 1) {
                        root.dialog.cwd = root.dialog.cwd.slice(0, root.dialog.cwd.length - 1);
                        event.accepted = true;
                    }
                }
            }

            ScrollBar.vertical: StyledScrollBar {
                flickable: gridView
            }

            model: fsModel

            delegate: Item {
                id: delegateContainer

                required property int index
                required property var modelData

                width: gridView.cellWidth
                height: gridView.cellHeight

                readonly property bool isSelected: gridView.currentIndex === index || root.selectedPaths.indexOf(delegateContainer.modelData ? delegateContainer.modelData.path : "") !== -1
                readonly property bool isHidden: delegateContainer.modelData ? (delegateContainer.modelData.isHidden || delegateContainer.modelData.name.startsWith('.')) : false

                StyledRect {
                    id: itemCard
                    anchors.centerIn: parent
                    width: parent.width - 8
                    height: parent.height - 8

                    radius: Tokens.rounding.large
                    color: delegateContainer.isSelected
                        ? Colours.palette.m3secondaryContainer
                        : (itemHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : Qt.alpha(Colours.tPalette.m3surfaceContainerHigh, 0))

                    clip: true
                    opacity: delegateContainer.isHidden ? 0.58 : 1.0

                    Behavior on opacity {
                        Anim { type: Anim.FastEffects }
                    }

                    Component.onCompleted: popInAnim.start()

                    Behavior on scale {
                        enabled: !popInAnim.running && !modifiedBounceAnim.running
                        Anim { type: Anim.FastEffects }
                    }

                    ParallelAnimation {
                        id: popInAnim
                        NumberAnimation {
                            target: itemCard
                            property: "scale"
                            from: 0.6
                            to: 1.0
                            duration: 250
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.3
                        }
                    }

                    Connections {
                        target: fsModel
                        function onFileModified(modifiedPath) {
                            if (delegateContainer.modelData && delegateContainer.modelData.path === modifiedPath) {
                                modifiedBounceAnim.restart();
                            }
                        }
                    }

                    SequentialAnimation {
                        id: modifiedBounceAnim
                        NumberAnimation {
                            target: itemCard
                            property: "scale"
                            to: 1.14
                            duration: 130
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: itemCard
                            property: "scale"
                            to: 1.0
                            duration: 220
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.4
                        }
                    }

                    MouseArea {
                        id: itemHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onClicked: mouse => {
                            gridView.currentIndex = delegateContainer.index;
                            if (root.dialog.multiple && (mouse.modifiers & Qt.ControlModifier) && !delegateContainer.modelData.isDir) {
                                let path = delegateContainer.modelData.path;
                                let idx = root.selectedPaths.indexOf(path);
                                let arr = root.selectedPaths.slice();
                                if (idx === -1)
                                    arr.push(path);
                                else
                                    arr.splice(idx, 1);
                                root.selectedPaths = arr;
                                return;
                            }
                            if (root.selectedPaths.length > 0 && !AppController.singleClick)
                                root.selectedPaths = [];
                            if (AppController.singleClick && mouse.button === Qt.LeftButton) {
                                root.handleItemClick(delegateContainer.modelData);
                            }
                        }

                        onDoubleClicked: mouse => {
                            if (mouse.button === Qt.LeftButton && !AppController.singleClick) {
                                root.handleItemClick(delegateContainer.modelData);
                            }
                        }
                    }

                    Item {
                        id: iconContainer
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        width: root.zoomSize
                        height: root.zoomSize

                        CachingIconImage {
                            id: icon
                            anchors.fill: parent
                            implicitSize: root.zoomSize

                            source: {
                                const file = delegateContainer.modelData;
                                if (!file) return "";
                                if (file.hasThumbnail) {
                                    let t = file.lastModified ? file.lastModified.getTime() : file.size;
                                    return "image://thumb/" + file.path + "?t=" + t;
                                } else {
                                    return FileUtils.iconForFile(file.name, file.isDir, file.mimeType);
                                }
                            }
                        }

                        StyledRect {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: Tokens.rounding.full
                            color: Qt.alpha(Colours.palette.m3surface, 0.9)
                            visible: delegateContainer.modelData ? delegateContainer.modelData.isReadOnly : false
                            z: 5

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "lock"
                                fontStyle: Tokens.font.icon.small
                                color: Colours.palette.m3error
                            }
                        }

                        StyledRect {
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: Tokens.rounding.full
                            color: Qt.alpha(Colours.palette.m3surface, 0.9)
                            visible: delegateContainer.modelData ? delegateContainer.modelData.isSymLink : false
                            z: 5

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "link"
                                fontStyle: Tokens.font.icon.small
                                color: Colours.palette.m3primary
                            }
                        }
                    }

                    StyledText {
                        id: name

                        anchors.top: iconContainer.bottom
                        anchors.topMargin: 4
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 4

                        text: delegateContainer.modelData ? delegateContainer.modelData.name : ""
                        color: delegateContainer.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        font: Tokens.font.body.small
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignTop
                        elide: Text.ElideMiddle
                        maximumLineCount: 4
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }

    Component {
        id: detailsViewComp
        VerticalFadeListView {
            id: detailsList

            clip: true
            focus: true
            currentIndex: -1
            interactive: true
            boundsBehavior: Flickable.DragAndOvershootBounds
            maximumFlickVelocity: 5000
            flickDeceleration: 5000
            spacing: 1

            Keys.onEscapePressed: currentIndex = -1
            Keys.onReturnPressed: root.triggerAcceptOrOpen()
            Keys.onEnterPressed: root.triggerAcceptOrOpen()

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                    if (detailsList.currentIndex <= 0 && fsModel.count > 0) {
                        detailsList.currentIndex = 0;
                    } else {
                        detailsList.moveCurrentIndexUp();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                    if (detailsList.currentIndex === -1 && fsModel.count > 0) {
                        detailsList.currentIndex = 0;
                    } else {
                        detailsList.moveCurrentIndexDown();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    if (detailsList.currentIndex === -1 && fsModel.count > 0) {
                        detailsList.currentIndex = 0;
                    } else {
                        detailsList.moveCurrentIndexUp();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    if (detailsList.currentIndex === -1 && fsModel.count > 0) {
                        detailsList.currentIndex = 0;
                    } else {
                        detailsList.moveCurrentIndexDown();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Backspace) {
                    if (root.dialog.cwd.length > 1) {
                        root.dialog.cwd = root.dialog.cwd.slice(0, root.dialog.cwd.length - 1);
                        event.accepted = true;
                    }
                }
            }

            ScrollBar.vertical: StyledScrollBar {
                flickable: detailsList
            }

            model: fsModel

            delegate: Item {
                id: detailDelegate

                required property int index
                required property var modelData

                width: detailsList.width
                height: 36

                readonly property bool isSelected: detailsList.currentIndex === index || root.selectedPaths.indexOf(detailDelegate.modelData ? detailDelegate.modelData.path : "") !== -1
                readonly property bool isHidden: detailDelegate.modelData ? (detailDelegate.modelData.isHidden || detailDelegate.modelData.name.startsWith('.')) : false

                StyledRect {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Tokens.rounding.small
                    color: detailDelegate.isSelected
                        ? Colours.palette.m3secondaryContainer
                        : (detailHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : Qt.alpha(Colours.tPalette.m3surfaceContainerHigh, 0))

                    opacity: detailDelegate.isHidden ? 0.58 : 1.0

                    MouseArea {
                        id: detailHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onClicked: mouse => {
                            detailsList.currentIndex = detailDelegate.index;
                            if (root.dialog.multiple && (mouse.modifiers & Qt.ControlModifier) && !detailDelegate.modelData.isDir) {
                                let path = detailDelegate.modelData.path;
                                let idx = root.selectedPaths.indexOf(path);
                                let arr = root.selectedPaths.slice();
                                if (idx === -1)
                                    arr.push(path);
                                else
                                    arr.splice(idx, 1);
                                root.selectedPaths = arr;
                                return;
                            }
                            if (root.selectedPaths.length > 0 && !AppController.singleClick)
                                root.selectedPaths = [];
                            if (AppController.singleClick && mouse.button === Qt.LeftButton) {
                                root.handleItemClick(detailDelegate.modelData);
                            }
                        }

                        onDoubleClicked: mouse => {
                            if (mouse.button === Qt.LeftButton && !AppController.singleClick) {
                                root.handleItemClick(detailDelegate.modelData);
                            }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.small
                        anchors.rightMargin: Tokens.padding.small
                        spacing: Tokens.padding.small

                        CachingIconImage {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 20
                            implicitHeight: 20
                            source: {
                                const file = detailDelegate.modelData;
                                if (!file) return "";
                                if (file.hasThumbnail) {
                                    let t = file.lastModified ? file.lastModified.getTime() : file.size;
                                    return "image://thumb/" + file.path + "?t=" + t;
                                } else {
                                    return FileUtils.iconForFile(file.name, file.isDir, file.mimeType);
                                }
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: detailDelegate.modelData ? detailDelegate.modelData.name : ""
                            color: detailDelegate.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            font: Tokens.font.body.medium
                            elide: Text.ElideMiddle
                        }

                        StyledText {
                            Layout.preferredWidth: 80
                            text: detailDelegate.modelData ? (detailDelegate.modelData.isDir ? qsTr("Folder") : formatSize(detailDelegate.modelData.size)) : ""
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.preferredWidth: 100
                            text: detailDelegate.modelData && detailDelegate.modelData.lastModified ? Qt.formatDateTime(detailDelegate.modelData.lastModified, "yyyy-MM-dd hh:mm") : ""
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
                        }
                    }
                }

                function formatSize(bytes) {
                    if (bytes === undefined || bytes === null) return "";
                    if (bytes < 1024) return bytes + " B";
                    if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB";
                    if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + " MB";
                    return (bytes / 1073741824).toFixed(1) + " GB";
                }
            }
        }
    }

    Component {
        id: compactViewComp
        VerticalFadeListView {
            id: compactList

            clip: true
            focus: true
            currentIndex: -1
            interactive: true
            boundsBehavior: Flickable.DragAndOvershootBounds
            maximumFlickVelocity: 5000
            flickDeceleration: 5000
            spacing: 0

            Keys.onEscapePressed: currentIndex = -1
            Keys.onReturnPressed: root.triggerAcceptOrOpen()
            Keys.onEnterPressed: root.triggerAcceptOrOpen()

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                    if (compactList.currentIndex <= 0 && fsModel.count > 0) {
                        compactList.currentIndex = 0;
                    } else {
                        compactList.moveCurrentIndexUp();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                    if (compactList.currentIndex === -1 && fsModel.count > 0) {
                        compactList.currentIndex = 0;
                    } else {
                        compactList.moveCurrentIndexDown();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    if (compactList.currentIndex === -1 && fsModel.count > 0) {
                        compactList.currentIndex = 0;
                    } else {
                        compactList.moveCurrentIndexUp();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    if (compactList.currentIndex === -1 && fsModel.count > 0) {
                        compactList.currentIndex = 0;
                    } else {
                        compactList.moveCurrentIndexDown();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Backspace) {
                    if (root.dialog.cwd.length > 1) {
                        root.dialog.cwd = root.dialog.cwd.slice(0, root.dialog.cwd.length - 1);
                        event.accepted = true;
                    }
                }
            }

            ScrollBar.vertical: StyledScrollBar {
                flickable: compactList
            }

            model: fsModel

            delegate: Item {
                id: compactDelegate

                required property int index
                required property var modelData

                width: compactList.width
                height: 28

                readonly property bool isSelected: compactList.currentIndex === index || root.selectedPaths.indexOf(compactDelegate.modelData ? compactDelegate.modelData.path : "") !== -1
                readonly property bool isHidden: compactDelegate.modelData ? (compactDelegate.modelData.isHidden || compactDelegate.modelData.name.startsWith('.')) : false

                StyledRect {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: Tokens.rounding.small
                    color: compactDelegate.isSelected
                        ? Colours.palette.m3secondaryContainer
                        : (compactHover.containsMouse ? Colours.tPalette.m3surfaceContainerHigh : Qt.alpha(Colours.tPalette.m3surfaceContainerHigh, 0))

                    opacity: compactDelegate.isHidden ? 0.58 : 1.0

                    MouseArea {
                        id: compactHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onClicked: mouse => {
                            compactList.currentIndex = compactDelegate.index;
                            if (root.dialog.multiple && (mouse.modifiers & Qt.ControlModifier) && !compactDelegate.modelData.isDir) {
                                let path = compactDelegate.modelData.path;
                                let idx = root.selectedPaths.indexOf(path);
                                let arr = root.selectedPaths.slice();
                                if (idx === -1)
                                    arr.push(path);
                                else
                                    arr.splice(idx, 1);
                                root.selectedPaths = arr;
                                return;
                            }
                            if (root.selectedPaths.length > 0 && !AppController.singleClick)
                                root.selectedPaths = [];
                            if (AppController.singleClick && mouse.button === Qt.LeftButton) {
                                root.handleItemClick(compactDelegate.modelData);
                            }
                        }

                        onDoubleClicked: mouse => {
                            if (mouse.button === Qt.LeftButton && !AppController.singleClick) {
                                root.handleItemClick(compactDelegate.modelData);
                            }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.small
                        anchors.rightMargin: Tokens.padding.small
                        spacing: Tokens.padding.small

                        CachingIconImage {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 16
                            implicitHeight: 16
                            source: {
                                const file = compactDelegate.modelData;
                                if (!file) return "";
                                return FileUtils.iconForFile(file.name, file.isDir, file.mimeType);
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: compactDelegate.modelData ? compactDelegate.modelData.name : ""
                            color: compactDelegate.isSelected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                            font: Tokens.font.body.small
                            elide: Text.ElideMiddle
                        }
                    }
                }
            }
        }
    }

    function focusView() {
        view.forceActiveFocus();
        if (view.currentIndex === -1 && fsModel.count > 0)
            view.currentIndex = 0;
    }

    function handleItemClick(file) {
        if (!file) return;
        if (file.isDir) {
            let newCwd = root.dialog.cwd.slice();
            newCwd.push(file.name);
            root.dialog.cwd = newCwd;
        } else if (root.dialog.saveMode) {
            root.dialog.saveName = file.name;
        } else if (root.dialog.selectionValid && !root.dialog.directoryOnly) {
            root.dialog.accepted(file.path);
        }
    }

    function triggerAcceptOrOpen() {
        if (root.dialog.multiple && root.selectedPaths.length > 0) {
            root.dialog.acceptedMultiple(root.selectedPaths);
            return;
        }

        if (currentItem && currentItem.modelData) {
            if (currentItem.modelData.isDir) {
                if (root.dialog.directoryOnly) {
                    root.dialog.accepted(currentItem.modelData.path);
                } else {
                    let newCwd = root.dialog.cwd.slice();
                    newCwd.push(currentItem.modelData.name);
                    root.dialog.cwd = newCwd;
                }
                return;
            }
        }

        if (root.dialog.selectionValid) {
            if (root.dialog.directoryOnly) {
                if (currentItem && currentItem.modelData && currentItem.modelData.isDir) {
                    root.dialog.accepted(currentItem.modelData.path);
                } else {
                    root.dialog.accepted(root.dialog.currentPath);
                }
            } else if (currentItem && currentItem.modelData) {
                root.dialog.accepted(currentItem.modelData.path);
            }
        }
    }

    CurrentItem {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.extraSmall

        currentItem: view.currentItem
    }
}
