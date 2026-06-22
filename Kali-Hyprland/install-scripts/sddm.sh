#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# SDDM with optional SDDM theme #

# installing with NO-recommends
sddm1=(
  sddm
)

sddm2=(
  libqt6svg6
  qt6-declarative-dev
  qt6-svg-dev
  qt6-virtualkeyboard-plugin
  libqt6multimedia6
  qml6-module-qtquick-controls
  qml6-module-qtquick-effects
)

# login managers to attempt to disable
login=(
  lightdm 
  gdm3 
  gdm 
  lxdm 
  lxdm-gtk3
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_sddm.log"


# Install SDDM (no-recommends)
printf "\n%s - Installing ${SKY_BLUE}SDDM and dependencies${RESET} .... \n" "${NOTE}"
for PKG1 in "${sddm1[@]}" ; do
  install_package "$PKG1" "$LOG"
done

# Installation of additional sddm stuff
for PKG2 in "${sddm2[@]}"; do
  install_package "$PKG2"  "$LOG"
done

# Kali-Hyprland: explicit confirmation before swapping the display manager.
# On Kali this means disabling lightdm (the default greeter). If the user is
# logged in via the graphical target right now, this will not take effect until
# next reboot, but the swap can still strand them at a black screen if SDDM is
# misconfigured. We never `apt purge` lightdm so they can restore it from a TTY.
echo -e "${WARN} ====================================================================="
echo -e "${WARN} About to disable: ${login[*]}"
echo -e "${WARN} and switch the system default greeter to SDDM."
echo -e "${WARN} On Kali this swaps the active display manager (lightdm -> sddm)."
echo -e "${WARN} If SDDM fails to start, log in on a TTY (Ctrl+Alt+F2) and run:"
echo -e "${WARN}   sudo systemctl disable sddm; sudo systemctl enable lightdm"
echo -e "${WARN} ====================================================================="
if [ ! -t 0 ] || [ "${NON_INTERACTIVE:-0}" = "1" ]; then
    echo -e "${NOTE} non-interactive mode — skipping DM swap. Set SDDM_SWAP=1 to force."
    [ "${SDDM_SWAP:-0}" = "1" ] || exit 0
fi
read -rp "Proceed with display manager swap? [yes/NO]: " sddm_ans
if [ "$sddm_ans" != "yes" ]; then
  echo -e "${NOTE} Display manager swap cancelled. Keeping current greeter."
  echo -e "${NOTE} Hyprland session will still be selectable from the greeter menu."
  exit 0
fi

# Check if other login managers are installed and disable their service before enabling SDDM
# Note: we DISABLE only, never apt-purge, so the user can revert from a TTY.
# Track failures: leaving the system with NO display manager enabled is a brick
# scenario — if every disable failed AND `sudo systemctl enable sddm.service`
# also fails, we abort before set-default flips the boot target.
disable_failures=0
disabled_any=0
for login_manager in "${login[@]}"; do
  if dpkg-query -W -f='${Status}' "$login_manager" 2>/dev/null | grep -q "install ok installed"; then
    echo "Disabling $login_manager (package kept installed for rollback)..."
    if sudo systemctl disable "$login_manager.service" >> "$LOG" 2>&1; then
        echo "$login_manager disabled."
        disabled_any=1
    else
        echo -e "${WARN} Failed to disable $login_manager (will not abort yet)" | tee -a "$LOG"
        disable_failures=$((disable_failures + 1))
    fi
  fi
done

# Double check with systemctl
for manager in "${login[@]}"; do
  if systemctl is-active --quiet "$manager.service" > /dev/null 2>&1; then
    echo "$manager.service is active, disabling it..." >> "$LOG" 2>&1
    if ! sudo systemctl disable "$manager.service" --now >> "$LOG" 2>&1; then
        echo -e "${WARN} Failed to disable $manager.service" | tee -a "$LOG"
        disable_failures=$((disable_failures + 1))
    fi
  else
    echo "$manager.service is not active" >> "$LOG" 2>&1
  fi
done

printf "\n%.0s" {1..1}
printf "${INFO} Activating sddm service........\n"
sudo systemctl set-default graphical.target 2>&1 | tee -a "$LOG"
if ! sudo systemctl enable sddm.service 2>&1 | tee -a "$LOG"; then
    echo -e "${ERROR} ====================================================================="
    echo -e "${ERROR} sddm.service could not be enabled."
    if [ "$disable_failures" -gt 0 ] || [ "$disabled_any" -eq 1 ]; then
        echo -e "${ERROR} Existing display manager(s) may already be disabled — this means the"
        echo -e "${ERROR} system would boot with NO graphical login. Re-enabling lightdm now"
        echo -e "${ERROR} so you are not stranded:"
        sudo systemctl enable lightdm 2>&1 | tee -a "$LOG" || true
    fi
    echo -e "${ERROR} Fix the SDDM install (check $LOG) and rerun ./install.sh sddm."
    echo -e "${ERROR} ====================================================================="
    exit 1
fi

wayland_sessions_dir=/usr/share/wayland-sessions
[ ! -d "$wayland_sessions_dir" ] && { printf "$CAT - $wayland_sessions_dir not found, creating...\n"; sudo mkdir -p "$wayland_sessions_dir" 2>&1 | tee -a "$LOG"; }

printf "\n%.0s" {1..2}