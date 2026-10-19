# Atlas Project Guide

## Project Overview
Atlas is a fast, lightweight Material Design 3 file manager and file picker built with Qt 6 and QML. It's a single, monolithic C++/QML project with organized source directories.

## Build Commands

### Configure and Build
```bash
# Configure
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build
```

### Run
```bash
# Run file manager locally
./build/bin/atlas

# Run picker mode directly
./build/bin/atlas -p
```

### Test QML Loading
The CI tests that Atlas starts without QML errors:
```bash
QT_QPA_PLATFORM=offscreen QT_LOGGING_TO_CONSOLE=1 timeout 20 ./build/bin/atlas "$HOME" > run.log 2>&1
```

## Installation
```bash
# Install system-wide: installs atlas and its desktop entry
sudo cmake --install build

# Or install to a custom prefix
cmake --install build --prefix ~/.local
```

## Directory Structure

- `src/` - C++ source files:
  - `src/config/` - Configuration and theme files
  - `src/controllers/` - Application controllers (e.g., TabManager)
  - `src/core/` - Core functionality
  - `src/models/` - Data models (e.g., FileSystemModel)

- `qml/` - QML files for UI components and main.qml

- `assets/` - Resource files (fonts, icons, sounds, images)

- `build/` - Build artifacts (created by CMake)

## Dependencies

### Required Build Dependencies
- C++20 compiler: GCC 11+ or Clang 14+
- CMake 3.19+
- Ninja build system
- pkg-config
- Qt 6.5+ development packages (all listed in README.md)

### Optional Dependencies (enables features)
- `udisks2` - external drive detection
- `git` - repository integration
- `ffmpeg` - media tools
- `exiv2` - EXIF metadata support

## Command Line Options

### General Options
- `-d`, `--directory <dir>` - Initial directory to open
- `-hidden` - Show hidden files by default
- `-light` - Force light theme
- `-dark` - Force dark theme
- `[path]` - Directory or file path to open

### Picker Mode
- `-p` - Run in picker mode
- `-s` - Save file picker mode
- `--directory-only` - Directory only picker
- `-f <ext>` - Filter by file extensions

## Version Management
Atlas uses automatic version detection from git tags:
- If git tag exists (e.g., v1.2.3), uses that version
- Otherwise, uses dev version (0.YYYYMMDD format)

## CI/CD
- Runs on Arch Linux via GitHub Actions
- Tests both with and without Exiv2 support
- Verifies QML loads without errors before accepting PR
- Releases create tar.gz archives with binary and source

## Team Conventions
- Projects use dark theme by default
- Repository tracks recent files in sidebar
- Supports both file and directory picking
- Uses Material Design 3 guidelines

## Common Issues

### Build Issues
- Missing Qt 6.5+ dependencies
- CMake 3.19+ required
- Ninja generator recommended

### Runtime Issues
- QML errors often indicate missing Qt modules
- Theme switching requires proper Qt QuickControls2
- External drive access requires udisks2

### Development Tips
- Use `-p` mode for testing without full UI
- Test light/dark theme with `-light` or `-dark` options
- CI automatically checks for QML errors on startup