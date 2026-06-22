#!/usr/bin/env bash
# logout-menu.sh — rofi-based session control

OPTIONS=(
    "  Lock"
    "  Logout"
    "  Suspend"
    "  Reboot"
    "  Shutdown"
)

choice=$(printf '%s\n' "${OPTIONS[@]}" | rofi -dmenu -i -p "Session" \
    -theme-str 'window { width: 300px; border: 2px; border-color: #7aa2f7; border-radius: 12px; padding: 20px; background-color: #0d0d11; location: center; anchor: center; }' \
    -theme-str 'listview { lines: 5; spacing: 6px; }' \
    -theme-str 'element { padding: 10px 14px; border-radius: 8px; background-color: #1a1b26; }' \
    -theme-str 'element selected { background-color: #7aa2f7; text-color: #0d0d11; }' \
    -theme-str 'element-text { font: "monospace 13"; text-color: #c0caf5; }' \
    2>/dev/null) || exit 0

choice=$(echo "$choice" | xargs)

case "$choice" in
    Lock)
        i3lock -c 000000
        ;;
    Logout)
        i3-msg exit
        ;;
    Suspend)
        systemctl suspend
        ;;
    Reboot)
        confirm=$(printf 'No\nYes' | rofi -dmenu -i -p "Reboot?" \
            -theme-str 'window { width: 250px; border: 2px; border-color: #f7768e; border-radius: 12px; padding: 16px; background-color: #0d0d11; location: center; anchor: center; }' \
            -theme-str 'element { padding: 8px 12px; border-radius: 6px; background-color: #1a1b26; }' \
            -theme-str 'element selected { background-color: #f7768e; text-color: #0d0d11; }' \
            -theme-str 'element-text { font: "monospace 12"; text-color: #c0caf5; }' \
            2>/dev/null) || exit 0
        [ "$confirm" = "Yes" ] && systemctl reboot
        ;;
    Shutdown)
        confirm=$(printf 'No\nYes' | rofi -dmenu -i -p "Shutdown?" \
            -theme-str 'window { width: 250px; border: 2px; border-color: #f7768e; border-radius: 12px; padding: 16px; background-color: #0d0d11; location: center; anchor: center; }' \
            -theme-str 'element { padding: 8px 12px; border-radius: 6px; background-color: #1a1b26; }' \
            -theme-str 'element selected { background-color: #f7768e; text-color: #0d0d11; }' \
            -theme-str 'element-text { font: "monospace 12"; text-color: #c0caf5; }' \
            2>/dev/null) || exit 0
        [ "$confirm" = "Yes" ] && systemctl poweroff
        ;;
esac
