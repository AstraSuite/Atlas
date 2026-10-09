# ATLAS.md — Reference for porting Atlas behaviour into Wormhole

Wormhole's portal dialogs share their Material 3 QML component library and
`FileSystemModel`/`FileUtils` lineage with **Atlas**, the AstraSuite file
manager. When a dialog needs navigation behaviour (address bar, search,
type-ahead, view switching), the source of truth is the Atlas implementation,
not guesses.

- Atlas repo: `~/Projects/astrasuite/Atlas`
- Wormhole repo: `~/Projects/astrasuite/Wormhole`

This document records the Atlas architecture and the exact semantics of the
features we mirror, so future ports do not require re-reading the whole Atlas
tree.

---

## 1. What Atlas is

Atlas is a Qt 6 / QML Material Design 3 **file manager** with a built-in
**picker mode** (`atlas -p`) used as `xdg-desktop-portal`'s file chooser.
It is a single C++/QML app:

- Language/standard: C++20, Qt 6.5+ (Wormhole currently builds against Qt 6.12).
- Version: from latest `v*` git tag, else `0.<YYYYMMDD>` dev version.
- Build: `cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release && cmake --build build`
- Run manager: `./build/bin/atlas`
- Run picker: `./build/bin/atlas -p` (also `-s` save, `--directory-only`, `-f <ext>` filters)
- CI smoke test (no QML errors):
  `QT_QPA_PLATFORM=offscreen QT_LOGGING_TO_CONSOLE=1 timeout 20 ./build/bin/atlas "$HOME"`

### Directory structure

```
src/
  config/       theme, colours, tokens, fonts
  controllers/  TabManager etc.
  core/         FileUtils, FileOperations, MimeService, AppController, AppIntegration, ...
  models/       FileSystemModel (+ FileSystemEntry)
qml/
  main.qml      window, global Shortcuts, tab/split container
  components/
    navigation/ NavigationBar.qml      <- breadcrumbs / address / search
    views/      FileGridView, FileDetailsView, FileCompactView, EmptyStateView,
                SplitViewContainer
    filedialog/ FileDialog, HeaderBar, FolderContents, Sidebar, DialogButtons,
                CurrentItem, Sizes   <- picker mode
    controls/   buttons, fields, menus, ...
    containers/ lists/grids with fade edges (VerticalFadeListView/GridView)
    dialogs/    preferences, new item, properties, open-with, ...
    tabs/ panels/ statusbar/ menus/ effects/ media/ utils/
```

### Picker mode vs main window (important)

There are **two** file-listing UIs in Atlas:

| | Main window | Picker (`-p`) |
|---|---|---|
| Navigation | `components/navigation/NavigationBar.qml` (breadcrumbs → address → search) | `components/filedialog/HeaderBar.qml` (breadcrumbs only) |
| Views | grid / details / compact, full key handling, **type-ahead** | simpler `FolderContents.qml` |
| Tabs / split | yes | no |

So Atlas' *own picker* does **not** have type-ahead or an editable address bar.
The behaviour we port into Wormhole's picker comes from the **main window**
(`NavigationBar` + the three views). This is the key thing to remember.

---

## 2. Shared lineage with Wormhole

Wormhole duplicates most of Atlas' Material 3 component library under
`qml/components/**`. Names and tokens largely match:

- `StyledRect`, `StyledText`, `MaterialIcon`, `StateLayer`, `StyledToolTip`,
  `StyledScrollBar`, `CachingIconImage`, `IconButton`, `SearchBar`, ...
- `Colours.palette.*` / `Colours.tPalette.*` and `Tokens.*` (padding, spacing,
  rounding, font builders, anim) are the same scheme.
- `FileSystemModel` lives at `src/models/filesystemmodel.{hpp,cpp}` in both and
  exposes the same navigation API.
- `FileUtils` exposes the same navigation helpers in both.

When porting a widget, prefer copying Atlas' structure and only renaming the
module import (`import atlas` → `import wormhole`) and adapting selection state
(Atlas uses tab/split models, Wormhole uses `dialog.cwd` + `fsModel`).

---

