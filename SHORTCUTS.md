# Shortcut Manager — Implementation Plan

A rebindable keyboard-shortcut manager for Atlas, surfaced as a new **Shortcuts**
tab inside the existing Preferences modal (`qml/components/dialogs/PreferencesModal.qml`).

The goal is that every global application shortcut (the `Shortcut {}` elements in
`qml/main.qml`) becomes user-editable: view it, record a new key combo, add an
extra combo, remove a combo, reset one action, or reset everything — with
conflict detection and persistence across restarts.

This document is a plan only. No code has been changed yet.

---

## 1. Current state (grounded findings)

- **All global shortcuts are hard-coded** as ~45 `Shortcut {}` blocks in
  `qml/main.qml` (lines ~711–1062), all using `context: Qt.ApplicationShortcut`.
  Some blocks carry multiple `sequences: [...]`; several semantically-identical
  actions are split across separate blocks (e.g. hidden files = `Ctrl+H` + `Alt+.`;
  address bar = `Ctrl+L` + `Alt+D`; redo = `Ctrl+Shift+Z` + `Ctrl+Y`).
- **Settings persistence** is `QSettings("astra-atlas", "atlas")`, accessed from
  C++ singletons. `AppController` (`src/core/appcontroller.hpp/.cpp`) is the
  canonical example: `Q_PROPERTY`s + `setX()` that writes a key and emits a
  `...Changed` signal. Complex structures (directory views, column widths) are
  stored as compact JSON strings.
- **QML singletons** are registered either via `QML_ELEMENT`/`QML_SINGLETON`
  (`AppController::create`) or via `engine.rootContext()->setContextProperty(...)`
  in `src/main.cpp` (e.g. `TabManager`, `PlacesModel`). Both patterns work.
- **Reusable UI components** already exist and should be reused:
  `SlidingSelector` (tab strip), `VerticalFadeFlickable`, `ToggleRow`,
  `RowButton`, `SplitButtonRow`, `IconButton`, `IconTextButton`, `TextButton`,
  `StyledRect`, `StyledText`, `MaterialIcon`, `StateLayer`, `StyledScrollBar`,
  `MenuItem`/`Menu`.
- **The Preferences modal** has 4 tabs (`General`, `View & Sorting`,
  `Context Menu`, `Scripts & Tools`) driving an inline `SlidingSelector` and a
  `Row` of 4 `VerticalFadeFlickable` pages with:
  `width: contentArea.width * 4` and `x: -root.currentCategory * contentArea.width`.
  Adding a tab means changing the multiplier to 5 and appending one page.
- **Key capture precedent**: views capture keys with `Keys.onPressed`
  (`FileGridView.qml`, `FileDetailsView.qml`, etc.); vim motions are gated by
  `AppController.vimMotions`. There is no existing shortcut-recording UI.
