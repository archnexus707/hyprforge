#!/usr/bin/env bash
# doctor.sh — Kali-Hyprland post-install self-diagnostic.
#
# Re-runs archnexus_preflight + checks every expected Hyprland binary,
# library, config file, and theme is in place. Prints a pass/fail table with
# specific repair commands per failure. Re-runnable any time.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Source Global_functions.sh in a subshell only — its `set -e` and side
# effects (mkdir build/, Install-Logs/) shouldn't leak into doctor.
# Instead we inline the bits we need.
if tput sgr0 >/dev/null 2>&1; then
    OK="$(tput setaf 2)[OK]$(tput sgr0)"
    ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
    WARN="$(tput setaf 3)[WARN]$(tput sgr0)"
    INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
else
    OK="[OK]"; ERROR="[ERROR]"; WARN="[WARN]"; INFO="[INFO]"
fi

PASS=0; FAIL=0; WARN_N=0
results=()

_check() {
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

# ----- pre-flight ----------------------------------------------------------
printf "%s ===== environment =====\n" "$INFO"
( . "$SCRIPT_DIR/install-scripts/Global_functions.sh" >/dev/null 2>&1; archnexus_preflight 1 ) || true

# ----- critical binaries ---------------------------------------------------
printf "\n%s ===== critical binaries =====\n" "$INFO"
# NOTE: this build uses swww (wallpaper) + sway-notification-center (swaync),
# NOT hyprpaper/dunst — those are checked as optional WARNs below, not hard FAILs.
for bin in Hyprland hyprctl hyprland hyprlock hypridle kitty rofi; do
    case "$bin" in
        Hyprland|hyprland)
            _check "binary: $bin" "command -v $bin || [ -x /usr/local/bin/$bin ] || [ -x /usr/bin/$bin ]" FAIL "rerun ./install.sh --resume" ;;
        *)
            _check "binary: $bin" "command -v $bin" FAIL "rerun ./install.sh --resume (or apt/build the $bin phase)" ;;
    esac
done

# ----- Hyprland support libraries ------------------------------------------
printf "\n%s ===== Hyprland support libraries =====\n" "$INFO"
for lib in libhyprutils libhyprlang libhyprgraphics libaquamarine libhyprwire libhyprland-share; do
    _check "lib: $lib" "ldconfig -p 2>/dev/null | grep -qi $lib" FAIL "rerun ./install.sh --resume (build phase for $lib)"
done

# ----- optional binaries ---------------------------------------------------
printf "\n%s ===== optional tools =====\n" "$INFO"
for bin in waybar wallust swww swaync grim slurp wf-recorder hyprshot pokemon-colorscripts; do
    _check "optional: $bin" "command -v $bin" WARN "apt install $bin (or rerun matching phase)"
done

# ----- archnexus-* helpers --------------------------------------------------
# Verify cli-tools.sh symlinked the helper suite into $PATH and that one of
# them is actually executable (smoke test using --help / --raw).
printf "\n%s ===== archnexus-* helper suite =====\n" "$INFO"
ARCHNEXUS_HELPERS=(
    archnexus-audio archnexus-automount archnexus-brightness archnexus-bt
    archnexus-cheatsheet archnexus-clip archnexus-display archnexus-nightlight
    archnexus-notify-history archnexus-ocr archnexus-power archnexus-recovery
    archnexus-screenrecord archnexus-shot archnexus-sync archnexus-theme
    archnexus-volume archnexus-watch archnexus-welcome archnexus-wifi
)
for h in "${ARCHNEXUS_HELPERS[@]}"; do
    _check "helper: $h" "command -v $h" FAIL "rerun ./install-scripts/cli-tools.sh"
done
# Smoke test: archnexus-cheatsheet --raw should produce at least one keybind
# line (works on either Hyprland or i3 sessions, since it auto-detects).
if command -v archnexus-cheatsheet >/dev/null 2>&1; then
    _check "smoke: archnexus-cheatsheet --raw emits keybinds" \
        "archnexus-cheatsheet --raw 2>/dev/null | grep -q '→'" \
        WARN "ensure ~/.config/hypr/hyprland.conf or ~/.config/i3/config has bind/bindsym lines"
fi

# ----- Hyprland keybind drop-in --------------------------------------------
# archnexus-keybinds.sh wires Super+A/B/W/X/V/slash/Print to the helpers.
# Without this drop-in (and the source = line in UserSettings.conf) the
# helpers are installed but unreachable from the keyboard.
printf "\n%s ===== archnexus keybind wiring =====\n" "$INFO"
KEYBINDS_FILE="$HOME/.config/hypr/UserConfigs/archnexus-keybinds.conf"
SETTINGS_FILE="$HOME/.config/hypr/UserConfigs/UserSettings.conf"
_check "drop-in: $KEYBINDS_FILE" "[ -f '$KEYBINDS_FILE' ]" WARN "rerun ./install-scripts/archnexus-keybinds.sh"
if [ -f "$SETTINGS_FILE" ]; then
    _check "wired: UserSettings.conf sources archnexus-keybinds.conf" \
        "grep -q 'archnexus-keybinds.conf' '$SETTINGS_FILE'" \
        WARN "append: source = ~/.config/hypr/UserConfigs/archnexus-keybinds.conf"
fi

# ----- configs --------------------------------------------------------------
printf "\n%s ===== configs =====\n" "$INFO"
for cfg in \
    "$HOME/.config/hypr/hyprland.conf" \
    "$HOME/.config/kitty/kitty.conf" \
    "$HOME/.config/rofi/config.rasi"; do
    _check "config: $cfg" "[ -f '$cfg' ]" FAIL "rerun ./install.sh --resume (dotfiles phase)"
done

# ----- hyprland.conf parse --------------------------------------------------
printf "\n%s ===== hyprland.conf parse =====\n" "$INFO"
if command -v hyprctl >/dev/null 2>&1 && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    if hyprctl reload >/dev/null 2>&1; then
        results+=( "$OK   hyprland.conf parses cleanly (live reload OK)" )
        PASS=$((PASS+1))
    else
        results+=( "$ERROR hyprctl reload failed  -> check ~/.config/hypr/hyprland.conf for syntax errors" )
        FAIL=$((FAIL+1))
    fi
elif [ -f "$HOME/.config/hypr/hyprland.conf" ]; then
    results+=( "$INFO  Hyprland not running — can't live-validate config (boot into Hyprland and rerun doctor)" )
fi

# ----- ldconfig sanity ------------------------------------------------------
printf "\n%s ===== /usr/local/lib in ldconfig =====\n" "$INFO"
_check "/usr/local/lib in ld.so.conf.d" "sudo -n grep -q '/usr/local/lib' /etc/ld.so.conf.d/*.conf 2>/dev/null || grep -q '/usr/local/lib' /etc/ld.so.conf 2>/dev/null" \
    WARN "echo '/usr/local/lib' | sudo tee -a /etc/ld.so.conf.d/usr-local.conf && sudo ldconfig"

# ----- session manifest -----------------------------------------------------
printf "\n%s ===== session logs =====\n" "$INFO"
if ls Install-Logs/install-*.log >/dev/null 2>&1; then
    n=$(ls -1 Install-Logs/install-*.log 2>/dev/null | wc -l)
    results+=( "$OK   $n install session log(s) found in Install-Logs/" )
    PASS=$((PASS+1))
else
    results+=( "$WARN no install logs found — has install.sh ever run?" )
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
    printf "\n%s doctor passed with %d warning(s) — optional pieces missing.\n" "$WARN" "$WARN_N"
    exit 0
fi
printf "\n%s everything looks great — enjoy.\n" "$OK"
exit 0
