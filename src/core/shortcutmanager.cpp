#include "shortcutmanager.hpp"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QKeyCombination>
#include <QKeySequence>
#include <QSettings>

namespace atlas::core {

static QString normalizeSequence(const QString& seq) {
    if (seq.trimmed().isEmpty())
        return {};
    const QKeySequence ks(seq);
    if (ks.isEmpty())
        return {};
    const QString out = ks.toString(QKeySequence::PortableText);
    return out.isEmpty() ? QString() : out;
}

/* ------------------------------------------------------------------ */

const QList<ShortcutManager::Action>& ShortcutManager::defaultActions() {
    // Order defines grouping order in the settings UI (grouped by category).
    static const QList<Action> actions = {
        // --- Application ---
        { "app.preferences", "Open Preferences", "Open the settings dialog", "Application", "settings",
          { "Ctrl+,", "Ctrl+." } },
        { "app.fullscreen", "Toggle Full Screen", "Switch between full screen and windowed mode", "Application", "fullscreen",
          { "F11", "Shift+F11" } },

        // --- Navigation ---
        { "nav.back", "Go Back", "Navigate to the previously visited folder", "Navigation", "arrow_back",
          { "Alt+Left" } },
        { "nav.forward", "Go Forward", "Navigate to the next visited folder", "Navigation", "arrow_forward",
          { "Alt+Right" } },
        { "nav.parent", "Go to Parent Folder", "Navigate up one directory level", "Navigation", "arrow_upward",
          { "Alt+Up" } },
        { "nav.home", "Go Home", "Navigate to the home directory", "Navigation", "home",
          { "Alt+Home" } },
        { "nav.search", "Search", "Search for files across the current folder", "Navigation", "search",
          { "Ctrl+F", "F9", "Shift+F9" } },
        { "nav.address", "Edit Location", "Type a path directly in the address bar", "Navigation", "edit_location",
          { "Ctrl+L", "Alt+D" } },

        // --- Tabs ---
        { "tabs.new", "New Tab", "Open a new tab", "Tabs", "tab",
          { "Ctrl+T" } },
        { "tabs.close", "Close Tab / Pane", "Close the current tab or split pane", "Tabs", "tab_close",
          { "Ctrl+W" } },
        { "tabs.next", "Next Tab", "Switch to the next tab", "Tabs", "chevron_right",
          { "Ctrl+Tab" } },
        { "tabs.previous", "Previous Tab", "Switch to the previous tab", "Tabs", "chevron_left",
          { "Ctrl+Shift+Tab" } },

        // --- File Operations ---
        { "file.newFile", "New File", "Create an empty file in the current folder", "File Operations", "note_add",
          { "Ctrl+N" } },
        { "file.newFolder", "New Folder", "Create a folder in the current folder", "File Operations", "create_new_folder",
          { "Ctrl+Shift+N", "F10", "Shift+F10" } },
        { "file.rename", "Rename", "Rename the selected file or folder", "File Operations", "drive_file_rename_outline",
          { "F2", "Shift+F2" } },
        { "file.trash", "Move to Trash", "Move the selection to the trash", "File Operations", "delete",
          { "Delete" } },
        { "file.deletePermanent", "Delete Permanently", "Delete the selection without the trash", "File Operations", "delete_forever",
          { "Shift+Delete" } },
        { "file.properties", "Properties", "Show properties of the selected item", "File Operations", "info",
          { "Alt+Return" } },

        // --- Editing ---
        { "edit.copy", "Copy", "Copy the selection to the clipboard", "Editing", "content_copy",
          { "Ctrl+C" } },
        { "edit.cut", "Cut", "Cut the selection to the clipboard", "Editing", "content_cut",
          { "Ctrl+X" } },
        { "edit.paste", "Paste", "Paste clipboard contents into the current folder", "Editing", "content_paste",
          { "Ctrl+V" } },
        { "edit.undo", "Undo", "Undo the last file operation", "Editing", "undo",
          { "Ctrl+Z" } },
        { "edit.redo", "Redo", "Redo the last undone file operation", "Editing", "redo",
          { "Ctrl+Shift+Z", "Ctrl+Y" } },

        // --- Selection ---
        { "edit.selectAll", "Select All", "Select every item in the current folder", "Selection", "select_all",
          { "Ctrl+A" } },
        { "edit.clearSelection", "Clear Selection", "Deselect all items", "Selection", "deselect",
          { "Ctrl+Shift+A", "Ctrl+D" } },
        { "edit.invertSelection", "Invert Selection", "Select everything that is not selected", "Selection", "flip",
          { "Ctrl+I" } },
        { "edit.selectByPattern", "Select by Pattern", "Select items matching a wildcard pattern", "Selection", "filter_alt",
          { "Ctrl+S" } },

        // --- View ---
        { "view.grid", "Grid View", "Display items as a grid of thumbnails", "View", "grid_view",
          { "Ctrl+1" } },
        { "view.details", "Details View", "Display items as a details list", "View", "view_list",
          { "Ctrl+2" } },
        { "view.compact", "Compact View", "Display items as a compact list", "View", "view_agenda",
          { "Ctrl+3" } },
        { "view.toggleHidden", "Show Hidden Files", "Toggle visibility of hidden dotfiles", "View", "visibility",
          { "Ctrl+H", "Alt+." } },
        { "view.split", "Toggle Split View", "Split or unsplit the current tab", "View", "vertical_split",
          { "F3", "Shift+F3" } },
        { "view.refresh", "Refresh", "Reload the current folder listing", "View", "refresh",
          { "F5", "Shift+F5", "Ctrl+R" } },
        { "view.previewPanel", "Toggle Preview Panel", "Show or hide the preview panel", "View", "preview",
          { "F1", "Shift+F1", "Alt+P" } },
        { "view.previewMedia", "Preview Media", "Open the selected media file in the viewer", "View", "play_circle",
          { "Space" } },
        { "view.zoomIn", "Zoom In", "Increase the icon size", "View", "zoom_in",
          { "Ctrl+=", "Ctrl++" } },
        { "view.zoomOut", "Zoom Out", "Decrease the icon size", "View", "zoom_out",
          { "Ctrl+-" } },
        { "view.zoomReset", "Reset Zoom", "Restore the default icon size", "View", "zoom_out_map",
          { "Ctrl+0" } },

        // --- Tools ---
        { "tools.terminal", "Open in Terminal", "Launch a terminal in the current folder", "Tools", "terminal",
          { "F4", "Shift+F4", "Ctrl+Alt+T", "Ctrl+`" } },
    };
    return actions;
}

const ShortcutManager::Action* ShortcutManager::findAction(const QString& id) {
    for (const Action& a : defaultActions()) {
        if (a.id == id)
            return &a;
    }
    return nullptr;
}

/* ------------------------------------------------------------------ */

ShortcutManager::ShortcutManager(QObject* parent)
    : QObject(parent) {
    QSettings settings("astra-atlas", "atlas");
    const QByteArray json = settings.value("shortcuts/bindings").toString().toUtf8();
    if (json.isEmpty())
        return;

    const QJsonObject obj = QJsonDocument::fromJson(json).object();
    for (auto it = obj.constBegin(); it != obj.constEnd(); ++it) {
        if (!findAction(it.key()) || !it.value().isArray())
            continue;
        QStringList list;
        const QJsonArray arr = it.value().toArray();
        for (const QJsonValue& v : arr) {
            const QString n = normalizeSequence(v.toString());
            if (!n.isEmpty() && !list.contains(n))
                list.append(n);
        }
        if (!list.isEmpty())
            m_overrides.insert(it.key(), list);
    }
}

ShortcutManager* ShortcutManager::instance() {
    static auto* s_instance = new ShortcutManager();
    return s_instance;
}

QVariantMap ShortcutManager::bindings() const {
    QVariantMap map;
    for (const Action& a : defaultActions())
        map.insert(a.id, effectiveSequences(a.id));
    return map;
}

QVariantList ShortcutManager::shortcuts() const {
    QVariantList list;
    for (const Action& a : defaultActions()) {
        QVariantMap m;
        m.insert(QStringLiteral("id"), a.id);
        m.insert(QStringLiteral("label"), a.label);
        m.insert(QStringLiteral("description"), a.description);
        m.insert(QStringLiteral("category"), a.category);
        m.insert(QStringLiteral("icon"), a.icon);
        m.insert(QStringLiteral("sequences"), effectiveSequences(a.id));
        m.insert(QStringLiteral("defaults"), a.defaults);
        m.insert(QStringLiteral("modified"), m_overrides.contains(a.id));
        list.append(m);
    }
    return list;
}

void ShortcutManager::setRecording(bool rec) {
    if (m_recording == rec)
        return;
    m_recording = rec;
    emit recordingChanged();
}

QStringList ShortcutManager::sequencesFor(const QString& id) const {
    return effectiveSequences(id);
}

bool ShortcutManager::hasOverride(const QString& id) const {
    return m_overrides.contains(id);
}

QStringList ShortcutManager::effectiveSequences(const QString& id) const {
    const auto it = m_overrides.constFind(id);
    if (it != m_overrides.constEnd())
        return it.value();
    return canonicalDefaults(id);
}

QStringList ShortcutManager::canonicalDefaults(const QString& id) const {
    const Action* a = findAction(id);
    if (!a)
        return {};
    QStringList out;
    for (const QString& s : a->defaults) {
        const QString n = normalizeSequence(s);
        if (!n.isEmpty() && !out.contains(n))
            out.append(n);
    }
    return out;
}

void ShortcutManager::applyOverride(const QString& id, const QStringList& seqs) {
    if (!findAction(id))
        return;

    QStringList clean;
    for (const QString& s : seqs) {
        const QString n = normalizeSequence(s);
        if (!n.isEmpty() && !clean.contains(n))
            clean.append(n);
    }

    if (clean == canonicalDefaults(id)) {
        m_overrides.remove(id);
    } else {
        m_overrides.insert(id, clean);
    }
    persistOverrides();
}

void ShortcutManager::persistOverrides() const {
    QJsonObject obj;
    for (auto it = m_overrides.cbegin(); it != m_overrides.cend(); ++it)
        obj.insert(it.key(), QJsonArray::fromStringList(it.value()));

    QSettings settings("astra-atlas", "atlas");
    if (obj.isEmpty()) {
        settings.remove("shortcuts/bindings");
    } else {
        settings.setValue("shortcuts/bindings",
                          QString::fromUtf8(QJsonDocument(obj).toJson(QJsonDocument::Compact)));
    }
}

bool ShortcutManager::setSequences(const QString& id, const QStringList& seqs) {
    if (!findAction(id))
        return false;
    applyOverride(id, seqs);
    emit shortcutsChanged();
    return true;
}

bool ShortcutManager::addSequence(const QString& id, const QString& seq) {
    const QString n = normalizeSequence(seq);
    if (n.isEmpty() || !findAction(id))
        return false;
    if (effectiveSequences(id).contains(n))
        return false;
    QStringList list = effectiveSequences(id);
    list.append(n);
    applyOverride(id, list);
    emit shortcutsChanged();
    return true;
}

bool ShortcutManager::removeSequence(const QString& id, const QString& seq) {
    const QString n = normalizeSequence(seq);
    if (n.isEmpty() || !findAction(id))
        return false;
    QStringList list = effectiveSequences(id);
    if (!list.removeOne(n))
        return false;
    applyOverride(id, list);
    emit shortcutsChanged();
    return true;
}

void ShortcutManager::resetAction(const QString& id) {
    if (!m_overrides.contains(id))
        return;
    m_overrides.remove(id);
    persistOverrides();
    emit shortcutsChanged();
}

void ShortcutManager::resetAll() {
    if (m_overrides.isEmpty())
        return;
    m_overrides.clear();
    persistOverrides();
    emit shortcutsChanged();
}

QVariantList ShortcutManager::conflicts(const QString& id, const QStringList& seqs) const {
    QStringList normalized;
    for (const QString& s : seqs) {
        const QString n = normalizeSequence(s);
        if (!n.isEmpty() && !normalized.contains(n))
            normalized.append(n);
    }
    if (normalized.isEmpty())
        return {};

    QVariantList result;
    for (const Action& a : defaultActions()) {
        if (a.id == id)
            continue;
        const QStringList eff = effectiveSequences(a.id);
        QStringList hit;
        for (const QString& n : normalized) {
            if (eff.contains(n))
                hit.append(n);
        }
        if (!hit.isEmpty()) {
            QVariantMap m;
            m.insert(QStringLiteral("id"), a.id);
            m.insert(QStringLiteral("label"), a.label);
            m.insert(QStringLiteral("sequences"), hit);
            result.append(m);
        }
    }
    return result;
}

bool ShortcutManager::reassign(const QString& id, const QString& seq) {
    const QString n = normalizeSequence(seq);
    if (n.isEmpty() || !findAction(id))
        return false;

    bool changed = false;
    for (const Action& a : defaultActions()) {
        if (a.id == id)
            continue;
        QStringList eff = effectiveSequences(a.id);
        if (eff.removeAll(n) > 0) {
            applyOverride(a.id, eff);
            changed = true;
        }
    }

    QStringList list = effectiveSequences(id);
    if (!list.contains(n)) {
        list.append(n);
        applyOverride(id, list);
        changed = true;
    }

    if (changed)
        emit shortcutsChanged();
    return changed;
}

QString ShortcutManager::sequenceFromKey(int key, int modifiers) const {
    const Qt::Key k = static_cast<Qt::Key>(key);
    switch (k) {
    case Qt::Key_unknown:
    case Qt::Key_Shift:
    case Qt::Key_Control:
    case Qt::Key_Alt:
    case Qt::Key_Meta:
    case Qt::Key_AltGr:
        return {};
    default:
        break;
    }

    const Qt::KeyboardModifiers mods =
        static_cast<Qt::KeyboardModifiers>(modifiers) & Qt::KeyboardModifierMask;
    const QKeySequence seq(QKeyCombination(mods, k));
    return seq.toString(QKeySequence::PortableText);
}

bool ShortcutManager::isAcceptable(const QString& seq) const {
    return !normalizeSequence(seq).isEmpty();
}

bool ShortcutManager::isBareKey(const QString& seq) const {
    const QKeySequence ks(seq);
    if (ks.isEmpty())
        return false;
    const QKeyCombination combo = ks[0];
    if (combo.keyboardModifiers() != Qt::NoModifier)
        return false;
    const int key = static_cast<int>(combo.key());
    // Function/navigation/special keys live at or above Qt::Key_Escape
    // (0x01000000) and must never count as bare printable keys.
    if (key < 0x20 || key > 0xFFFF)
        return false;
    if (key >= 0xD800 && key <= 0xDFFF) // unpaired surrogate
        return false;
    const QChar ch(key);
    return ch.isPrint() && !ch.isSpace();
}

} // namespace atlas::core