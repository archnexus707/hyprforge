#!/usr/bin/env bash
# recovery.sh — TTY rescue menu for Kali-Hyprland.
#
# Drop into this if Hyprland won't start or you're locked out. From a TTY
# (Ctrl+Alt+F2), `cd` to this project root and run ./recovery.sh.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

if tput sgr0 >/dev/null 2>&1; then
    OK="$(tput setaf 2)[OK]$(tput sgr0)"
    ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
    WARN="$(tput setaf 3)[WARN]$(tput sgr0)"
    INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
    BLUE="$(tput setaf 4)"; RESET="$(tput sgr0)"
else
    OK="[OK]"; ERROR="[ERROR]"; WARN="[WARN]"; INFO="[INFO]"
    BLUE=""; RESET=""
fi

_banner() {
    cat <<EOF

  ${BLUE}╔══════════════════════════════════════════════════════════════╗${RESET}
  ${BLUE}║   archnexus707 Kali-Hyprland recovery mode                   ║${RESET}
  ${BLUE}║   You're not locked out — pick an option.                    ║${RESET}
  ${BLUE}╚══════════════════════════════════════════════════════════════╝${RESET}

EOF
}

_menu() {
    cat <<'EOF'

  1) Re-run install with --resume (continue from last successful phase)
  2) Run ./doctor.sh (diagnose what's broken)
  3) List + roll back to a snapshot (timeshift / snapper / btrfs)
  4) Edit ~/.config/hypr/hyprland.conf
  5) Edit /etc/sddm.conf (if SDDM was installed)
  6) Run sudo ldconfig + restart display manager
  7) Launch Hyprland directly (debug startup)
  8) Drop to interactive shell (Ctrl+D returns)
  9) View latest install log (less)
  q) Quit

EOF
}

_choose_snapshot_target() {
    if command -v timeshift >/dev/null 2>&1; then
        echo "${INFO} Timeshift snapshots:"
        local list
        list=$(sudo timeshift --list 2>/dev/null | sed -n '/^[0-9]/p' || true)
        if [ -z "$list" ]; then
            echo "${WARN} No timeshift snapshots found."
            return 1
        fi
        printf '%s\n' "$list" | sed 's/^/  /'
        read -rp "Snapshot name to restore (empty to cancel): " name
        [ -z "$name" ] && return 1
        # Validate name appears in the list — typo'd names previously silently
        # ran `timeshift --restore --snapshot "$name"` which can leave the
        # system mid-restore.
        if ! printf '%s\n' "$list" | grep -qF -- "$name"; then
            echo "${ERROR} '$name' is not in the snapshot list above; aborting"
            return 1
        fi
        read -rp "About to restore '$name'. Continue? [yes/NO]: " a
        if [ "$a" = "yes" ]; then
            if sudo timeshift --restore --snapshot "$name" --skip-grub; then
                echo "${OK} timeshift restore reported success — reboot recommended"
            else
                echo "${ERROR} timeshift restore failed; system may be in a partial state"
                return 1
            fi
        fi
    elif command -v snapper >/dev/null 2>&1; then
        local snlist
        snlist=$(sudo snapper -c root list 2>/dev/null || true)
        printf '%s\n' "$snlist" | sed 's/^/  /'
        read -rp "Snapshot # to roll back: " num
        [ -z "$num" ] && return 1
        if ! printf '%s\n' "$snlist" | awk '{print $1}' | grep -qE "^${num}$"; then
            echo "${ERROR} '$num' is not in the snapshot list above; aborting"
            return 1
        fi
        read -rp "Rollback to $num? [yes/NO]: " a
        if [ "$a" = "yes" ]; then
            sudo snapper -c root rollback "$num" || {
                echo "${ERROR} snapper rollback failed"; return 1; }
        fi
    elif command -v btrfs >/dev/null 2>&1 && [ -d /.archnexus-snapshots ]; then
        sudo ls -1 /.archnexus-snapshots/ | sed 's/^/  /'
        echo "${INFO} Raw btrfs — manual rollback (copy subvolume contents back as appropriate)."
        read -rp "Press Enter."
    else
        echo "${WARN} No snapshot tooling detected."
    fi
}

_launch_hyprland_debug() {
    if ! command -v Hyprland >/dev/null 2>&1 && ! command -v hyprland >/dev/null 2>&1; then
        echo "${ERROR} Hyprland binary not found. Run option 1 first."
        return 1
    fi
    echo "${INFO} launching Hyprland with verbose logging (Ctrl+C to abort)..."
    local bin
    bin=$(command -v Hyprland || command -v hyprland)
    "$bin" 2>&1 | tee /tmp/hyprland-debug-$$.log
}

_main() {
    while true; do
        clear
        _banner
        _menu
        read -rp "  Choice: " choice
        case "${choice,,}" in
            1) ./install.sh --resume ;;
            2) ./doctor.sh ;;
            3) _choose_snapshot_target ;;
            4) "${EDITOR:-nano}" "$HOME/.config/hypr/hyprland.conf" ;;
            5) sudo "${EDITOR:-nano}" /etc/sddm.conf ;;
            6) sudo ldconfig; sudo systemctl restart sddm 2>/dev/null || sudo systemctl restart lightdm 2>/dev/null ;;
            7) _launch_hyprland_debug ;;
            8) "${SHELL:-bash}" ;;
            9)
                local latest; latest=$(ls -1t Install-Logs/install-*.log 2>/dev/null | head -1 || true)
                if [ -n "$latest" ]; then less "$latest"; else echo "no logs found"; sleep 2; fi ;;
            q|quit|exit) break ;;
            *) ;;
        esac
        echo "Press Enter to continue."; read -r _
    done
}

_main "$@"
