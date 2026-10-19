# Navigation

How a user moves around: the navigation bar at the top of each pane, and the three file
views below it.

## The navigation bar

`qml/components/navigation/NavigationBar.qml` is one rounded bar with three mutually
exclusive modes:

1. **Breadcrumbs**, when idle. Each path segment is a pill; clicking an earlier one
   navigates there. Clicking the last segment, or the empty space after the crumbs, opens
   the address editor.
2. **Address editor** (`isEditingPath`), opened with `Ctrl+L` or `Alt+D`.
3. **Search** (`isSearching`), opened with `Ctrl+F`, `F9` or `/` in a view.

Opening one mode closes the other, so `Ctrl+L` during a search never reveals a stale
address editor.

### Address editor

`openAddressEdit()` fills the field with the current path and selects it. As the user
types, `FileUtils` does the work:

- `getPathSuggestions(input, cwd)` returns up to 30 `{ displayPath, isDir, icon }` entries
  for the dropdown. `~`, `~user`, `$VAR` and relative paths are understood.
- `getCompletedPath(input, cwd)` returns the full completion, or the longest common prefix
  of the suggestions. The remainder is drawn dimmed after the cursor; `Tab` or `→` accepts
  it.
- `expandPath(input, cwd)` resolves the final text when `commitPath()` navigates.

`commitPath()` also accepts `sftp://`, `smb://`, `ftp://` and `ssh://` addresses, which
are handed to `NetworkManager` to mount, and `atlas://` addresses (see
[Architecture](architecture.md#easter-eggs)).

While the dropdown is open the bar raises its `z` to 500 so the popup paints over the file
view. Anything that wraps the bar must not clip it.

### Search

Typing in the search field sets `FileSystemModel.searchQuery`. A non-empty query runs
`performSearch` on a worker thread: a case-insensitive substring match on file names, from
the current folder down, capped at 500 results. The walk skips hidden directories unless
hidden files are shown, and never follows directory symlinks, which would loop forever in
places like Wine prefixes. Results from an outdated query are dropped.

In the search field:

| Key | Effect |
|-----|--------|
| `Enter` | Select the first result and focus the view. |
| `↓` / `↑` | Focus the view and step the selection. |
| `Esc` | Close the field and focus the results. The query stays until it is cleared. |
| `Backspace` on an empty field | Close the search. |
| `/` | Ignored, so the key that opened search never lands in the query. |

Navigating to another folder or switching tabs clears the search. Results can come from
any subfolder, so opening a result navigates by its absolute path.

`Ctrl+S` opens a separate pattern filter (`isFiltering`) that selects items matching a
wildcard pattern in the current folder.

## The file views

`SplitViewContainer` shows one view per pane, chosen by the tab's view mode:

| View | File | Root item |
|------|------|-----------|
| Grid (`Ctrl+1`) | `views/FileGridView.qml` | `GridView` |
| Details (`Ctrl+2`) | `views/FileDetailsView.qml` | `ListView` with resizable, reorderable columns |
| Compact (`Ctrl+3`) | `views/FileCompactView.qml` | `ListView` |

Each view handles its own keys in `Keys.onPressed`, and the three implementations are
kept in step by hand. A change to selection, key handling or drag behaviour in one view
almost always needs to go into the other two.

### Keys inside a view

These are not in the shortcut registry, because they must not fire while a text field has
focus:

| Key | Effect |
|-----|--------|
| Arrows, or `H` `J` `K` `L` with *Vim motions* on | Move the current item. |
| `Enter`, `→` | Open the current item. |
| `Backspace` | Go to the parent folder, or close an active search. |
| `/` | Open search. |
| `Space` | Preview the selected image or video in the media viewer. |
| Any other printable key | Type-ahead. |

Vim motions are on by default (`preferences/vimMotions`) and can be turned off in
Preferences.

### Type-ahead

Each view keeps a `typeAheadBuffer` that a timer clears after 800 ms without a key:

- A new character extends the buffer, and the view jumps to the first name starting with
  it (case-insensitively).
- Pressing the same single key again cycles to the next name starting with that letter
  instead of building a two-letter prefix.
- The lookup is `FileSystemModel.findFirstIndexByPrefix(prefix, startIndex)`, which wraps
  around to the top and returns `-1` when nothing matches.

### Mouse

Single or double click to open is a preference (`session/singleClick`). Dragging on empty
space draws a rubber band; with *drag to scroll* on (`session/dragToScroll`), dragging
scrolls the view instead. A drag that starts on an item respects the current selection:
it drags all selected items, or only that one if it wasn't selected.

## Tabs and splits

`TabManager` holds the tabs; each `TabItem` has its own path, back/forward history and
view mode. `F3` splits the current tab into two panes, each with its own model and view;
`Ctrl+W` closes the focused pane first, then the tab. Tabs are restored at startup when
*restore tabs* is on, from `session/tabPaths` and `session/currentTab`.
