#!/usr/bin/env bash
# xfce-tweaks.sh — configure XFCE to cooperate with i3 + picom.
#
# Strategy: keep XFCE's session manager, panel, and applications (Thunar,
# xfce4-terminal, xfce4-screenshooter). But disable XFCE's own compositor
# (xfwm4 + xfce4-compositor) so picom owns rendering, and tell the session
# manager to use i3 as the window manager.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/safety.sh
. "$SCRIPT_DIR/lib/safety.sh"

if ! command -v xfconf-query >/dev/null 2>&1; then
    log "xfconf-query not present; installing xfce4-settings"
    apt_install_safe xfce4-settings || die "xfce4-settings install failed; cannot apply XFCE tweaks (see $DWM_LOG)"
fi

printf "\n%s ===== XFCE tweaks =====%s\n" "$YELLOW" "$RESET"

# These xfconf changes only take effect for the current $USER and are easy to revert.
# Each is recorded in the manifest so uninstall.sh can flip them back.

set_xfconf() {
    local channel="$1" prop="$2" type="$3" value="$4"
    local prev
    prev=$(xfconf-query -c "$channel" -p "$prop" 2>/dev/null || echo "")
    if [ "$DWM_DRY_RUN" = "1" ]; then
        printf "%s would set %s %s = %s (was: %s)\n" "$DRY" "$channel" "$prop" "$value" "${prev:-<unset>}"
        return 0
    fi
    if [ -n "$prev" ]; then
        register_undo "xfconf-query -c '$channel' -p '$prop' -t '$type' -s '$prev'"
    else
        register_undo "xfconf-query -c '$channel' -p '$prop' -r"
    fi
    xfconf-query -c "$channel" -p "$prop" -n -t "$type" -s "$value" 2>>"$DWM_LOG"
    log "xfconf $channel $prop = $value (was ${prev:-unset})"
}

# Disable XFCE's own compositor — picom takes over.
set_xfconf xfwm4 /general/use_compositing bool false

# Stop xfdesktop from drawing the root window (i3 manages the background; picom
# can show wallpapers via feh/swww-x equivalents). Leave it off for now; the
# wallpaper phase decides.
set_xfconf xfce4-desktop /backdrop/screen0/monitor0/workspace0/image-style int 0

# Reduce xfce4-panel decorations so picom can blur + round it cleanly.
# Compositing OFF on the panel, transparent BG so picom can apply blur underneath.
if command -v xfce4-panel >/dev/null 2>&1; then
    log "xfce4-panel detected; theming pass will style it"
fi

printf "%s XFCE tweaks complete.\n" "$OK"
