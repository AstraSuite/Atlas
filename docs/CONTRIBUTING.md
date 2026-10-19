# Contributing to Atlas

Thank you for contributing. This page describes how to set up a development build, what CI
checks, and the conventions the codebase follows.

## Setting up

You need a C++20 compiler (GCC 11+ or Clang 14+), CMake 3.19+, Ninja, pkg-config and the
Qt 6.5+ development packages listed in the [README](../README.md). Exiv2's development
package is optional: without it Atlas builds without EXIF metadata.

```sh
git clone https://github.com/AstraSuite/Atlas
cd Atlas
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

The binary lands in `build/bin/atlas`. QML is compiled into the binary as the `atlas` QML
module, so every new `.qml` file (and every new `.cpp`/`.hpp`) has to be listed in
`CMakeLists.txt` or it won't be found at runtime.

## Running your build

```sh
./build/bin/atlas                # opens the startup directory from Preferences
./build/bin/atlas ~/Downloads    # or a given folder; a file opens its parent
./build/bin/atlas --dark --hidden # force the dark palette and show dotfiles
```

Your development build shares settings with an installed Atlas
(`~/.config/astra-atlas/atlas.conf`), so a change to how settings are written affects both.

## Version

`CMakeLists.txt` takes the version from the latest `v*` git tag. Without a tag it uses
`0.<YYYYMMDD>` of the last commit, since CMake only accepts numeric components. Pass
`-DATLAS_VERSION=X.Y.Z` to pin it.

## CI

`.github/workflows/build.yml` builds on Arch Linux twice, with and without Exiv2, then
starts Atlas offscreen for 20 seconds and fails on any QML error or binding loop in the
log. Run the same check before opening a pull request:

```sh
QT_QPA_PLATFORM=offscreen QT_LOGGING_TO_CONSOLE=1 timeout 20 ./build/bin/atlas "$HOME" > run.log 2>&1
grep -aiE '\.qml:[0-9]+.*(error|is not a type|Cannot |Unable to assign|TypeError)|binding loop' run.log
```

No output from `grep` means it passes. This only catches errors at startup: code in a
dialog or a menu runs when it is opened, so open what you changed.

Pushing a `v*` tag runs `release.yml`, which publishes the binary and a source tarball as a
GitHub release with generated notes.

## Making a change

1. Branch off `main`.
2. Keep each change to one feature or fix. A new preference usually touches three places:
   a `Q_PROPERTY` and setter in `AppController`, the code reading it, and its row in
   `PreferencesModal.qml`. A new global shortcut is described in
   [Shortcuts](shortcuts.md#adding-an-action).
3. Try it in the real app, in light and dark, and in each view mode it affects.
4. Open a pull request against `AstraSuite/Atlas`. Describe what changed for the user, and
   add a screenshot for anything visual.

### Commit messages

Commits use a conventional prefix and a lower-case summary of the result:

```
feat: go to parent folder with Backspace
fix: launch Terminal=true apps (e.g. micro) inside a terminal emulator
refactor: strip picker mode from Atlas
```

Use `feat`, `fix`, `perf`, `refactor`, `docs` or `chore`. The body, when there is one,
explains why and what a user will notice.

## Code conventions

### Comments

Comments explain why code is there or how something non-obvious works, not what the next
line does. A spec quirk, a workaround for a Qt or `xdg-open` behaviour, or a reason a
simpler approach fails is worth a comment. Longer explanations belong in `docs/`.

### C++

- Everything lives in the `atlas::` namespaces (`atlas::core`, `atlas::models`,
  `atlas::controllers`, `atlas::config`).
- Services are singletons with `instance()` and are exposed to QML as context properties
  in `src/main.cpp`. See [Architecture](architecture.md).
- Settings go through `QSettings("astra-atlas", "atlas")`. Group keys under `session/`
  (remembered state), `preferences/` (user choices), or the feature's own group. Structured
  values are stored as compact JSON strings.
- Filesystem walks, process output and image decoding run off the UI thread through
  `QtConcurrent::run`, then hand results back with `QMetaObject::invokeMethod`. Check the
  result is still wanted before applying it (see `FileSystemModel::performSearch`).
- Paths passed to a shell are quoted with `shellQuote`. Prefer `QProcess` with an argument
  list over `sh -c`.

### QML

- Follow the component library before writing new controls: `StyledRect`, `StyledText`,
  `MaterialIcon`, `StateLayer`, `IconButton`, `TextButton`, `ToggleRow`, `SlidingSelector`,
  `Menu`/`MenuItem` and the fading containers in `components/containers`.
- Use `Colours.palette.*` and `Tokens.*` (rounding, spacing, padding, font, anim) instead
  of literal colours, sizes and durations. See [Theming](theming.md).
- Interface text goes through `qsTr()`.
- The three file views (`FileGridView`, `FileDetailsView`, `FileCompactView`) duplicate
  their key handling and selection logic. A change to one almost always belongs in all
  three.

## Licensing

Atlas is GPLv3, and contributions are accepted under the same license. It derives design
tokens, components and animations from [Caelestia Shell](https://github.com/caelestia-dots/shell);
when porting a piece from it, name the original in a comment. Bundled fonts keep their own
licenses, listed in [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).
