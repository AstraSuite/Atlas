# Contributing to Atlas

Thank you for contributing. This page describes how to set up a development build, what CI
checks, and the conventions the codebase follows.

## Setting up

You need a stable Rust toolchain, a C++ compiler, and the Qt 6.5+ development packages
listed in the [README](../README.md), with `qmake6` on `PATH` (or `QMAKE` set).

```sh
git clone https://github.com/AstraSuite/Atlas
cd Atlas
cargo build --release
```

The binary lands in `target/release/atlas` (`target/debug/atlas` without `--release`).
`build.rs` picks things up on its own: every `.qml` file under `qml/` is compiled into the
`atlas` QML module, and every file in `src/bridge/` containing a `cxx_qt::bridge` is
generated. Two lists in `build.rs` are kept by hand: `NATIVE` (the C++ files in `native/`)
and `RESOURCES` (non-QML files embedded in the binary, such as fonts and sounds).

## Running your build

```sh
./target/release/atlas                 # opens the startup directory from Preferences
./target/release/atlas ~/Downloads     # or a given folder; a file opens its parent
./target/release/atlas --dark --hidden # force the dark palette and show dotfiles
```

Your development build shares settings with an installed Atlas
(`~/.config/astra-atlas/atlas.conf`), so a change to how settings are written affects both.

## Version

`build.rs` takes the version from the latest `v*` git tag. Without a tag it uses
`0.<YYYYMMDD>` of the last commit. Set `ATLAS_VERSION=X.Y.Z` in the environment to pin it.
`Cargo.toml`'s own version is only the last fallback.

## CI

`.github/workflows/build.yml` builds on Arch Linux, runs `cargo test`, then starts Atlas
offscreen for 20 seconds and fails on any QML error or binding loop in the
log. Run the same check before opening a pull request:

```sh
cargo test
QT_QPA_PLATFORM=offscreen QT_LOGGING_TO_CONSOLE=1 timeout 20 ./target/release/atlas "$HOME" > run.log 2>&1
grep -aiE '\.qml:[0-9]+.*(error|is not a type|Cannot |Unable to assign|TypeError)|binding loop' run.log
```

No output from `grep` means it passes. This only catches errors at startup: code in a
dialog or a menu runs when it is opened, so open what you changed.

Pushing a `v*` tag runs `release.yml`, which publishes the binary and a source tarball as a
GitHub release with generated notes.

## Making a change

1. Branch off `main`.
2. Keep each change to one feature or fix. A new preference usually touches three places:
   a row in the property table at the top of `src/bridge/appcontroller.rs`, the code reading it, and its row in
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

### Rust and C++

- QObjects live in `src/bridge/`, one bridge per file; logic with no Qt types belongs in
  `src/core/` so it can be unit tested. See [Architecture](architecture.md).
- New services are QML singletons (`#[qml_element]`, `#[qml_singleton]`). QML files that use
  them need `import atlas`. A service other services call records itself in
  `src/bridge/registry.rs` from its `cxx_qt::Initialize` impl.
- cxx-qt invokables have no default arguments. When QML calls a method with fewer
  arguments, add an overload with the same `cxx_name` for each arity.
- Settings go through `bridge::native::settings`, which wraps
  `QSettings("astra-atlas", "atlas")` so `atlas.conf` keeps its format. Group keys under
  `session/` (remembered state), `preferences/` (user choices), or the feature's own group.
  Structured values are stored as compact JSON strings.
- Filesystem walks, process output and network calls run on a worker thread, then hand
  results back with `self.qt_thread().queue(...)`. Check the result is still wanted before
  applying it (see `FileSystemModel::perform_search`).
- Paths passed to a shell are quoted with `desktop::shell_quote`. Prefer
  `std::process::Command` with an argument list over `sh -c`.
- Keep C++ to `native/`: only what needs Qt types cxx-qt can't bind (image providers,
  `QEasingCurve`/`QFont` gadgets, `QPainter`, `QDrag`) or a Qt service with no Rust
  equivalent (`QSettings`, `QMimeDatabase`, `QIcon` themes).
- Run `cargo test` for anything in `src/core/`, and keep the build free of warnings.

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
