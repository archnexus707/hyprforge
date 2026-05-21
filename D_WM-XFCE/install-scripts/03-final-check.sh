#!/usr/bin/env bash
# 03-final-check.sh — verifies the install produced something usable.
# Non-zero exit if anything critical is missing.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/safety.sh
. "$SCRIPT_DIR/lib/safety.sh"

printf "\n%s ===== final check =====%s\n" "$YELLOW" "$RESET"

# In dry-run mode nothing was actually installed; the check would always fail
# on critical binaries. Print a note and exit clean.
if [ "$DWM_DRY_RUN" = "1" ]; then
    printf "%s dry-run mode: skipping installed-binary checks (nothing was installed).\n" "$DRY"
    printf "%s rerun without --dry-run to actually install, then this phase will verify.\n" "$INFO"
    exit 0
fi

critical_bins=(
    i3
    kitty
    zsh
    rofi
    dunst
    fastfetch
)

optional_bins=(
    picom
    pokemon-colorscripts
    eza
    bat
    btop
    starship
)

critical_configs=(
    "$HOME/.config/i3/config"
    "$HOME/.config/kitty/kitty.conf"
    "$HOME/.config/picom/picom.conf"
    "$HOME/.zshrc"
)

missing_critical=0
for b in "${critical_bins[@]}"; do
    if command -v "$b" >/dev/null 2>&1; then
        printf "%s %s\n" "$OK" "$b"
    else
        printf "%s missing critical binary: %s\n" "$ERROR" "$b"
        missing_critical=$((missing_critical+1))
    fi
done

for b in "${optional_bins[@]}"; do
    if command -v "$b" >/dev/null 2>&1; then
        printf "%s %s (optional)\n" "$OK" "$b"
    else
        printf "%s missing optional: %s\n" "$WARN" "$b"
    fi
done

for c in "${critical_configs[@]}"; do
    if [ -f "$c" ]; then
        printf "%s config %s\n" "$OK" "$c"
    else
        printf "%s missing config %s\n" "$WARN" "$c"
    fi
done

if [ "$missing_critical" -gt 0 ]; then
    printf "\n%s %d critical components missing. Review log: %s\n" "$ERROR" "$missing_critical" "$DWM_LOG"
    exit 1
fi

printf "\n%s D_WM-XFCE install verified.\n" "$OK"
printf "%s Reboot or log out, then pick 'i3' from your greeter session menu.\n" "$INFO"
printf "%s Switch themes any time with: ~/.local/bin/dwm-theme <cyberpunk|tokyo|catppuccin>\n" "$INFO"
