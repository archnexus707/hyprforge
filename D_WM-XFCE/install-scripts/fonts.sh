#!/usr/bin/env bash
# fonts.sh — install Nerd Fonts used by kitty, waybar/xfce-panel, and rofi.
#
# We install per-user to ~/.local/share/fonts/ so no sudo is needed and uninstall
# is just deleting the directory. fc-cache is run to refresh the font cache.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/safety.sh
. "$SCRIPT_DIR/lib/safety.sh"

FONT_DIR="$HOME/.local/share/fonts/D_WM"
NF_VERSION="3.2.1"
NF_BASE="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NF_VERSION}"

fonts=(
    "JetBrainsMono.zip"
    "FiraCode.zip"
    "Iosevka.zip"
)

printf "\n%s ===== installing Nerd Fonts (per-user) =====%s\n" "$YELLOW" "$RESET"

if [ "$DWM_DRY_RUN" = "1" ]; then
    for f in "${fonts[@]}"; do
        printf "%s would download %s/%s into %s\n" "$DRY" "$NF_BASE" "$f" "$FONT_DIR"
    done
    exit 0
fi

mkdir -p "$FONT_DIR"
register_undo "rm -rf \"$FONT_DIR\""

tmpdir=$(mktemp -d) || die "mktemp -d failed"
trap "rm -rf '$tmpdir'" EXIT

download_failures=0
for f in "${fonts[@]}"; do
    name="${f%.zip}"
    if ls "$FONT_DIR" 2>/dev/null | grep -qi "^${name}"; then
        log "$name already installed; skipping"
        continue
    fi
    log "downloading $f (with retry on network failure)"
    if ! safe_curl_download "$NF_BASE/$f" "$tmpdir/$f" 2>>"$DWM_LOG"; then
        printf "%s download failed after retries: %s\n" "$WARN" "$f"
        download_failures=$((download_failures+1))
        continue
    fi
    log "extracting $f"
    unzip -qo "$tmpdir/$f" -d "$FONT_DIR/$name" 2>>"$DWM_LOG" \
        || { printf "%s unzip failed for %s\n" "$WARN" "$f"; download_failures=$((download_failures+1)); continue; }
done

# Refresh font cache
if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$FONT_DIR" >>"$DWM_LOG" 2>&1
    log "fc-cache refreshed"
fi

# Verify at least one Nerd Font is now available. Missing icons leave kitty,
# rofi, and the panel rendering boxes — call that a phase failure so install.sh
# surfaces it in the final summary instead of burying it as a soft warning.
if fc-list 2>/dev/null | grep -qi "nerd"; then
    printf "%s Nerd Fonts installed.\n" "$OK"
    exit 0
fi

printf "%s no Nerd Font detected after install.\n" "$ERROR"
printf "%s kitty + rofi icons WILL render as boxes until a Nerd Font is available.\n" "$INFO"
if [ "$download_failures" -gt 0 ]; then
    printf "%s %d font download(s) failed — check network/proxy then rerun: ./install.sh --only fonts\n" \
        "$INFO" "$download_failures"
fi
exit 1
