import QtQuick
import QtQuick.Layouts
import "../"
import prism

StyledRect {
    id: root

    property string targetPath: ""
    property bool expanded: false

    signal closeRequested()

    implicitWidth: expanded ? 300 : 0
    visible: width > 0
    clip: true

    color: Colours.tPalette.m3surfaceContainer

    Behavior on implicitWidth {
        Anim {
            type: Anim.Emphasized
            duration: 300
        }
    }

    FileMetadata {
        id: meta
        path: root.targetPath
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        // Header
        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Information")
                font: Tokens.font.title.medium
                color: Colours.palette.m3onSurface
            }

            Item {
                implicitWidth: 28
                implicitHeight: 28

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.full
                    color: Colours.tPalette.m3surfaceContainerHigh

                    StateLayer {
                        onClicked: root.closeRequested()
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "close"
                        fontStyle: Tokens.font.icon.small
                        color: Colours.palette.m3onSurface
                    }
                }
            }
        }

        // Preview Box
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 180
            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainerHigh

            CachingIconImage {
                anchors.centerIn: parent
                implicitSize: 140
                visible: root.targetPath.length > 0

                Component.onCompleted: {
                    if (meta.isDir) {
                        source = FileUtils.iconForFile(meta.name, true, "");
                    } else if (meta.mimeType.startsWith("image/")) {
                        source = Qt.resolvedUrl("file://" + meta.path);
                    } else {
                        source = FileUtils.iconForFile(meta.name, false, meta.mimeType);
                    }
                }

                Connections {
                    target: meta
                    function onMetadataChanged() {
                        if (meta.isDir) {
                            parent.source = FileUtils.iconForFile(meta.name, true, "");
                        } else if (meta.mimeType.startsWith("image/")) {
                            parent.source = Qt.resolvedUrl("file://" + meta.path);
                        } else {
                            parent.source = FileUtils.iconForFile(meta.name, false, meta.mimeType);
                        }
                    }
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: root.targetPath.length === 0
                text: qsTr("No item selected")
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
            }
        }

        // Title / Name
        StyledText {
            Layout.fillWidth: true
            text: meta.name.length > 0 ? meta.name : qsTr("Select a file")
            font: Tokens.font.body.builders.large.weight(Font.Bold).build()
            color: Colours.palette.m3onSurface
            elide: Text.ElideMiddle
        }

        // Details List (Flickable)
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: detailsCol.implicitHeight
            clip: true

            ColumnLayout {
                id: detailsCol
                width: parent.width
                spacing: Tokens.spacing.small

                Repeater {
                    model: [
                        { label: qsTr("Size"), value: meta.formattedSize },
                        { label: qsTr("Type"), value: meta.mimeDescription },
                        { label: qsTr("Dimensions"), value: meta.imageDimensions, visible: meta.imageDimensions.length > 0 },
                        { label: qsTr("Modified"), value: meta.modifiedFormatted },
                        { label: qsTr("Created"), value: meta.createdFormatted },
                        { label: qsTr("Permissions"), value: meta.permissions },
                        { label: qsTr("Owner"), value: `${meta.owner}:${meta.group}` }
                    ]

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        visible: modelData.visible !== false && modelData.value.length > 0

                        StyledText {
                            text: modelData.label
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.value
                            color: Colours.palette.m3onSurface
                            font: Tokens.font.body.small
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }
            }
        }
    }
}
