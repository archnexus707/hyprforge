#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Zsh and Oh my Zsh + Optional Pokemon ColorScripts#

zsh=(
  lsd
  zsh
  mercurial
  zplug
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
LOG="Install-Logs/install-$(date +%d-%H%M%S)_zsh.log"

# Check if the log file already exists, if yes, append a counter to make it unique
COUNTER=1
while [ -f "$LOG" ]; do
  LOG="Install-Logs/install-$(date +%d-%H%M%S)_${COUNTER}_zsh.log"
  ((COUNTER++))
done

# Installing zsh packages
printf "${NOTE} Installing core zsh packages...${RESET}\n"
for ZSHP in "${zsh[@]}"; do
  install_package "$ZSHP"
done

printf "\n%.0s" {1..1}

# Install Oh My Zsh, plugins, and set zsh as default shell
if command -v zsh >/dev/null; then
  printf "${NOTE} Installing ${SKY_BLUE}Oh My Zsh and plugins${RESET} ...\n"
  if [ ! -d "$HOME/.oh-my-zsh" ]; then  
    sh -c "$(curl -fsSL https://install.ohmyz.sh)" "" --unattended  	       
  else
    echo "${INFO} Directory .oh-my-zsh already exists. Skipping re-installation." 2>&1 | tee -a "$LOG"
  fi
  
  # Check if the directories exist before cloning the repositories
  if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
      git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 
  else
      echo "${INFO} Directory zsh-autosuggestions already exists. Cloning Skipped." 2>&1 | tee -a "$LOG"
  fi

  if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 
  else
      echo "${INFO} Directory zsh-syntax-highlighting already exists. Cloning Skipped." 2>&1 | tee -a "$LOG"
  fi
  
  # Check if ~/.zshrc and .zprofile exists, create a backup, and copy the new
  # configuration. Skip the overwrite if our marker is already present so
  # repeated installs don't clobber the user's edits to .zshrc.
  KOOL_MARKER="# KooL-Hyprland-zsh-marker"
  if [ -f "$HOME/.zshrc" ] && grep -qF "$KOOL_MARKER" "$HOME/.zshrc" 2>/dev/null; then
      echo "${INFO} ~/.zshrc already contains KooL marker — leaving as-is (set ZSH_FORCE_OVERWRITE=1 to overwrite)" | tee -a "$LOG"
      if [ "${ZSH_FORCE_OVERWRITE:-0}" = "1" ]; then
          ts="$(date -u +%Y%m%dT%H%M%SZ)"
          cp -a "$HOME/.zshrc" "$HOME/.zshrc-backup-$ts" || true
          [ -f "$HOME/.zprofile" ] && cp -a "$HOME/.zprofile" "$HOME/.zprofile-backup-$ts" || true
          cp -r 'assets/.zshrc' "$HOME/"
          cp -r 'assets/.zprofile' "$HOME/"
          # Stamp the marker so future runs detect it
          printf '\n%s\n' "$KOOL_MARKER" >> "$HOME/.zshrc"
      fi
  else
      ts="$(date -u +%Y%m%dT%H%M%SZ)"
      if [ -f "$HOME/.zshrc" ]; then
          cp -a "$HOME/.zshrc" "$HOME/.zshrc-backup-$ts" || true
      fi
      if [ -f "$HOME/.zprofile" ]; then
          cp -a "$HOME/.zprofile" "$HOME/.zprofile-backup-$ts" || true
      fi
      cp -r 'assets/.zshrc' "$HOME/"
      cp -r 'assets/.zprofile' "$HOME/"
      printf '\n%s\n' "$KOOL_MARKER" >> "$HOME/.zshrc"
  fi

  # Check if the current shell is zsh
  current_shell=$(basename "$SHELL")
  if [ "$current_shell" != "zsh" ]; then
    printf "${NOTE} Changing default shell to ${MAGENTA}zsh${RESET}..."
    printf "\n%.0s" {1..2}

    # Confirm zsh actually has a usable path BEFORE entering the loop —
    # otherwise `chsh -s ""` is invalid and the loop would never exit.
    zsh_path="$(command -v zsh)"
    if [ -z "$zsh_path" ] || [ ! -x "$zsh_path" ]; then
        echo "${ERROR} zsh binary not found on PATH; cannot chsh. Skipping default-shell change." | tee -a "$LOG"
    else
        chsh_attempts=0
        chsh_max=5
        while ! chsh -s "$zsh_path"; do
          chsh_attempts=$((chsh_attempts + 1))
          if [ "$chsh_attempts" -ge "$chsh_max" ]; then
              echo "${ERROR} chsh failed $chsh_max times; giving up. Run later: chsh -s $zsh_path" | tee -a "$LOG"
              break
          fi
          echo "${ERROR} Authentication failed ($chsh_attempts/$chsh_max). Please enter the correct password." 2>&1 | tee -a "$LOG"
          sleep 1
        done
        if [ "$chsh_attempts" -lt "$chsh_max" ]; then
            printf "${INFO} Shell changed successfully to ${MAGENTA}zsh${RESET}" 2>&1 | tee -a "$LOG"
        fi
    fi
  else
    echo "${NOTE} Your shell is already set to ${MAGENTA}zsh${RESET}."
  fi

fi

# copy additional oh-my-zsh themes from assets
if [ -d "$HOME/.oh-my-zsh/themes" ]; then
    cp -r assets/add_zsh_theme/* ~/.oh-my-zsh/themes >> "$LOG" 2>&1
fi

printf "\n%.0s" {1..2}
