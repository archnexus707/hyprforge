#!/usr/bin/env bash
set -uo pipefail

ok()  { echo -e "\033[38;5;46m[OK]\033[0m $*"; }
log() { echo -e "\033[38;5;226m[..]\033[0m $*"; }
warn(){ echo -e "\033[38;5;196m[WARN]\033[0m $*"; }

log "installing cyberpunk theme stack"

# GTK theme via apt
sudo apt-get install -y --no-install-recommends arc-theme papirus-icon-theme \
    >>/dev/null 2>&1 || warn "some theme packages failed"

# Catppuccin GTK theme (dark cyberpunk look)
THEME_DIR="$HOME/.themes"
mkdir -p "$THEME_DIR"

if [ ! -d "$THEME_DIR/Catppuccin-Mocha-Standard-Mauve-Dark" ]; then
    log "downloading Catppuccin GTK theme"
    tmp=$(mktemp -d)
    curl_err=$(mktemp)
    # Catppuccin renamed assets in v1.0.3 — use explicit version URL
    curl -fsSL "https://github.com/catppuccin/gtk/releases/download/v1.0.3/catppuccin-mocha-mauve-standard+default.zip" \
        -o "$tmp/catppuccin.zip" 2>"$curl_err" || {
        warn "Catppuccin theme download failed (${curl_err:+\"$(cat "$curl_err")\"}) — using Arc-Dark fallback"
        rm -rf "$tmp" "$curl_err"
        log "using Arc-Dark GTK theme"
    }
    if [ -f "$tmp/catppuccin.zip" ]; then
        unzip -qo "$tmp/catppuccin.zip" -d "$THEME_DIR" 2>/dev/null || warn "unzip failed"
        rm -rf "$tmp"
    fi
    [ -e "$curl_err" ] && rm -f "$curl_err"
fi

# Bibata cursor
CURSOR_DIR="$HOME/.icons/Bibata-Modern-Ice"
if [ ! -d "$CURSOR_DIR" ]; then
    mkdir -p "$HOME/.icons"
    log "downloading Bibata cursor"
    tmp=$(mktemp -d)
    curl_err=$(mktemp)
    curl -fsSL "https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Ice.tar.xz" \
        -o "$tmp/bibata.tar.xz" 2>"$curl_err" && \
        tar -xf "$tmp/bibata.tar.xz" -C "$HOME/.icons" 2>/dev/null || \
        warn "Bibata cursor download failed (${curl_err:+\"$(cat "$curl_err")\"})"
    rm -rf "$tmp" "$curl_err"
fi

# Set GTK theme via xfconf if available
if command -v xfconf-query >/dev/null 2>&1; then
    if [ -d "$THEME_DIR/Catppuccin-Mocha-Standard-Mauve-Dark" ]; then
        GTK="Catppuccin-Mocha-Standard-Mauve-Dark"
    else
        GTK="Arc-Dark"
    fi
    xfconf-query -c xsettings -p /Net/ThemeName -t string -s "$GTK" --create -n 2>/dev/null || true
    xfconf-query -c xsettings -p /Net/IconThemeName -t string -s "Papirus-Dark" --create -n 2>/dev/null || true
    [ -d "$CURSOR_DIR" ] && \
        xfconf-query -c xsettings -p /Gtk/CursorThemeName -t string -s "Bibata-Modern-Ice" --create -n 2>/dev/null || true
    log "applied GTK theme via xfconf"
fi

ok "theme stack complete"
