#!/usr/bin/env bash
# doctor.sh — D_WM-XFCE post-install self-diagnostic.
#
# Re-runs archnexus_preflight + checks every expected binary, config file,
# theme dir, and dotfile is in place. Prints a pass/fail table with a
# specific repair command per failure. Re-runnable any time.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install-scripts/lib/safety.sh
. "$SCRIPT_DIR/install-scripts/lib/safety.sh"

PASS=0; FAIL=0; WARN_N=0
results=()

_check() {
    # $1=label, $2=command, $3=severity (FAIL|WARN), $4=repair hint
    local label="$1" cmd="$2" sev="$3" hint="$4"
    if eval "$cmd" >/dev/null 2>&1; then
        results+=( "$OK   $label" )
        PASS=$((PASS+1))
    elif [ "$sev" = "FAIL" ]; then
        results+=( "$ERROR $label  -> $hint" )
        FAIL=$((FAIL+1))
    else
        results+=( "$WARN $label  -> $hint" )
        WARN_N=$((WARN_N+1))
    fi
}

if command -v archnexus_banner >/dev/null 2>&1; then
    archnexus_banner "D_WM-XFCE doctor" "post-install self-diagnostic"
fi

printf "\n%s ===== environment =====\n" "$INFO"
archnexus_preflight 1 || true

# Map critical binaries → install.sh phase name (so the repair hint actually
# names a real --only target). `${bin%-*}` was the previous heuristic and
# produced suggestions like `--only zsh` which doesn't exist.
declare -A _bin_phase=(
    [i3]=i3
    [kitty]=kitty-zsh
    [rofi]=i3
    [dunst]=i3
    [fastfetch]=kitty-zsh
    [zsh]=kitty-zsh
)

printf "\n%s ===== critical binaries =====\n" "$INFO"
for bin in i3 kitty rofi dunst fastfetch zsh; do
    phase="${_bin_phase[$bin]:-$bin}"
    _check "binary: $bin" "command -v $bin" FAIL "rerun ./install.sh --only $phase (or apt install $bin)"
done

printf "\n%s ===== optional binaries =====\n" "$INFO"
for bin in picom feh eza bat btop starship pokemon-colorscripts; do
    _check "optional: $bin" "command -v $bin" WARN "apt install $bin (or rerun the relevant phase)"
done

# ----- archnexus-* helpers --------------------------------------------------
# Verify cli-tools.sh symlinked the helper suite into $PATH.
printf "\n%s ===== archnexus-* helper suite =====\n" "$INFO"
ARCHNEXUS_HELPERS=(
    archnexus-audio archnexus-automount archnexus-brightness archnexus-bt
    archnexus-cheatsheet archnexus-clip archnexus-display archnexus-nightlight
    archnexus-notify-history archnexus-ocr archnexus-power archnexus-recovery
    archnexus-screenrecord archnexus-shot archnexus-sync archnexus-theme
    archnexus-volume archnexus-watch archnexus-welcome archnexus-wifi
)
for h in "${ARCHNEXUS_HELPERS[@]}"; do
    _check "helper: $h" "command -v $h" FAIL "rerun ./install.sh --only cli-tools"
done
# Smoke test: the i3 cheat-sheet should emit at least one keybind line.
if command -v archnexus-cheatsheet >/dev/null 2>&1; then
    _check "smoke: archnexus-cheatsheet --raw emits keybinds" \
        "archnexus-cheatsheet --raw 2>/dev/null | grep -q '→'" \
        WARN "ensure ~/.config/i3/config has bindsym lines"
fi

printf "\n%s ===== configs =====\n" "$INFO"
for cfg in \
    "$HOME/.config/i3/config" \
    "$HOME/.config/kitty/kitty.conf" \
    "$HOME/.config/rofi/config.rasi" \
    "$HOME/.config/dunst/dunstrc" \
    "$HOME/.zshrc"; do
    _check "config: $cfg" "[ -f '$cfg' ]" FAIL "rerun ./install.sh --only dotfiles"
done

_check "config: ~/.config/picom/picom.conf" "[ -f \"$HOME/.config/picom/picom.conf\" ]" WARN "rerun ./install.sh --only dotfiles"

printf "\n%s ===== themes / icons / cursor =====\n" "$INFO"
_check "Nerd Font available"            "fc-list | grep -qi 'nerd'"                                FAIL "./install.sh --only fonts"
_check "Catppuccin GTK theme"           "ls \"$HOME/.themes\" 2>/dev/null | grep -qi catppuccin" WARN "./install.sh --only themes"
_check "Tela-circle icon theme"         "ls \"$HOME/.icons\" 2>/dev/null | grep -qi tela"       WARN "./install.sh --only themes"
_check "Bibata-Modern-Ice cursor"       "[ -d \"$HOME/.icons/Bibata-Modern-Ice\" ]"             WARN "./install.sh --only themes"

printf "\n%s ===== i3 config parse =====\n" "$INFO"
if command -v i3 >/dev/null 2>&1 && [ -f "$HOME/.config/i3/config" ]; then
    if i3 -C -c "$HOME/.config/i3/config" >/dev/null 2>&1; then
        results+=( "$OK   i3 config parses cleanly" )
        PASS=$((PASS+1))
    else
        msg=$(i3 -C -c "$HOME/.config/i3/config" 2>&1 | head -3 | tr '\n' '|')
        results+=( "$ERROR i3 config has errors: $msg  -> fix in ~/.config/i3/config" )
        FAIL=$((FAIL+1))
    fi
fi

printf "\n%s ===== display manager =====\n" "$INFO"
active_dm=$(detect_dm 2>/dev/null || echo none)
results+=( "$INFO active DM: $active_dm" )

printf "\n%s ===== backups =====\n" "$INFO"
if [ -d "$HOME/.dwm-backup" ]; then
    n=$(ls -1 "$HOME/.dwm-backup" 2>/dev/null | wc -l)
    results+=( "$OK   $n install session backup(s) under ~/.dwm-backup/" )
    PASS=$((PASS+1))
else
    results+=( "$WARN no backups under ~/.dwm-backup/  -> first install may not have completed" )
    WARN_N=$((WARN_N+1))
fi

# ----- print summary -----
printf "\n%s ===== results =====\n" "$INFO"
printf '%s\n' "${results[@]}"

printf "\n%s ===== summary =====\n" "$INFO"
printf "  passed:   %d\n" "$PASS"
printf "  warnings: %d\n" "$WARN_N"
printf "  failed:   %d\n" "$FAIL"

if [ "$FAIL" -gt 0 ]; then
    printf "\n%s doctor reports %d hard failure(s). See repair hints above.\n" "$ERROR" "$FAIL" >&2
    exit 1
fi
if [ "$WARN_N" -gt 0 ]; then
    printf "\n%s doctor passed with %d warning(s) — optional pieces are missing.\n" "$WARN" "$WARN_N"
    exit 0
fi
printf "\n%s everything looks great — enjoy.\n" "$OK"
exit 0
