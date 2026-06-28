#!/bin/bash
# optional-deps.sh — install the apt packages needed by the new archnexus-*
# CLI tools (clip / shot / OCR / brightness / nightlight / lock / Qt theming /
# display / automount / live-reload / secrets).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || exit 1

# shellcheck source=Global_functions.sh
if ! source "$SCRIPT_DIR/Global_functions.sh"; then
    echo "Failed to source Global_functions.sh"; exit 1
fi

LOG="Install-Logs/install-$(date +%d-%H%M%S)_optional-deps.log"

declare -A DEP_GROUPS=(
    [CLIP]="cliphist wl-clipboard xclip xsel"
    [SHOT]="grim slurp swappy flameshot maim"
    [RECORD]="wf-recorder ffmpeg"
    [OCR]="tesseract-ocr tesseract-ocr-eng"
    [MEDIA]="brightnessctl playerctl pamixer wireplumber"
    [NIGHTLIGHT]="wlsunset redshift"
    [LOCK]="swaylock i3lock-color xss-lock"
    [QT]="qt6ct qt5ct qt5-style-kvantum qt5-style-kvantum-themes"
    [DISPLAY]="autorandr wlr-randr"
    [MOUNT]="udiskie udisks2"
    [WATCH]="inotify-tools entr"
    [SECRETS]="age"
    [MISC]="fzf"
)
DEP_ORDER=(CLIP SHOT RECORD OCR MEDIA NIGHTLIGHT LOCK QT DISPLAY MOUNT WATCH SECRETS MISC)
declare -A DEP_DESC=(
    [CLIP]="clipboard history (archnexus-clip)"
    [SHOT]="screenshot suite (archnexus-shot)"
    [RECORD]="screen recording (archnexus-screenrecord)"
    [OCR]="region OCR (archnexus-ocr)"
    [MEDIA]="brightness + volume + media keys"
    [NIGHTLIGHT]="night-light schedule (archnexus-nightlight)"
    [LOCK]="lock backends for archnexus-power"
    [QT]="Qt5/Qt6 theme consistency with GTK"
    [DISPLAY]="multi-monitor + hotplug helpers"
    [MOUNT]="auto-mount removable media (archnexus-automount)"
    [WATCH]="dotfile live-reload (archnexus-watch)"
    [SECRETS]="age-encrypted dotfile secrets (archnexus-sync)"
    [MISC]="fzf for the no-rofi fallback"
)

printf "\n%s - Installing ${SKY_BLUE}optional CLI-tool deps${RESET}\n" "${NOTE}"

for g in "${DEP_ORDER[@]}"; do
    var="ARCHNEXUS_SKIP_$g"
    flag="${!var:-0}"
    state="ON"
    [ "$flag" = "1" ] && state="SKIP"
    printf "  [%-4s]  %-10s  %-44s  %s\n" "$state" "$g" "${DEP_DESC[$g]}" "${DEP_GROUPS[$g]}"
done

if [ "${NON_INTERACTIVE:-0}" != "1" ]; then
    if command -v whiptail >/dev/null 2>&1 && [ -t 0 ]; then
        whiptail --title "Install optional CLI-tool deps?" \
            --yesno "Install the packages above?\n\nSkip groups via ARCHNEXUS_SKIP_<GROUP>=1." 14 78 || {
            echo "${NOTE} user declined; nothing installed" | tee -a "$LOG"
            exit 0
        }
    else
        read -rp "Install all groups above? [y/N]: " _ans
        case "${_ans,,}" in y|yes) ;; *) echo "${NOTE} declined" | tee -a "$LOG"; exit 0 ;; esac
    fi
fi

_available() {
    apt-cache show "$1" 2>/dev/null | grep -q "^Package:"
}

installed=0; skipped=0; missing=0
for g in "${DEP_ORDER[@]}"; do
    var="ARCHNEXUS_SKIP_$g"
    [ "${!var:-0}" = "1" ] && { skipped=$((skipped+1)); continue; }
    printf "\n%s -- group: %s --\n" "${INFO}" "$g"
    for pkg in ${DEP_GROUPS[$g]}; do
        if ! _available "$pkg"; then
            echo "${WARN} pkg not in apt: $pkg — skipping" | tee -a "$LOG"
            missing=$((missing+1))
            continue
        fi
        install_package "$pkg" "$LOG"
        installed=$((installed+1))
    done
done

echo
echo "${INFO} optional-deps summary: installed-attempts=$installed skipped-groups=$skipped pkgs-missing-from-apt=$missing" | tee -a "$LOG"
exit 0