- **Out of scope (documented so we don't overreach)**: view-local keys handled
  inside `Keys.onPressed` (`/`, arrow keys, type-ahead, `Backspace`, Enter/Right)
  and shortcuts local to components (`MediaViewerModal`, `VectorBloomOverlay`,
  `RunnerGameModal`, `DropActionMenu`). Phase 2 can expose a subset later.

---

## 2. Architecture overview

```
QSettings("astra-atlas","atlas")  ──  [shortcuts] bindings = compact JSON
        ▲                                            │
        │ writes overrides / read at startup         ▼
┌──────────────────────────────┐         ┌───────────────────────────────┐
│  ShortcutManager (C++ singleton)        │  AppShortcut.qml (wrapper)    │
│  - canonical action registry │◀────────│  - actionId                   │
│  - defaults + user overrides │  bind   │  sequences: manager.bindings  │
│  - conflict detection        │         │  enabled/active gating        │
│  - key-event → portable text │         └──────────────┬────────────────┘
└──────────────┬───────────────┘                        │ used by
               │ exposes shortcuts()/bindings            │
               ▼                                         ▼
┌──────────────────────────────┐              qml/main.qml
│ ShortcutsTab.qml (settings)  │              (onActivated logic stays here)
│  - search / group / rows     │
│  - record / add / remove     │
│  - reset one / reset all     │
│  - import / export (Phase 2) │
└──────────────────────────────┘
```

**Key separation of concerns:** `ShortcutManager` owns *which keys are bound*
(data). `qml/main.qml` owns *what each action does* (`onActivated`). Actions are
keyed by a stable string `actionId`; the manager never knows about the behavior.

---

## 3. Action registry (canonical IDs + defaults)

Consolidate the 45 current blocks into ~34 logical actions. One `actionId` = one
wrapped `AppShortcut` in `main.qml`, with all of its default combos in one list.
`Category` drives grouping in the settings tab.

| actionId | Label | Category | Default sequences | Current source |
|---|---|---|---|---|
| `app.preferences` | Open Preferences | Application | `Ctrl+,` | main.qml:727 |
| `app.fullscreen` | Toggle Full Screen | Application | `F11`, `Shift+F11` | main.qml:1011 |
| `nav.back` | Go Back | Navigation | `Alt+Left` | main.qml:919 |
| `nav.forward` | Go Forward | Navigation | `Alt+Right` | main.qml:925 |
| `nav.parent` | Go to Parent Folder | Navigation | `Alt+Up` | main.qml:931 |
| `nav.home` | Go Home | Navigation | `Alt+Home` | main.qml:937 |
| `nav.search` | Search | Navigation | `Ctrl+F`, `F9`, `Shift+F9` | main.qml:943 |
| `nav.address` | Edit Location | Navigation | `Ctrl+L`, `Alt+D` | 949 + 955 (merged) |
| `tabs.new` | New Tab | Tabs | `Ctrl+T` | 733 |
| `tabs.close` | Close Tab / Pane | Tabs | `Ctrl+W` | 739 |
| `tabs.next` | Next Tab | Tabs | `Ctrl+Tab` | 751 |
| `tabs.previous` | Previous Tab | Tabs | `Ctrl+Shift+Tab` | 757 |
| `file.newFile` | New File | File Operations | `Ctrl+N` | 763 |
| `file.newFolder` | New Folder | File Operations | `Ctrl+Shift+N`, `F10`, `Shift+F10` | 774 + 994 (merged) |
| `file.rename` | Rename | File Operations | `F2`, `Shift+F2` | 827 |
| `file.trash` | Move to Trash | File Operations | `Delete` | 809 |
| `file.deletePermanent` | Delete Permanently | File Operations | `Shift+Delete` | 818 |
| `file.properties` | Properties | File Operations | `Alt+Return` | 842 |
| `edit.copy` | Copy | Editing | `Ctrl+C` | 785 |
| `edit.cut` | Cut | Editing | `Ctrl+X` | 794 |
| `edit.paste` | Paste | Editing | `Ctrl+V` | 803 |
| `edit.undo` | Undo | Editing | `Ctrl+Z` | 1023 |
| `edit.redo` | Redo | Editing | `Ctrl+Shift+Z`, `Ctrl+Y` | 1029 + 1035 (merged) |
| `edit.selectAll` | Select All | Selection | `Ctrl+A` | 866 |
| `edit.clearSelection` | Clear Selection | Selection | `Ctrl+Shift+A`, `Ctrl+D` | 872 + 878 (merged) |
| `edit.invertSelection` | Invert Selection | Selection | `Ctrl+I` | 884 |
| `edit.selectByPattern` | Select by Pattern | Selection | `Ctrl+S` | 890 |
| `view.grid` | Grid View | View | `Ctrl+1` | 901 |
| `view.details` | Details View | View | `Ctrl+2` | 907 |
| `view.compact` | Compact View | View | `Ctrl+3` | 913 |
| `view.toggleHidden` | Show Hidden Files | View | `Ctrl+H`, `Alt+.` | 854 + 860 (merged) |
| `view.split` | Toggle Split View | View | `F3`, `Shift+F3` | 961 |
| `view.refresh` | Refresh | View | `F5`, `Shift+F5`, `Ctrl+R` | 984 |
| `view.previewPanel` | Toggle Preview Panel | View | `F1`, `Shift+F1`, `Alt+P` | 1005 |
| `view.previewMedia` | Preview Media | View | `Space` | 712 |
| `view.zoomIn` | Zoom In | View | `Ctrl+=`, `Ctrl++` | 1041 + 1047 (merged) |
| `view.zoomOut` | Zoom Out | View | `Ctrl+-` | 1053 |
| `view.zoomReset` | Reset Zoom | View | `Ctrl+0` | 1059 |
| `tools.terminal` | Open in Terminal | Tools | `F4`, `Shift+F4`, `Ctrl+Alt+T`, `` Ctrl+` `` | 974 |

Notes / decisions:

- Merged duplicates (same `onActivated` body) into one action with multiple
  default sequences. This avoids two registry entries fighting over one combo and
  gives the user one place to edit.
- `view.previewMedia` keeps its current dynamic `enabled` gate (only when no modal
  is open and a media file is selected). `AppShortcut.active` preserves that.
- Ordering in the tab should follow Category, then the order above.

---

## 4. C++ `ShortcutManager` singleton

**New files:** `src/core/shortcutmanager.hpp`, `src/core/shortcutmanager.cpp`
(added to `CMakeLists.txt` next to `appcontroller.*`; `src/core` is already an
include dir).

Mirror `AppController`'s singleton shape and register it in `src/main.cpp` via
`setContextProperty("ShortcutManager", ...)` (or `QML_ELEMENT`/`QML_SINGLETON`).

### Data model

```cpp
struct ShortcutAction {
    QString id;                  // stable key, e.g. "tabs.new"
    QString label;               // translated display name
    QString description;         // optional secondary line
    QString category;            // "Navigation", "Tabs", ...
    QString icon;                // material symbol name
    QStringList defaultSequences;// QKeySequence portable strings
};

QHash<QString, QStringList> m_bindings; // user override only (id -> sequences)
```

### Public API (sketch)

```cpp
Q_PROPERTY(QVariantList shortcuts READ shortcuts NOTIFY shortcutsChanged)
Q_PROPERTY(QVariantMap  bindings  READ bindings  NOTIFY shortcutsChanged)
Q_PROPERTY(bool recording READ recording WRITE setRecording NOTIFY recordingChanged)

Q_INVOKABLE QStringList sequencesFor(const QString& id) const;
Q_INVOKABLE QVariantList actions() const;               // grouped descriptors
Q_INVOKABLE bool hasOverride(const QString& id) const;

Q_INVOKABLE bool setSequences(const QString& id, const QStringList& seqs);
Q_INVOKABLE bool addSequence(const QString& id, const QString& seq);
Q_INVOKABLE bool removeSequence(const QString& id, const QString& seq);
Q_INVOKABLE void resetAction(const QString& id);
Q_INVOKABLE void resetAll();

// conflict detection (normalised with QKeySequence, so Ctrl++ == Ctrl+=)
Q_INVOKABLE QVariantList conflicts(const QString& id, const QStringList& seqs) const;
Q_INVOKABLE bool reassign(const QString& id, const QString& seq); // steal from others

// recording helper: turns Keys.onPressed data into portable text
Q_INVOKABLE QString sequenceFromKey(int key, int modifiers) const;
Q_INVOKABLE bool isAcceptable(const QString& seq) const; // reject bare letters etc.

// optional Phase 2
Q_INVOKABLE bool exportToFile(const QString& path) const;
Q_INVOKABLE bool importFromFile(const QString& path);

signals:
    void shortcutsChanged();
    void recordingChanged();
```

### Behaviour details

- **Defaults** live in a static table in the `.cpp` (the IDs above).
  `sequencesFor(id)` returns the override if present, else the default.
- **Persistence**: store only overrides, as compact JSON under one key:
  `settings.setValue("shortcuts/bindings", <json string>)`; call
  `resetAction` → remove entry, `resetAll` → `settings.remove("shortcuts/bindings")`.
  Load in the constructor; sanitise unknown IDs/sequences on load.
- **Notifications**: every mutation emits `shortcutsChanged()`, which makes the
  `bindings` property binding in `AppShortcut` re-evaluate live — no restart.
- **`sequenceFromKey`**: ignore pure modifiers; build
  `QKeySequence(QKeyCombination(mods, key)).toString(QKeySequence::PortableText)`;
  return `{}` for invalid.
- **`isAcceptable`**: allow modifier combos and function/special keys
  (`F1–F12`, `Delete`, `Return`, arrows, `Space`, `Home`, etc.); either reject or
  require confirmation for a bare printable character (typing conflict).
- **Conflict policy**: `conflicts()` returns `[{id,label,sequences}]` for every
  *other* action already using any of the candidate sequences. The UI offers
  **Replace** (call `reassign`) or **Cancel**.

---

## 5. QML `AppShortcut` wrapper

**New file:** `qml/components/AppShortcut.qml` (registered in `CMakeLists.txt`
`QML_FILES`).

```qml
import QtQuick
import atlas

Shortcut {
    id: root

    property string actionId: ""
    property bool active: true

    context: Qt.ApplicationShortcut
    // empty while recording so the recorder can capture the combo
    sequences: ShortcutManager.recording ? [] : (ShortcutManager.bindings[root.actionId] || [])
    enabled: root.active && !ShortcutManager.recording
}
```

Why a wrapper:

- Binds `sequences` to the manager map so rebinds are live.
- Centralises the "disable every global shortcut while recording" rule in one
  place instead of editing ~40 blocks.
- Keeps `onActivated` in `main.qml`, so behaviour is untouched.

---

## 6. Refactor `qml/main.qml`

Mechanical replacement of each hard-coded `Shortcut {}` with a wrapper that only
declares the action ID and (optionally) the dynamic gate.

Before:

```qml
Shortcut {
    sequence: "Ctrl+T"
    context: Qt.ApplicationShortcut
    onActivated: TabManager.newTab()
}
```

After:

```qml
AppShortcut {
    actionId: "tabs.new"
    onActivated: TabManager.newTab()
}
```

Before (dynamic gate + multiple sequences):

```qml
Shortcut {
    sequences: ["F1", "Shift+F1", "Alt+P"]
    context: Qt.ApplicationShortcut
    onActivated: previewPanel.expanded = !previewPanel.expanded
}
```

After:

```qml
AppShortcut {
    actionId: "view.previewPanel"
    onActivated: previewPanel.expanded = !previewPanel.expanded
}
```

Before (conditionally enabled):

```qml
Shortcut {
    sequence: "Space"
    context: Qt.ApplicationShortcut
    enabled: !mediaViewerModal.expanded && !newItemModal.expanded && ...
    onActivated: { /* media preview */ }
}
```

After:

```qml
AppShortcut {
    actionId: "view.previewMedia"
    active: !mediaViewerModal.expanded && !newItemModal.expanded && ...
    onActivated: { /* media preview */ }
}
```

Also: **merge** the duplicate blocks listed in §3 so each action appears once.

---

## 7. Shortcuts settings tab UI

**New files** (registered in `CMakeLists.txt`):

- `qml/components/settings/ShortcutsTab.qml` — the whole tab page.
- `qml/components/settings/ShortcutRow.qml` — one action row.
- `qml/components/settings/KeyRecorderDialog.qml` — capture overlay.

(If a new `qml/components/settings/` folder is undesired, place them in
`qml/components/dialogs/` instead. Decision: use `qml/components/settings/` to
keep the preferences surface grouped.)

### Wireframe

```
┌──────────────────────────────────────────────────────────────┐
│ [ search shortcuts…                          ]  ⟳ Reset All  │
│                                                              │
│  NAVIGATION                                                  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ ◀ Go Back                        Alt+Left      ✎  ↺    │  │
│  │ ▶ Go Forward                     Alt+Right     ✎  ↺    │  │
│  │ ⬆ Go to Parent                   Alt+Up        ✎  ↺    │  │
│  │ ⌂ Go Home                        Alt+Home      ✎  ↺    │  │
│  │ 🔍 Search                        Ctrl+F  F9 …  ✎  ↺  + │  │
│  └────────────────────────────────────────────────────────┘  │
│  TABS                                                        │
│  │ + New Tab                        Ctrl+T        ✎  ↺  + │  │
│  …                                                           │
└──────────────────────────────────────────────────────────────┘
```

### `ShortcutsTab.qml`

- Top toolbar row:
  - search/`TextField` (reuse the inline `TextInput`+`StyledRect` pattern already
    used for the custom-path field) that filters by label/category.
  - `IconTextButton` **Reset All** (`restart_alt`), disabled when
    `ShortcutManager` has no overrides; opens a small confirm popup.
- Body: a `VerticalFadeFlickable` containing, per category, a header
  `StyledText` followed by a `ColumnLayout` of `ShortcutRow`s inside a
  `ConnectedRect` group (same `first`/`last` visual language as `ToggleRow`).
- Empty state when the filter matches nothing.

### `ShortcutRow.qml` (based on `RowButton`)

- Left: action `icon` + `label` + `description`.
- Middle/right: one **key chip** per bound sequence. Each chip is a `StyledRect`
  with the portable text; clicking a chip removes that binding (with tooltip
  "Remove") or selects it for editing.
- Trailing controls:
  - **Record/edit** (`edit` icon) → opens `KeyRecorderDialog` bound to this action.
  - **Add** (`add` icon) → opens `KeyRecorderDialog` in "append sequence" mode
    (this is the requested *Add* button; appears on hover / always per row).
  - **Reset this action** (`restart_alt`) → `ShortcutManager.resetAction(id)`;
    only visible/enabled when `hasOverride(id)`.
- Uses `ConnectedRect` so rows visually join into a group.

### `KeyRecorderDialog.qml`

- Full-modal overlay (like other dialogs, `z` above the preferences card).
- Message: "Press the key combination you want to assign to **<label>**".
- A focusable `Item`/`StyledRect` with `Keys.onPressed`:
  - ignore modifier-only keys;
  - `Esc` → cancel;
  - otherwise `let s = ShortcutManager.sequenceFromKey(event.key, event.modifiers)`;
    if invalid, keep waiting; if not acceptable, show inline warning.
  - on success: check `ShortcutManager.conflicts(actionId, [s])`:
    - none → `addSequence`/`setSequences` and close;
    - conflicts → show conflict list with **Replace** / **Cancel**.
- While open, set `ShortcutManager.recording = true` so every `AppShortcut` is
  disabled and cannot swallow the keystroke. Reset to `false` on close/destroy.
- Buttons: **Cancel**, and **Clear** (remove existing binding in edit mode).

---

## 8. PreferencesModal integration

In `qml/components/dialogs/PreferencesModal.qml`:

1. Add to the `SlidingSelector` model:
   ```qml
   { tab: 4, label: qsTr("Shortcuts"), icon: "keyboard" }
   ```
2. Change `pagesRow.width` from `contentArea.width * 4` to `contentArea.width * 5`.
3. Append a fifth page:
   ```qml
   ShortcutsTab {
       width: contentArea.width
       height: contentArea.height
   }
   ```
   (The existing pages use `VerticalFadeFlickable`; `ShortcutsTab` should own its
   own flickable so the tab stays self-contained.)

Consider making the card a little wider (`760 → 820`) or the tab strip wrap if
5 labels feel cramped at the current width; verify on a narrow window.

---

## 9. Edge cases & policies

- **Recording isolation**: `ShortcutManager.recording` disables all
  `AppShortcut`s. Do not rely on focus alone — `Qt.ApplicationShortcut` fires
  globally.
- **Ambiguous shortcuts**: never leave two enabled shortcuts with the same
  sequence (the codebase already documents this hazard in `ATLAS.md` §8). The
  conflict check plus the recording gate prevents it. Show a warning chip if a
  user-imported config contains duplicates.
- **Bare printable keys**: warn (typing would trigger them). `Delete`, `Space`,
  F-keys and arrows are fine.
- **Invalid/`unknown` keys**: `sequenceFromKey` returns empty → recorder keeps
  waiting.
- **Normalisation**: compare with `QKeySequence` so `Ctrl++`/`Ctrl+=`,
  `Alt+Return`/`Alt+Enter` dedupe correctly.
- **Platform differences**: `Meta`/`Super` should be capturable; keep using
  portable `QKeySequence` text so `Ctrl` maps to `Cmd` on macOS automatically.
- **Reset semantics**: `resetAction` removes the override (reverts to defaults),
  it does not clear to "unbound". Provide an explicit **Clear/Unbind** inside the
  recorder for "no shortcut".
- **Persistence migration**: unknown IDs in stored JSON are dropped on load;
  newly added default actions simply have no override. No version bump needed.
- **View-local keys** (`/`, arrows, type-ahead, `Backspace`) and component-local
  shortcuts are **not** in this registry (Phase 1). Document this in the tab's
  intro text or an info row to avoid confusion.

---

## 10. Files to add / modify

**Add**

- `src/core/shortcutmanager.hpp`
- `src/core/shortcutmanager.cpp`
- `qml/components/AppShortcut.qml`
- `qml/components/settings/ShortcutsTab.qml`
- `qml/components/settings/ShortcutRow.qml`
- `qml/components/settings/KeyRecorderDialog.qml`

**Modify**

- `CMakeLists.txt` — add the two C++ sources; add the new QML files to
  `QML_FILES`.
- `src/main.cpp` — instantiate/register `ShortcutManager` if using
  `setContextProperty` (skip if using `QML_SINGLETON`).
- `qml/main.qml` — replace the ~45 `Shortcut {}` blocks with `AppShortcut {}`
  (`actionId` + preserved `onActivated`/`active`); merge duplicates.
- `qml/components/dialogs/PreferencesModal.qml` — add the 5th tab, widen
  `pagesRow`, append the `ShortcutsTab` page.
- `ATLAS.md` — update §7 (keybind reference) to note bindings are user-editable
  and point at the new tab.

---

## 11. Suggested implementation phases

1. **Data layer** — `ShortcutManager` (registry, load/save, `sequencesFor`,
   conflict, `sequenceFromKey`). Build and unit-check via a tiny QML harness or
   `qDebug`.
2. **Wrapper + refactor** — add `AppShortcut`, convert `main.qml`, verify the app
   still behaves identically with defaults (smoke test).
3. **Settings tab (read-only first)** — list actions grouped by category with
   their current sequences; no editing yet. Verify layout at 5 tabs.
4. **Recording + editing** — `KeyRecorderDialog`, add/remove/edit, per-action
   reset, conflict dialog.
5. **Reset All + search/filter + polish** — toolbar, empty states, confirm popup.
6. **Optional Phase 2** — import/export JSON, unbound actions list, expose a few
   view-local keys, "reset all shortcuts" from a menu.

---

## 12. Testing

- **Build**: `cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release && cmake --build build`.
- **QML smoke test (CI parity)**:
  `QT_QPA_PLATFORM=offscreen QT_LOGGING_TO_CONSOLE=1 timeout 20 ./build/bin/atlas "$HOME" > run.log 2>&1`
  and confirm no `QML` errors in `run.log`.
- **Manual matrix**:
  - defaults all fire exactly as before the refactor;
  - rebind `Ctrl+T` → `Ctrl+Shift+E`, confirm old combo stops and new works;
  - add a second binding to `view.refresh`;
  - record a combo already used by another action → conflict dialog → Replace;
  - reset one action; Reset All; restart app and confirm persistence/reversion;
  - while the recorder is open, confirm no global shortcut fires (e.g. typing
    `Ctrl+T`);
  - `Space` media preview still only fires when no modal is open;
  - Preferences still opens with `Ctrl+,` and closes cleanly.

---

## 13. Open decisions (defaults chosen, easy to change)

1. **Registry home**: C++ `ShortcutManager` (chosen) vs. a QML singleton.
   C++ matches the `QSettings` pattern and is easier to reset/validate.
2. **New folder**: keep the merged `Ctrl+Shift+N`, `F10`, `Shift+F10` (chosen) vs.
   splitting into two actions.
3. **Tab folder**: `qml/components/settings/` (chosen) vs. `dialogs/`.
4. **Bare-key policy**: warn but allow (chosen) vs. hard-reject.
5. **Import/export**: Phase 2 (chosen) vs. Phase 1.
