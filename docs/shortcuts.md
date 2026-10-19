# Shortcuts

Every global shortcut in Atlas can be rebound from Preferences → Shortcuts. This page
describes how the registry works, which keys are deliberately left out of it, and how to
add an action.

## How it fits together

```
ShortcutManager (C++)          AppShortcut (QML)               main.qml
  id → default keys      ──▶     actionId: "edit.paste"   ──▶    onActivated: paste…
  + user overrides               sequences from bindings
```

- `src/core/shortcutmanager.cpp` holds the registry: for every action a stable id, label,
  description, category, Material Symbols icon and default key sequences. The order of
  `defaultActions()` is the order of the settings page.
- `qml/components/AppShortcut.qml` wraps a Qt `Shortcut` with
  `context: Qt.ApplicationShortcut`. It takes an `actionId`, reads its sequences from
  `ShortcutManager.bindings`, and has an `active` property for extra gating, such as "no
  modal is open".
- The behaviour stays in `qml/main.qml`, in each `AppShortcut`'s `onActivated`. The
  registry only knows about keys.

`ShortcutManager.bindings` maps every id to its effective sequences: the user's override
if there is one, otherwise the defaults. Sequences are stored as
`QKeySequence::PortableText`, so `Ctrl+Shift+N` reads the same everywhere.

## Persistence

Only overrides are saved, as compact JSON under `shortcuts/bindings` in
`~/.config/astra-atlas/atlas.conf`:

```ini
[shortcuts]
bindings={"file.newFolder":["Ctrl+Shift+N"],"tools.terminal":["F4"]}
```

Setting an action back to exactly its defaults removes its override, and resetting
everything removes the key. A default that changes in a later release therefore reaches
every user who hasn't customised that action.

## Recording keys

`ShortcutsTab.qml` lists the actions by category, with one `ShortcutRow` each.
`KeyRecorderDialog.qml` captures a new combination:

1. Opening the recorder sets `ShortcutManager.recording`, which empties every
   `AppShortcut`'s sequences so none of them fire while the user presses keys.
2. `sequenceFromKey(key, modifiers)` turns the press into portable text and ignores a
   lone modifier.
3. `conflicts(id, [seq])` lists other actions already using it. The user can cancel or
   take the key over, which calls `reassign` to remove it from the others.
4. A bare printable key (`isBareKey`, such as `A` or `.` with no modifier) would steal
   typing in the views, so it needs an explicit confirmation.
5. The result replaces the action's keys (`setSequences`) or is added to them
   (`addSequence`).

`Esc` cancels the recorder, so it can't be recorded.

## Keys outside the registry

Some keys are handled inside a component rather than as application shortcuts, because
they must not fire while a text field has focus or only make sense in one place:

- In the file views: arrows and Vim motions, `Enter`, `Backspace`, `/` and type-ahead.
  See [Navigation](navigation.md#keys-inside-a-view).
- In the address and search fields: `Tab`, `Enter`, `Esc`, the arrows.
- In modals and overlays: the media viewer, the drop action menu, the runner game and the
  bloom overlay each handle their own keys.

## Adding an action

1. Add an entry to `defaultActions()` in `src/core/shortcutmanager.cpp`, in the category
   it belongs to. Ids are `<category>.<camelCase>` and must never change once released,
   since saved overrides refer to them.
2. Add an `AppShortcut` to `qml/main.qml` with that `actionId` and the behaviour in
   `onActivated`. Set `active` if it must not fire while a modal is open.
3. Check the new default doesn't collide with an existing one or with a key the views
   handle themselves.

The settings page picks up the new entry on its own.

## Defaults

### Application

| Action | Id | Default keys |
|--------|----|--------------|
| Open Preferences | `app.preferences` | `Ctrl+,`, `Ctrl+.` |
| Toggle Full Screen | `app.fullscreen` | `F11`, `Shift+F11` |

### Navigation

| Action | Id | Default keys |
|--------|----|--------------|
| Go Back | `nav.back` | `Alt+Left` |
| Go Forward | `nav.forward` | `Alt+Right` |
| Go to Parent Folder | `nav.parent` | `Alt+Up` |
| Go Home | `nav.home` | `Alt+Home` |
| Search | `nav.search` | `Ctrl+F`, `F9`, `Shift+F9` |
| Edit Location | `nav.address` | `Ctrl+L`, `Alt+D` |

### Tabs

| Action | Id | Default keys |
|--------|----|--------------|
| New Tab | `tabs.new` | `Ctrl+T` |
| Close Tab / Pane | `tabs.close` | `Ctrl+W` |
| Next Tab | `tabs.next` | `Ctrl+Tab` |
| Previous Tab | `tabs.previous` | `Ctrl+Shift+Tab` |

### File Operations

| Action | Id | Default keys |
|--------|----|--------------|
| New File | `file.newFile` | `Ctrl+N` |
| New Folder | `file.newFolder` | `Ctrl+Shift+N`, `F10`, `Shift+F10` |
| Rename | `file.rename` | `F2`, `Shift+F2` |
| Move to Trash | `file.trash` | `Delete` |
| Delete Permanently | `file.deletePermanent` | `Shift+Delete` |
| Properties | `file.properties` | `Alt+Return` |

### Editing

| Action | Id | Default keys |
|--------|----|--------------|
| Copy | `edit.copy` | `Ctrl+C` |
| Cut | `edit.cut` | `Ctrl+X` |
| Paste | `edit.paste` | `Ctrl+V` |
| Undo | `edit.undo` | `Ctrl+Z` |
| Redo | `edit.redo` | `Ctrl+Shift+Z`, `Ctrl+Y` |

### Selection

| Action | Id | Default keys |
|--------|----|--------------|
| Select All | `edit.selectAll` | `Ctrl+A` |
| Clear Selection | `edit.clearSelection` | `Ctrl+Shift+A`, `Ctrl+D` |
| Invert Selection | `edit.invertSelection` | `Ctrl+I` |
| Select by Pattern | `edit.selectByPattern` | `Ctrl+S` |

### View

| Action | Id | Default keys |
|--------|----|--------------|
| Grid View | `view.grid` | `Ctrl+1` |
| Details View | `view.details` | `Ctrl+2` |
| Compact View | `view.compact` | `Ctrl+3` |
| Show Hidden Files | `view.toggleHidden` | `Ctrl+H`, `Alt+.` |
| Toggle Split View | `view.split` | `F3`, `Shift+F3` |
| Refresh | `view.refresh` | `F5`, `Shift+F5`, `Ctrl+R` |
| Toggle Preview Panel | `view.previewPanel` | `F1`, `Shift+F1`, `Alt+P` |
| Preview Media | `view.previewMedia` | `Space` |
| Zoom In | `view.zoomIn` | `Ctrl+=`, `Ctrl++` |
| Zoom Out | `view.zoomOut` | `Ctrl+-` |
| Reset Zoom | `view.zoomReset` | `Ctrl+0` |

### Tools

| Action | Id | Default keys |
|--------|----|--------------|
| Open in Terminal | `tools.terminal` | `F4`, `Shift+F4`, `Ctrl+Alt+T`, `` Ctrl+` `` |
