import QtQuick
import QtQuick.Layouts
import "../"
import prism

MouseArea {
    id: root

    property bool expanded: false
    property string targetPath: ""

    anchors.fill: parent
    enabled: expanded
    hoverEnabled: expanded
    cursorShape: expanded ? Qt.ArrowCursor : undefined

    opacity: expanded ? 1 : 0
    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

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
                    font: Tokens.font.title.medium
                    color: Colours.palette.m3onSurface
                }

                Item {
                    implicitWidth: 28
                    implicitHeight: 28

                    StyledRect {
                        anchors.fill: parent
                        radius: Tokens.rounding.full
                        color: Colours.tPalette.m3surfaceContainer

                        StateLayer {
                            onClicked: root.expanded = false
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

            // Name & Icon
            RowLayout {
                spacing: Tokens.spacing.medium

                CachingIconImage {
                    implicitSize: 48

                    Component.onCompleted: {
                        if (meta.isDir) {
                            source = FileUtils.iconForFile(meta.name, true, "");
                        } else if (meta.mimeType.startsWith("image/")) {
                            source = Qt.resolvedUrl("file://" + meta.path);
                        } else {
                            source = FileUtils.iconForFile(meta.name, false, meta.mimeType);
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: meta.name
                        font: Tokens.font.body.builders.large.weight(Font.Bold).build()
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideMiddle
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: meta.path
                        font: Tokens.font.label.small
                        color: Colours.palette.m3outline
                        elide: Text.ElideMiddle
                    }
                }
            }

            // Details List
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Repeater {
                    model: [
                        { label: qsTr("Size:"), value: meta.formattedSize },
                        { label: qsTr("Type:"), value: meta.mimeDescription },
                        { label: qsTr("Dimensions:"), value: meta.imageDimensions, visible: meta.imageDimensions.length > 0 },
                        { label: qsTr("Modified:"), value: meta.modifiedFormatted },
                        { label: qsTr("Created:"), value: meta.createdFormatted },
                        { label: qsTr("Accessed:"), value: meta.accessedFormatted },
                        { label: qsTr("Permissions:"), value: meta.permissions },
                        { label: qsTr("Owner:"), value: `${meta.owner} : ${meta.group}` }
                    ]

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium
                        visible: modelData.visible !== false && modelData.value.length > 0

                        StyledText {
                            Layout.preferredWidth: 100
                            text: modelData.label
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.value
                            color: Colours.palette.m3onSurface
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // Close Button
            RowLayout {
                Layout.alignment: Qt.AlignRight

                StyledRect {
                    implicitWidth: 90
                    implicitHeight: 36
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3primary

                    StateLayer {
                        onClicked: root.expanded = false
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: qsTr("Close")
                        font: Tokens.font.label.large
                        color: Colours.palette.m3onPrimary
                    }
                }
            }
        }
    }
}
