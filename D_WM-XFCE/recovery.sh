#!/usr/bin/env bash
# recovery.sh — TTY rescue menu for D_WM-XFCE.
#
# Drop into this if the graphical session won't start or you're locked out.
# From a TTY (Ctrl+Alt+F2), cd to this project root and run ./recovery.sh
# (or just `archnexus-recovery` after install — it gets symlinked into
# ~/.local/bin/ by cli-tools.sh).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Reuse the project's color primitives if available.
if [ -f "$SCRIPT_DIR/install-scripts/lib/safety.sh" ]; then
    # shellcheck disable=SC1091
    . "$SCRIPT_DIR/install-scripts/lib/safety.sh" 2>/dev/null || true
fi

_banner() {
    if command -v archnexus_banner >/dev/null 2>&1; then
        archnexus_banner "D_WM-XFCE recovery" "you're not locked out — pick an option"
    else
        cat <<'EOF'

  ╔══════════════════════════════════════════════════════════════╗
  ║   archnexus707 recovery mode                                 ║
  ║   You're not locked out — pick an option.                    ║
  ╚══════════════════════════════════════════════════════════════╝

EOF
    fi
}

_menu() {
    cat <<'EOF'

  1) Re-run install with --resume (continue from last successful phase)
  2) Run ./doctor.sh (diagnose what's broken)
  3) List + roll back to a snapshot (timeshift / snapper / btrfs)
  4) Edit ~/.config/i3/config in nano (or $EDITOR)
  5) Edit ~/.config/picom/picom.conf
  6) Restart display manager
  7) Drop to interactive shell (Ctrl+D to come back)
  8) View latest install log (less)
  q) Quit

EOF
}

_choose_snapshot_target() {
    if command -v timeshift >/dev/null 2>&1; then
        echo "Timeshift snapshots:"
        sudo timeshift --list 2>/dev/null | sed -n '/^[0-9]/p' | sed 's/^/  /' || true
        read -rp "Enter snapshot name to restore (or empty to cancel): " name
        [ -z "$name" ] && return 1
        echo "About to: sudo timeshift --restore --snapshot \"$name\" --skip-grub"
        read -rp "Continue? [yes/NO]: " a
        [ "$a" = "yes" ] && sudo timeshift --restore --snapshot "$name" --skip-grub
    elif command -v snapper >/dev/null 2>&1; then
        echo "Snapper snapshots:"
        sudo snapper -c root list 2>/dev/null | tail -n +4 | sed 's/^/  /' || true
        read -rp "Enter snapshot number to roll back to: " num
        [ -z "$num" ] && return 1
        echo "About to: sudo snapper -c root rollback $num"
        read -rp "Continue? [yes/NO]: " a
        [ "$a" = "yes" ] && sudo snapper -c root rollback "$num"
    elif command -v btrfs >/dev/null 2>&1 && [ -d /.archnexus-snapshots ]; then
        echo "Raw btrfs snapshots under /.archnexus-snapshots/:"
        sudo ls -1 /.archnexus-snapshots/ | sed 's/^/  /'
        echo "(Manual rollback only — copy the subvolume contents back as appropriate.)"
        read -rp "Press Enter to continue."
    else
        echo "No snapshot tooling detected on this system."
    fi
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
            4) "${EDITOR:-nano}" "$HOME/.config/i3/config" ;;
            5) "${EDITOR:-nano}" "$HOME/.config/picom/picom.conf" ;;
            6)
                read -rp "Restart current display manager? [y/N]: " a
                [ "${a,,}" = "y" ] || continue
                local dm; dm=$(detect_dm 2>/dev/null || echo lightdm)
                sudo systemctl restart "${dm}.service" ;;
            7) "${SHELL:-bash}" ;;
            8)
                local latest; latest=$(ls -1t Install-Logs/install-*.log 2>/dev/null | head -1 || true)
                if [ -n "$latest" ]; then less "$latest"; else echo "no logs found"; sleep 2; fi ;;
            q|quit|exit) break ;;
            *) ;;
        esac
        echo "Press Enter to continue."; read -r _
    done
}

_main "$@"
