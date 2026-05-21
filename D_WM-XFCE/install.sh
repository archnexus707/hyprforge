#!/usr/bin/env bash
# D_WM-XFCE installer entry point.
# Architectural pattern adapted from JaKooLit's Debian-Hyprland (GPL-3.0).
# Safety chassis (--dry-run, backups, manifest-driven uninstall) is original.

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || { echo "[ERROR] cannot cd to $SCRIPT_DIR"; exit 1; }

# shellcheck source=install-scripts/lib/safety.sh
. "$SCRIPT_DIR/install-scripts/lib/safety.sh"
# safety.sh transitively sources archnexus_banner.sh, so the banner / phase /
# spinner helpers are now available everywhere.

print_help() {
    cat <<EOF
D_WM-XFCE installer — Hyprland-style ricing for XFCE on Kali Linux.

USAGE: ./install.sh [OPTIONS]

OPTIONS:
  --dry-run         Show every action without making any change (safe).
  --force           Skip all yes/no confirmations (DANGEROUS — review --dry-run first).
  --preset <file>   Source a preset.sh file with ON/OFF toggles. Default: ./preset.sh
  --only <phase>    Run only one phase (00-deps | i3 | picom | xfce | kitty-zsh | fonts | themes | dotfiles | polish | vmware).
  --skip <phase>    Skip a phase (comma-separated also OK).
  --resume <ts>     Continue an interrupted install using its backup-dir timestamp.
  -h, --help        Print this help and exit.

EXAMPLES:
  ./install.sh --dry-run                            # see what would happen
  ./install.sh                                      # full interactive install
  ./install.sh --only i3 --dry-run                  # preview just the i3-gaps phase
  ./install.sh --skip themes,dotfiles               # base stack only

SAFETY:
  * Every modified file is backed up under ~/.dwm-backup/<timestamp>/
  * Every action is logged in Install-Logs/install-<timestamp>.log
  * Run ./uninstall.sh <timestamp> to roll back a session.
EOF
}

# ----- parse args ------------------------------------------------------------
PRESET_FILE="$SCRIPT_DIR/preset.sh"
ONLY_PHASE=""
SKIP_PHASES=""
RESUME_TS=""

# Generate one session timestamp BEFORE sourcing safety.sh so every sub-script
# inherits the same value via env. Sub-scripts use ${DWM_SESSION_TS:-...}.
export DWM_SESSION_TS="$(date -u +%Y-%m-%dT%H-%M-%SZ)"

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)  DWM_DRY_RUN=1; export DWM_DRY_RUN; shift ;;
        --force)    DWM_FORCE=1; export DWM_FORCE; shift ;;
        --preset)   PRESET_FILE="$2"; shift 2 ;;
        --only)     ONLY_PHASE="$2"; shift 2 ;;
        --skip)     SKIP_PHASES="$2"; shift 2 ;;
        --resume)   RESUME_TS="$2"; shift 2 ;;
        -h|--help)  print_help; exit 0 ;;
        *) printf "%s unknown argument: %s\n" "$ERROR" "$1"; print_help; exit 1 ;;
    esac
done

# ----- preset toggles --------------------------------------------------------
if [ -f "$PRESET_FILE" ]; then
    # shellcheck disable=SC1090
    . "$PRESET_FILE"
    log "loaded preset $PRESET_FILE"
fi

# Per-machine override (#30): same git repo, different toggles per host.
# Source AFTER the project preset so local.preset always wins.
LOCAL_PRESET="${ARCHNEXUS_LOCAL_PRESET:-$HOME/.config/archnexus/local.preset}"
if [ -f "$LOCAL_PRESET" ]; then
    # shellcheck disable=SC1090
    . "$LOCAL_PRESET"
    log "loaded per-machine override $LOCAL_PRESET"
fi

# defaults if preset didn't define them
: "${i3="ON"}"
: "${picom="ON"}"
: "${xfce_tweaks="ON"}"
: "${kitty_zsh="ON"}"
: "${fonts="ON"}"
: "${themes="ON"}"
: "${dotfiles="ON"}"
: "${pokemon="ON"}"
: "${polish="ON"}"           # archnexus polish: dwm-palette + dwm-powermenu
: "${optional_deps="OFF"}"   # default OFF — opt in for the new CLI tool deps
: "${sddm_swap="OFF"}"       # default OFF — keep Kali's lightdm
: "${vmware_tweaks="AUTO"}"  # AUTO = enable iff is_vmware

# ----- safety -----------------------------------------------------------------
clear
archnexus_banner "D_WM-XFCE" "Hyprland-grade ricing for XFCE on Kali Linux"
safety_banner

