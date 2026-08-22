#!/usr/bin/env bash

# OpenRC / Non-Systemd XDG Desktop Portal Lifecycle Script
# Use this script in ~/.xprofile, ~/.config/hypr/hyprland.conf (exec-once),
# or run manually to launch/reload xdg-desktop-portal without systemd.

set -e

echo "[Prism] Initializing XDG Desktop Portal environment for OpenRC/non-systemd..."

# Ensure environment variables are imported into D-Bus session
if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment --all || true
    dbus-update-activation-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE || true
fi

# Terminate existing portal instances
killall -9 xdg-desktop-portal-prism 2>/dev/null || true
killall -9 xdg-desktop-portal-termfilechooser 2>/dev/null || true
killall -9 xdg-desktop-portal-hyprland 2>/dev/null || true
killall -9 xdg-desktop-portal-wlr 2>/dev/null || true
killall -9 xdg-desktop-portal-gtk 2>/dev/null || true
killall -9 xdg-desktop-portal 2>/dev/null || true

sleep 0.5

# Find portal binaries
LIBEXEC_PATHS=("/usr/bin" "/usr/local/bin" "/usr/libexec" "/usr/lib/xdg-desktop-portal" "/usr/lib")

find_bin() {
    local name="$1"
    if command -v "$name" >/dev/null 2>&1; then
        command -v "$name"
        return 0
    fi
    for p in "${LIBEXEC_PATHS[@]}"; do
        if [ -x "$p/$name" ]; then
            echo "$p/$name"
            return 0
        fi
    done
    return 1
}

# Start backend portals if available
if PORTAL_PRISM="$(find_bin xdg-desktop-portal-prism)"; then
    echo "[Prism] Starting $PORTAL_PRISM..."
    nohup "$PORTAL_PRISM" </dev/null >/dev/null 2>&1 &
elif PORTAL_TERM="$(find_bin xdg-desktop-portal-termfilechooser)"; then
    echo "[Prism] Starting $PORTAL_TERM..."
    nohup "$PORTAL_TERM" </dev/null >/dev/null 2>&1 &
fi

if PORTAL_HYPR="$(find_bin xdg-desktop-portal-hyprland)"; then
    echo "[Prism] Starting $PORTAL_HYPR..."
    nohup "$PORTAL_HYPR" </dev/null >/dev/null 2>&1 &
elif PORTAL_WLR="$(find_bin xdg-desktop-portal-wlr)"; then
    echo "[Prism] Starting $PORTAL_WLR..."
    nohup "$PORTAL_WLR" </dev/null >/dev/null 2>&1 &
elif PORTAL_GTK="$(find_bin xdg-desktop-portal-gtk)"; then
    echo "[Prism] Starting $PORTAL_GTK..."
    nohup "$PORTAL_GTK" </dev/null >/dev/null 2>&1 &
fi

sleep 0.5

# Start main portal daemon
if PORTAL_MAIN="$(find_bin xdg-desktop-portal)"; then
    echo "[Prism] Starting main $PORTAL_MAIN daemon..."
    nohup "$PORTAL_MAIN" </dev/null >/dev/null 2>&1 &
    disown -a 2>/dev/null || true
    echo "[Prism] Portal successfully started!"
else
    echo "[Prism] Warning: xdg-desktop-portal binary not found in standard paths." >&2
fi
