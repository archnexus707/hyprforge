#!/usr/bin/env bash
# spawn.sh — D_WM-XFCE cyberpunk session launcher
# Run manually or add to terminal startup for the full neon experience
set -uo pipefail

RESET='\033[0m'; BOLD='\033[1m'; DIM='\033[2m'
GREEN='\033[38;5;46m'; CYAN='\033[38;5;51m'; NEON='\033[38;5;123m'
PINK='\033[38;5;198m'; ORANGE='\033[38;5;208m'; PURPLE='\033[38;5;99m'
YELLOW='\033[38;5;226m'; RED='\033[38;5;196m'; GRAY='\033[38;5;240m'

COLS=$(tput cols 2>/dev/null || echo 80)
TAG="${NEON}${BOLD}[D_WM-XFCE]${RESET}"

typewriter() {
    local text="$1" delay="${2:-0.01}"
    for ((i=0; i<${#text}; i++)); do
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
    echo
}

glitch_out() {
    local text="$1" frames="${2:-3}"
    for ((f=0; f<frames; f++)); do
        local glitched=""
        for ((i=0; i<${#text}; i++)); do
            if [ $((RANDOM % 6)) -eq 0 ]; then
                glitched+=$(printf "\\$(printf '%03o' $((RANDOM % 94 + 33)))")
            else
                glitched+="${text:$i:1}"
            fi
        done
        echo -ne "\r${CYAN}${glitched}${RESET}"
        sleep 0.03
    done
    echo -e "\r${NEON}${BOLD}${text}${RESET}"
}

spinner() {
    local pid="$1" msg="$2"
    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${CYAN}%s${RESET} %s" "${spin:$i:1}" "$msg"
        i=$(( (i+1) % ${#spin} ))
        sleep 0.08
    done
    printf "\r  ${GREEN}■${RESET} %s ${DIM}done${RESET}\n" "$msg"
}

banner() {
    clear
    echo
    echo -e "${NEON}${BOLD}"
    cat <<'EOF'
     ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄▄▄▄▄
     ██▄  ██ ███████████ ███████████ ██▄  ██ ███████████
     ▐██▌  █ ▐████  ████ ▐███     ▐█ ▐██▌  █ ▐███     ▐█
     ▐██▌       ████  ████ ▐█████████▌ ▐██▌    ▐█████████▌
     ▐██▌  ██   ████  ████ ▐███▌       ▐██▌  █ ▐███▌
     ██▌▄ ██   ████  ████ ███████████ ██▌▄ ██ ███████████
EOF
    echo -e "${RESET}"
    echo
    typewriter "  ${PINK}◆${RESET} ${NEON}${BOLD}D_WM-XFCE // SESSION SPAWN // SYSTEM ONLINE${RESET}" 0.008
    echo
}

# ────────────────────────────────────────────────────────────────────────────────
banner

echo -e "${TAG} ${DIM}initializing subsystems...${RESET}"
sleep 0.2

# detect environment
if [ -z "${DISPLAY:-}" ]; then
    echo -e "${TAG} ${RED}no X11 display detected — run from within an i3/XFCE session${RESET}"
    exit 1
fi

# launch daemons if not already running
start_if_dead() {
    local name="$1" cmd="$2"
    if pgrep -x "$name" >/dev/null 2>&1; then
        echo -e "${TAG} ${GREEN}■${RESET} ${name} ${DIM}already running${RESET}"
    else
        echo -ne "${TAG} ${CYAN}◌${RESET} ${name} ${DIM}launching...${RESET}"
        eval "$cmd" &
        sleep 0.3
        if pgrep -x "$name" >/dev/null 2>&1; then
            echo -e "\r${TAG} ${GREEN}■${RESET} ${name} ${DIM}online${RESET}"
        else
            echo -e "\r${TAG} ${RED}□${RESET} ${name} ${RED}failed${RESET}"
        fi
    fi
}

start_if_dead "picom"     "picom --config ~/.config/picom/picom.conf 2>/dev/null"
start_if_dead "dunst"     "dunst 2>/dev/null"

# nm-applet
if pgrep -x "nm-applet" >/dev/null 2>&1; then
    echo -e "${TAG} ${GREEN}■${RESET} nm-applet ${DIM}already running${RESET}"
else
    nm-applet 2>/dev/null &
    echo -e "${TAG} ${GREEN}■${RESET} nm-applet ${DIM}online${RESET}"
fi

# polkit agent
POLKIT_PID=$(pgrep -f polkit-gnome 2>/dev/null || true)
if [ -n "$POLKIT_PID" ]; then
    echo -e "${TAG} ${GREEN}■${RESET} polkit-agent ${DIM}already running${RESET}"
else
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 2>/dev/null &
fi

echo

# ── wallpaper check ────────────────────────────────────────────────────────────
WP="$HOME/.config/i3/wallpaper.png"
if [ -f "$WP" ]; then
    echo -e "${TAG} ${GREEN}■${RESET} wallpaper ${DIM}$(du -h "$WP" | cut -f1)${RESET}"
else
    echo -e "${TAG} ${YELLOW}□${RESET} wallpaper missing — run ${CYAN}./install.sh${RESET}"
fi

echo

# ── fastfetch ──────────────────────────────────────────────────────────────────
if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi

echo
echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo
echo -e "  ${ORANGE}${BOLD}◆ QUICK START${RESET}"
echo
echo -e "  ${CYAN}SUPER+Enter${RESET}   ${DIM}→${RESET} terminal (kitty)"
echo -e "  ${CYAN}SUPER+r${RESET}       ${DIM}→${RESET} launcher (rofi)"
echo -e "  ${CYAN}SUPER+Shift+q${RESET} ${DIM}→${RESET} logout menu"
echo -e "  ${CYAN}./doctor.sh${RESET}  ${DIM}→${RESET} system diagnostic"
echo -e "  ${CYAN}./welcome.sh${RESET} ${DIM}→${RESET} full interactive tour"
echo
echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${GRAY}forged by archnexus707 // hyprforge${RESET}"
echo
