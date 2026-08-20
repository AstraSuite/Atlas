import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import prism

StyledRect {
    id: root

    property string targetPath: ""
    property bool expanded: false
    property int panelWidth: 260
    signal previewClicked(string path)

    implicitWidth: expanded ? panelWidth : 0
    visible: width > 0
    clip: true
    color: Colours.tPalette.m3surfaceContainer

    Behavior on implicitWidth {
        Anim {
            type: Anim.SlowEffects
            easing: Tokens.anim.standard
        }
    }

    FileMetadata {
        id: meta
        path: root.targetPath
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        contentHeight: previewCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: StyledScrollBar {
            flickable: parent
        }

        ColumnLayout {
            id: previewCol

            width: parent.width
            spacing: Tokens.spacing.medium

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "info"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Information")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.medium
                }
            }

            // Image / Video / Icon Preview
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 180
                radius: Tokens.rounding.medium
                color: previewCardHover.containsMouse ? Colours.palette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainerHigh
                clip: true

                // Image Preview
                Image {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.small
                    fillMode: Image.PreserveAspectFit
                    source: meta.isImage ? Qt.resolvedUrl("file://" + meta.path) : ""
                    visible: meta.isImage
                    asynchronous: true
                }

                // Video Thumbnail or Generic Icon Preview
                CachingIconImage {
                    anchors.centerIn: parent
                    implicitSize: 72
                    visible: !meta.isImage
                    source: meta.isVideo ? "image://thumb/" + meta.path : FileUtils.iconForFile(meta.name, meta.isDir, meta.mimeType)
                }

                // Video Badge Overlay
                StyledRect {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: Tokens.padding.small
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: Tokens.rounding.full
                    color: Qt.alpha(Colours.palette.m3surface, 0.8)
                    visible: meta.isVideo

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "play_arrow"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.small
                    }
                }

                MouseArea {
                    id: previewCardHover
                    anchors.fill: parent
                    hoverEnabled: meta.isImage || meta.isVideo
                    enabled: meta.isImage || meta.isVideo
                    cursorShape: (meta.isImage || meta.isVideo) ? Qt.PointingHandCursor : undefined
                    onClicked: root.previewClicked(meta.path)
                }
            }

            // Name and path
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    text: meta.name.length > 0 ? meta.name : qsTr("No Selection")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.small
                    wrapMode: Text.WrapAnywhere
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: meta.path.length > 0
                    text: meta.path
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.small
                    elide: Text.ElideMiddle
                }

                // Symlink target if applicable
                StyledText {
                    Layout.fillWidth: true
                    visible: meta.isSymLink
                    text: `↳ ${meta.symLinkTarget}`
                    color: Colours.palette.m3primary
                    font: Tokens.font.mono.small
                    elide: Text.ElideMiddle
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Colours.palette.m3outlineVariant
                visible: meta.name.length > 0
            }

            // Key-Value Metadata List
            Repeater {
                model: [
                    { label: qsTr("Size:"), value: meta.isDir ? `${meta.itemCount} items` : meta.formattedSize },
                    { label: qsTr("Type:"), value: meta.mimeDescription.length > 0 ? meta.mimeDescription : (meta.isDir ? "Folder" : "File") },
                    { label: qsTr("Dimensions:"), value: meta.imageDimensions, visible: meta.isImage && meta.imageDimensions.length > 0 },
                    { label: qsTr("Modified:"), value: meta.formattedModified },
                    { label: qsTr("Created:"), value: meta.formattedCreated },
                    { label: qsTr("Accessed:"), value: meta.formattedAccessed },
                    { label: qsTr("Permissions:"), value: meta.permissions },
                    { label: qsTr("Owner:"), value: `${meta.owner} : ${meta.group}` }
                ]

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: modelData.visible !== false && modelData.value && String(modelData.value).length > 0

                    StyledText {
                        text: modelData.label || ""
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.medium
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.value ? String(modelData.value) : ""
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.body.small
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }
    }
}
