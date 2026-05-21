#!/usr/bin/env bash
# archnexus_banner.sh — neon-green ASCII banner + phase headers.
#
# Brand accent: #00ff9c (archnexus707 mint). The banner renders with a soft
# vertical glow gradient around that accent. Falls back to plain text on
# dumb terminals.
#
# Safe to source from anywhere: no `set -e`, no globals beyond the function
# bodies, no destructive side-effects. Honors NO_BANNER=1 for CI / dumb
# terminals and emits no escapes when stdout is not a TTY.
#
# Three functions:
#   archnexus_banner  <project> <tagline>
#   archnexus_phase   <name>    <subtitle>
#   archnexus_spinner <pid>     <label>

# Pad $1 with spaces on the right so its character count reaches $2.
# Uses ${#str} (code-point count), so single-code-point UTF-8 glyphs like
# em-dash (—), middot (·), and most emoji count as 1 cell — which matches
# how a UTF-8 monospace TTY renders them. Wide CJK and emoji-presentation
# characters may still drift by one cell on terminals that double-width them;
# the banner avoids those on purpose.
_ax_pad() {
    local s="$1" width="$2" n
    n=${#s}
    if [ "$n" -lt "$width" ]; then
        printf '%s%*s' "$s" $((width - n)) ''
    else
        printf '%s' "$s"
    fi
}

archnexus_banner() {
    [ "${NO_BANNER:-0}" = "1" ] && return 0
    local project="${1:-D_WM}"
    local tagline="${2:-Hyprland-grade ricing — forged for rebels}"

    # Color capability detection. Use truecolor if the terminal advertises it
    # OR if it claims ≥256 colors (xterm/alacritty/kitty/wezterm/gnome/konsole
    # all accept truecolor escapes and quantize internally if needed).
    local supports_color=0
    if [ -t 1 ]; then
        case "${COLORTERM:-}" in
            truecolor|24bit) supports_color=1 ;;
            *)
                if [ "$(tput colors 2>/dev/null || echo 0)" -ge 256 ]; then
                    supports_color=1
                fi
                ;;
        esac
    fi

    # Emit text in a 24-bit color. $1 is "R;G;B", $2 is the text.
    _ax_line() {
        if [ "$supports_color" = "1" ]; then
            printf '\e[38;2;%sm%s\e[0m\n' "$1" "$2"
        else
            printf '%s\n' "$2"
        fi
    }

    # archnexus707 brand accent + symmetric glow gradient. Each value is the
    # RGB triple for one row of the 6-line ASCII art, forming a neon glow
    # that peaks on the brand color in the middle two rows.
    local brand="0;255;156"          # #00ff9c — the headline accent
    local glow_hi="100;255;195"      # lighter mint above/below the peak
    local glow_md="0;230;145"        # near-peak mint
    local glow_lo="0;180;115"        # dimmer mint at the edges
    local glow_dim="0;128;82"        # darkest mint (fade-out)
    local headline="220;255;235"     # near-white mint for readable headline text
    local meta="120;255;195"         # softer mint for footer rows

    # 6-line "ARCHNEXUS" in ANSI Shadow (75 cols wide).
    local -a logo=(
" █████╗ ██████╗  ██████╗██╗  ██╗███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗"
"██╔══██╗██╔══██╗██╔════╝██║  ██║████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝"
"███████║██████╔╝██║     ███████║██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗"
"██╔══██║██╔══██╗██║     ██╔══██║██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║"
"██║  ██║██║  ██║╚██████╗██║  ██║██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║"
"╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
    )
    # 6-line "707" in ANSI Shadow (25 cols), centered under ARCHNEXUS with
    # 25 leading spaces so it sits dead-center of the 75-col logo above.
    local -a digits=(
"                         ███████╗ ██████╗ ███████╗"
"                         ╚════██║██╔═████╗╚════██║"
"                             ██╔╝██║██╔██║    ██╔╝"
"                            ██╔╝ ████╔╝██║   ██╔╝ "
"                            ██║  ╚██████╔╝   ██║  "
"                            ╚═╝   ╚═════╝    ╚═╝  "
    )
    # Symmetric glow: dim → mid → peak → peak → mid → dim. Both blocks
    # share the same ramp so the eye reads them as one luminous sign.
    local -a ramp=("$glow_lo" "$glow_md" "$brand" "$brand" "$glow_md" "$glow_lo")

    printf "\n"
    local i
    for i in 0 1 2 3 4 5; do
        _ax_line "${ramp[$i]}" "${logo[$i]}"
        sleep 0.04 2>/dev/null || true
    done
    for i in 0 1 2 3 4 5; do
        _ax_line "${ramp[$i]}" "${digits[$i]}"
        sleep 0.04 2>/dev/null || true
    done
    printf "\n"

    # Box geometry: top bar = 71 ━ chars between corners → 71-cell inner
    # width. Content slot with 3-space inner padding each side = 65 cells.
    local pad="  "
    local bar="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    local blank
    blank=$(printf '%71s' '')

    _ax_line "$brand"    "${pad}┏${bar}┓"
    _ax_line "$brand"    "${pad}┃${blank}┃"
    _ax_line "$headline" "${pad}┃   $(_ax_pad "${project} — ${tagline}" 65)   ┃"
    _ax_line "$brand"    "${pad}┃${blank}┃"
    _ax_line "$meta"     "${pad}┃   $(_ax_pad "forged by archnexus707 · for the rebels of the terminal" 65)   ┃"
    _ax_line "$meta"     "${pad}┃   $(_ax_pad "⚡  Star · Fork · Hack · Customize — the desktop is yours" 65)   ┃"
    _ax_line "$brand"    "${pad}┃${blank}┃"
    _ax_line "$brand"    "${pad}┗${bar}┛"
    printf "\n"
    unset -f _ax_line
}

archnexus_phase() {
    [ "${NO_BANNER:-0}" = "1" ] && { printf "\n>>> %s %s\n" "$1" "${2:-}"; return 0; }
    local name="${1:-phase}" sub="${2:-}"
    local supports_color=0
    if [ -t 1 ]; then
        case "${COLORTERM:-}" in
            truecolor|24bit) supports_color=1 ;;
            *)
                if [ "$(tput colors 2>/dev/null || echo 0)" -ge 256 ]; then
                    supports_color=1
                fi
                ;;
        esac
    fi
    local bar="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ "$supports_color" = "1" ]; then
        # Brand-green frame, near-white headline name, mint subtitle.
        printf '\n\e[38;2;0;255;156m┏%s┓\e[0m\n' "$bar"
        printf '\e[38;2;0;255;156m┃\e[0m  \e[1;38;2;220;255;235m▶ %s\e[0m \e[38;2;120;255;195m%s\e[0m\n' "$name" "$sub"
        printf '\e[38;2;0;255;156m┗%s┛\e[0m\n' "$bar"
    else
        printf "\n+%s+\n| > %s %s\n+%s+\n" "$bar" "$name" "$sub" "$bar"
    fi
}

# Cool "now installing" spinner — drop-in spinner for foreground tasks. Spinner
# glyph in brand mint to stay consistent with the rest of the banner.
archnexus_spinner() {
    local pid="$1" label="${2:-working}"
    local -a frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local i=0
    tput civis 2>/dev/null || true
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  \e[38;2;0;255;156m%s\e[0m  %s" "${frames[$((i % 10))]}" "$label"
        i=$((i + 1))
        sleep 0.1 2>/dev/null || sleep 1
    done
    printf "\r\e[K"
    tput cnorm 2>/dev/null || true
}
