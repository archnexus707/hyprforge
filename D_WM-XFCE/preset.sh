# D_WM-XFCE preset toggles. Source-able by install.sh.
# IMPORTANT: values must be quoted strings, either "ON" or "OFF".
# Edit this file before running ./install.sh to customise which phases run.

### Tiling WM (replaces xfwm4 inside XFCE session with i3-gaps)
i3="ON"

### Picom-ftlabs compositor (window animations, blur, rounded corners)
picom="ON"

### XFCE panel/desktop tweaks so it cooperates with i3 + picom
xfce_tweaks="ON"

### Kitty + zsh + oh-my-zsh + powerlevel10k + fastfetch
kitty_zsh="ON"

### Pokemon color scripts in terminal on launch
pokemon="ON"

### Nerd fonts (JetBrains Mono, Maple Mono, Iosevka) + display font
fonts="ON"

### GTK + icon + cursor themes + 3-theme switcher (Cyberpunk / Tokyo / Catppuccin)
themes="ON"

### Deploy dotfiles (kitty, zsh, i3, picom, rofi, dunst) to ~/.config/
dotfiles="ON"

### archnexus polish — dwm-palette (wallpaper-driven color regen) +
### dwm-powermenu (rofi power menu with Nerd Font icons + hover highlight).
### Adds SUPER+Escape (power menu) and SUPER+Shift+W (palette) keybinds.
polish="ON"

### Apt packages needed by the new archnexus-* CLI tools
### (clip/shot/OCR/brightness/nightlight/lock/Qt theming/display/automount/
###  live-reload/secrets). Default OFF — opt in here, or skip and rely on
### doctor.sh to tell you what to apt-install per tool you actually use.
### Can also be run anytime via: ./install-scripts/optional-deps.sh
optional_deps="OFF"

### Switch display manager from lightdm to sddm
###   OFF = keep Kali's default lightdm (RECOMMENDED for low-risk installs)
###   ON  = swap to sddm (only do this from a TTY, not inside an X session)
sddm_swap="OFF"

### VMware-guest tweaks (open-vm-tools + GL probe + picom safe-mode fallback)
###   AUTO = enable iff systemd-detect-virt reports vmware
###   ON   = force-enable
###   OFF  = skip even inside a VM
vmware_tweaks="AUTO"
