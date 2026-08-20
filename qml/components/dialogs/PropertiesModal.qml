import QtQuick
import QtQuick.Layouts
import "../"
import prism

MouseArea {
    id: root

    property bool expanded: false
    property string targetPath: ""

    anchors.fill: parent
    visible: expanded
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined
    z: 100

    onClicked: root.expanded = false

    Keys.onEscapePressed: root.expanded = false

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.palette.m3scrim, 0.4)
    }

    FileMetadata {
        id: meta
        path: root.targetPath
    }

    StyledRect {
        id: propCard

        anchors.centerIn: parent
        implicitWidth: 420
        implicitHeight: propCol.implicitHeight + Tokens.padding.large * 2

        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainerHigh

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: propCol

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            // Header
            RowLayout {
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: meta.isDir ? "folder" : "info"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Properties")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.medium
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
                        onClicked: root.expanded = false
                    }
                }
            }

            // File Icon & Name Preview
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                CachingIconImage {
                    implicitSize: 48
                    source: {
                        if (meta.isImage) {
                            return Qt.resolvedUrl("file://" + root.targetPath);
                        }
                        return FileUtils.iconForFile(meta.name, meta.isDir, meta.mimeType);
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: meta.name
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.title.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: meta.path
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.small
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

            // Metadata key-value list
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

            // Divider
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Colours.palette.m3outlineVariant
            }

            // Buttons
            RowLayout {
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

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
                        text: qsTr("Close")
                        color: Colours.palette.m3onPrimary
                        font: Tokens.font.label.large
                    }
                }
            }
        }
    }
}
