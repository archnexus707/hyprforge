#!/bin/bash
# Kali-Hyprland auto-installer — by archnexus707
# Special thanks: JaKooLit — early foundation this build was inspired by.

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# Variables
# NOTE: Github_URL is the initial-clone source for the inherited baseline.
# Once Kali-Hyprland is published under your own GitHub, change this to your
# fork URL (e.g. https://github.com/archnexus707/Kali-Hyprland.git).
Distro="Kali-Hyprland"
Github_URL="https://github.com/JaKooLit/Debian-Hyprland.git"
Distro_DIR="$HOME/$Distro"

printf "\n%.0s" {1..1}

if ! command -v git &> /dev/null
then
    echo "${INFO} Git not found! ${SKY_BLUE}Installing Git...${RESET}"
    if ! sudo apt install -y git; then
        echo "${ERROR} Failed to install Git. Exiting."
        exit 1
    fi
fi

printf "\n%.0s" {1..1}

if [ -d "$Distro_DIR" ]; then
    echo "${YELLOW}$Distro_DIR exists. Updating the repository... ${RESET}"
    cd "$Distro_DIR" || { echo "${ERROR} cannot cd into $Distro_DIR"; exit 1; }

    # Don't silently stash the user's work. A blind `git stash && git pull`
    # discards any uncommitted edits with no recovery hint. If the tree is
    # dirty: confirm first, or refuse outright in non-interactive mode.
    if ! git diff --quiet HEAD 2>/dev/null || ! git diff --cached --quiet 2>/dev/null \
        || [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        echo "${WARN} Working tree in $Distro_DIR has uncommitted changes."
        if [ "${AUTO_INSTALL_OVERWRITE:-0}" = "1" ]; then
            echo "${WARN} AUTO_INSTALL_OVERWRITE=1 — stashing them as 'auto-install pre-pull'."
            git stash push -u -m "auto-install pre-pull $(date -u +%Y%m%dT%H%M%SZ)" \
                || { echo "${ERROR} git stash failed"; exit 1; }
        elif [ -t 0 ]; then
            read -rp "${CAT} Stash them and pull? [y/N]: " _ans
            case "${_ans,,}" in
                y|yes)
                    git stash push -u -m "auto-install pre-pull $(date -u +%Y%m%dT%H%M%SZ)" \
                        || { echo "${ERROR} git stash failed"; exit 1; }
                    echo "${INFO} Restore your work later with: git stash list && git stash pop"
                    ;;
                *)
                    echo "${ERROR} aborting — commit or stash your changes, then rerun"
                    exit 1
                    ;;
            esac
        else
            echo "${ERROR} non-interactive and tree is dirty; refusing to discard work"
            echo "${ERROR} set AUTO_INSTALL_OVERWRITE=1 to stash automatically"
            exit 1
        fi
    fi
    git pull || { echo "${ERROR} git pull failed"; exit 1; }
    chmod +x install.sh
    ./install.sh
else
    echo "${MAGENTA}$Distro_DIR does not exist. Cloning the repository...${RESET}"
    git clone --depth=1 "$Github_URL" "$Distro_DIR" \
        || { echo "${ERROR} git clone failed"; exit 1; }
    cd "$Distro_DIR" || { echo "${ERROR} cannot cd into $Distro_DIR"; exit 1; }
    chmod +x install.sh
    ./install.sh
fi