## 3. NavigationBar (`qml/components/navigation/NavigationBar.qml`)

The single most important component to understand. It is one rounded bar that
switches between three mutually exclusive modes:

1. **Breadcrumbs** (idle) — `/`-separated path segments, horizontally flickable,
   pinned to the end.
2. **Editable address bar** — `isEditingPath === true`.
3. **Search** — `isSearching === true`.

State properties:

```qml
property bool isEditingPath: false
property bool isSearching: false
property bool isFiltering: false          // pattern filter (Ctrl+S)
property string searchText: ""
property string filterText: ""
property var pathSuggestions: []
property int selectedSuggestionIndex: -1
property bool showSuggestions: false
readonly property string ghostCompletionText: ""   // inline completion hint
```

Key functions:

- `openAddressEdit()` — `isEditingPath = true`, prefill `pathInput.text` with the
  current path, focus and `selectAll()`, `updateSuggestions()`.
- `openSearch(initialChar)` — `isSearching = true`; if `initialChar` given, seed
  the search field with it and emit `searchRequested(initialChar)`, else
  `selectAll()`; then focus the search input.
- `updateSuggestions()` — `FileUtils.getPathSuggestions(pathInput.text, cwd)`.
- `applySuggestion(index)` — fill the field with the suggestion; if it's a dir,
  refresh suggestions, else hide the dropdown.
- `commitPath(customText)` — resolve via `FileUtils.expandPath(text, cwd)` and
  navigate; also handles `sftp:// smb:// ftp:// ssh://` URLs and custom
  protocols. Clears `showSuggestions`/`isEditingPath`.
- `ghostCompletionText` — `FileUtils.getCompletedPath(text, cwd)`, the remainder
  after the typed text, rendered dimmed; Tab or → accepts it.

Signals: `togglePreview()`, `toggleTerminal()`, `createNewFolder()`,
`createNewFile()`, `reload()`, `searchRequested(string)`,
`filterRequested(string)`, `preferencesRequested()`,
`specialProtocolInvoked(int)`.

Breadcrumb behaviour:

- Each segment is a `StyledRect` pill; the **last (active) segment** and the
  **blank area after the crumbs** open the address bar (`openAddressEdit()`).
- Any earlier segment navigates to that prefix.

Search field:

- `onTextChanged` → `searchRequested(text)`.
- `Esc` clears and closes search.
- Search icon in the bar closes/reopens; tooltip `Search (Ctrl+F)`.

Layering: the bar raises its `z` (to 500) while the suggestion dropdown is open
so the popup paints over the file view. The popup itself is a `StyledRect`
containing a `ListView` of `{ displayPath, isDir, icon }`.

### Global shortcuts that drive it (`qml/main.qml`)

```qml
Shortcut { sequences: ["Ctrl+F", "F9", "Shift+F9"]; onActivated: navBar.openSearch() }
Shortcut { sequence: "Ctrl+L"; onActivated: navBar.openAddressEdit() }
Shortcut { sequence: "Alt+D";  onActivated: navBar.openAddressEdit() }
```

Wormhole mirrors these in `FileDialog.qml`. `Esc` is special: while a text input
is active it must close the input, not reject the dialog. Wormhole keeps a
dedicated `Esc` shortcut that is only enabled while `isTextInputActive`, and the
global reject shortcut is disabled in exactly that state (never both enabled, or
Qt reports an ambiguous shortcut and neither fires — see the warning comment in
`FileDialog.qml`).

---

## 4. File views and key handling

Three views, each a self-contained component with its own `Keys.onPressed`:

- `FileGridView` (root is a `GridView`)
- `FileDetailsView` (list)
- `FileCompactView`

Common structure of `Keys.onPressed` (from `FileGridView`):

