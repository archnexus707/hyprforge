#!/usr/bin/env bash
set -uo pipefail

ok()  { echo -e "\033[38;5;46m[OK]\033[0m $*"; }
log() { echo -e "\033[38;5;226m[..]\033[0m $*"; }
warn(){ echo -e "\033[38;5;196m[WARN]\033[0m $*"; }
die() { echo -e "\033[38;5;196m[FATAL]\033[0m $*"; exit 1; }

log "refreshing apt package lists"
sudo apt-get update || warn "apt update had issues, continuing anyway"

PACKAGES=(
    i3 i3-wm i3status i3lock
    picom
    rofi
    dunst
    feh
    kitty
    zsh
    fastfetch
    eza
    bat
    btop
    maim
    xclip
    flameshot
    pulseaudio-utils
    playerctl
    brightnessctl
    papirus-icon-theme
    network-manager-gnome
    thunar
)

for pkg in "${PACKAGES[@]}"; do
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        log "already installed: $pkg"
        continue
    fi
    log "installing $pkg"
    sudo apt-get install -y --no-install-recommends "$pkg" || warn "failed to install $pkg"
done

# picom config dir
mkdir -p "$HOME/.config/picom"

# pokemon-colorscripts — powers the fastfetch terminal greeter. Not in apt, so
# install from upstream (needs python3 + git). Idempotent: skip if present.
if command -v pokemon-colorscripts >/dev/null 2>&1; then
    log "already installed: pokemon-colorscripts"
elif command -v git >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
    log "installing pokemon-colorscripts (terminal greeter)"
    _pcs_dir="$(mktemp -d)"
    if git clone --depth=1 https://gitlab.com/phoneybadger/pokemon-colorscripts.git "$_pcs_dir" >/dev/null 2>&1; then
        ( cd "$_pcs_dir" && sudo ./install.sh ) >/dev/null 2>&1 \
            && ok "pokemon-colorscripts installed" \
            || warn "pokemon-colorscripts install failed (greeter falls back to plain fastfetch)"
    else
        warn "pokemon-colorscripts clone failed (greeter falls back to plain fastfetch)"
    fi
    rm -rf "$_pcs_dir"
else
    warn "git/python3 missing — skipping pokemon-colorscripts (greeter falls back to plain fastfetch)"
fi

ok "dependencies complete"
