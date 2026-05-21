#!/usr/bin/env bash
# 00-dependencies.sh — base build + runtime deps for D_WM-XFCE.
# Idempotent: re-running is a no-op if everything is already installed.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/safety.sh
. "$SCRIPT_DIR/lib/safety.sh"

# Build tools needed to compile picom-ftlabs from source.
build_deps=(
    build-essential
    cmake
    meson
    ninja-build
    pkg-config
    git
    curl
    wget
    unzip
    ca-certificates
)

# Picom build dependencies (Xorg + EGL + image/text libs).
picom_deps=(
    libxext-dev
    libxcb1-dev
    libxcb-damage0-dev
    libxcb-dpms0-dev
    libxcb-xfixes0-dev
    libxcb-shape0-dev
    libxcb-render-util0-dev
    libxcb-render0-dev
    libxcb-randr0-dev
    libxcb-composite0-dev
    libxcb-image0-dev
    libxcb-present-dev
    libxcb-glx0-dev
    libxcb-util0-dev
    libpixman-1-dev
    libdbus-1-dev
    libconfig-dev
    libgl1-mesa-dev
    libegl-dev
    libpcre2-dev
    libevdev-dev
    uthash-dev
    libev-dev
    libx11-xcb-dev
    libxcb-xinerama0-dev
)

# Runtime tools we depend on across phases.
runtime_deps=(
    whiptail
    xdotool
    jq
    xdg-utils
    xdg-user-dirs
)

printf "\n%s ===== installing base + build dependencies =====%s\n" "$YELLOW" "$RESET"

# Refresh package lists once at the start so the rest of the install run uses
# current versions. apt-get update is allowed to soft-fail (network blip on a
# single mirror is not fatal — the actual install will surface a hard error).
if [ "$DWM_DRY_RUN" != "1" ]; then
    log "refreshing apt package lists"
    sudo apt-get update >>"$DWM_LOG" 2>&1 || \
        printf "%s apt-get update returned non-zero (continuing)\n" "$WARN"
fi

apt_install_safe "${build_deps[@]}" || die "build deps failed"
apt_install_safe "${runtime_deps[@]}" || die "runtime deps failed"
apt_install_safe "${picom_deps[@]}" || die "picom deps failed"

log "00-dependencies.sh complete"