```qml
if (event.modifiers === Qt.NoModifier || event.modifiers === Qt.KeypadModifier) {
    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { open current }
    else if (event.key === Qt.Key_Left  || (AppController.vimMotions && event.key === Qt.Key_H)) { move left }
    else if (event.key === Qt.Key_Down  || (AppController.vimMotions && event.key === Qt.Key_J)) { move down }
    else if (event.key === Qt.Key_Up    || (AppController.vimMotions && event.key === Qt.Key_K)) { move up }
    else if (event.key === Qt.Key_Right || (AppController.vimMotions && event.key === Qt.Key_L)) { move right }
    else if (event.key === Qt.Key_Slash) { navBar.openSearch("") }        // "/" opens search
    else if (event.key === Qt.Key_Backspace) { go up }
}
if ((event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)
        && event.text.length > 0) {
    let ch = event.text, code = ch.charCodeAt(0);
    if (code >= 32 && ch !== ' ') { handleTypeAhead(ch); event.accepted = true; }
}
```

Notes:

- **Vim motions** (H/J/K/L) are gated behind `AppController.vimMotions`
  (persisted in `preferences/vimMotions`, default `true`, toggled in
  `PreferencesModal`). They are optional aliases for the arrow keys.
- **`/` opens search** — it is handled in the views, not as an application
  shortcut, precisely so it does not fire while typing in a text field.
- **Type-ahead** is the trailing `event.text` branch; any printable, non-space
  character (including `.`, `-`, `_`, names with dots, etc.) triggers it.

---

## 5. Type-ahead algorithm (canonical semantics)

Defined identically in `FileGridView`, `FileDetailsView`, `FileCompactView`.
Replicate this exactly.

```qml
property string typeAheadBuffer: ""

Timer {
    id: typeAheadTimer
    interval: 800
    repeat: false
    onTriggered: root.typeAheadBuffer = ""
}

function handleTypeAhead(text) {
    if (!root.model || root.model.count === 0) return;
    typeAheadTimer.restart();

    // Repeating the same single key cycles through matches starting with it,
    // instead of building a two-letter prefix.
    let isSingleCharRepeat = (text.length === 1
        && root.typeAheadBuffer.length === 1
        && root.typeAheadBuffer.toLowerCase() === text.toLowerCase());

    let startIndex = 0;
    if (isSingleCharRepeat) {
        startIndex = view.currentIndex + 1;   // next occurrence
    } else {
        root.typeAheadBuffer += text;         // extend the prefix
    }

    let matchIdx = -1;
    if (root.model.findFirstIndexByPrefix) {
        matchIdx = root.model.findFirstIndexByPrefix(root.typeAheadBuffer, startIndex);
    }
    if (matchIdx !== -1) {
        view.currentIndex = matchIdx;
        view.positionViewAtIndex(matchIdx, GridView.Contain); // ListView.Contain for lists
    }
}
```

Behavioural summary:

- Press `x` → jump to the first entry whose name starts with `x` (case-insensitive).
- Press `x` again within 800 ms → jump to the **next** entry starting with `x`
  (wraps around at the end).
- Type quickly `fo` → jump to an entry starting with `fo`; the buffer resets
  after 800 ms of inactivity.
- The lookup wraps (`findFirstIndexByPrefix` scans `startIndex..end` then wraps to
  the beginning).

`FileSystemModel.findFirstIndexByPrefix(prefix, startIndex = 0)` is the model
side; it is `Q_INVOKABLE` and returns `-1` when nothing matches.

---

## 6. Model + helpers API (identical in Atlas and Wormhole)

`FileSystemModel` (relevant subset):

```cpp
Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
Q_PROPERTY(QString searchQuery READ searchQuery WRITE setSearchQuery NOTIFY searchQueryChanged)
Q_PROPERTY(bool isSearching READ isSearching NOTIFY isSearchingChanged)
Q_PROPERTY(bool showHidden READ showHidden WRITE setShowHidden ...)
Q_PROPERTY(SortField sortField ...)  // SortByName/Size/Type/Date
Q_PROPERTY(Qt::SortOrder sortOrder ...)
Q_PROPERTY(int count READ count NOTIFY countChanged)

Q_INVOKABLE FileSystemEntry* get(int index) const;
Q_INVOKABLE int indexOfPath(const QString& path) const;
Q_INVOKABLE int findFirstIndexByPrefix(const QString& prefix, int startIndex = 0) const;
Q_INVOKABLE void refresh();
```

