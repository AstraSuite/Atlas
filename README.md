# Atlas

Atlas is a fast, lightweight Material Design 3 file manager and file picker built with Qt 6 and QML.

## Dependencies

### Build Dependencies (Required)

- C++20 compiler: GCC 11+ or Clang 14+
- CMake 3.19+
- Ninja build system
- pkg-config
- Qt 6.5+ development packages:
  - `Qt6Core`
  - `Qt6Gui`
  - `Qt6Qml`
  - `Qt6Quick`
  - `Qt6QuickControls2`
  - `Qt6QuickEffects`
  - `Qt6Concurrent`
  - `Qt6Svg`
  - `Qt6Multimedia`
  - `Qt6Network`
  - `Qt6DBus`

### Runtime Dependencies (Required)

- Qt 6 runtime libraries:
  - `qt6-declarative` / `qt6-qml`
  - `qt6-quickcontrols2`
  - `qt6-quickeffects`
  - `qt6-svg`
  - `qt6-multimedia`
  - `qt6-network`
  - `qt6-dbus`

### Optional Dependencies

- `udisks2`: external drive and partition detection, mounting, and unmounting
- `gvfs` and `gvfs-backends`: remote network filesystem mounting for SFTP, SMB, FTP, NFS, WebDAV
- `gio`: command-line URI mounting and volume management
- `xdg-desktop-portal`: desktop portal integration for system-wide file chooser dialogs
- `xdg-utils`: default application launching via `xdg-open`
- `git`: inline repository status, branch tracking, and Git modal operations
- `caelestia-cli`: dynamic color palette and accent syncing with Caelestia
- `papirus-icon-theme` and `papirus-folders`: dynamic folder color and system icon theme integration
- Archive tools: `p7zip`, `tar`, `gzip`, `bzip2`, `xz`, `zip`, `unzip` for archive extraction and compression

## Build Instructions

```bash
# Configure
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build

# Run file manager locally
./build/bin/atlas

# Run picker mode directly
./build/bin/atlas -p
```

## Installation

```bash
# Install system-wide: installs atlas, xdg-desktop-portal-astra-atlas, and services
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

Atlas provides a native XDG Desktop Portal backend `xdg-desktop-portal-astra-atlas` implementing `org.freedesktop.impl.portal.FileChooser`. This allows browsers, editors such as VS Code and VSCodium, and desktop applications to use Atlas as their default file open and save dialog.

### 1. Configure Portal Routing

Ensure your portal configuration specifies Atlas for the `FileChooser` interface.

Create or edit `~/.config/xdg-desktop-portal/portals.conf`:

```ini
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.FileChooser=astra-atlas
```

### 2. Service Management

Atlas automatically installs D-Bus activation files so `xdg-desktop-portal` can launch the backend on demand.

#### OpenRC and Non-Systemd Desktops

Run the user session portal helper:

```bash
atlas-portal-openrc
```

You can also add `atlas-portal-openrc &` to your compositor startup configuration such as `hyprland.conf`.

#### Systemd Desktops

Enable and start the user service:

```bash
systemctl --user daemon-reload
systemctl --user enable --now xdg-desktop-portal-astra-atlas.service
```

### 3. Window Rules on Wayland Compositors

To ensure the picker opens centered as a floating modal, add a window rule for the picker title.

#### Hyprland

In your `hyprland.conf`:

```ini
windowrulev2 = float, title:^(.*Atlas File Picker.*)$
windowrulev2 = center, title:^(.*Atlas File Picker.*)$
windowrulev2 = size 1000 620, title:^(.*Atlas File Picker.*)$
windowrulev2 = focusonactivate, title:^(.*Atlas File Picker.*)$
```

#### Caelestia in ~/.config/caelestia/hypr-user.lua

```lua
local rules = {
    {
        pattern = ".*Atlas File Picker.*",
        type = "title",
        float = true,
        center = true,
        size = "1000 620",
        focus = true
    }
}
```

### 4. Direct CLI Picker Mode

Atlas can also be invoked directly in picker mode by scripts or external tools:

```bash
# Open file picker
atlas -p -t "Select File" -d ~/Documents

# Save file picker
atlas -p -s -t "Save As" -d ~/Downloads

# Directory only picker
atlas -p --directory-only -t "Select Directory"

# Filter by extensions
atlas -p -f "png,jpg,webp" -t "Select Image"
```

## Credits and Licensing

This project is licensed under the GNU General Public License v3.0 (GPLv3).

Atlas incorporates design tokens, QML components, animations, and styling derived from [Caelestia Shell](https://github.com/caelestia-dots/shell). Heavy credit and gratitude go to the authors and contributors of Caelestia Shell for their work under the GPLv3 license.