if [ -n "$RESUME_TS" ]; then
    DWM_SESSION_TS="$RESUME_TS"
    DWM_BACKUP_DIR="$DWM_BACKUP_ROOT/$DWM_SESSION_TS"
    DWM_MANIFEST="$DWM_BACKUP_DIR/manifest.sh"
    DWM_LOG="$DWM_LOG_DIR/install-$DWM_SESSION_TS.log"
    [ -d "$DWM_BACKUP_DIR" ] || die "no backup dir for session $RESUME_TS"
    log "resuming session $DWM_SESSION_TS"
    # System state can drift between the original run and a resume (apt lock,
    # disk fill, repo signing changes). Re-run preflight before doing anything
    # destructive. Set ARCHNEXUS_RESUME_SKIP_PREFLIGHT=1 to override.
    if [ "${ARCHNEXUS_RESUME_SKIP_PREFLIGHT:-0}" != "1" ]; then
        safety_preflight || die "pre-flight failed on resume (set ARCHNEXUS_RESUME_SKIP_PREFLIGHT=1 to override)"
        if ! archnexus_preflight 5; then
            die "extended pre-flight reported hard error(s) on resume; fix above and rerun"
        fi
    else
        log "ARCHNEXUS_RESUME_SKIP_PREFLIGHT=1 — skipping preflight on resume"
    fi
    safety_sudo_prime
else
    safety_preflight || die "pre-flight failed"
    # Extended diagnostics (disk/lock/apt/network). Set
    # ARCHNEXUS_PREFLIGHT_STRICT=1 to treat warnings as hard errors.
    if ! archnexus_preflight 5; then
        die "extended pre-flight reported hard error(s); fix above and rerun"
    fi
    safety_init_session
    safety_sudo_prime
    # Optional opt-in pre-install snapshot (Timeshift / Snapper / Btrfs).
    archnexus_offer_snapshot
fi

# Export the resolved session vars so every sub-script shares one log + manifest.
export DWM_BACKUP_DIR DWM_MANIFEST DWM_LOG DWM_LOG_DIR

# Hooks live in install-scripts/hooks/ — exported so sub-scripts that source
# safety.sh can also resolve hooks without relying on cwd.
export ARCHNEXUS_HOOK_DIR="$SCRIPT_DIR/install-scripts/hooks"

# ----- phase dispatcher ------------------------------------------------------
phase_should_run() {
    local name="$1"
    [ -n "$ONLY_PHASE" ] && [ "$ONLY_PHASE" != "$name" ] && return 1
    case ",$SKIP_PHASES," in
        *",$name,"*) return 1 ;;
    esac
    return 0
}

run_phase() {
    local name="$1" script="$2" toggle="${3:-ON}"
    phase_should_run "$name" || { log "skipping phase: $name"; return 0; }
    [ "$toggle" = "ON" ] || { log "preset disabled phase: $name"; return 0; }
    [ -x "$script" ] || { log "phase script not yet implemented: $script"; return 0; }
    if command -v archnexus_phase >/dev/null 2>&1; then
        archnexus_phase "$name" "$(basename "$script")"
    else
        printf "\n%s ===== phase: %s =====%s\n" "$YELLOW" "$name" "$RESET"
    fi
    archnexus_run_hooks "pre-all" "$name"
    archnexus_run_hooks "pre-$name"
    archnexus_notify "Phase started: $name" "$(basename "$script")"
    "$script"
    local rc=$?
    archnexus_run_hooks "post-$name" "$rc"
    archnexus_run_hooks "post-all" "$name=$rc"
    if [ "$rc" -eq 0 ]; then
        archnexus_notify "Phase OK: $name" "$(basename "$script")"
    else
        archnexus_notify "Phase FAILED: $name" "rc=$rc — see $DWM_LOG" critical
    fi
    return "$rc"
}

# VMware autosense
if [ "$vmware_tweaks" = "AUTO" ]; then
    if is_vmware; then vmware_tweaks="ON"; else vmware_tweaks="OFF"; fi
fi

