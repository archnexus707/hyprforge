#!/usr/bin/env bash
# logout-menu.sh — rofi prompt for session actions. Bound to SUPER+SHIFT+E.
set -uo pipefail

choices=$(printf '%s\n' \
    "  Lock" \
    "󰍃  Logout" \
    "󰒲  Suspend" \
    "  Reboot" \
    "󰐥  Shutdown")

pick=$(printf '%s' "$choices" | rofi -dmenu -i -p "session" -theme-str 'window {width: 20%;}')

case "$pick" in
    *Lock*)     i3lock -c 000000 ;;
    *Logout*)   i3-msg exit ;;
    *Suspend*)  systemctl suspend ;;
    *Reboot*)   systemctl reboot ;;
    *Shutdown*) systemctl poweroff ;;
esac
