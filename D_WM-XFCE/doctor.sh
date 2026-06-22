#!/usr/bin/env bash
# doctor.sh — D_WM-XFCE system health diagnostic
set -uo pipefail

RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[38;5;46m'
RED='\033[38;5;196m'
YELLOW='\033[38;5;226m'
CYAN='\033[38;5;51m'
MAGENTA='\033[38;5;201m'

PASS=0; FAIL=0; WARN=0

pass() { ((PASS++)); echo -e "  ${GREEN}[PASS]${RESET} $*"; }
fail() { ((FAIL++)); echo -e "  ${RED}[FAIL]${RESET} $*"; }
warn() { ((WARN++)); echo -e "  ${YELLOW}[WARN]${RESET} $*"; }

header() { echo; echo -e "${MAGENTA}── $* ──${RESET}"; }

banner() {
    echo -e "${CYAN}  D_WM-XFCE System Diagnostic${RESET}"
    echo -e "${CYAN}  $(date)${RESET}"
    echo
}

pkg_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"; }
file_exists()  { [ -e "$1" ]; }
cmd_exists()   { command -v "$1" >/dev/null 2>&1; }
is_vmware()    { systemd-detect-virt 2>/dev/null | grep -qi vmware; }

# ────────────────────────────────────────────────────────────────────────────────
banner

# ── system ─────────────────────────────────────────────────────────────────────
header "System"

is_kali(){ [ -r /etc/os-release ] && grep -qi kali /etc/os-release; }
is_kali && pass "Kali Linux detected" || warn "not Kali — some deps may differ"

is_root_user(){ [ "$(id -u)" -eq 0 ]; }
is_root_user && warn "running as root (not recommended)" || pass "running as normal user"

header "Core Packages"
for pkg in i3 i3-wm i3status i3lock picom rofi dunst feh kitty zsh; do
    pkg_installed "$pkg" && pass "$pkg" || fail "$pkg — missing"
done

header "CLI Tools"
for pkg in fastfetch eza bat btop maim xclip; do
    pkg_installed "$pkg" && pass "$pkg" || warn "$pkg — missing (optional)"
done

header "Audio & Brightness"
for pkg in pulseaudio-utils playerctl brightnessctl; do
    pkg_installed "$pkg" && pass "$pkg" || warn "$pkg — missing"
done

header "System Utils"
for pkg in policykit-1-gnome network-manager-gnome thunar; do
    pkg_installed "$pkg" && pass "$pkg" || fail "$pkg — missing"
done

# ── i3 session ─────────────────────────────────────────────────────────────────
header "i3 Session Entry"
DESKTOP="/usr/share/xsessions/i3-cyberpunk.desktop"
if file_exists "$DESKTOP"; then
    pass "session desktop entry exists"
    grep -q "i3" "$DESKTOP" && pass "desktop entry references i3" || fail "desktop entry may be invalid"
else
    fail "session desktop entry missing — run 01-i3.sh"
fi

# ── dotfiles ───────────────────────────────────────────────────────────────────
header "Dotfiles Deployment"

check_dotfile() { file_exists "$1" && pass "$2" || fail "$2 — missing"; }

check_dotfile "$HOME/.config/i3/config"           "i3 config"
check_dotfile "$HOME/.config/i3/logout-menu.sh"    "i3 logout-menu"
[ -x "$HOME/.config/i3/logout-menu.sh" ] 2>/dev/null && pass "logout-menu is executable" || warn "logout-menu not +x"
check_dotfile "$HOME/.config/i3/wallpaper.png"     "wallpaper"
check_dotfile "$HOME/.config/kitty/kitty.conf"     "kitty config"
check_dotfile "$HOME/.config/rofi/config.rasi"     "rofi config"
check_dotfile "$HOME/.config/rofi/theme.rasi"      "rofi theme"
check_dotfile "$HOME/.config/dunst/dunstrc"        "dunst config"
check_dotfile "$HOME/.config/picom/picom.conf"     "picom config"

# ── picom VMware check ─────────────────────────────────────────────────────────
if is_vmware; then
    if grep -q 'backend.*xrender' "$HOME/.config/picom/picom.conf" 2>/dev/null; then
        pass "picom using VMware-safe xrender backend"
    else
        fail "VMware detected but picom using GLX — run 02-picom.sh to fix"
    fi
else
    pass "bare-metal — picom config check skipped (GLX should work)"
fi

# ── shell ──────────────────────────────────────────────────────────────────────
header "Shell & OMZ"

cmd_exists zsh && pass "zsh available" || fail "zsh not found"
[ "$(basename "$SHELL")" = "zsh" ] && pass "default shell is zsh" || warn "default shell is $(basename "$SHELL")"

OMZ_DIR="$HOME/.oh-my-zsh"
if [ -d "$OMZ_DIR/.git" ]; then
    pass "oh-my-zsh installed"
else
    fail "oh-my-zsh not installed — run 03-terminal.sh"
fi

P10K_DIR="${ZSH_CUSTOM:-$OMZ_DIR/custom}/themes/powerlevel10k"
[ -d "$P10K_DIR/.git" ] && pass "powerlevel10k installed" || fail "powerlevel10k missing"

for plug in zsh-autosuggestions zsh-syntax-highlighting; do
    [ -d "$OMZ_DIR/custom/plugins/$plug/.git" ] && pass "$plug" || fail "$plug missing"
done

# ── theme stack ────────────────────────────────────────────────────────────────
header "GTK Theme & Cursor"

THEME_DIR="$HOME/.themes"
CAT_THEME="$THEME_DIR/Catppuccin-Mocha-Standard-Mauve-Dark"
[ -d "$CAT_THEME" ] && pass "Catppuccin GTK theme" || warn "Catppuccin theme missing — run 04-theme.sh"

[ -f "$HOME/.icons/Bibata-Modern-Ice/index.theme" ] 2>/dev/null && pass "Bibata cursor" || warn "Bibata cursor missing"

pkg_installed arc-theme && pass "arc-theme (fallback)" || warn "arc-theme missing"

# ── fonts ──────────────────────────────────────────────────────────────────────
header "Fonts"
if fc-list 2>/dev/null | grep -qi "JetBrainsMono"; then
    pass "JetBrainsMono Nerd Font"
else
    warn "JetBrainsMono Nerd Font not found — kitty may fall back to monospace"
fi

# ── wallpaper ──────────────────────────────────────────────────────────────────
header "Wallpaper"
if [ -f "$HOME/.config/i3/wallpaper.png" ]; then
    pass "wallpaper present ($(du -h "$HOME/.config/i3/wallpaper.png" | cut -f1))"
else
    fail "wallpaper missing"
fi

# ── summary ────────────────────────────────────────────────────────────────────
echo
echo -e "${BOLD}═══════════════════════════════════════${RESET}"
echo -e "${GREEN}PASS: $PASS${RESET}  ${RED}FAIL: $FAIL${RESET}  ${YELLOW}WARN: $WARN${RESET}"
if [ "$FAIL" -eq 0 ] && [ "$WARN" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}  All checks passed — system is healthy${RESET}"
elif [ "$FAIL" -eq 0 ]; then
    echo -e "${YELLOW}${BOLD}  System OK with $WARN warnings${RESET}"
else
    echo -e "${RED}${BOLD}  $FAIL issue(s) need attention — re-run the failing phases${RESET}"
fi
echo -e "${BOLD}═══════════════════════════════════════${RESET}"
