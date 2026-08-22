# Prism

Prism is a fast, lightweight Material Design 3 file manager and file picker built with Qt 6 and QML.

## Dependencies

- C++20 compiler (GCC 11+ or Clang 14+)
- CMake 3.19+
- Ninja
- Qt 6.5+ (Qt6Core, Qt6Gui, Qt6Qml, Qt6Quick, Qt6QuickControls2, Qt6QuickEffects, Qt6Concurrent, Qt6Svg, Qt6DBus)
- udisks2 (for mounting external drives and storage partitions)
- xdg-desktop-portal (for system-wide file chooser integration)

## Build Instructions

```bash
# Configure
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build

# Run file manager locally
./build/bin/prism

# Run picker mode directly
./build/bin/prism -p
```

## Installation

```bash
# Install system-wide (installs prism, xdg-desktop-portal-prism, and services)
sudo cmake --install build

# Or install to a custom prefix
cmake --install build --prefix ~/.local
```

### Uninstallation

```bash
# Remove all installed files recorded in the build manifest
sudo xargs rm -fv < build/install_manifest.txt
```

## XDG Desktop File Picker Setup

Prism provides a native XDG Desktop Portal backend (`xdg-desktop-portal-prism`) implementing `org.freedesktop.impl.portal.FileChooser`. This allows browsers, editors (such as VS Code and VSCodium), and desktop applications to use Prism as their default file open and save dialog.

### 1. Configure Portal Routing

Ensure your portal configuration specifies Prism for the `FileChooser` interface.

Create or edit `~/.config/xdg-desktop-portal/portals.conf`:

```ini
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.FileChooser=prism
```

### 2. Service Management

Prism automatically installs D-Bus activation files so `xdg-desktop-portal` can launch the backend on demand.

#### OpenRC and Non-Systemd Desktops

Run the user session portal helper:

```bash
prism-portal-openrc
```

You can also add `prism-portal-openrc &` to your compositor startup configuration (such as `hyprland.conf`).

#### Systemd Desktops

Enable and start the user service:

```bash
systemctl --user daemon-reload
systemctl --user enable --now xdg-desktop-portal-prism.service
```

### 3. Window Rules (Wayland Compositors)

To ensure the picker opens centered as a floating modal, add a window rule for the picker title.

#### Hyprland

In your `hyprland.conf`:

```ini
windowrulev2 = float, title:^(.*Prism File Picker.*)$
windowrulev2 = center, title:^(.*Prism File Picker.*)$
windowrulev2 = size 1000 620, title:^(.*Prism File Picker.*)$
windowrulev2 = focusonactivate, title:^(.*Prism File Picker.*)$
```

#### Caelestia (`~/.config/caelestia/hypr-user.lua`)

```lua
local rules = {
    {
        pattern = ".*Prism File Picker.*",
        type = "title",
        float = true,
        center = true,
        size = "1000 620",
        focus = true
    }
}
```

### 4. Direct CLI Picker Mode

Prism can also be invoked directly in picker mode by scripts or external tools:

```bash
# Open file picker
prism -p -t "Select File" -d ~/Documents

# Save file picker
prism -p -s -t "Save As" -d ~/Downloads

# Directory only picker
prism -p --directory-only -t "Select Directory"

# Filter by extensions
prism -p -f "png,jpg,webp" -t "Select Image"
```

## Credits and Licensing

This project is licensed under the GNU General Public License v3.0 (GPLv3).

Prism incorporates design tokens, QML components, animations, and styling derived from [Caelestia Shell](https://github.com/caelestia-dots/shell). Heavy credit and gratitude go to the authors and contributors of Caelestia Shell for their work under the GPLv3 license.

