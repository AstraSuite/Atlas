# File operations

`core::FileOperations` (exposed to QML as `FileOperations`) does everything that changes
files: copy, move, rename, create, trash, delete, archives and the clipboard. It owns the
undo stack and the progress object the operations modal and status bar watch.

## Running an operation

Long operations (copy, move, delete, archives) run through `QtConcurrent::run`. They
report through `FileOperationProgress` (`progress`, `statusText`, `running`) and finish with
`operationFinished(success, message)`. `cancelOperation()` sets a flag that the copy loop
checks between files.

Copy and move have three engines, chosen in Preferences (`transferEngine`):

| Engine | Behaviour |
|--------|-----------|
| Standard | Atlas copies files itself, with byte-level progress. Symlinks are copied as links. |
| Rsync | Runs `rsync -avh --progress --checksum`. Needs `rsync` installed. |
| Custom | Stores a user command (`customCommand`). Copy and move don't use it yet and behave as Standard. |

A move inside one filesystem is a rename. Moving or copying a folder into itself, or onto
itself, is refused before anything starts.

## Clipboard

Atlas uses the system clipboard so copy and paste work with other file managers:

- Copying writes `text/uri-list` and, for cut, `application/x-kde-cutselection` set to
  `1`, which Dolphin and other KDE apps understand.
- Before reading, `syncFromSystemClipboard()` picks up whatever another app put there:
  file URLs, the cut flag, and image data.
- `Ctrl+V` (`window.pasteFromClipboard()` in `main.qml`) pastes files when there are any.
  A cut is moved and the clipboard cleared; a copy can be pasted again.

### Pasting an image

When the clipboard holds an image and no files (a screenshot, an image copied from a
browser), `Ctrl+V` writes it as a PNG:

1. `syncFromSystemClipboard()` reads the image from `QMimeData::imageData()`, or from the
   first of `image/png`, `image/jpeg`, `image/bmp`, `image/gif`, `image/webp` that
   decodes, and keeps it PNG-encoded.
2. `pasteImage(dir)` writes `image.png`, or `image (1).png`, `image (2).png` and so on,
   never overwriting a file.
3. `main.qml` opens the rename dialog on the new file, as Dolphin does.

## Trash

Trashing follows the [FreeDesktop trash spec](https://specifications.freedesktop.org/trash-spec/latest/):

- `TrashLocations::forSourceFile` picks the trash for the file's volume: the home trash
  (`~/.local/share/Trash`) for the home filesystem, `$topdir/.Trash/$uid` or
  `$topdir/.Trash-$uid` on other mounts.
- Each file gets a `.trashinfo` with its original path and deletion date, so other file
  managers can restore it and Atlas can restore theirs.
- Deleting from inside the trash deletes permanently.
- `confirmMoveToTrash` and `confirmPermanentDelete` in Preferences decide whether a
  confirmation dialog is shown first.

## Undo

Undoable operations push an `UndoAction` onto the undo stack: rename, bulk rename, create
file, create folder, move and move to trash. `undo()` reverses the latest one (a trash is
undone by restoring from its `.trashinfo`) and moves it to the redo stack. Any new
operation clears the redo stack. Copies and permanent deletes cannot be undone;
`UndoAction::Copy` exists but nothing records it yet.

## Other operations

- **New file and templates:** `createFile`, `createDirectory`, and `createFromTemplate`
  for files in the XDG templates folder (`~/Templates`), which `FileUtils.templates()`
  lists for the New menu.
- **Duplicate and symlinks:** `duplicateFile` creates `name (copy).ext`.
  `pasteAsSymlink` links the clipboard's files into a folder.
- **Archives:** `extractArchive` picks `unzip`, `tar` (gz, xz, zst, bz2) or `7z` from the
  file name. `createArchive` runs `zip`, `tar` or `7z` for the chosen format.
- **Uploads:** `uploadToCatbox` and `uploadToLitterbox` hand files to `CatboxUploader`,
  which copies the link to the clipboard when it's done.
- **Dragging out:** `startNativeDrag` starts a real drag with `text/uri-list`, so files can
  be dropped into other applications. Drops onto Atlas show `DropActionMenu`: move, copy,
  link, or move into a new folder.
