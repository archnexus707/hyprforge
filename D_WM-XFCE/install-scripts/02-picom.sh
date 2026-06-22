#!/usr/bin/env bash
# 02-picom.sh — picom compositor. Detects VMware, uses safe backend.
set -uo pipefail

ok()  { echo -e "\033[38;5;46m[OK]\033[0m $*"; }
log() { echo -e "\033[38;5;226m[..]\033[0m $*"; }
warn(){ echo -e "\033[38;5;196m[WARN]\033[0m $*"; }

log "verifying picom installation"
command -v picom >/dev/null 2>&1 || { log "installing picom via apt"; sudo apt-get install -y picom || { warn "picom apt install failed"; exit 1; }; }

picom_ver=$(picom --version 2>/dev/null | head -1 || echo "unknown")
log "picom version: $picom_ver"

# VMware detection
is_vmware() { systemd-detect-virt 2>/dev/null | grep -qi vmware; }

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/dotfiles"
SRC="$DOTFILES/picom/picom.conf"
DST="$HOME/.config/picom/picom.conf"

if [ -f "$DST" ]; then
    cp -a "$DST" "$DST.bak.$(date +%s)"
    log "backed up existing picom.conf"
fi
mkdir -p "$(dirname "$DST")"

if is_vmware; then
    log "VMware detected — using xrender backend (VMware-safe, no blur)"
    SRC="$DOTFILES/picom/picom-vmware.conf"
fi

cp "$SRC" "$DST"
ok "picom config installed: $DST ($(is_vmware && echo 'VMware-safe xrender' || echo 'GLX with effects'))"
