#!/usr/bin/env bash
# i3-gaps.sh — install i3 (with gaps support built in) and configure XFCE
# Session Manager to use it as the window manager in place of xfwm4.
#
# i3-gaps has been merged into mainline i3 since 4.22, so the Debian/Kali
# package `i3-wm` already supports `gaps` directives in the config.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/safety.sh
. "$SCRIPT_DIR/lib/safety.sh"

i3_pkgs=(
    i3
    i3-wm
    i3blocks
    i3status
    i3lock
    rofi
    dunst
    feh
    flameshot
)

printf "\n%s ===== i3 + tiling stack =====%s\n" "$YELLOW" "$RESET"

apt_install_safe "${i3_pkgs[@]}" || die "i3 stack apt install failed"

# Verify i3 supports gaps (mainline i3 >= 4.22 does).
if command -v i3 >/dev/null 2>&1; then
    i3_version=$(i3 --version 2>/dev/null | head -1)
    log "installed: $i3_version"
    # We don't fail on missing gaps support, just warn — config will still mostly work.
    if ! i3 --help 2>&1 | grep -q "gaps" && [ "${i3_version#*version }" \< "4.22" ]; then
        printf "%s i3 < 4.22 detected; gaps directives may be ignored. Consider Debian backports.\n" "$WARN"
    fi
fi

# Install a small `xfce-i3` startup wrapper that boots XFCE session with i3 as WM.
# This is placed in /usr/local/bin so XFCE Session Manager can find it.
WRAPPER=/usr/local/bin/xfce-i3-session

if [ "$DWM_DRY_RUN" = "1" ]; then
    printf "%s would write %s\n" "$DRY" "$WRAPPER"
else
    backup_file "$WRAPPER"
    sudo tee "$WRAPPER" >/dev/null <<'WRAPPER_EOF'
#!/bin/sh
# xfce-i3-session — runs i3 inside an XFCE session.
# Set as the SESSION_MANAGER WM via xfconf-query.
exec i3 "$@"
WRAPPER_EOF
    sudo chmod +x "$WRAPPER"
    register_undo "sudo rm -f \"$WRAPPER\""
    log "wrote $WRAPPER"
fi

# Tell xfce4-session to use the i3 wrapper as window manager.
if command -v xfconf-query >/dev/null 2>&1; then
    prev=$(xfconf-query -c xfce4-session -p /sessions/Failsafe/Client0_Command -a 2>/dev/null | tr '\n' ' ')
    if [ "$DWM_DRY_RUN" = "1" ]; then
        printf "%s would set xfce4-session Failsafe Client0_Command -> i3\n" "$DRY"
    else
        # Preserve previous setting for rollback if present
        if [ -n "$prev" ]; then
            register_undo "echo 'restore xfce4-session Client0_Command manually if needed; was: $prev'"
        fi
        xfconf-query -c xfce4-session \
            -p /sessions/Failsafe/Client0_Command \
            -t string -s "$WRAPPER" \
            --create -n 2>>"$DWM_LOG" || true
        log "xfce4-session now launches i3 as WM"
    fi
fi

# Install an Xsession .desktop so display managers (lightdm/sddm) offer "i3" too.
DESKTOP=/usr/share/xsessions/i3-dwm.desktop

if [ "$DWM_DRY_RUN" = "1" ]; then
    printf "%s would write %s\n" "$DRY" "$DESKTOP"
else
    backup_file "$DESKTOP"
    sudo tee "$DESKTOP" >/dev/null <<'DESKTOP_EOF'
[Desktop Entry]
Name=i3 (D_WM)
Comment=i3 inside an XFCE session — cyberpunk tiling
Exec=i3
Type=Application
DesktopNames=i3
DESKTOP_EOF
    register_undo "sudo rm -f \"$DESKTOP\""
    log "wrote $DESKTOP — will appear in greeter session menu"
fi

printf "%s i3 stack installed and wired.\n" "$OK"
