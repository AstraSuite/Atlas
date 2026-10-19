# Custom actions

The context menu can run user scripts and service-menu actions, alongside entries Atlas
adds for tools it finds installed. Everything is collected by
`AppIntegration::scanCustomActions`, which runs each time the menu opens, so a new script
shows up without restarting.

## Detected tools

When the executable is on `PATH`, Atlas adds:

- **Analyze Disk Usage** on folders, with `baobab`, `filelight` or `k4dirstat`.
- **Open in editor** with VS Code, VSCodium, VS Code Insiders, Cursor or Sublime Text.

The icon comes from the tool's desktop entry categories, mapped to a Material Symbol.

All custom actions, including scripts and service menus, are listed under *Open* in the
context menu. The *Secondary Code Editor* toggle in Preferences → Context Menu
(`contextMenu/showSecondaryEditor`) hides the whole group, not only the editors.

*Send To* is separate: `getAvailableSharingServices` lists LocalSend, KDE Connect, Quick
Share (`rquickshare`, `nearbyshare`, `warpinator`), Bluetooth and email when present.

## Scripts

Every executable file in these folders becomes a menu entry:

1. `~/.local/share/atlas/scripts` (Preferences → Scripts & Tools has a button to open it)
2. `~/.local/share/nautilus/scripts`, so Nautilus scripts work as they are

A name found in both is only listed once, from the first folder. The entry's label is the
file name with `.sh` removed and `_` replaced by spaces: `resize_to_1080p.sh` shows as
*resize to 1080p*. Scripts appear for every selection.

A script is run as `'<script>' <selected paths…>` through `/bin/sh -c`, with each path
quoted and the folder as the working directory. With nothing selected, the current folder
is passed instead.

```sh
#!/bin/sh
# ~/.local/share/atlas/scripts/make_thumbnails.sh
for f in "$@"; do
    magick "$f" -resize 320x320 "${f%.*}_thumb.png"
done
```

Scripts and service menus also get these environment variables:

| Variable | Value |
|----------|-------|
| `ATLAS_SELECTED_PATHS` | The selected paths, one per line. |
| `ATLAS_CURRENT_DIR` | The current folder. |
| `NAUTILUS_SCRIPT_SELECTED_FILE_PATHS` | The same as `ATLAS_SELECTED_PATHS`, for Nautilus scripts. |
| `NAUTILUS_SCRIPT_CURRENT_URI` | The current folder as a `file://` URL. |

`PRISM_SELECTED_PATHS` and `PRISM_CURRENT_DIR` are set too, for scripts written before the
rename.

## Service menus

`.desktop` files in these folders are read as actions:

1. `~/.local/share/atlas/actions`
2. `~/.local/share/file-manager/actions`
3. `~/.local/share/kio/servicemenus`
4. `/usr/share/kio/servicemenus`

Dolphin's service menus therefore show up in Atlas. A file with an `Actions=` key adds one
entry per `[Desktop Action <name>]` group; one without adds a single entry from
`[Desktop Entry]`. `MimeType=` limits where the entries appear, with `*/*` and `image/*`
style wildcards supported.

```ini
# ~/.local/share/atlas/actions/images.desktop
[Desktop Entry]
Type=Service
MimeType=image/*;
Actions=toWebp;

[Desktop Action toWebp]
Name=Convert to WebP
Icon=image
Exec=for f in %F; do magick "$f" "${f%.*}.webp"; done
```

The `Exec` line runs through `/bin/sh -c` after these substitutions, each shell-quoted:

| Code | Replaced with |
|------|---------------|
| `%f` | The first selected path, or the current folder. |
| `%F` | All selected paths, space-separated. |
| `%u`, `%U` | The same as `file://` URLs. |
| `%d`, `%D` | The current folder, or the selected folder when exactly one is selected. |
| `%n` | The file name of the first selected path. |

`Icon=` may be a theme icon name. Without one, the entry uses the generic `extension`
symbol.
