import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import prism

Item {
    id: root

    property var model: []
    property var currentValue: undefined
    property string valueKey: "value"
    property string labelKey: "label"
    property string iconKey: "icon"
    property string text: ""
    property string icon: ""
    property bool disabled: false

    signal selected(var value, int index)
    signal clicked()
    signal menuTriggered()

    readonly property var currentItem: {
        if (!model || model.length === 0) return null;
        for (let i = 0; i < model.length; ++i) {
            const it = model[i];
            const val = (typeof it === "object" && it !== null && root.valueKey in it) ? it[root.valueKey] : it;
            if (val === root.currentValue) return it;
        }
        return model[0];
    }

    readonly property string displayText: {
        if (root.text.length > 0) return root.text;
        if (currentItem) {
            if (typeof currentItem === "object" && currentItem !== null && root.labelKey in currentItem) {
                return currentItem[root.labelKey];
            }
            if (typeof currentItem === "string") return currentItem;
        }
        return "";
    }

    readonly property string displayIcon: {
        if (root.icon.length > 0) return root.icon;
        if (currentItem && typeof currentItem === "object" && currentItem !== null && root.iconKey in currentItem) {
            return currentItem[root.iconKey] || "";
        }
        return "";
    }

    implicitWidth: splitRow.implicitWidth
    implicitHeight: 36

    Row {
        id: splitRow
        anchors.fill: parent
        spacing: 2

        // Main button
        StyledRect {
            id: mainBtn
            height: root.implicitHeight
            implicitWidth: contentRow.implicitWidth + Tokens.padding.medium * 2
            topLeftRadius: Tokens.rounding.full
            bottomLeftRadius: Tokens.rounding.full
            topRightRadius: 4
            bottomRightRadius: 4
            color: menuPopup.visible ? Colours.palette.m3primaryContainer : (mainHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainerHigh)

            Behavior on color { Anim { type: Anim.FastEffects } }

            StateLayer {
                anchors.fill: parent
                topLeftRadius: parent.topLeftRadius
                bottomLeftRadius: parent.bottomLeftRadius
                topRightRadius: parent.topRightRadius
                bottomRightRadius: parent.bottomRightRadius
                color: menuPopup.visible ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                disabled: root.disabled
                onClicked: {
                    if (root.model && root.model.length > 0) {
                        menuPopup.visible ? menuPopup.close() : menuPopup.open();
                    } else {
                        root.clicked();
                    }
                }
            }

            RowLayout {
                id: contentRow
                anchors.centerIn: parent
                spacing: 6

                MaterialIcon {
                    visible: root.displayIcon.length > 0
                    text: root.displayIcon
                    fontStyle: Tokens.font.icon.small
                    color: menuPopup.visible ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                }

                StyledText {
                    text: root.displayText
                    font: Tokens.font.label.large
                    color: menuPopup.visible ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: mainHover
                anchors.fill: parent
                hoverEnabled: !root.disabled
                cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
                onClicked: {
                    if (root.model && root.model.length > 0) {
                        menuPopup.visible ? menuPopup.close() : menuPopup.open();
                    } else {
                        root.clicked();
                    }
                }
            }
        }

        // Dropdown trigger button
        StyledRect {
            id: dropBtn
            width: 32
            height: root.implicitHeight
            topRightRadius: Tokens.rounding.full
            bottomRightRadius: Tokens.rounding.full
            topLeftRadius: 4
            bottomLeftRadius: 4
            color: menuPopup.visible ? Colours.palette.m3primaryContainer : (dropHover.containsMouse ? Colours.tPalette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainerHigh)

            Behavior on color { Anim { type: Anim.FastEffects } }

            StateLayer {
                anchors.fill: parent
                topLeftRadius: parent.topLeftRadius
                bottomLeftRadius: parent.bottomLeftRadius
                topRightRadius: parent.topRightRadius
                bottomRightRadius: parent.bottomRightRadius
                color: menuPopup.visible ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                disabled: root.disabled
                onClicked: {
                    root.menuTriggered();
                    menuPopup.visible ? menuPopup.close() : menuPopup.open();
                }
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: menuPopup.visible ? "expand_less" : "expand_more"
                fontStyle: Tokens.font.icon.small
                color: menuPopup.visible ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
            }

            MouseArea {
                id: dropHover
                anchors.fill: parent
                hoverEnabled: !root.disabled
                cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
                onClicked: {
                    root.menuTriggered();
                    menuPopup.visible ? menuPopup.close() : menuPopup.open();
                }
            }
        }
    }

    Popup {
        id: menuPopup
        y: root.height + 4
        x: root.width - width
        implicitWidth: Math.max(root.width, menuCol.implicitWidth + Tokens.padding.medium * 2)
        implicitHeight: menuCol.implicitHeight + Tokens.padding.small * 2
        padding: Tokens.padding.small
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: StyledRect {
            radius: Tokens.rounding.medium
            color: Colours.palette.m3surfaceContainerHighest
            border.width: 1
            border.color: Qt.alpha(Colours.palette.m3outline, 0.2)
        }

        ColumnLayout {
            id: menuCol
            anchors.fill: parent
            spacing: 2

            Repeater {
                model: root.model

                delegate: StyledRect {
                    id: menuItem
                    required property int index
                    required property var modelData

                    readonly property var itemValue: {
                        if (typeof modelData === "object" && modelData !== null && root.valueKey in modelData) {
                            return modelData[root.valueKey];
                        }
                        return modelData;
                    }

                    readonly property string itemLabel: {
                        if (typeof modelData === "object" && modelData !== null && root.labelKey in modelData) {
                            return modelData[root.labelKey];
                        }
                        if (typeof modelData === "string") return modelData;
                        return "";
                    }

                    readonly property string itemIcon: {
                        if (typeof modelData === "object" && modelData !== null && root.iconKey in modelData) {
                            return modelData[root.iconKey] || "";
                        }
                        return "";
                    }

                    readonly property bool isSelected: root.currentValue === itemValue

                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: Tokens.rounding.small
                    color: isSelected
                        ? Colours.palette.m3primaryContainer
                        : (itemMouse.containsMouse ? Qt.alpha(Colours.palette.m3onSurface, 0.08) : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.medium
                        anchors.rightMargin: Tokens.padding.medium
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            visible: menuItem.itemIcon.length > 0
                            text: menuItem.itemIcon
                            fontStyle: Tokens.font.icon.small
                            color: menuItem.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: menuItem.itemLabel
                            font: Tokens.font.body.medium
                            color: menuItem.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.currentValue = menuItem.itemValue;
                            root.selected(menuItem.itemValue, menuItem.index);
                            menuPopup.close();
                        }
                    }
                }
            }
        }
    }
}
