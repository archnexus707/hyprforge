#!/usr/bin/env bash
# 06-wallpapers.sh — download the hyprforge anime/cyberpunk wallpaper pack.
#
# The pack (~1 GB, 194 images) is shipped as a GitHub Release asset rather than
# committed to the repo, so clones stay fast. This extracts it into
# ~/Pictures/wallpapers (merging, never deleting existing files).
#
# Skip with ARCHNEXUS_SKIP_WALLPAPERS=1. Override the source with WALLPAPER_URL.
set -uo pipefail

ok()  { echo -e "\033[38;5;46m[OK]\033[0m $*"; }
log() { echo -e "\033[38;5;226m[..]\033[0m $*"; }
warn(){ echo -e "\033[38;5;196m[WARN]\033[0m $*"; }

URL="${WALLPAPER_URL:-https://github.com/archnexus707/hyprforge/releases/download/wallpapers-v1/hyprforge-wallpapers.tar}"
DEST="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"

if [ "${ARCHNEXUS_SKIP_WALLPAPERS:-0}" = "1" ]; then
    log "ARCHNEXUS_SKIP_WALLPAPERS=1 — skipping wallpaper pack."
    exit 0
fi

mkdir -p "$DEST"

# Already populated? Treat as idempotent unless forced.
existing=$(find "$DEST" -maxdepth 1 -type f 2>/dev/null | wc -l)
if [ "$existing" -ge 50 ] && [ "${WALLPAPER_FORCE:-0}" != "1" ]; then
    ok "wallpaper pack already present ($existing files in $DEST) — skipping (WALLPAPER_FORCE=1 to redownload)"
    exit 0
fi

# Pick a downloader.
fetch() {
    local url="$1" out="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 -o "$out" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$out" "$url"
    else
        warn "neither curl nor wget found — cannot download wallpapers."
        return 1
    fi
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
tarball="$tmp/wallpapers.tar"

log "downloading wallpaper pack (~1 GB) from release..."
if ! fetch "$URL" "$tarball"; then
    warn "wallpaper download failed — you can re-run ./install-scripts/06-wallpapers.sh later."
    exit 0   # non-fatal: the rice works without the pack
fi

log "extracting into $DEST"
# tar -xf auto-detects gz/zstd/plain; we ship plain .tar.
if tar -xf "$tarball" -C "$DEST"; then
    count=$(find "$DEST" -maxdepth 1 -type f 2>/dev/null | wc -l)
    ok "wallpaper pack installed: $count images in $DEST"
else
    warn "extraction failed — archive may be corrupt; re-run later."
    exit 0
fi