# Phase order (each script idempotent; safe to rerun).
# Failures are tracked but do NOT abort — so an early phase failing still lets
# later ones run and gives the user a complete picture. The summary below uses
# DWM_PHASE_FAILURES to decide between [OK] and [FAIL], and the process exit
# code reflects the aggregate.
DWM_PHASE_FAILURES=()
run_phase 00-deps    "$SCRIPT_DIR/install-scripts/00-dependencies.sh" ON              || DWM_PHASE_FAILURES+=("00-deps")
run_phase pre-clean  "$SCRIPT_DIR/install-scripts/02-pre-cleanup.sh"  ON              || DWM_PHASE_FAILURES+=("pre-clean")
run_phase vmware     "$SCRIPT_DIR/install-scripts/vmware.sh"          "$vmware_tweaks" || DWM_PHASE_FAILURES+=("vmware")
run_phase i3         "$SCRIPT_DIR/install-scripts/i3-gaps.sh"         "$i3"           || DWM_PHASE_FAILURES+=("i3")
run_phase picom      "$SCRIPT_DIR/install-scripts/picom-ftlabs.sh"    "$picom"        || DWM_PHASE_FAILURES+=("picom")
run_phase xfce       "$SCRIPT_DIR/install-scripts/xfce-tweaks.sh"     "$xfce_tweaks"  || DWM_PHASE_FAILURES+=("xfce")
run_phase kitty-zsh  "$SCRIPT_DIR/install-scripts/kitty-zsh.sh"       "$kitty_zsh"    || DWM_PHASE_FAILURES+=("kitty-zsh")
run_phase fonts      "$SCRIPT_DIR/install-scripts/fonts.sh"           "$fonts"        || DWM_PHASE_FAILURES+=("fonts")
run_phase themes     "$SCRIPT_DIR/install-scripts/themes.sh"          "$themes"       || DWM_PHASE_FAILURES+=("themes")
run_phase dotfiles   "$SCRIPT_DIR/install-scripts/dotfiles.sh"        "$dotfiles"     || DWM_PHASE_FAILURES+=("dotfiles")
run_phase polish     "$SCRIPT_DIR/install-scripts/polish-archnexus.sh" "$polish"      || DWM_PHASE_FAILURES+=("polish")
run_phase cli-tools  "$SCRIPT_DIR/install-scripts/cli-tools.sh"       ON              || DWM_PHASE_FAILURES+=("cli-tools")
run_phase optional-deps "$SCRIPT_DIR/install-scripts/optional-deps.sh"  "$optional_deps" || DWM_PHASE_FAILURES+=("optional-deps")
run_phase final      "$SCRIPT_DIR/install-scripts/03-final-check.sh"  ON              || DWM_PHASE_FAILURES+=("final")

# OPTIONAL: download a curated lofi + anime wallpaper pack. The script prompts
# the user; declining is a clean no-op. Re-runnable any time stand-alone.
if [ -x "$SCRIPT_DIR/install-scripts/wallpaper-pack.sh" ] && [ "$DWM_DRY_RUN" != "1" ]; then
    "$SCRIPT_DIR/install-scripts/wallpaper-pack.sh" || true
fi

# ----- summary ---------------------------------------------------------------
_dwm_failed_count=${#DWM_PHASE_FAILURES[@]}
if [ "$_dwm_failed_count" -gt 0 ]; then
    printf "\n%s===========================================%s\n" "$RED" "$RESET"
    printf "%s install session %s FAILED (%d phase(s))%s\n" "$ERROR" "$DWM_SESSION_TS" "$_dwm_failed_count" "$RESET"
    printf "%s failed phases: %s%s\n" "$ERROR" "${DWM_PHASE_FAILURES[*]}" "$RESET"
    printf "%s backup dir: %s%s\n" "$INFO" "$DWM_BACKUP_DIR" "$RESET"
    printf "%s log:        %s%s\n" "$INFO" "$DWM_LOG" "$RESET"
    printf "%s rollback:   ./uninstall.sh %s%s\n" "$INFO" "$DWM_SESSION_TS" "$RESET"
    printf "%s===========================================%s\n\n" "$RED" "$RESET"
    archnexus_notify "D_WM-XFCE install FAILED" "Session $DWM_SESSION_TS — phases: ${DWM_PHASE_FAILURES[*]} — see $DWM_LOG" critical
    if [ "$DWM_DRY_RUN" = "1" ]; then
        printf "%s no changes were made. Re-run without --dry-run to apply.\n" "$DRY"
    fi
    exit 1
fi

printf "\n%s===========================================%s\n" "$GREEN" "$RESET"
printf "%s install session %s complete%s\n" "$OK" "$DWM_SESSION_TS" "$RESET"
printf "%s backup dir: %s%s\n" "$INFO" "$DWM_BACKUP_DIR" "$RESET"
printf "%s log:        %s%s\n" "$INFO" "$DWM_LOG" "$RESET"
printf "%s rollback:   ./uninstall.sh %s%s\n" "$INFO" "$DWM_SESSION_TS" "$RESET"
printf "%s===========================================%s\n\n" "$GREEN" "$RESET"

archnexus_notify "D_WM-XFCE install complete" "Session $DWM_SESSION_TS — see $DWM_LOG"

if [ "$DWM_DRY_RUN" = "1" ]; then
    printf "%s no changes were made. Re-run without --dry-run to apply.\n" "$DRY"
fi
