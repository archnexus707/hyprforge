#!/usr/bin/env bash
# welcome.sh — D_WM-XFCE post-install cyberpunk welcome tour
set -uo pipefail

RESET='\033[0m'; BOLD='\033[1m'; DIM='\033[2m'; BLINK='\033[5m'
RED='\033[38;5;196m'; GREEN='\033[38;5;46m'; YELLOW='\033[38;5;226m'
CYAN='\033[38;5;51m'; MAGENTA='\033[38;5;201m'; ORANGE='\033[38;5;208m'
ACCENT='\033[38;5;45m'; PINK='\033[38;5;198m'; PURPLE='\033[38;5;99m'
NEON='\033[38;5;123m'; WHITE='\033[38;5;255m'; GRAY='\033[38;5;240m'

COLS=$(tput cols 2>/dev/null || echo 80)
hr() { printf "%${COLS}s" | tr ' ' '─'; echo; }
center() { printf "%$(( (COLS + ${#1}) / 2 ))s\n" "$1"; }

glitch() {
    local text="$1" color="${2:-$NEON}"
    echo -ne "$color$BOLD$text$RESET"
    sleep 0.02
    echo -ne "\r$GRAY$text$RESET"
    sleep 0.02
    echo -ne "\r$color$BOLD$text$RESET"
}

