# fix_in_atlas.md — Bugs & gaps found in Atlas (fixed in Wormhole only)

Reference: `ATLAS.md`. While porting Atlas behaviour into Wormhole's portal
file chooser, the following real bugs / gaps in Atlas were found. Per project
rules, fixes were implemented **only** in Wormhole — nothing here has been
pushed back to Atlas yet.

Each entry lists: the Atlas location, the problem, evidence, and what Wormhole
did instead.

---

## 1. Search descends into hidden directories even when "show hidden" is off

- **File:** `src/models/filesystemmodel.cpp` — `FileSystemModel::performSearch`
  (around line 582 in Atlas).
- **Problem:** the search iterator is created with `QDir::Hidden` always set and
  `QDirIterator::Subdirectories`:
  ```cpp
  QDirIterator it(rootPath, QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden,
                  QDirIterator::Subdirectories);
  ```
  Hidden entries are only removed from the *results* afterwards, in
  `filterAndSortOnly` (`if (!m_showHidden && e->isHidden()) continue;`). The
  traversal itself still descends into every hidden folder, so files **inside**
  `~/.config`, `~/.local/state/...`, the Trash, caches, etc. match and show up.
- **Evidence (searching "something" from `~/`):** results include
  `~/.local/state/nvim/undo/%home%…%something.txt`,
  `~/.local/share/Trash/info/something.trashinfo`,
  `~/.local/share/Trash/files/something`, i.e. files living inside hidden dirs.
- **Wormhole fix:** `performSearch` now walks the tree manually with an
  iterative stack, adding `QDir::Hidden` only when `m_showHidden` is set, so
  hidden directories are pruned at traversal time. Searching "something" from
  `~/` now returns exactly the 5 visible matches.

## 2. Directory symlink cycles can flood the results

- **Related to item 1** — the manual traversal must mirror
  `QDirIterator::Subdirectories`, which **does not follow directory symlinks**.
  A naive recursive/stack walk *does* follow them (a symlink dir reports
  `isDir() == true`) and Wine prefixes (`.../prefix/pfx/…/dosdevices/z:/…`)
  then re-emit the same files dozens of times and can take minutes.
- **Wormhole fix:** descend only when `fi.isDir() && !fi.isSymLink()`.

## 3. No keyboard path from the search field into the results

- **File:** `qml/components/navigation/NavigationBar.qml` — the `searchInput`
  (a `TextInput`) has only `onTextChanged` (fires `searchRequested`) and
  `Keys.onEscapePressed`. The Enter / Down / Up handlers in that file
  (lines 467–494) belong to the **address** `pathInput`, not search.
- **Problem:** while the search field is focused:
  - `Enter` does nothing (cannot select/act on the first result);
  - `↑` / `↓` only move the text caret in the field, so results cannot be
    navigated with the keyboard at all;
  - `Esc` (and the × button) **cancel the query entirely**
    (`searchRequested("")`), so there is no way to keep results and hand focus
    to the view. Keyboard-only users can never reach a search result.
- **Wormhole fix:** in the portal picker the search input now handles
  `Enter`→ select first match in the view, `↓`/`↑`→ focus the view and step the
  selection, `Esc`→ close search *and restore focus to the results view*
  (query stays until explicitly cleared), and stray `/` is consumed so it never
  leaks into the query.

## 4. Picker mode (`-p`) lacks the main-window navigation features

- **Files:** `qml/components/filedialog/*` (`HeaderBar.qml`, `FolderContents.qml`)
  vs `qml/components/navigation/NavigationBar.qml` + `qml/components/views/*`.
- **Problem:** Atlas's own picker mode is a much weaker file chooser than its
  main window:
  - `HeaderBar.qml` is breadcrumbs-only — no editable address bar, no path
    suggestions / ghost completion, no search field, no `Ctrl+L`/`Ctrl+F`,
    clicking the active crumb or the blank area does not open an address editor;
  - `FolderContents.qml` has no type-ahead and no `/` quick-search (grep for
    `typeAhead | Key_Slash | vimMotions` in `qml/components/filedialog/` is
    empty).
- **Wormhole fix:** the portal picker ports the main-window behaviour: editable
  address bar with suggestions + ghost completion (`Ctrl+L`/`Alt+D`), search
  (`Ctrl+F`/`F9`/`Shift+F9` *and* `/`), type-ahead with same-key cycling, and
  crumb/blank-click editing.
