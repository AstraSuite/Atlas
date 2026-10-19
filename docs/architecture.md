# Architecture

Atlas is one Qt 6 binary, `atlas`. C++ owns the filesystem, processes, settings and system
integration; QML owns every pixel. This page describes how the two halves meet.

## Layout

| Path | Contents |
|------|----------|
| `src/main.cpp` | Command-line parsing, singleton creation, QML context registration. |
| `src/config/` | `Colours` (the Material 3 palette), `Tokens` (rounding, spacing, padding, fonts, animation) and the font builders. See [Theming](theming.md). |
| `src/models/` | `FileSystemModel` and its `FileSystemEntry` rows: one directory listing, or search results. |
| `src/controllers/` | `TabManager` and `TabItem`: tabs, split panes, per-tab history. |
| `src/core/` | Services: file operations, MIME and app launching, places, drives, network mounts, git, media tools, thumbnails, icons, shortcuts, uploads. |
| `qml/main.qml` | The window, the tab/split container, every modal, and the global shortcuts. |
| `qml/components/` | The component library and the feature UI, grouped by folder (`views`, `navigation`, `dialogs`, `menus`, `panels`, `media`, `settings`, `controls`, `containers`). |
| `assets/` | Fonts, the icon, the desktop entry and the Material Symbols name list, compiled in as Qt resources. |

## Startup

`main.cpp` sets a 32-bit RGBA surface format (to avoid RGB565 banding), copies settings from
the old `prism` organisation on first run, and registers the bundled fonts. It then parses
the command line:

| Option | Effect |
|--------|--------|
| `[path]` | Open this folder, or the folder containing this file. `file://` URLs work. |
| `-d`, `--directory <dir>` | Same, as an option. |
| `--hidden` | Show hidden files, and remember it. |
| `--light`, `--dark` | Force a palette instead of following Caelestia's scheme. |

Every service is created next, so `TabManager` can restore tabs before QML loads. Last,
the singletons are attached to the root context and `qrc:/qt/qml/atlas/qml/main.qml` is
loaded.

## Exposing C++ to QML

Services are process-wide singletons reached through `instance()`. Their headers declare
`QML_ELEMENT`/`QML_SINGLETON`, so they are part of the `atlas` QML module, and `main.cpp`
also sets most of them as context properties. Either way, QML refers to them by name:

| Name | Class | Role |
|------|-------|------|
| `AppController` | `core::AppController` | Preferences and remembered UI state. |
| `TabManager` | `controllers::TabManager` | Tabs, splits, the current path of each pane. |
| `FileOperations` | `core::FileOperations` | Copy, move, trash, clipboard, undo, archives. See [File operations](file-operations.md). |
| `FileUtils` | `core::FileUtils` | Static helpers: formatting, path expansion and completion, MIME and icon lookup. |
| `AppIntegration` | `core::AppIntegration` | Opening and running files, terminals, custom actions, Papirus. See [Opening files](opening-files.md). |
| `PlacesModel` | `core::PlacesModel` | The sidebar's places and bookmarks. |
| `DriveManager` | `core::DriveManager` | Drives and partitions through `udisks2`. |
| `NetworkManager` | `core::NetworkManager` | SFTP, SMB, FTP, NFS and WebDAV mounts through `gio`/GVFS. |
| `MediaTools` | `core::MediaTools` | `ffmpeg` and ImageMagick conversions. |
| `CatboxUploader` | `core::CatboxUploader` | Uploads to catbox.moe and litterbox. |
| `ShortcutManager` | `core::ShortcutManager` | The shortcut registry. See [Shortcuts](shortcuts.md). |
| `PapirusWatcher` | `core::PapirusWatcher` | Reloads icons when the Papirus folder colour changes. |
| `Colours`, `Tokens` | `config::*` | The palette and design tokens. |
| `RunnerGame` | `core::RunnerGame` | The offline runner game easter egg. |
| `MimeService` | `core::MimeService` | Default applications and Open With. Module singleton only. |
| `GitManager` | `core::GitManager` | Branch and status for the git modal. Module singleton only. |
| `IconCatalog` | `core::IconCatalog` | Searchable Material Symbols names for the icon picker. Module singleton only. |

`FileMetadata` (the properties dialog and preview panel) is a plain QML type, created per
use.

Two image providers are registered too: `image://icon/<name>` resolves theme icons and
`image://thumb/<path>` produces thumbnails (see below).

`FileSystemModel` is registered as a QML type rather than a singleton. `SplitViewContainer`
creates one per pane and binds its `path` to that pane's `TabItem`, so a split tab has two
models.

## Threads

The UI thread runs QML and all model state. Anything that can block runs elsewhere:

- Directory scans and recursive search in `FileSystemModel` run through
  `QtConcurrent::run`. Results are posted back with `QMetaObject::invokeMethod` and
  dropped if the path or query changed in the meantime.
- File operations run on worker threads and report through `FileOperationProgress`
  objects, which drive the operations modal and the status bar.
- External tools (`git`, `ffmpeg`, `magick`, `gio`, `udisksctl`, archivers) run as
  `QProcess`es and report through signals.
- Thumbnails are a `QQuickAsyncImageProvider`. Each request runs on the global thread
  pool, checks a 200-entry in-memory LRU, then a PNG disk cache in
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
`AppIntegration::handleCustomProtocol`, which returns an id that `main.qml` turns into a
hidden overlay (`VectorBloomOverlay`, `RunnerGameModal`). The addresses are obfuscated in
the source on purpose.
