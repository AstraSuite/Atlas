import QtQuick
import QtQuick.Layouts
import "../"
import prism

MouseArea {
    id: root

    property bool expanded: false
    property string targetPath: ""

    anchors.fill: parent
    visible: opacity > 0.001
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    z: 100

    opacity: expanded ? 1.0 : 0.0
    Behavior on opacity {
        Anim {
            type: Anim.FastEffects
        }
    }

    onClicked: root.expanded = false

    Keys.onEscapePressed: root.expanded = false

    FileMetadata {
        id: meta
        path: root.targetPath
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.4)
    }

    StyledRect {
        id: modalCard

        anchors.centerIn: parent
        implicitWidth: 420
        implicitHeight: modalCol.implicitHeight + Tokens.padding.large * 2

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
        }

        ColumnLayout {
            id: modalCol

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            // Header (no top close button)
            RowLayout {
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: meta.isDir ? "folder" : "description"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Properties")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.medium
                }
            }

            // Name & Icon preview
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                CachingIconImage {
                    implicitSize: 48
                    source: FileUtils.iconForFile(meta.name, meta.isDir, meta.mimeType)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: meta.name
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.title.small
                        wrapMode: Text.WrapAnywhere
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: meta.path
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.small
                        elide: Text.ElideMiddle
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: meta.isSymLink
                        text: `↳ ${meta.symLinkTarget}`
                        color: Colours.palette.m3primary
                        font: Tokens.font.mono.small
                        elide: Text.ElideMiddle
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Colours.palette.m3outlineVariant
            }

            // Metadata rows
            Repeater {
                model: [
                    { label: qsTr("Type:"), value: meta.mimeDescription.length > 0 ? meta.mimeDescription : (meta.isDir ? "Folder" : "File") },
                    { label: qsTr("Size:"), value: meta.isDir ? `${meta.itemCount} items` : meta.formattedSize },
                    { label: qsTr("Dimensions:"), value: meta.imageDimensions, visible: meta.isImage && meta.imageDimensions.length > 0 },
                    { label: qsTr("Modified:"), value: meta.formattedModified },
                    { label: qsTr("Created:"), value: meta.formattedCreated },
                    { label: qsTr("Accessed:"), value: meta.formattedAccessed },
                    { label: qsTr("Permissions:"), value: meta.permissions },
                    { label: qsTr("Owner:"), value: `${meta.owner} : ${meta.group}` }
                ]

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium
                    visible: modelData.visible !== false && Boolean(modelData.value && String(modelData.value).length > 0)

                    StyledText {
                        Layout.preferredWidth: 100
                        text: modelData.label || ""
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.value ? String(modelData.value) : ""
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }
                }
            }

            // Bottom OK / Close Button
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }

                StyledRect {
                    implicitWidth: 80
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3primary

                    StateLayer {
                        color: Colours.palette.m3onPrimary
                        onClicked: root.expanded = false
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("OK")
                        color: Colours.palette.m3onPrimary
                        font: Tokens.font.label.large
                    }
                }
            }
        }
    }
}