pulse() {
    local text="$1" delay="${2:-0.015}"
    local i len=${#text}
    for ((i=0; i<len; i++)); do
        echo -ne "${ACCENT}${text:$i:1}${RESET}"
        sleep "$delay"
    done
    echo
}

fade_in() {
    local text="$1"
    echo -e "$DIM$text$RESET"
    sleep 0.08
    echo -e "\033[1A${RESET}$text$RESET"
}

box() {
    local color="$1" text="$2"
    local pad=$(( (COLS - ${#text} - 4) / 2 ))
    [ "$pad" -lt 0 ] && pad=0
    printf "${color}%${pad}s┌─ %s ─┐%s\n" "" "$text" "$RESET" | sed "s/ /─/g; s/┌/╭/; s/┐/╮/"
}

# ────────────────────────────────────────────────────────────────────────────────
clear
echo
echo -e "$CYAN$BOLD"
cat <<'BOOT'
    ╔══════════════════════════════════════════════════════════╗
    ║     ▓▓ ▓▓   ▓▓  ▓▓▓▓▓▓▓▓    ▓▓▓▓▓▓   ▓▓▓▓▓▓▓▓          ║
    ║     ▓▓ ▓▓   ▓▓  ▓▓▓▓▓▓▓▓   ▓▓▓▓▓▓▓   ▓▓▓▓▓▓▓▓          ║
    ║     ▓▓ ▓▓ ▓ ▓▓  ▓▓▓▓▓▓▓▓   ▓▓▓ ▓▓▓   ▓▓▓▓▓▓▓▓          ║
    ║     ▓▓ ▓▓▓ ▓▓▓  ▓▓▓▓▓▓▓▓   ▓▓▓ ▓▓▓   ▓▓▓▓▓▓▓▓          ║
    ║     ▓▓ ▓▓   ▓▓  ▓▓▓▓▓▓▓▓   ▓▓▓ ▓▓▓   ▓▓▓▓▓▓▓▓          ║
    ║     ▓▓ ▓▓   ▓▓  ▓▓▓▓▓▓▓▓   ▓▓▓ ▓▓▓   ▓▓▓▓▓▓▓▓          ║
    ╚══════════════════════════════════════════════════════════╝
BOOT
echo -e "$RESET"
echo
pulse ">>> D_WM-XFCE // cyberpunk rice // system online <<<"
echo
hr

# ── system scan ────────────────────────────────────────────────────────────────
box "$PINK" "SYSTEM SCAN"
echo

KERNEL=$(uname -r)
DISTRO=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "unknown")
SHELL_VER=$("$SHELL" --version 2>/dev/null | head -1 || echo "$SHELL")
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' || uptime)
RAM=$(free -h | awk '/^Mem:/ {print $3 " / " $2}')
DISK=$(df -h / | awk 'NR==2 {print $3 " / " $2}')
CPU=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d: -f2 | xargs || echo "unknown")
GPU=$(lspci 2>/dev/null | grep -i vga | head -1 | cut -d: -f3 | xargs || echo "unknown")
IS_VM=$(systemd-detect-virt 2>/dev/null || echo "none")

echo -e "  ${ACCENT}distro${RESET}    ${DISTRO}"
echo -e "  ${ACCENT}kernel${RESET}    ${KERNEL}"
echo -e "  ${ACCENT}shell${RESET}     ${SHELL_VER}"
echo -e "  ${ACCENT}uptime${RESET}    ${UPTIME}"
echo -e "  ${ACCENT}ram${RESET}       ${RAM}"
echo -e "  ${ACCENT}disk${RESET}      ${DISK}"
echo -e "  ${ACCENT}cpu${RESET}       ${CPU}"
echo -e "  ${ACCENT}gpu${RESET}       ${GPU:-unknown}"
echo -e "  ${ACCENT}platform${RESET}  ${IS_VM}"
echo
sleep 0.3

# ── rice check ─────────────────────────────────────────────────────────────────
box "$NEON" "RICE INTEGRITY"
echo

checks=(
    "$HOME/.config/i3/config:i3 config"
    "$HOME/.config/picom/picom.conf:picom compositor"
    "$HOME/.config/kitty/kitty.conf:kitty terminal"
    "$HOME/.config/rofi/config.rasi:rofi launcher"
    "$HOME/.config/dunst/dunstrc:dunst notifications"
    "$HOME/.config/i3/wallpaper.png:wallpaper"
    "$HOME/.oh-my-zsh/.git:oh-my-zsh"
    "$HOME/.config/i3/logout-menu.sh:logout menu"
)

for check in "${checks[@]}"; do
    path="${check%%:*}" label="${check##*:}"
    if [ -e "$path" ]; then
        echo -e "  ${GREEN}[■]${RESET} $label ${GRAY}online${RESET}"
    else
        echo -e "  ${RED}[□]${RESET} $label ${RED}offline${RESET}"
    fi
    sleep 0.04
done
echo

# ── keybinds quick ref ─────────────────────────────────────────────────────────
box "$CYAN" "QUICK REFERENCE"
echo
echo -e "  ${ACCENT}SUPER + Enter${RESET}    terminal (kitty)"
echo -e "  ${ACCENT}SUPER + r${RESET}        app launcher (rofi)"
echo -e "  ${ACCENT}SUPER + d${RESET}        app launcher (rofi)"
echo -e "  ${ACCENT}SUPER + Tab${RESET}      window switcher"
echo -e "  ${ACCENT}SUPER + q${RESET}        close window"
echo -e "  ${ACCENT}SUPER + f${RESET}        fullscreen toggle"
echo -e "  ${ACCENT}SUPER + space${RESET}    float toggle"
echo -e "  ${ACCENT}SUPER + 1..0${RESET}     switch workspace"
echo -e "  ${ACCENT}SUPER + Shift+q${RESET}  logout menu"
echo -e "  ${ACCENT}SUPER + Shift+c${RESET}  reload i3 config"
echo -e "  ${ACCENT}SUPER + t${RESET}        resize mode"
echo -e "  ${ACCENT}SUPER + h/j/k/l${RESET}  vim-style focus"
echo

# ── tips ───────────────────────────────────────────────────────────────────────
box "$ORANGE" "PRO TIPS"
echo
echo -e "  ${YELLOW}▸${RESET} Edit i3 config:  ${ACCENT}kitty ~/.config/i3/config${RESET}"
echo -e "  ${YELLOW}▸${RESET} Change wallpaper: ${ACCENT}feh --bg-fill <image>${RESET}"
echo -e "  ${YELLOW}▸${RESET} System diagnostic: ${ACCENT}./doctor.sh${RESET}"
echo -e "  ${YELLOW}▸${RESET} Re-run installer:  ${ACCENT}./install.sh${RESET}"
echo -e "  ${YELLOW}▸${RESET} Full system monitor: ${ACCENT}btop${RESET}"
echo -e "  ${YELLOW}▸${RESET} Screenshot (area):  ${ACCENT}Print${RESET}"
echo -e "  ${YELLOW}▸${RESET} Screenshot (gui):   ${ACCENT}SUPER + Print${RESET}"
echo -e "  ${YELLOW}▸${RESET} Logout to XFCE:     pick ${ACCENT}Xfce Session${RESET} in greeter"
echo

# ── footer ─────────────────────────────────────────────────────────────────────
hr
echo
pulse ">>> forged by arch_nexus707 // hyprforge // reboot the system <<<"
echo -e "$DIM   https://github.com/archnexus707/hyprforge$RESET"
echo

# ── offer to launch rofi launcher ──────────────────────────────────────────────
if command -v rofi >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
    echo -ne "  ${CYAN}[?]${RESET} Launch app launcher? ${DIM}[y/N]${RESET} "
    read -r ans
    [ "$ans" = "y" ] || [ "$ans" = "Y" ] && rofi -show drun &
fi

echo