`setSearchQuery("")` cancels search and rescans the directory; a non-empty query
runs `performSearch(path, query)` recursively (case-insensitive substring,
capped at 500 results) on a worker thread and discards stale results.

> **Wormhole divergence:** its `performSearch` prunes hidden directories at
> traversal time when `showHidden` is off (Atlas returns matches from inside
> hidden dirs and only filters the entries afterwards), and it does not follow
> directory symlinks (see `fix_in_atlas.md` items 1–2).

`FileUtils` navigation helpers (all `Q_INVOKABLE static`):

- `expandPath(input, currentDir)` — `~`, `~user`, `$VAR`, relative paths; cleans
  and preserves a trailing slash.
- `getPathSuggestions(input, currentDir)` — up to 30 entries; each item is
  `{ displayPath, isDir, icon }`; respects `~/`, `$VAR`, relative prefixes.
- `getCompletedPath(input, currentDir)` — the full completion of `input`, or the
  longest common prefix of its suggestions.

---

## 7. Atlas global keybind reference (`qml/main.qml`)

Navigation / search:

| Keys | Action |
|------|--------|
| `Alt+Left` / `Alt+Right` | Back / forward |
| `Alt+Up` | Go to parent |
| `Alt+Home` | Home |
| `Ctrl+F`, `F9`, `Shift+F9` | Open search |
| `Ctrl+L`, `Alt+D` | Edit address bar |
| `/` | Open search (handled inside the views) |
| any printable | Type-ahead jump-to-name (inside the views) |
| `Backspace` | Go up (inside the views) |

Views / selection:

| Keys | Action |
|------|--------|
| `Ctrl+1` / `Ctrl+2` / `Ctrl+3` | Grid / details / compact |
| `Ctrl+A` / `Ctrl+Shift+A` / `Ctrl+D` | Select all / clear / clear |
| `Ctrl+I` | Invert selection |
| `Ctrl+S` | Select by pattern (filter) |
| `Space` | Preview media |
| `Enter` / `Right` | Open |
| `F1` / `Alt+P` | Toggle preview panel |
| `F3` | Toggle split |
| `F5` / `Ctrl+R` | Refresh |
| `Ctrl+=` / `Ctrl++` / `Ctrl+-` / `Ctrl+0` | Zoom in / in / out / reset |

Files:

| Keys | Action |
|------|--------|
| `Ctrl+T` / `Ctrl+W` | New tab / close tab (or split pane) |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Next / previous tab |
| `Ctrl+C` / `Ctrl+X` / `Ctrl+V` | Copy / cut / paste |
| `Delete` / `Shift+Delete` | Trash / permanent delete |
| `F2` | Rename |
| `Alt+Return` | Properties |
| `Ctrl+H` / `Alt+.` | Toggle hidden files |
| `Ctrl+Z` / `Ctrl+Shift+Z` / `Ctrl+Y` | Undo / redo |
| `F4`, `Ctrl+Alt+T`, `` Ctrl+` `` | Open terminal |
| `Ctrl+,` | Preferences |

---

## 8. Porting notes / gotchas

- **Pick from the main window, not Atlas' picker** — type-ahead and the editable
  address bar exist only in the main-window views/NavigationBar.
- **`z` ordering** — the address suggestion dropdown must paint above the file
  view. Raise the bar's `z` while suggestions are open and make sure no ancestor
  clips.
- **`Esc` ambiguity** — never let two enabled shortcuts share a sequence. Gate the
  dialog-level `Esc` on "text input active" and disable the global reject `Esc`
  in the same condition.
- **`/` must be view-local** — implementing it as an application shortcut would
  steal `/` from the address/search fields.
- **Type-ahead buffer resets after 800 ms**; the same key twice cycles, it does
  not form a prefix.
- **Search results can live anywhere** — when opening a result folder, navigate
  by its absolute path and clear the search, don't append its name to the cwd.
- **Selection model differs** — Atlas uses `splitContainer.selectedPaths` and
  multi-select; Wormhole's picker is single-select (`folderContents.currentItem`).
  Port behaviour, not storage.
