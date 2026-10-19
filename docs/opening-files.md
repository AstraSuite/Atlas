# Opening files

What happens when a file is double-clicked, picked from Open With, or is itself a program.
The code is in `core::MimeService` (`src/core/mimeservice.cpp`) and
`core::AppIntegration` (`src/core/appintegration.cpp`).

## Opening with the default application

`AppIntegration::openWithDefault` resolves the handler itself and launches it through
`MimeService::openWith`, the same path the Open With dialog uses. It does not hand the file
to `xdg-open` or `QDesktopServices`: when an association only exists under
`[Added Associations]`, or the desktop's handler cache is stale, `xdg-open` shows its "choose
an application" prompt even though a good handler exists. `xdg-open` also ignores
`Terminal=true`. Only when Atlas finds no handler at all does it fall back to
`QDesktopServices::openUrl`.

`MimeService::getDefaultApp(mime)` looks in this order and takes the first hit:

1. `~/.config/mimeapps.list`: `[Default Applications]`, then the first entry of
   `[Added Associations]`. `[Removed Associations]` is remembered for the later steps.
2. `mimeapps.list` in `/etc/xdg`, `/usr/share/applications` and
   `/usr/local/share/applications`: `[Default Applications]`.
3. `xdg-mime query default <mime>`.
4. The first installed application whose `MimeType=` lists the type.

A handler listed under `[Removed Associations]` is skipped. Desktop files are looked up in
`~/.local/share/applications`, `/usr/local/share/applications` and
`/usr/share/applications`.

## Open With

`MimeService::getApplicationsForFile` returns every application, recommended ones (those
declaring the file's MIME type) first. Applications with `NoDisplay=true` are hidden from
launchers but are included when they declare the file's type explicitly: swappy, for
example, ships `NoDisplay=true` with `MimeType=image/png;image/jpeg;`, and is a perfectly
good image handler.

Desktop entries are parsed line by line rather than with `QSettings`, which mangles values
containing `;` and `,`.

### Setting a default

*Always use this application* calls `MimeService::setDefaultApp(mime, desktopId)`. It
registers the application for the chosen type and for every other type in the same group
that the application declares: picking an image viewer for a PNG also makes it the default
for the JPEG, WebP and other `image/*` types it lists. Otherwise a later choice for one
image type would leave others pointing elsewhere.

For each type, the application is moved to the front of `[Default Applications]` and
`[Added Associations]`, and removed from `[Removed Associations]`.

`mimeapps.list` is read and written by hand. `QSettings::IniFormat` would escape the space
in `[Default Applications]` and the `/` in MIME keys, producing a file `xdg-open` silently
ignores. Section and key order are kept so the file stays readable.

If `$XDG_CURRENT_DESKTOP-mimeapps.list` (for example `hyprland-mimeapps.list`) exists and
isn't empty, it takes priority over `mimeapps.list` for other tools, so Atlas logs a
warning that the new default may appear not to work.

## Terminal applications

An application with `Terminal=true` (micro, nvim, htop) needs a terminal to run in.
`MimeService::openWith` launches it as `<terminal> -e <program> <args> <file>`.

The terminal is `$TERMINAL` when set, otherwise the first installed of `foot`, `kitty`,
`alacritty`, `ghostty`, `wezterm`, `konsole`, `gnome-terminal` and `xterm`. The same choice is
used for *Open in Terminal* (`F4`), which starts the terminal in the current folder.

## Running programs

Opening a file that `AppIntegration::isRunnable` accepts shows `RunFileModal` instead of
opening it in an editor. A file is runnable when it has the executable bit and is an ELF
executable, a shared library, a shell script, or a text file starting with `#!`. The
modal offers to run it directly or in a terminal (`runExecutable(path, inTerminal)`), with
its folder as the working directory.
