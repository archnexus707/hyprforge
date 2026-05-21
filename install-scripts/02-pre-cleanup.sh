#!/bin/bash

# This script is cleaning up previous manual installation files / directories

# 22 Aug 2024
# Files to be removed from /usr/local/bin

TARGET_DIR="/usr/local/bin"

# Define packages to manually remove (was manually installed previously)
PACKAGES=(
  cliphist
  pypr
  swappy
  waybar
  magick
)

# List of packages installed from Debian-Hyprland repo
uninstall=(
  hyprland
  xdg-desktop-portal-hyprland
  libhhyprland-dev
  libhyprutils-dev
  libhyprutils0
  hyprwayland-scanner
  hyprland-protocols
  hyprctl
  hyprpm
  Hyprland
)

# Kali-Hyprland addition: portal implementations that conflict with
# xdg-desktop-portal-hyprland. If both are installed, the wrong one usually
# wins at session start and screen sharing / file pickers break under Hyprland.
# These are removed with a confirmation prompt because removing them affects
# file dialogs in the user's original XFCE session.
xdph_conflicts=(
  xdg-desktop-portal-xfce
  xdg-desktop-portal-gtk
)

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Failed to change directory to $PARENT_DIR"; exit 1; }

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_pre-clean-up.log"

# Loop through the list of packages
for PKG_NAME in "${PACKAGES[@]}"; do
  # Construct the full path to the file
  FILE_PATH="$TARGET_DIR/$PKG_NAME"

  # Check if the file exists
  if [[ -f "$FILE_PATH" ]]; then
    # Delete the file
    sudo rm "$FILE_PATH"
    echo "Deleted: $FILE_PATH" 2>&1 | tee -a "$LOG"
  else
    echo "File not found: $FILE_PATH" 2>&1 | tee -a "$LOG"
  fi
done


# packages removal installed from Debian-Hyprland repo
overall_failed=0
printf "\n%s - ${SKY_BLUE}Removing some packages${RESET} installed from Debian Hyprland official repo \n" "${NOTE}"
for PKG in "${uninstall[@]}"; do
  uninstall_package "$PKG" 2>&1 | tee -a "$LOG"
  if [ $? -ne 0 ]; then
    overall_failed=1
  fi
done

if [ $overall_failed -ne 0 ]; then
  echo -e "${ERROR} Some packages failed to uninstall. Please check the log."
fi

# Kali-Hyprland: remove conflicting XDG portal implementations with confirmation.
# These ship with Kali's XFCE default and will fight xdph at Hyprland session start.
xdph_present=0
for pkg in "${xdph_conflicts[@]}"; do
  if dpkg -l 2>/dev/null | awk '{print $2}' | grep -qx "$pkg"; then
    xdph_present=1
    break
  fi
done

if [ "$xdph_present" -eq 1 ]; then
  echo -e "${WARN} XFCE XDG portal implementations detected (${xdph_conflicts[*]})."
  echo -e "${NOTE} These conflict with xdg-desktop-portal-hyprland and must be removed"
  echo -e "       for screen-share and file dialogs to work correctly under Hyprland."
  echo -e "${NOTE} They will be reinstallable later via apt if you return to XFCE."
  read -rp "Remove conflicting XDG portals now? [yes/NO]: " ans
  if [ "$ans" = "yes" ]; then
    for pkg in "${xdph_conflicts[@]}"; do
      uninstall_package "$pkg" 2>&1 | tee -a "$LOG" || true
    done
  else
    echo -e "${NOTE} Skipped XDG portal cleanup. You may experience portal conflicts."
  fi
fi

printf "\n%.0s" {1..1}