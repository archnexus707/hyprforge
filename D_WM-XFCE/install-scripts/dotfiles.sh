#!/usr/bin/env bash
# dotfiles.sh — deploy D_WM-XFCE dotfiles from ./dotfiles/ to ~/.config/
# (and ~/ for .zshrc). Every existing file is backed up first via safety.sh.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/safety.sh
. "$SCRIPT_DIR/lib/safety.sh"

DOTFILES_DIR="$SCRIPT_DIR/../dotfiles"

if [ ! -d "$DOTFILES_DIR" ]; then
    die "dotfiles source dir missing: $DOTFILES_DIR"
fi

printf "\n%s ===== deploying dotfiles =====%s\n" "$YELLOW" "$RESET"

# ~/.config targets — each subdir of dotfiles/ except 'home' maps to ~/.config/<subdir>
for src in "$DOTFILES_DIR"/*/; do
    [ -d "$src" ] || continue
    name=$(basename "$src")
    case "$name" in
        home) continue ;;  # handled below
    esac
    dst="$HOME/.config/$name"
    copy_into_place "$src" "$dst"
done

# 'home' subdir: contents are dotfiles for $HOME directly (e.g. .zshrc, .p10k.zsh)
if [ -d "$DOTFILES_DIR/home" ]; then
    for f in "$DOTFILES_DIR/home"/.[!.]*; do
        [ -e "$f" ] || continue
        copy_into_place "$f" "$HOME/$(basename "$f")"
    done
fi

# Install the theme-switcher binary if it exists in themes/
if [ -f "$SCRIPT_DIR/../themes/dwm-theme.sh" ]; then
    mkdir -p "$HOME/.local/bin"
    copy_into_place "$SCRIPT_DIR/../themes/dwm-theme.sh" "$HOME/.local/bin/dwm-theme"
    [ "$DWM_DRY_RUN" = "1" ] || chmod +x "$HOME/.local/bin/dwm-theme"
    log "installed dwm-theme switcher to ~/.local/bin/"
fi

printf "%s dotfiles deployed.\n" "$OK"
