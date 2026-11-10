# Architecture

Atlas is one binary, `atlas`, written in Rust on Qt 6 through [cxx-qt](https://github.com/KDAB/cxx-qt).
Rust owns the filesystem, processes, settings and system integration; QML owns every pixel.
This page describes how the two halves meet.

## Layout

| Path | Contents |
|------|----------|
| `src/main.rs`, `src/cli.rs` | Command-line parsing, application and engine setup. |
| `src/bridge/` | Every QObject QML sees, one `#[cxx_qt::bridge]` per file: the services, `FileSystemModel`, `TabManager`, `Colours`. cxx-qt-build only accepts one source directory per QML module, so all bridges live here. |
| `src/bridge/native.rs` | The bridge to `native/qthelpers.h`, plus helpers for strings, JSON to `QVariant`, settings and MIME lookups. |
| `src/bridge/registry.rs` | Pointers to the singletons that other services call. |
| `src/core/` | Plain Rust with no Qt types: paths and XDG dirs, mounts, the trash spec, recent files, desktop entries and process launching, EXIF, the inotify watcher, listing rows, and the blocking file operations. |
| `native/theme/` | `Tokens` and the font builders, in C++: they expose `QEasingCurve` and `QFont` gadget values, which cxx-qt cannot express. See [Theming](theming.md). |
| `native/providers/` | The `image://icon` and `image://thumb` image providers, in C++. |
| `native/qthelpers.*` | The Qt facilities Rust calls into: `QSettings`, the MIME database, theme icons, `QLocale` dates, `QKeySequence`, the clipboard and native drags. |
| `native/register.cpp` | Installs the image providers and the `Tokens` singleton on the engine. |
| `build.rs` | Compiles every `.qml` file into the `atlas` QML module and embeds the assets, at the same `qrc:/qt/qml/atlas/...` paths the old CMake build used. |
| `qml/main.qml` | The window, the tab/split container, every modal, and the global shortcuts. |
| `qml/components/` | The component library and the feature UI, grouped by folder (`views`, `navigation`, `dialogs`, `menus`, `panels`, `media`, `settings`, `controls`, `containers`). |
| `assets/` | Fonts, the icon, the desktop entry and the Material Symbols name list. |

## Startup

`main.rs` parses the command line, sets a 32-bit RGBA surface format (to avoid RGB565
banding), creates the application, copies settings from the old `prism` organisation on
first run, and registers the bundled fonts. It then installs the image providers and
`Tokens` on the engine and loads `qrc:/qt/qml/atlas/qml/main.qml`.

| Option | Effect |
|--------|--------|
| `[path]` | Open this folder, or the folder containing this file. `file://` URLs work. |
| `-d`, `--directory <dir>` | Same, as an option. |
| `--hidden` | Show hidden files, and remember it. |
| `--light`, `--dark` | Force a palette instead of following KiiteShell's or Caelestia's scheme. |
| `--tty` | Use the TTY look for this run. See [Theming](theming.md#tty). |

The options are kept in `cli::options()`. Services read them as the QML engine creates
them: `TabManager` opens the given folder in its current tab, `AppController` applies
`--hidden`, and `Colours` applies `--light`/`--dark` and `--tty`.

## Exposing Rust to QML

Every service is a QML singleton in the `atlas` module (`#[qml_element]` and
`#[qml_singleton]`), created by the engine the first time QML uses it. QML files reach
them with `import atlas`:

| Name | Bridge | Role |
|------|--------|------|
| `AppController` | `appcontroller.rs` | Preferences and remembered UI state. |
| `TabManager` | `tabmanager.rs` | Tabs, splits, the current path of each pane. |
| `FileOperations` | `fileoperations.rs` | Copy, move, trash, clipboard, undo, archives. See [File operations](file-operations.md). |
| `FileUtils` | `fileutils.rs` | Formatting, path expansion and completion, MIME and icon lookup. |
| `AppIntegration` | `appintegration.rs` | Opening and running files, terminals, custom actions, Papirus. See [Opening files](opening-files.md). |
| `PlacesModel` | `placesmodel.rs` | The sidebar's places and bookmarks. |
| `DriveManager` | `drivemanager.rs` | Drives and partitions through `udisks2`. |
| `NetworkManager` | `networkmanager.rs` | SFTP, SMB, FTP, NFS and WebDAV mounts through `gio`/GVFS. |
| `MediaTools` | `mediatools.rs` | `ffmpeg` and ImageMagick conversions. |
| `CatboxUploader` | `catboxuploader.rs` | Uploads to catbox.moe and litterbox. |
| `ShortcutManager` | `shortcutmanager.rs` | The shortcut registry. See [Shortcuts](shortcuts.md). |
| `PapirusWatcher` | `papiruswatcher.rs` | Reloads icons when the Papirus folder colour changes. |
| `Colours` | `colours.rs` | The palette. See [Theming](theming.md). |
| `Tokens` | `native/theme/tokens.hpp` | Rounding, spacing, padding, fonts and motion. |
| `RunnerGame` | `runnergame.rs` | The offline runner game easter egg. |
| `MimeService` | `mimeservice.rs` | Default applications and Open With. |
| `GitManager` | `gitmanager.rs` | Branch and status for the git modal. |
| `IconCatalog` | `iconcatalog.rs` | Searchable Material Symbols names for the icon picker. |

`FileMetadata` (the properties dialog and preview panel), `FileSystemModel` and
`CircularIndicatorManager` are plain QML types, created per use. `SplitViewContainer`
creates one `FileSystemModel` per pane, so a split tab has two. Rows are
`FileSystemEntry` objects, tabs are `TabItem` objects; Rust creates both as children of
their model through `native/qobjectfactory.h`.

cxx-qt invokables cannot have default arguments, so where QML calls a method with fewer
arguments, the bridge declares one overload per arity under the same `cxx_name` (for
example `TabManager.newTab()`, `newTab(path)` and `newTab(path, activate)`).

Two image providers are registered too: `image://icon/<name>` resolves theme icons and
`image://thumb/<path>` produces thumbnails (see below).

## Threads

The UI thread runs QML and all model state. Anything that can block runs on a worker
thread and hands its result back with cxx-qt's `qt_thread().queue(...)`:

- Directory scans and recursive search in `FileSystemModel`. Results are dropped if the
  path or query changed in the meantime (a generation counter).
- File operations, which report through the `FileOperationProgress` object that drives the
  operations modal and the status bar.
- External tools (`git`, `ffmpeg`, `ffprobe`, `magick`, `gio`, `udisksctl`, `lsblk`,
  archivers) and uploads.
- Change notification: `core::watcher` wraps inotify for folders and settings files, and
  `DriveManager` watches `/proc/self/mounts` for mount changes.
- Thumbnails are a C++ `QQuickAsyncImageProvider`. Each request runs on a thread pool,
  checks a 200-entry in-memory LRU, then a PNG disk cache in
  `~/.cache/astra-atlas/atlas/thumbnails`, and only then decodes the file (with
  `ffmpegthumbnailer` for videos).

## Where state lives

| What | Where |
|------|-------|
| Preferences, session state, shortcut overrides, hidden places and devices | `~/.config/astra-atlas/atlas.conf` (`QSettings("astra-atlas", "atlas")`) |
| Bookmarks | `~/.local/share/user-places.xbel`, shared with KDE. `~/.config/gtk-3.0/bookmarks` is read too. Both are watched for outside changes. |
| Recent files | `~/.local/share/recently-used.xbel` |
| Default applications | `~/.config/mimeapps.list` |
| User scripts | `~/.local/share/atlas/scripts` |
| Service menus | `~/.local/share/atlas/actions` and the shared locations in [Custom actions](custom-actions.md) |
| Thumbnails | `~/.cache/astra-atlas/atlas/thumbnails` |

The settings groups are:

- `session/`: state Atlas remembers on its own: last path, open tabs, view mode, zoom,
  sidebar width, show-hidden.
- `preferences/`: choices made in Preferences. `preferences/directoryViews` holds the
  per-folder view and sort as JSON when *directory-specific views* is on, and
  `preferences/transferEngine` and `preferences/customTransferCommand` the copy engine.
- `contextMenu/`: which optional context menu entries are shown.
- `shortcuts/bindings`: overrides only, as JSON (see [Shortcuts](shortcuts.md)).
- `places/`, `devices/`: hidden sidebar entries.

`AppController` and `TabManager` fall back to the old `caelestia/prism` keys when a key is
missing, so settings from before the rename still load.

## Easter eggs

`atlas://` addresses typed in the address bar go to
`AppIntegration.handleCustomProtocol`, which returns an id that `main.qml` turns into a
hidden overlay (`VectorBloomOverlay`, `RunnerGameModal`). The addresses are obfuscated in
the source on purpose.
