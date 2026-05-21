#!/usr/bin/env bash
# wallpaper.sh — set i3 desktop background.
# Looks for ~/.config/i3/wallpaper.png first; falls back to a solid color.
set -uo pipefail

WP="$HOME/.config/i3/wallpaper.png"

if [ -f "$WP" ] && command -v feh >/dev/null 2>&1; then
    feh --no-fehbg --bg-fill "$WP"
else
    # Solid-color fallback (Catppuccin Mocha base)
    xsetroot -solid "#1e1e2e" 2>/dev/null || true
fi
