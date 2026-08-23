import QtQuick
import QtQuick.Layouts
import "../"
import "../containers"
import prism

RowLayout {
    id: root

    property var model: []
    property var currentValue: undefined
    property string valueKey: "value"
    property string labelKey: "label"
    property string iconKey: "icon"
    property var isSelected: null // optional custom callback: (modelData, index) => bool
    property bool multiSelect: false

    signal selected(var value, int index)

    spacing: 2
    implicitHeight: 40

    Repeater {
        id: repeater
        model: root.model

        delegate: ConnectedRect {
            id: itemRect
            required property int index
            required property var modelData

            readonly property bool checked: {
                if (root.isSelected) {
                    return root.isSelected(modelData, index);
                }
                const val = typeof modelData === "object" && modelData !== null && root.valueKey in modelData
                    ? modelData[root.valueKey]
                    : modelData;
                return root.currentValue === val;
            }

            readonly property string itemIcon: {
                if (typeof modelData === "object" && modelData !== null && root.iconKey in modelData) {
                    return modelData[root.iconKey] || "";
                }
                return "";
            }

            readonly property string itemLabel: {
                if (typeof modelData === "object" && modelData !== null && root.labelKey in modelData) {
                    return modelData[root.labelKey] || "";
                }
                if (typeof modelData === "string") {
                    return modelData;
                }
                return "";
            }

            horizontal: true
            first: index === 0
            last: index === repeater.count - 1

            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: root.implicitHeight

            color: itemRect.checked
                ? Colours.palette.m3primaryContainer
                : (itemHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer)

            Behavior on color {
                Anim { type: Anim.FastEffects }
            }

            StateLayer {
                anchors.fill: parent
                topLeftRadius: parent.topLeftRadius
                topRightRadius: parent.topRightRadius
                bottomLeftRadius: parent.bottomLeftRadius
                bottomRightRadius: parent.bottomRightRadius
                color: itemRect.checked ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                MaterialIcon {
                    visible: itemRect.itemIcon.length > 0
                    text: itemRect.itemIcon
                    fontStyle: Tokens.font.icon.small
                    color: itemRect.checked ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    text: itemRect.itemLabel
                    font: Tokens.font.body.small
                    color: itemRect.checked ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: itemHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const val = typeof itemRect.modelData === "object" && itemRect.modelData !== null && root.valueKey in itemRect.modelData
                        ? itemRect.modelData[root.valueKey]
                        : itemRect.modelData;
                    root.selected(val, itemRect.index);
                }
            }
        }
    }
}
