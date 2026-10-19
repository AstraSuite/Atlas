# Theming

Atlas follows Material Design 3, with tokens and components derived from
[Caelestia Shell](https://github.com/caelestia-dots/shell). QML never uses literal colours,
sizes or durations; it reads them from two C++ singletons, `Colours` and `Tokens`.

## Colours

`config::ColoursSingleton` (`src/config/colours.cpp`) exposes:

- `Colours.palette`: an `M3Palette` with every Material 3 role as an `m3`-prefixed colour
  property: `m3primary`, `m3onSurface`, `m3surfaceContainerHigh`, `m3outlineVariant` and so
  on.
- `Colours.tPalette`: the same roles, for surfaces that may be drawn translucent.
- `Colours.light`: whether the light scheme is active.

### Following Caelestia

At startup Atlas reads `~/.local/state/caelestia/scheme.json`, the scheme Caelestia
writes when the wallpaper or theme changes:

```json
{
  "mode": "dark",
  "colours": { "primary": "a8c8ff", "onSurface": "e3e2e6", "surfaceContainer": "1e1f23", … }
}
```

`mode` sets `Colours.light`, and each `colours` entry `<role>: <hex>` is written to
`m3<role>` on both palettes. A `QFileSystemWatcher` on the file and on its folder (the file
is often replaced rather than edited) reloads the scheme while Atlas runs, so it recolours
with the rest of the desktop.

Without Caelestia, or with `--light` / `--dark` on the command line, Atlas uses the
built-in default palette for that mode (`M3Palette::loadDefaults`). A forced mode lasts
until the scheme file next changes.

## Tokens

`config::TokensSingleton` groups the remaining design values:

| Token | Contents |
|-------|----------|
| `Tokens.rounding` | Corner radii, from `extraSmall` (4) to `full`. |
| `Tokens.spacing` | Gaps between siblings. |
| `Tokens.padding` | Insets inside containers. |
| `Tokens.font` | Ready-made fonts by role (`Tokens.font.body.small`, `Tokens.font.title.medium`, `Tokens.font.icon.small`). |
| `Tokens.anim` | Material easing curves and `anim.durations`, used by `Anim` and `CAnim`. |
| `Tokens.sizes` | Fixed component sizes, such as `sizes.sidebar`. |

A new component should be built from these and from the shared controls (`StyledRect`,
`StyledText`, `StateLayer`, `IconButton` and so on) so it inherits the palette, the state
layers and the motion of the rest of the app.

## Fonts and symbols

Two fonts are compiled into the binary and registered in `main.cpp`:

- **Google Sans Flex** for all text. `FontBuilder` sets its variable axes (weight, width,
  grade) so one file covers every style.
- **Material Symbols Rounded** for interface icons, drawn by `MaterialIcon` from a symbol
  name like `"folder"` or `"content_copy"`. `assets/material_icons.txt` lists the names, and
  `IconCatalog` searches it for the icon picker in the place editor.

## File and application icons

File, folder and application icons come from the system icon theme through the
`image://icon/<name>` provider (`IconImageProvider`), with `CachingIconImage` caching the
result in QML. `FileUtils.iconForFile` picks the name from the MIME type.

With Papirus installed, Preferences shows the current folder colour, and
`AppIntegration.setPapirusColor` runs `papirus-folders -C <colour>` to change it.
`PapirusWatcher` watches the `papirus-folders` state and the icon folders it rewrites, and
bumps `AppController.iconThemeVersion` so every icon reloads without a restart.
