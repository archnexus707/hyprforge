#!/usr/bin/env bash
# setup.sh — D_WM-XFCE quick bootstrapper
# Installs only the essential apt dependencies + i3 session entry.
# For the full cyberpunk rice, run ./install.sh after this.
set -uo pipefail

RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[38;5;46m'
RED='\033[38;5;196m'
YELLOW='\033[38;5;226m'
CYAN='\033[38;5;51m'

ok()  { echo -e "  ${GREEN}[OK]${RESET} $*"; }
log() { echo -e "  ${YELLOW}[..]${RESET} $*"; }
die() { echo -e "  ${RED}[FATAL]${RESET} $*"; exit 1; }

echo -e "${CYAN}${BOLD}D_WM-XFCE Setup Bootstrapper${RESET}"
echo

[ "$(id -u)" -eq 0 ] && die "do not run as root"

is_kali() { [ -r /etc/os-release ] && grep -qi kali /etc/os-release; }
is_kali || echo -e "  ${YELLOW}[WARN]${RESET} not Kali Linux — proceed with caution"
echo

# ── apt update ─────────────────────────────────────────────────────────────────
log "updating apt package lists"
sudo apt-get update || die "apt update failed"

# ── core packages ──────────────────────────────────────────────────────────────
CORE=(
    i3 i3-wm i3status i3lock
    picom rofi dunst feh kitty zsh
    policykit-1-gnome network-manager-gnome thunar
)
log "installing core packages (${#CORE[@]} total)"
sudo apt-get install -y --no-install-recommends "${CORE[@]}" || die "core package install failed"
ok "core packages installed"

# ── optional CLI tools ─────────────────────────────────────────────────────────
OPTIONAL=(fastfetch eza bat btop maim xclip flameshot pulseaudio-utils playerctl brightnessctl)
log "installing optional CLI tools (${#OPTIONAL[@]} total)"
for pkg in "${OPTIONAL[@]}"; do
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed" && continue
    sudo apt-get install -y --no-install-recommends "$pkg" 2>/dev/null || echo -e "  ${YELLOW}[WARN]${RESET} skipped: $pkg"
done
ok "optional tools done"

# ── picom config dir ───────────────────────────────────────────────────────────
mkdir -p "$HOME/.config/picom"

# ── i3 session entry ───────────────────────────────────────────────────────────
DESKTOP="/usr/share/xsessions/i3-cyberpunk.desktop"
if [ ! -f "$DESKTOP" ]; then
    log "creating i3 session desktop entry"
    sudo tee "$DESKTOP" >/dev/null <<'EOF'
[Desktop Entry]
Name=i3 Cyberpunk
Comment=Cyberpunk i3 tiling session with picom compositing
Exec=i3
Type=Application
DesktopNames=i3
EOF
    ok "session entry created"
else
    ok "session entry already exists"
fi

echo
echo -e "${GREEN}${BOLD}Setup complete. Next: run ./install.sh for the full rice.${RESET}"
