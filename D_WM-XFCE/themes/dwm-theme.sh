#!/usr/bin/env bash
# dwm-theme — D_WM-XFCE theme switcher.
#
# Switches kitty, rofi, dunst, i3 and GTK between the three packaged themes:
#   cyberpunk-edgerunners  · tokyo-night-storm  · catppuccin-mocha
#
# USAGE:
#   dwm-theme                  # show rofi picker
#   dwm-theme <name>           # switch directly
#   dwm-theme rofi             # alias for the picker
#   dwm-theme --list           # print available themes
#
# Theme files live under ~/.local/share/D_WM/themes/<name>/ after install;
# during development they're in $REPO/themes/<name>/.

set -uo pipefail

# Locate theme dir: prefer installed location, fall back to dev repo.
for candidate in \
    "$HOME/.local/share/D_WM/themes" \
    "$(dirname "$(readlink -f "$0")")/../themes" \
    "$HOME/Desktop/D_WM-XFCE/themes"; do
    if [ -d "$candidate" ]; then
        THEMES_DIR="$candidate"
        break
    fi
done
: "${THEMES_DIR:=$HOME/.local/share/D_WM/themes}"

list_themes() {
    [ -d "$THEMES_DIR" ] || { echo "no themes dir at $THEMES_DIR"; exit 1; }
    find "$THEMES_DIR" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort
}

pick_via_rofi() {
    list_themes | rofi -dmenu -i -p "theme" -theme-str 'window { width: 25%; }'
}

case "${1:-}" in
    --list|-l)
        list_themes
        exit 0
        ;;
    ""|rofi)
        choice=$(pick_via_rofi)
        [ -n "$choice" ] || exit 0
        ;;
    -h|--help)
        sed -n '3,15p' "$0" | sed 's/^# *//'
        exit 0
        ;;
    *)
        choice="$1"
        ;;
esac

THEME_DIR="$THEMES_DIR/$choice"
if [ ! -d "$THEME_DIR" ]; then
    echo "unknown theme: $choice" >&2
    echo "available: $(list_themes | tr '\n' ' ')" >&2
    exit 1
fi

echo "switching to theme: $choice"

# ----- kitty -----------------------------------------------------------------
if [ -f "$THEME_DIR/kitty.conf" ]; then
    cp "$THEME_DIR/kitty.conf" "$HOME/.config/kitty/theme.conf"
    # SIGUSR1 reloads kitty config in all running kitty windows.
    pkill -USR1 kitty 2>/dev/null || true
    echo "  kitty: reloaded"
fi

# ----- rofi ------------------------------------------------------------------
if [ -f "$THEME_DIR/rofi.rasi" ]; then
    cp "$THEME_DIR/rofi.rasi" "$HOME/.config/rofi/theme.rasi"
    echo "  rofi:  theme written"
fi

# ----- dunst -----------------------------------------------------------------
if [ -f "$THEME_DIR/dunst.snippet" ]; then
    # Merge the snippet into ~/.config/dunst/dunstrc by replacing
    # the urgency_* blocks.
    DUNSTRC="$HOME/.config/dunst/dunstrc"
    if [ -f "$DUNSTRC" ]; then
        # awk: when we hit [urgency_low], replace the entire 3-block region with snippet.
        awk -v snippet="$(cat "$THEME_DIR/dunst.snippet")" '
            /^\[urgency_low\]/    { print snippet; in_block=1; next }
            /^\[urgency_normal\]/ { if (in_block) next }
            /^\[urgency_critical\]/ { if (in_block) next }
            /^\[/                  { in_block=0 }
            !in_block               { print }
            in_block && /^$/        { in_block=0; print "" }
        ' "$DUNSTRC" > "$DUNSTRC.tmp" && mv "$DUNSTRC.tmp" "$DUNSTRC"
        pkill -HUP dunst 2>/dev/null || (pkill dunst 2>/dev/null; dunst &)
        echo "  dunst: reloaded"
    fi
fi

# ----- i3 colors -------------------------------------------------------------
if [ -f "$THEME_DIR/i3.colors" ]; then
    I3_CFG="$HOME/.config/i3/config"
    if [ -f "$I3_CFG" ]; then
        awk -v colors="$(cat "$THEME_DIR/i3.colors")" '
            /# THEME-START/ { print; print colors; in_block=1; next }
            /# THEME-END/   { print; in_block=0; next }
            !in_block        { print }
        ' "$I3_CFG" > "$I3_CFG.tmp" && mv "$I3_CFG.tmp" "$I3_CFG"
        i3-msg reload >/dev/null 2>&1 || true
        echo "  i3:    colors swapped + reloaded"
    fi
fi

# ----- GTK + icon + cursor (via xfconf where available) ----------------------
META="$THEME_DIR/meta.env"
if [ -f "$META" ]; then
    # shellcheck disable=SC1090
    . "$META"
    if command -v xfconf-query >/dev/null 2>&1; then
        [ -n "${GTK_THEME:-}" ]   && xfconf-query -c xsettings -p /Net/ThemeName     -t string -s "$GTK_THEME"   --create -n 2>/dev/null
        [ -n "${ICON_THEME:-}" ]  && xfconf-query -c xsettings -p /Net/IconThemeName -t string -s "$ICON_THEME"  --create -n 2>/dev/null
        [ -n "${CURSOR_THEME:-}" ] && xfconf-query -c xsettings -p /Gtk/CursorThemeName -t string -s "$CURSOR_THEME" --create -n 2>/dev/null
        echo "  gtk:   ${GTK_THEME:-unchanged} / ${ICON_THEME:-unchanged}"
    fi
    if [ -n "${WALLPAPER:-}" ] && command -v feh >/dev/null 2>&1; then
        # Expand ~ in WALLPAPER
        WP="${WALLPAPER/#\~/$HOME}"
        [ -f "$WP" ] && feh --no-fehbg --bg-fill "$WP" && echo "  wp:    set"
    fi
fi

# ----- notify user -----------------------------------------------------------
if command -v notify-send >/dev/null 2>&1; then
    notify-send "D_WM theme" "switched to $choice" -t 2500 2>/dev/null || true
fi

echo "done."
