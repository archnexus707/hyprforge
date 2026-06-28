#!/usr/bin/env bash
set -uo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPTS_DIR/../dotfiles" && pwd)"
BACKUP_SUFFIX=".bak.$(date +%s)"

ok()  { echo -e "\033[38;5;46m[OK]\033[0m $*"; }
log() { echo -e "\033[38;5;226m[..]\033[0m $*"; }

backup_and_copy() {
    local src="$1" dst="$2"
    [ -e "$src" ] || { log "missing src: $src"; return 1; }
    if [ -e "$dst" ]; then
        cp -a "$dst" "$dst$BACKUP_SUFFIX"
        log "backed up $dst"
    fi
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
    ok "deployed $dst"
}

log "deploying dotfiles"

# ~/.config/ targets
backup_and_copy "$DOTFILES/i3/config"      "$HOME/.config/i3/config"
backup_and_copy "$DOTFILES/i3/logout-menu.sh" "$HOME/.config/i3/logout-menu.sh"
# picom.conf deployed by 02-picom.sh (with VMware detection)
backup_and_copy "$DOTFILES/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
backup_and_copy "$DOTFILES/rofi/config.rasi" "$HOME/.config/rofi/config.rasi"
backup_and_copy "$DOTFILES/rofi/theme.rasi"  "$HOME/.config/rofi/theme.rasi"
backup_and_copy "$DOTFILES/dunst/dunstrc"    "$HOME/.config/dunst/dunstrc"
# fastfetch pokemon greeter config (used by the .zshrc terminal-launch greeter)
backup_and_copy "$DOTFILES/fastfetch/config-pokemon.jsonc" "$HOME/.config/fastfetch/config-pokemon.jsonc"

# home dotfiles
if [ -d "$DOTFILES/home" ]; then
    for f in "$DOTFILES/home"/.[!.]*; do
        [ -e "$f" ] || continue
        backup_and_copy "$f" "$HOME/$(basename "$f")"
    done
fi

# wallpaper
WALLPAPER_SRC="$SCRIPTS_DIR/../wallpaper/cyberpunk.png"
WALLPAPER_DST="$HOME/.config/i3/wallpaper.png"
if [ -f "$WALLPAPER_SRC" ]; then
    backup_and_copy "$WALLPAPER_SRC" "$WALLPAPER_DST"
fi

# make logout menu executable
if [ -f "$HOME/.config/i3/logout-menu.sh" ]; then
    chmod +x "$HOME/.config/i3/logout-menu.sh"
fi

ok "dotfiles deployed"
