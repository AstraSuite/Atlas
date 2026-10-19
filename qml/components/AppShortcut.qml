import QtQuick
import atlas

// Wraps a global application Shortcut so its sequence comes from the
// ShortcutManager registry instead of being hard-coded. Behaviour stays in
// the consumer's onActivated handler; this component only supplies the keys.
Shortcut {
    id: root

    // Stable action id registered in ShortcutManager (see SHORTCUTS.md §3).
    property string actionId: ""
    // Optional dynamic gate, e.g. "only while no modal is open".
    property bool active: true

    context: Qt.ApplicationShortcut
    // Empty while the key recorder is open so it can capture the combo.
    sequences: ShortcutManager.recording ? [] : (ShortcutManager.bindings[root.actionId] || [])
    enabled: root.active && !ShortcutManager.recording
}