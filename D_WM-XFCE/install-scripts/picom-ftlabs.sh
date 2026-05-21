#!/usr/bin/env bash
# picom-ftlabs.sh — build and install FT-Labs/picom (the maintained X11
# compositor fork with window animations, dual-kawase blur, rounded corners,
# and shadows). Installed to /usr/local/bin/picom so it takes precedence
# over any apt picom on PATH.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/safety.sh
. "$SCRIPT_DIR/lib/safety.sh"

PICOM_REPO="https://github.com/FT-Labs/picom.git"
PICOM_REF="${PICOM_REF:-main}"
SRC_DIR="$HOME/.cache/dwm-xfce/picom-ftlabs"
INSTALLED_BIN=/usr/local/bin/picom

printf "\n%s ===== picom-ftlabs (build from source) =====%s\n" "$YELLOW" "$RESET"

# Quick skip if we already have a build of this ref.
if [ -x "$INSTALLED_BIN" ] && [ "${FORCE_REBUILD_PICOM:-0}" != "1" ]; then
    current=$("$INSTALLED_BIN" --version 2>/dev/null | head -1 || echo "unknown")
    log "$INSTALLED_BIN already present ($current); skipping. Use FORCE_REBUILD_PICOM=1 to rebuild."
    exit 0
fi

if [ "$DWM_DRY_RUN" = "1" ]; then
    printf "%s would clone %s into %s and build with meson+ninja\n" "$DRY" "$PICOM_REPO" "$SRC_DIR"
    exit 0
fi

mkdir -p "$(dirname "$SRC_DIR")" || die "cannot create cache dir parent of $SRC_DIR"

# Build toolchain sanity check. These come from 00-dependencies.sh; verify
# directly here so that a swallowed apt failure earlier doesn't surface as a
# confusing "meson: command not found" mid-build.
for _picom_tool in git meson ninja pkg-config cc; do
    command -v "$_picom_tool" >/dev/null 2>&1 \
        || die "build tool '$_picom_tool' not found on PATH — rerun ./install.sh --only 00-deps"
done

# Clone or update.
if [ -d "$SRC_DIR/.git" ]; then
    log "updating existing clone at $SRC_DIR"
    git -C "$SRC_DIR" fetch --quiet origin >>"$DWM_LOG" 2>&1 || true
    git -C "$SRC_DIR" reset --hard "origin/$PICOM_REF" >>"$DWM_LOG" 2>&1 || \
        die "git reset to origin/$PICOM_REF failed"
else
    log "cloning $PICOM_REPO into $SRC_DIR (with retry on network failure)"
    safe_git_clone "$PICOM_REPO" "$SRC_DIR" --branch "$PICOM_REF" >>"$DWM_LOG" 2>&1 || \
        die "git clone failed after retries — see $DWM_LOG"
fi

# Configure + build.
cd "$SRC_DIR" || die "cd failed: $SRC_DIR"
log "running meson setup"
meson setup --buildtype=release --prefix=/usr/local build >>"$DWM_LOG" 2>&1 || \
    die "meson setup failed (see $DWM_LOG)"

log "running ninja -C build"
ninja -C build >>"$DWM_LOG" 2>&1 || die "ninja build failed (see $DWM_LOG)"

log "installing to /usr/local"
sudo ninja -C build install >>"$DWM_LOG" 2>&1 || die "ninja install failed"
register_undo "sudo rm -f /usr/local/bin/picom; sudo rm -f /usr/local/share/man/man1/picom.1"

if [ -x "$INSTALLED_BIN" ]; then
    installed_version=$("$INSTALLED_BIN" --version 2>/dev/null | head -1 || echo "unknown")
    printf "%s picom-ftlabs installed: %s\n" "$OK" "$installed_version"
else
    die "picom binary not found after install"
fi
