# Prism

Prism is a fast, lightweight Material Design 3 file manager and file picker built with Qt 6 and QML.

## Dependencies

- C++20 compiler (GCC 11+ or Clang 14+)
- CMake 3.19+
- Ninja
- Qt 6.5+ (Qt6Core, Qt6Gui, Qt6Qml, Qt6Quick, Qt6QuickControls2, Qt6QuickEffects, Qt6Concurrent, Qt6Svg)
- udisks2 (for mounting external drives and storage partitions)

## Build Instructions

```bash
# Configure
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build

# Run locally
./build/bin/prism
```

## Installation

```bash
# Install system-wide (installs binary, .desktop launcher, and icons to /usr)
sudo cmake --install build

# Or install to a custom prefix (e.g. ~/.local)
cmake --install build --prefix ~/.local
```

### Uninstallation

```bash
# Remove all installed files recorded in the build manifest
sudo xargs rm -fv < build/install_manifest.txt
```

## Credits and Licensing

This project is licensed under the GNU General Public License v3.0 (GPLv3).

Prism incorporates design tokens, QML components, animations, and styling derived from [Caelestia Shell](https://github.com/caelestia-dots/shell). Heavy credit and gratitude go to the authors and contributors of Caelestia Shell for their work under the GPLv3 license.
