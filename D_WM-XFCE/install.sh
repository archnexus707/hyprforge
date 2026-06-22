#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[38;5;196m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
CYAN='\033[38;5;51m'
MAGENTA='\033[38;5;201m'
ORANGE='\033[38;5;208m'
PINK='\033[38;5;198m'
NEON='\033[38;5;123m'

banner() {
    clear
    echo
    echo -e "${CYAN}${BOLD}"
    cat <<'EOF'
         ██████╗     ██╗    ██╗███╗   ███╗
         ██╔══██╗    ██║    ██║████╗ ████║
         ██║  ██║    ██║ █╗ ██║██╔████╔██║
         ██║  ██║    ██║███╗██║██║╚██╔╝██║
         ██████╔╝    ╚███╔███╔╝██║ ╚═╝ ██║
         ╚═════╝      ╚══╝╚══╝ ╚═╝     ╚═╝
          ██╗  ██╗███████╗ ██████╗███████╗
          ╚██╗██╔╝██╔════╝██╔════╝██╔════╝
           ╚███╔╝ █████╗  ██║     █████╗  
           ██╔██╗ ██╔══╝  ██║     ██╔══╝  
          ██╔╝ ██╗██║     ╚██████╗███████╗
          ╚═╝  ╚═╝╚═╝      ╚═════╝╚══════╝
EOF
    echo -e "${RESET}"
    echo
    echo -e "  ${NEON}${BOLD}◆${RESET} ${CYAN}${BOLD}D_WM-XFCE${RESET}  ${DIM}cyberpunk tiling compositor for Kali XFCE${RESET}"
    echo -e "  ${NEON}${BOLD}◆${RESET} ${ORANGE}i3wm${RESET} ${DIM}·${RESET} ${ORANGE}picom${RESET} ${DIM}·${RESET} ${ORANGE}kitty${RESET} ${DIM}·${RESET} ${ORANGE}rofi${RESET} ${DIM}·${RESET} ${ORANGE}dunst${RESET} ${DIM}·${RESET} ${ORANGE}zsh${RESET}"
    echo -e "  ${NEON}${BOLD}◆${RESET} ${DIM}forged by${RESET} ${PINK}archnexus707${RESET} ${DIM}// hyprforge${RESET}"
    echo
    sleep 0.1
}

die() { echo -e "${RED}[FATAL]${RESET} $*"; exit 1; }
ok()  { echo -e "${GREEN}[OK]${RESET} $*"; }
log() { echo -e "${YELLOW}[..]${RESET} $*"; }
warn(){ echo -e "${RED}[WARN]${RESET} $*"; }

is_kali()     { [ -r /etc/os-release ] && grep -qi kali /etc/os-release; }
is_root_user(){ [ "$(id -u)" -eq 0 ]; }

confirm() {
    [ "${FORCE:-0}" = "1" ] && return 0
    local prompt="${1:-Continue?}"
    printf "%b [y/N]: " "$prompt"
    read -r ans
    [ "$ans" = "y" ] || [ "$ans" = "Y" ] || [ "$ans" = "yes" ]
}

run_phase() {
    local name="$1" script="$2" toggle="${3:-ON}"
    [ "$toggle" = "ON" ] || { log "skipping $name (disabled in preset)"; return 0; }
    [ -x "$script" ] || { warn "script not found: $script"; return 1; }
    echo
    echo -e "${CYAN}===== $name =====${RESET}"
    if "$script"; then
        ok "phase $name complete"
    else
        warn "phase $name FAILED"
        return 1
    fi
}

########## main ##########
banner

is_root_user && die "do not run as root. This installer uses sudo when needed."

is_kali || warn "This installer is built for Kali Linux. Proceed with caution."

echo
echo -e "${ORANGE}This installer will:${RESET}"
echo "  • install i3-wm + picom + kitty + zsh + rofi + dunst (via apt)"
echo "  • drop cyberpunk-themed dotfiles into ~/.config/"
echo "  • add an 'i3 Cyberpunk' session entry to your greeter"
echo "  • optionally install oh-my-zsh + powerlevel10k"
echo
echo -e "${GREEN}It will NOT:${RESET}"
echo "  • modify your XFCE session or disable xfwm4"
echo "  • change your display manager"
echo "  • delete or overwrite any of your existing files (they get .bak)"
echo "  • build anything from source"
echo
echo -e "${ORANGE}Your regular XFCE desktop stays exactly as-is.${RESET}"
echo -e "${ORANGE}Pick 'i3 Cyberpunk' from the login screen to use the rice.${RESET}"
echo
confirm "Start the install?" || die "aborted by user"

# source preset
PRESET_FILE="$SCRIPT_DIR/preset.sh"
if [ -f "$PRESET_FILE" ]; then
    # shellcheck disable=SC1090
    . "$PRESET_FILE"
    log "loaded preset: $PRESET_FILE"
fi

: "${i3wm="ON"}"
: "${picom="ON"}"
: "${terminal="ON"}"
: "${theme="ON"}"
: "${dotfiles="ON"}"

SCRIPTS="$SCRIPT_DIR/install-scripts"

run_phase "dependencies"    "$SCRIPTS/00-deps.sh"     ON              || die "deps failed — cannot continue"
run_phase "i3wm"           "$SCRIPTS/01-i3.sh"        "$i3wm"         || warn "i3 phase had issues"
run_phase "picom"          "$SCRIPTS/02-picom.sh"     "$picom"        || warn "picom phase had issues"
run_phase "terminal+zsh"   "$SCRIPTS/03-terminal.sh"  "$terminal"     || warn "terminal phase had issues"
run_phase "cyberpunk-theme" "$SCRIPTS/04-theme.sh"    "$theme"        || warn "theme phase had issues"
run_phase "dotfiles"       "$SCRIPTS/05-dotfiles.sh"  "$dotfiles"     || warn "dotfile phase had issues"

echo
echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN}  D_WM-XFCE install complete!${RESET}"
echo
echo -e "${CYAN}  Log out, then pick 'i3 Cyberpunk'${RESET}"
echo -e "${CYAN}  from the greeter session menu.${RESET}"
echo
echo -e "${MAGENTA}  Keybinds:${RESET}"
echo -e "    SUPER+Enter  — terminal (kitty)"
echo -e "    SUPER+r      — app launcher (rofi)"
echo -e "    SUPER+q      — close window"
echo -e "    SUPER+1..9   — switch workspace"
echo -e "    SUPER+Shift+q — logout menu"
echo
echo -e "${GREEN}============================================${RESET}"
