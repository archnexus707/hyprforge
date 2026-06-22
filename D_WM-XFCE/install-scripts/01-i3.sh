#!/usr/bin/env bash
set -uo pipefail

ok()  { echo -e "\033[38;5;46m[OK]\033[0m $*"; }
log() { echo -e "\033[38;5;226m[..]\033[0m $*"; }
warn(){ echo -e "\033[38;5;196m[WARN]\033[0m $*"; }

log "verifying i3 installation"
command -v i3 >/dev/null 2>&1 || { warn "i3 not found, run 00-deps.sh first"; exit 1; }

i3_ver=$(i3 --version 2>/dev/null | head -1)
log "i3 version: $i3_ver"

# Create session .desktop so greeter shows "i3 Cyberpunk"
DESKTOP="/usr/share/xsessions/i3-cyberpunk.desktop"
log "creating session entry: $DESKTOP"
sudo tee "$DESKTOP" >/dev/null <<'EOF' || { warn "cannot write $DESKTOP (sudo required)"; exit 1; }
[Desktop Entry]
Name=i3 Cyberpunk
Comment=Cyberpunk i3 tiling session with picom compositing
Exec=i3
Type=Application
DesktopNames=i3
EOF

ok "i3 session entry created. Will appear in greeter as 'i3 Cyberpunk'"
