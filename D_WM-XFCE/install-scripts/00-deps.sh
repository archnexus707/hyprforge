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
    policykit-1-gnome
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

ok "dependencies complete"
