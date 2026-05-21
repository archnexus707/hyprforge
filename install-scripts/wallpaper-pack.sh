#!/usr/bin/env bash
# wallpaper-pack.sh — OPTIONAL final-phase script.
# Downloads a curated lofi + anime wallpaper pack into ~/Pictures/Wallpapers/
# and (where applicable) sets the first image as the active wallpaper.
#
# Designed to run AFTER the main install. It will:
#   - prompt the user (whiptail if available, plain read otherwise)
#   - skip cleanly if the user declines, no internet, or git missing
#   - never modify anything outside $HOME
#
# Sources are deliberately overridable so the user can swap in their own:
#   WALLPAPER_LOFI_REPO  (default: D3Ext/aesthetic-wallpapers, multi-style pack)
#   WALLPAPER_ANIME_REPO (default: dharmx/walls, anime/aesthetic pack)
#
# Honors NON_INTERACTIVE=1 to skip the prompt entirely (auto-decline).

set -uo pipefail

# Reuse the banner helpers if available (sourced from the parent install.sh
# via safety.sh / Global_functions.sh). Otherwise provide tiny shims.
if ! command -v archnexus_phase >/dev/null 2>&1; then
    archnexus_phase() { printf "\n>>> %s %s\n" "$1" "${2:-}"; }
fi

LOFI_REPO="${WALLPAPER_LOFI_REPO:-https://github.com/D3Ext/aesthetic-wallpapers.git}"
ANIME_REPO="${WALLPAPER_ANIME_REPO:-https://github.com/dharmx/walls.git}"
WALL_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

archnexus_phase "wallpaper-pack" "OPTIONAL — lofi + anime wallpapers"

if [ "${NON_INTERACTIVE:-0}" = "1" ]; then
    echo "[INFO] NON_INTERACTIVE=1; skipping wallpaper pack."
    exit 0
fi

_want_walls=0
if command -v whiptail >/dev/null 2>&1 && [ -t 0 ]; then
    if whiptail --title "Wallpaper pack (optional)" \
        --yesno "Download a curated LOFI + ANIME wallpaper pack into:\n\n  $WALL_DIR\n\nThis is OPTIONAL and can be re-run later via:\n  ./install-scripts/wallpaper-pack.sh\n\nProceed?" 16 70; then
        _want_walls=1
    fi
else
    printf "\n  Download lofi + anime wallpaper pack into %s ?\n" "$WALL_DIR"
    read -rp "  [y/N]: " _ans
    case "${_ans,,}" in
        y|yes) _want_walls=1 ;;
        *) _want_walls=0 ;;
    esac
fi

if [ "$_want_walls" -ne 1 ]; then
    echo "[INFO] Skipped wallpaper pack download (you can re-run any time)."
    exit 0
fi

if ! command -v git >/dev/null 2>&1; then
    echo "[ERROR] git not found; cannot download wallpaper pack." >&2
    exit 1
fi

mkdir -p "$WALL_DIR/lofi" "$WALL_DIR/anime"

_pack_clone() {
    # $1 = repo URL, $2 = destination subdir (under $WALL_DIR)
    local repo="$1" dest="$WALL_DIR/$2"
    local tmp; tmp="$(mktemp -d)"
    echo "[INFO] cloning $repo …"
    if git clone --depth=1 --quiet "$repo" "$tmp/pack" 2>/dev/null; then
        # Copy any image file found under the clone into $dest, flattening.
        find "$tmp/pack" -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
               -o -iname '*.webp' -o -iname '*.gif' \) \
            -exec cp -n {} "$dest"/ \; 2>/dev/null
        local count
        count=$(find "$dest" -maxdepth 1 -type f | wc -l)
        echo "[OK] $count image(s) copied to $dest"
    else
        echo "[WARN] could not clone $repo (offline or repo moved). Skipping."
    fi
    rm -rf "$tmp"
}

_pack_clone "$LOFI_REPO"  "lofi"
_pack_clone "$ANIME_REPO" "anime"

# Optionally set the first image as desktop wallpaper if a WM is detectable.
_first_image=$(find "$WALL_DIR" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
    | head -n1 || true)

if [ -n "$_first_image" ]; then
    echo "[INFO] sample image picked: $_first_image"
    # XFCE / i3 + feh
    if [ -d "$HOME/.config/i3" ]; then
        ln -sf "$_first_image" "$HOME/.config/i3/wallpaper.png"
        echo "[OK] symlinked into ~/.config/i3/wallpaper.png (i3/feh consumers will pick it up)"
    fi
    # Hyprland + swww (only if swww-daemon is running — best-effort)
    if command -v swww >/dev/null 2>&1 && pgrep -x swww-daemon >/dev/null 2>&1; then
        swww img "$_first_image" 2>/dev/null && \
            echo "[OK] applied via swww img" || true
    fi
    # Plain XFCE desktop (xfconf)
    if command -v xfconf-query >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
        xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image \
            -s "$_first_image" 2>/dev/null || true
    fi
fi

echo "[OK] wallpaper pack ready under $WALL_DIR"
exit 0
