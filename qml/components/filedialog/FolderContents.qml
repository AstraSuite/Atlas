import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import prism
import "../"

Item {
    id: root

    required property var dialog
    readonly property var currentItem: view.currentItem

    Sizes {
        id: sizes
    }

    FileSystemModel {
        id: fsModel
        path: {
            if (root.dialog.cwd.length === 0)
                return FileUtils.home;
            if (root.dialog.cwd[0] === "Home") {
                if (root.dialog.cwd.length === 1)
                    return FileUtils.home;
                return FileUtils.home + "/" + root.dialog.cwd.slice(1).join("/");
            } else if (root.dialog.cwd[0] === "") {
                return "/" + root.dialog.cwd.slice(1).join("/");
            } else {
                return root.dialog.cwd.join("/");
            }
        }
        showHidden: root.dialog.showHidden
        onPathChanged: view.currentIndex = -1
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

    GridView {
        id: view

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall + Tokens.padding.medium

        cellWidth: sizes.itemWidth + Tokens.spacing.small
        cellHeight: sizes.itemWidth + Tokens.spacing.large + Tokens.padding.medium * 2 + 1

        clip: true
        focus: true
        currentIndex: -1
        Keys.onEscapePressed: currentIndex = -1

        Keys.onReturnPressed: {
            if (root.dialog.selectionValid && currentItem)
                root.dialog.accepted(currentItem.modelData.path);
        }
        Keys.onEnterPressed: {
            if (root.dialog.selectionValid && currentItem)
                root.dialog.accepted(currentItem.modelData.path);
        }

        ScrollBar.vertical: StyledScrollBar {
            flickable: view
        }

        model: fsModel

        delegate: StyledRect {
            id: item

            required property int index
            required property var modelData

            readonly property real nonAnimHeight: icon.implicitHeight + name.anchors.topMargin + name.implicitHeight + Tokens.padding.medium * 2

            implicitWidth: sizes.itemWidth
            implicitHeight: nonAnimHeight

            radius: Tokens.rounding.large
            color: Qt.alpha(Colours.tPalette.m3surfaceContainerHighest, GridView.isCurrentItem ? Colours.tPalette.m3surfaceContainerHighest.a : 0)
            z: GridView.isCurrentItem || implicitHeight !== nonAnimHeight ? 1 : 0
            clip: true

            StateLayer {
                onClicked: view.currentIndex = item.index
                onDoubleClicked: {
                    if (item.modelData.isDir) {
                        let newCwd = root.dialog.cwd.slice();
                        newCwd.push(item.modelData.name);
                        root.dialog.cwd = newCwd;
                    } else if (root.dialog.selectionValid) {
                        root.dialog.accepted(item.modelData.path);
                    }
                }
            }

            CachingIconImage {
                id: icon

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Tokens.padding.medium

                implicitSize: sizes.itemWidth - Tokens.padding.medium * 2

                source: {
                    const file = item.modelData;
                    if (!file) return "";
                    if (file.isImage) {
                        let t = file.lastModified ? file.lastModified.getTime() : file.size;
                        return "image://thumb/" + file.path + "?t=" + t;
                    } else {
                        return FileUtils.iconForFile(file.name, file.isDir, file.mimeType);
                    }
                }
            }

            StyledText {
                id: name

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: icon.bottom
                anchors.topMargin: Tokens.spacing.small
                anchors.margins: Tokens.padding.medium

                horizontalAlignment: Text.AlignHCenter
                elide: item.GridView.isCurrentItem ? Text.ElideNone : Text.ElideRight
                wrapMode: item.GridView.isCurrentItem ? Text.WrapAtWordBoundaryOrAnywhere : Text.NoWrap

                text: item.modelData ? item.modelData.name : ""
            }

            Behavior on implicitHeight {
                Anim {}
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
