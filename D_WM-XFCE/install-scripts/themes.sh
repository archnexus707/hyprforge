#!/usr/bin/env bash
# themes.sh — install GTK themes, icon themes, and cursor themes that the
# three D_WM theme presets switch between. The actual switching binary
# lives in themes/dwm-theme.sh (Phase 5) and is installed by dotfiles.sh.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/safety.sh
. "$SCRIPT_DIR/lib/safety.sh"

# Stuff Kali has in apt repos (lowest-risk path).
apt_themes=(
    papirus-icon-theme
    adwaita-icon-theme-full
    arc-theme
)

printf "\n%s ===== GTK / icon / cursor themes =====%s\n" "$YELLOW" "$RESET"

apt_install_safe "${apt_themes[@]}" || die "theme apt packages failed (see $DWM_LOG)"

USER_THEMES="$HOME/.themes"
USER_ICONS="$HOME/.icons"
mkdir -p "$USER_THEMES" "$USER_ICONS"

# ----- helper to git-clone into a target dir, skipping if present ------------
clone_if_missing() {
    local name="$1" repo="$2" dest="$3" subdir="${4:-}"
    if [ -d "$dest" ]; then
        log "$name already installed at $dest"
        return 0
    fi
    if [ "$DWM_DRY_RUN" = "1" ]; then
        printf "%s would clone %s into %s\n" "$DRY" "$repo" "$dest"
        return 0
    fi
    local tmp; tmp=$(mktemp -d)
    if safe_git_clone "$repo" "$tmp/src" >>"$DWM_LOG" 2>&1; then
        if [ -n "$subdir" ] && [ -d "$tmp/src/$subdir" ]; then
            mv "$tmp/src/$subdir" "$dest"
        else
            mv "$tmp/src" "$dest"
        fi
        register_undo "rm -rf \"$dest\""
        log "installed $name"
    else
        printf "%s clone failed after retries: %s — skipping\n" "$WARN" "$name"
    fi
    rm -rf "$tmp"
}

# ----- Catppuccin GTK theme (for catppuccin-mocha preset) --------------------
clone_if_missing "Catppuccin-GTK" \
    "https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme.git" \
    "$HOME/.cache/dwm-xfce/Catppuccin-GTK"
# Actual install (its installer copies into ~/.themes/)
if [ -d "$HOME/.cache/dwm-xfce/Catppuccin-GTK/themes" ] && [ "$DWM_DRY_RUN" != "1" ]; then
    cp -r "$HOME/.cache/dwm-xfce/Catppuccin-GTK/themes/"* "$USER_THEMES/" 2>>"$DWM_LOG" || true
    register_undo "rm -rf \"$USER_THEMES/Catppuccin-Mocha-Standard-Mauve-Dark\""
fi

# ----- Tokyo Night GTK theme --------------------------------------------------
clone_if_missing "Tokyonight-GTK" \
    "https://github.com/Fausto-Korpsvart/Tokyo-Night-GTK-Theme.git" \
    "$HOME/.cache/dwm-xfce/Tokyonight-GTK"
if [ -d "$HOME/.cache/dwm-xfce/Tokyonight-GTK/themes" ] && [ "$DWM_DRY_RUN" != "1" ]; then
    cp -r "$HOME/.cache/dwm-xfce/Tokyonight-GTK/themes/"* "$USER_THEMES/" 2>>"$DWM_LOG" || true
    register_undo "find \"$USER_THEMES\" -maxdepth 1 -name 'Tokyonight-*' -exec rm -rf {} +"
fi

# ----- Tela-circle icon theme (cyan = cyberpunk-ish) -------------------------
clone_if_missing "Tela-circle-icons" \
    "https://github.com/vinceliuice/Tela-circle-icon-theme.git" \
    "$HOME/.cache/dwm-xfce/Tela-circle"
if [ -x "$HOME/.cache/dwm-xfce/Tela-circle/install.sh" ] && [ "$DWM_DRY_RUN" != "1" ]; then
    log "running Tela-circle install.sh (cyan variant)"
    (cd "$HOME/.cache/dwm-xfce/Tela-circle" && ./install.sh -d "$USER_ICONS" cyan) \
        >>"$DWM_LOG" 2>&1 || \
        printf "%s Tela-circle installer failed; you can rerun manually.\n" "$WARN"
    register_undo "find \"$USER_ICONS\" -maxdepth 1 -name 'Tela-circle*' -exec rm -rf {} +"
fi

# ----- Bibata Modern Ice cursor ----------------------------------------------
BIBATA_DIR="$USER_ICONS/Bibata-Modern-Ice"
if [ -d "$BIBATA_DIR" ]; then
    log "Bibata-Modern-Ice cursor already installed"
elif [ "$DWM_DRY_RUN" = "1" ]; then
    printf "%s would download Bibata-Modern-Ice cursor\n" "$DRY"
else
    log "downloading Bibata-Modern-Ice cursor"
    BIBATA_URL="https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Ice.tar.xz"
    tmp=$(mktemp -d)
    if safe_curl_download "$BIBATA_URL" "$tmp/bibata.tar.xz" >>"$DWM_LOG" 2>&1; then
        tar -xf "$tmp/bibata.tar.xz" -C "$USER_ICONS" >>"$DWM_LOG" 2>&1
        register_undo "rm -rf \"$BIBATA_DIR\""
        log "Bibata-Modern-Ice installed"
    else
        printf "%s Bibata download failed after retries.\n" "$WARN"
    fi
    rm -rf "$tmp"
fi

printf "%s themes phase complete (3 GTK themes + Tela-circle + Bibata).\n" "$OK"
