import QtQuick
import atlas

// A TTY menu row, `▶ label          ^C`: lower case, no icon, the hovered row
// marked and raised, its shortcut (or `›` for a submenu) dim on the right.
Item {
    id: root

    property string text
    property bool hovered: false
    property bool danger: false
    property bool hasSubmenu: false
    // A ShortcutManager action id whose first binding is shown on the right,
    // or the keys themselves
    property string shortcut
    property string keys
    // Set for a choice among several: `(•)` for the current one, `( )` else
    property bool checkable: false
    property bool checked: false

    readonly property string hint: hasSubmenu ? "›" : keys.length > 0 ? abbreviate(keys) : shortcut.length > 0 ? abbreviate((ShortcutManager.bindings[shortcut] || [])[0] || "") : ""

    // Ctrl+Shift+N → ^S-N, Alt+Return → M-⏎, as a terminal writes keys
    function abbreviate(seq: string): string {
        return seq.replace(/Ctrl\+/g, "^").replace(/Alt\+/g, "M-").replace(/Shift\+/g, "S-")
            .replace(/Return|Enter/g, "⏎").replace(/Delete/g, "Del").replace(/^Shift$/, "S").replace(/^Ctrl$/, "^").replace(/\^S-$/, "^S");
    }

    implicitWidth: label.implicitWidth + hintText.implicitWidth + 28 + 24
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        visible: root.hovered
        color: Colours.palette.m3surfaceContainerHighest
    }

    StyledText {
        id: label

        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.StyledText
        text: (root.hovered ? `<font color="${Colours.palette.m3primary}">▶ </font>` : "&nbsp;&nbsp;") + (root.checkable ? (root.checked ? "(•) " : "(&nbsp;) ") : "") + root.text.toLowerCase().replace(/&/g, "&amp;").replace(/</g, "&lt;")
        color: root.danger ? Colours.palette.m3error : root.hovered ? Colours.palette.m3inverseOnSurface : Colours.palette.m3onSurface
        font: Tokens.font.body.medium
    }

    StyledText {
        id: hintText

        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.hint
        color: root.danger ? Colours.palette.m3error : root.hovered ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3outline
        font: Tokens.font.body.medium
    }
}
