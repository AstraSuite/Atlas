# Theming

Atlas follows Material Design 3, with tokens and components derived from
[Caelestia Shell](https://github.com/caelestia-dots/shell). QML never uses literal colours,
sizes or durations; it reads them from two singletons, `Colours` (Rust) and `Tokens` (C++).

## Colours

`Colours` (`src/bridge/colours.rs`) exposes:

- `Colours.palette`: an `M3Palette` with every Material 3 role as an `m3`-prefixed colour
  property: `m3primary`, `m3onSurface`, `m3surfaceContainerHigh`, `m3outlineVariant` and so
  on.
- `Colours.tPalette`: the same roles, for surfaces that may be drawn translucent.
- `Colours.light`: whether the light scheme is active (never under TTY, which is dark only).
- `Colours.style`: the Style preference (`preferences/uiStyle`): 0 follows KiiteShell,
  1 is Material 3, 2 is TTY.
- `Colours.tty`: whether the TTY look is on. See [TTY](#tty) below.

### Following KiiteShell or Caelestia

Atlas reads [KiiteShell](https://github.com/Kiite-Org/KiiteShell)'s generated palette,
`~/.local/state/kiite/user/generated/colors.json`: a flat object of snake_case Material
roles (`"surface_container_high": "#1E2B29"`). Each becomes the `m3`-prefixed camelCase
role on both palettes. The file has no mode, so `Colours.light` comes from the
background's brightness.

Without KiiteShell it reads `~/.local/state/caelestia/scheme.json`, the scheme Caelestia
writes when the wallpaper or theme changes:

```json
{
  "mode": "dark",
  "colours": { "primary": "a8c8ff", "onSurface": "e3e2e6", "surfaceContainer": "1e1f23", … }
}
```

`mode` sets `Colours.light`, and each `colours` entry `<role>: <hex>` is written to
`m3<role>` on both palettes. An inotify watch on both files and their folders (they are
often replaced rather than edited) reloads the scheme while Atlas runs, so it recolours
with the rest of the desktop.

Without either, or with `--light` / `--dark` on the command line, Atlas uses the
built-in default palette for that mode (`M3Palette::load_defaults`). A forced mode lasts
until the scheme file next changes.

## TTY

TTY draws Atlas like a terminal, as KiiteShell's own TTY theme draws the shell: one
monospace face, square boxes with their titles in the border, no shadows, and motion that
redraws in a few hard frames instead of easing.

Whether it is on: `--tty` on the command line, else the Style preference. "Follow
KiiteShell", the default, uses TTY while `appearance.theme` in `~/.config/kiite/config.json`
is `"tty"`, and switches as soon as that file changes.

Most of it comes from switches every surface already goes through:

- **Palette**: the scheme's accents stay, and its surfaces flatten to one near-black ground
  (`#0b0e0d`) with KiiteShell's tinted neutrals for rows, borders and text
  (`tty_color` in `colours.rs`, after KiiteShell's `tty_palette`).
- **Corners**: `Tokens.rounding` returns 0 for every size.
- **Face**: `Tokens.font` switches to the monospace face KiiteShell is set to
  (`appearance.fonts.monospace`), else JetBrains Mono or the first terminal face installed.
  Material Symbols icons stay.
- **Motion**: every curve becomes four even steps, the first at once, over 180 ms for a move;
  fades take a single frame.

A few components change shape for it, through these:

- `TtyBox`: a square 1 px box with its title set into the top edge. The sidebar is one
  `places` box, each file pane a box titled with its folder (the focused one brighter, with
  a blinking cursor), the preview panel a `preview` box.
- `TtyTitle`: a box title that types itself in, a few characters at a time with a couple of
  scrambled cells ahead of a block cursor, as KiiteShell's do.
- `TtyRule`: a section header as a rule, `── devices ──`.
- `TtyBar`: a bar drawn in text, `████▌░░░`, for a running file operation.
- `StyledRect.ttyFrame`: dialog and menu cards draw a 1 px border, since every surface
  shares the ground.
- The status bar becomes a status line, segments split by `│` with an `atlas` cap in the
  accent; the selected tab is a square cell underlined in the accent.

## Tokens

`TokensSingleton` (`native/theme/tokens.hpp`) groups the remaining design values. It stays
in C++ because it hands QML `QEasingCurve` values and `QFont` builder gadgets, which cxx-qt
cannot express:

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

Two fonts are compiled into the binary and registered at startup (`setupApplication` in
`native/qthelpers.cpp`):

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
