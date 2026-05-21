#!/usr/bin/env bash
# safety.sh — shared safety primitives for D_WM-XFCE / Kali-Hyprland installers.
#
# Source this file at the top of install.sh BEFORE any system modification.
# All file writes, apt operations, and systemctl actions MUST go through the
# helpers in this file so they get logged, backed up, and replayed by uninstall.sh.
#
# Exit codes:
#   0 = success
#   2 = preflight refused
#   3 = user aborted at a confirmation prompt

set -o pipefail

# archnexus707 banner + phase + spinner helpers. Sourced here (rather than from
# install.sh only) so every sub-script that sources safety.sh also has them.
_SAFETY_LIB_DIR_EARLY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$_SAFETY_LIB_DIR_EARLY/archnexus_banner.sh" ]; then
    # shellcheck disable=SC1091
    . "$_SAFETY_LIB_DIR_EARLY/archnexus_banner.sh"
fi

# ----- color / log primitives -------------------------------------------------
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    OK="$(tput setaf 2)[OK]$(tput sgr0)"
    ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
    NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
    INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
    WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
    DRY="$(tput setaf 5)[DRY-RUN]$(tput sgr0)"
    RED="$(tput setaf 1)"
    YELLOW="$(tput setaf 3)"
    GREEN="$(tput setaf 2)"
    RESET="$(tput sgr0)"
else
    OK="[OK]";    ERROR="[ERROR]"; NOTE="[NOTE]"
    INFO="[INFO]"; WARN="[WARN]";  DRY="[DRY-RUN]"
    RED=""; YELLOW=""; GREEN=""; RESET=""
fi

# ----- session state ---------------------------------------------------------
DWM_DRY_RUN="${DWM_DRY_RUN:-0}"
DWM_FORCE="${DWM_FORCE:-0}"
DWM_BACKUP_ROOT="${DWM_BACKUP_ROOT:-$HOME/.dwm-backup}"
DWM_SESSION_TS="${DWM_SESSION_TS:-$(date -u +%Y-%m-%dT%H-%M-%SZ)}"
DWM_BACKUP_DIR="$DWM_BACKUP_ROOT/$DWM_SESSION_TS"
DWM_MANIFEST="$DWM_BACKUP_DIR/manifest.sh"
_SAFETY_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DWM_LOG_DIR="${DWM_LOG_DIR:-$_SAFETY_LIB_DIR/../../Install-Logs}"
DWM_LOG="${DWM_LOG_DIR}/install-${DWM_SESSION_TS}.log"

safety_init_session() {
    if [ "$DWM_DRY_RUN" = "1" ]; then
        printf "%s dry-run mode; no files will be modified\n" "$DRY"
        printf "%s would create backup dir: %s\n" "$DRY" "$DWM_BACKUP_DIR"
        mkdir -p "$DWM_LOG_DIR" 2>/dev/null || true
        return 0
    fi
    # Backup dir must exist and be writable before we promise the user "we
    # backed it up." A failure here (RO mount, NFS perms, full disk) must be
    # fatal — otherwise the manifest is silently lost and rollback is impossible.
    mkdir -p "$DWM_BACKUP_DIR" "$DWM_LOG_DIR" \
        || die "cannot create backup dir $DWM_BACKUP_DIR (check permissions / disk space)"
    [ -w "$DWM_BACKUP_DIR" ] || die "backup dir not writable: $DWM_BACKUP_DIR"
    [ -w "$DWM_LOG_DIR" ]    || die "log dir not writable: $DWM_LOG_DIR"
    chmod 700 "$DWM_BACKUP_DIR" || die "chmod 700 failed on $DWM_BACKUP_DIR"
    if ! cat > "$DWM_MANIFEST" <<EOF
# D_WM install manifest — replayed by uninstall.sh in reverse order.
# Session: $DWM_SESSION_TS
# Started: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
# Host:    $(uname -n)
# User:    $USER
EOF
    then
        die "failed to write manifest header at $DWM_MANIFEST"
    fi
    log "session $DWM_SESSION_TS started; backups go to $DWM_BACKUP_DIR"
}

# Prime sudo once at session start so all later apt/systemctl calls (which
# redirect stderr to the log) don't silently stall on a hidden password
# prompt. A background keep-alive refreshes the timestamp every 60s so long
# download/theme phases don't let credentials expire mid-install.
safety_sudo_prime() {
    [ "$DWM_DRY_RUN" = "1" ] && return 0
    if sudo -n true 2>/dev/null; then
        log "sudo credentials already cached"
    else
        printf "%s installer needs sudo for apt + systemctl. Enter your password once now:\n" "$INFO"
        if ! sudo -v; then
            die "sudo authentication failed; aborting before any modification"
        fi
    fi
    # Refresh the sudo timestamp until the parent shell exits. `kill -0 $$`
    # ties the keep-alive lifetime to this shell so it exits cleanly even if
    # the trap is missed (e.g. on SIGKILL of the parent).
    # Refresh every 30s (well under the default 5-min sudoers timeout) so a
    # long-running download or theme phase can't let credentials lapse between
    # ticks. Cheap; one `sudo -n true` per 30s is essentially free.
    ( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null || exit; sleep 30; done ) &
    _DWM_SUDO_KEEPALIVE_PID=$!
    trap '_safety_sudo_cleanup' EXIT INT TERM
    log "sudo credentials primed (keep-alive pid=$_DWM_SUDO_KEEPALIVE_PID)"
}

_safety_sudo_cleanup() {
    if [ -n "${_DWM_SUDO_KEEPALIVE_PID:-}" ]; then
        kill "$_DWM_SUDO_KEEPALIVE_PID" 2>/dev/null || true
        _DWM_SUDO_KEEPALIVE_PID=""
    fi
}

log() {
    local ts msg="$*"
    ts="$(date -u +%H:%M:%S)"
    [ -d "$DWM_LOG_DIR" ] && printf "[%s] %s\n" "$ts" "$msg" >> "$DWM_LOG" 2>/dev/null
    printf "%s %s\n" "$INFO" "$msg"
}

die() {
    printf "%s %s\n" "$ERROR" "$*" >&2
    exit 2
}

abort() {
    printf "%s %s\n" "$WARN" "$*" >&2
    exit 3
}

confirm() {
    # $1: prompt; returns 0 on yes, non-zero on no. Honors DWM_FORCE=1.
    local prompt="$1" ans
    if [ "$DWM_FORCE" = "1" ]; then
        log "auto-confirmed (DWM_FORCE=1): $prompt"
        return 0
    fi
    if command -v whiptail >/dev/null 2>&1 && [ -t 0 ]; then
        whiptail --title "Confirm" --yesno "$prompt" 12 70
    else
        read -rp "$prompt [yes/NO]: " ans
        [ "$ans" = "yes" ]
    fi
}

# ----- environment detection -------------------------------------------------
is_root()        { [ "$(id -u)" -eq 0 ]; }
is_vmware()      { [ "$(systemd-detect-virt 2>/dev/null || echo none)" = "vmware" ]; }
is_any_vm()      { [ "$(systemd-detect-virt 2>/dev/null || echo none)" != "none" ]; }
is_in_graphical_session() {
    [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]
}
free_disk_gb() {
    df -BG --output=avail "$HOME" 2>/dev/null | awk 'NR==2 {gsub("G",""); print $1}'
}
detect_dm() {
    # prints the active display manager unit or "none"
    local dm
    for dm in lightdm gdm gdm3 sddm lxdm; do
        if systemctl is-active --quiet "$dm.service" 2>/dev/null; then
            echo "$dm"; return 0
        fi
    done
    echo "none"
}

# ----- pre-flight ------------------------------------------------------------
safety_banner() {
    printf "\n%s========================================================%s\n" "$RED" "$RESET"
    printf "%s  D_WM / Kali-Hyprland installer — READ BEFORE PROCEEDING %s\n" "$RED" "$RESET"
    printf "%s========================================================%s\n\n" "$RED" "$RESET"
    cat <<'EOF'
This installer will (only if you opt in to each phase):
  * install packages via apt
  * change the system display manager (lightdm -> sddm) — OPTIONAL
  * write configuration files under ~/.config/
  * disable XFCE's default window manager — OPTIONAL

This installer will NOT:
  * compile kernel modules unless you explicitly opt into nvidia.sh on bare metal
  * delete personal files
  * modify anything outside your $HOME or /etc paths listed in the manifest
  * proceed if any pre-flight check fails

Every file we modify is first backed up to ~/.dwm-backup/<timestamp>/.
To roll back, run: ./uninstall.sh <timestamp>

Recommendations:
  * Always run --dry-run first to see exactly what would change
  * On bare metal: switch to a TTY (Ctrl+Alt+F2) before running risky phases
  * In VMware: take a snapshot before running

EOF
}

safety_preflight() {
    local errs=0

    if is_root; then
        printf "%s do not run as root. The installer uses sudo where needed.\n" "$ERROR"
        errs=$((errs+1))
    fi

    local free; free=$(free_disk_gb)
    if [ -z "$free" ] || [ "$free" -lt 5 ]; then
        printf "%s insufficient free disk in \$HOME: %sGB available, 5GB minimum\n" "$ERROR" "${free:-?}"
        errs=$((errs+1))
    fi

    if ! command -v apt-get >/dev/null 2>&1; then
        printf "%s apt-get not found; this installer targets Debian/Kali\n" "$ERROR"
        errs=$((errs+1))
    fi

    if [ ! -r /etc/os-release ]; then
        printf "%s /etc/os-release missing; cannot identify OS\n" "$ERROR"
        errs=$((errs+1))
    else
        . /etc/os-release
        case "${ID:-}" in
            kali)
                printf "%s detected Kali (%s)\n" "$OK" "${VERSION_CODENAME:-rolling}" ;;
            debian)
                printf "%s detected Debian (%s)\n" "$OK" "${VERSION_CODENAME:-unknown}" ;;
            *)
                printf "%s OS ID '%s' is not Kali or Debian; refusing\n" "$ERROR" "${ID:-?}"
                errs=$((errs+1)) ;;
        esac
    fi

    if [ "$errs" -ne 0 ]; then
        printf "\n%s %d pre-flight check(s) failed; aborting before any modification\n" "$ERROR" "$errs"
        return 2
    fi

    # virtualization
    if is_vmware; then
        printf "%s VMware guest detected\n" "$INFO"
        if [ "$DWM_DRY_RUN" != "1" ]; then
            confirm "Have you taken a VMware snapshot in the last 10 minutes? Choose No to abort and snapshot first." \
                || abort "Take a snapshot first, then rerun."
        fi
    elif is_any_vm; then
        printf "%s VM detected (%s). Not VMware — proceed with caution.\n" "$WARN" "$(systemd-detect-virt)"
    else
        printf "%s bare-metal host detected\n" "$INFO"
    fi

    # graphical session warning
    if is_in_graphical_session; then
        printf "%s you are running from inside a graphical session (\$DISPLAY=%s)\n" \
            "$WARN" "${DISPLAY:-${WAYLAND_DISPLAY:-?}}"
        printf "%s phases that swap display manager or window manager may end your session\n" "$WARN"
        printf "%s recommended: Ctrl+Alt+F2, log in on the TTY, rerun there\n" "$WARN"
        if [ "$DWM_DRY_RUN" != "1" ]; then
            confirm "Continue from inside the graphical session?" \
                || abort "Switch to a TTY and rerun."
        fi
    fi

    printf "%s pre-flight passed\n\n" "$OK"
    return 0
}

# ----- manifest / undo -------------------------------------------------------
register_undo() {
    # append undo command(s) to manifest. uninstall.sh sources & replays.
    # The manifest is later run via `bash -c "$line"`, so any unescaped command
    # substitution survives into rollback. Reject lines that look like they
    # contain `$(...)` or backtick expansion — callers must build undo commands
    # with already-expanded literal paths, never with embedded shell expansions.
    [ "$DWM_DRY_RUN" = "1" ] && return 0
    [ -f "$DWM_MANIFEST" ] || return 0
    local cmd="$*"
    case "$cmd" in
        *'$('*|*'`'*)
            printf "%s register_undo refused (embedded command substitution): %s\n" \
                "${WARN:-[WARN]}" "$cmd" >&2
            return 1
            ;;
    esac
    printf '%s\n' "$cmd" >> "$DWM_MANIFEST"
}

# ----- backup primitives -----------------------------------------------------
backup_file() {
    local src="$1"
    [ -e "$src" ] || return 0
    if [ "$DWM_DRY_RUN" = "1" ]; then
        printf "%s would back up %s\n" "$DRY" "$src"
        return 0
    fi
    local dst="$DWM_BACKUP_DIR$src"
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
    register_undo "cp -a \"$dst\" \"$src\""
    log "backed up $src"
}

backup_dir() {
    local src="$1"
    [ -d "$src" ] || return 0
    if [ "$DWM_DRY_RUN" = "1" ]; then
        printf "%s would back up dir %s\n" "$DRY" "$src"
        return 0
    fi
    local dst="$DWM_BACKUP_DIR$src"
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
    register_undo "rm -rf \"$src\" && cp -a \"$dst\" \"$src\""
    log "backed up dir $src"
}

# ----- apt wrappers ----------------------------------------------------------
_is_pkg_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

_apt_dump_tail() {
    # Print the last N lines of the install log to the terminal so the user
    # can see the actual apt failure (broken deps, network error, dpkg
    # interrupted, etc.) without having to open the log file.
    local n="${1:-25}"
    [ -f "$DWM_LOG" ] || return 0
    printf "%s ---- last %d lines of %s ----\n" "$ERROR" "$n" "$DWM_LOG" >&2
    tail -n "$n" "$DWM_LOG" 2>/dev/null | sed 's/^/    /' >&2
    printf "%s ---- end of log tail ----\n" "$ERROR" >&2
}

apt_install_safe() {
    local pkg
    for pkg in "$@"; do
        if _is_pkg_installed "$pkg"; then
            log "already installed: $pkg"
            continue
        fi
        if [ "$DWM_DRY_RUN" = "1" ]; then
            printf "%s apt install %s\n" "$DRY" "$pkg"
            # Skip sudo apt --simulate in pure dry-run to avoid password prompts.
            # Set DWM_DRY_RUN_DEEP=1 to also call apt --simulate for dep checks.
            if [ "${DWM_DRY_RUN_DEEP:-0}" = "1" ]; then
                sudo apt-get --simulate install -y "$pkg" >>"$DWM_LOG" 2>&1 || true
            fi
            continue
        fi
        log "installing $pkg"
        # Run apt in background so we can show a spinner. archnexus_spinner is
        # provided by archnexus_banner.sh (sourced at the top of this file);
        # if absent, fall back to a synchronous call.
        if command -v archnexus_spinner >/dev/null 2>&1; then
            sudo apt-get install -y --no-install-recommends "$pkg" >>"$DWM_LOG" 2>&1 &
            local _apt_pid=$!
            archnexus_spinner "$_apt_pid" "installing $pkg"
            wait "$_apt_pid"; local _apt_rc=$?
        else
            sudo apt-get install -y --no-install-recommends "$pkg" >>"$DWM_LOG" 2>&1
            local _apt_rc=$?
        fi
        if [ "$_apt_rc" -eq 0 ]; then
            register_undo "sudo apt-get remove -y \"$pkg\""
            printf "%s installed %s\n" "$OK" "$pkg"
            continue
        fi
        # First attempt failed. The two most common recoverable causes on
        # Kali are an interrupted dpkg state and stale package lists — fix
        # both, then retry once before giving up. Track which recovery steps
        # actually succeeded so we don't retry the install when recovery itself
        # is what's broken (which is the real underlying problem).
        printf "%s apt install failed for %s; attempting auto-recovery\n" "$WARN" "$pkg"
        log "running recovery: dpkg --configure -a; apt-get update; apt-get -f install"
        local _rec_rc=0
        sudo dpkg --configure -a >>"$DWM_LOG" 2>&1 \
            || { _rec_rc=1; printf "%s recovery step failed: dpkg --configure -a\n" "$WARN"; }
        sudo apt-get update >>"$DWM_LOG" 2>&1 \
            || { _rec_rc=1; printf "%s recovery step failed: apt-get update (network/repos?)\n" "$WARN"; }
        sudo apt-get -f install -y >>"$DWM_LOG" 2>&1 \
            || { _rec_rc=1; printf "%s recovery step failed: apt-get -f install\n" "$WARN"; }
        if [ "$_rec_rc" -ne 0 ]; then
            printf "%s skipping retry for %s because apt itself is unhealthy\n" "$ERROR" "$pkg"
            printf "%s fix the underlying apt/dpkg problem above, then rerun\n" "$INFO"
            _apt_dump_tail 25
            return 1
        fi
        if sudo apt-get install -y --no-install-recommends "$pkg" >>"$DWM_LOG" 2>&1; then
            register_undo "sudo apt-get remove -y \"$pkg\""
            printf "%s installed %s (after recovery)\n" "$OK" "$pkg"
            continue
        fi
        printf "%s apt install failed for %s — full log: %s\n" "$ERROR" "$pkg" "$DWM_LOG"
        _apt_dump_tail 25
        return 1
    done
}

apt_remove_safe() {
    local pkg
    for pkg in "$@"; do
        if ! _is_pkg_installed "$pkg"; then
            log "not installed, skipping remove: $pkg"
            continue
        fi
        if [ "$DWM_DRY_RUN" = "1" ]; then
            printf "%s apt remove %s\n" "$DRY" "$pkg"
            continue
        fi
        log "removing $pkg"
        if sudo apt-get remove -y "$pkg" >>"$DWM_LOG" 2>&1; then
            register_undo "sudo apt-get install -y --no-install-recommends \"$pkg\""
            printf "%s removed %s\n" "$OK" "$pkg"
        else
            printf "%s apt remove failed for %s (continuing)\n" "$WARN" "$pkg"
        fi
    done
}

# ----- file write wrappers ---------------------------------------------------
copy_into_place() {
    # $1 = src file/dir,  $2 = absolute dst path. Backs up dst first if present.
    local src="$1" dst="$2"
    [ -e "$src" ] || { printf "%s source missing: %s\n" "$ERROR" "$src"; return 1; }
    if [ -e "$dst" ]; then
        backup_file "$dst"
    fi
    if [ "$DWM_DRY_RUN" = "1" ]; then
        printf "%s would copy %s -> %s\n" "$DRY" "$src" "$dst"
        return 0
    fi
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
    register_undo "rm -rf \"$dst\""
    log "wrote $dst"
}

ensure_line_in_file() {
    # $1 = file, $2 = line. Adds line if absent; backs up first.
    local file="$1" line="$2"
    if [ -f "$file" ] && grep -qxF "$line" "$file"; then
        return 0
    fi
    if [ "$DWM_DRY_RUN" = "1" ]; then
        printf "%s would add to %s: %s\n" "$DRY" "$file" "$line"
        return 0
    fi
    backup_file "$file"
    printf '%s\n' "$line" | sudo tee -a "$file" >/dev/null
    log "added line to $file: $line"
}

# ----- systemctl wrappers ----------------------------------------------------
systemctl_disable_safe() {
    local svc="$1"
    if ! systemctl list-unit-files 2>/dev/null | awk '{print $1}' | grep -qx "$svc.service"; then
        log "service $svc not present, skipping"
        return 0
    fi
    if [ "$DWM_DRY_RUN" = "1" ]; then
        printf "%s systemctl disable %s\n" "$DRY" "$svc"
        return 0
    fi
    local was_enabled
    was_enabled=$(systemctl is-enabled "$svc.service" 2>/dev/null || echo disabled)
    sudo systemctl disable "$svc.service" >>"$DWM_LOG" 2>&1 || true
    if [ "$was_enabled" = "enabled" ]; then
        register_undo "sudo systemctl enable \"$svc.service\""
    fi
    log "disabled $svc (was $was_enabled)"
}

systemctl_enable_safe() {
    local svc="$1"
    if [ "$DWM_DRY_RUN" = "1" ]; then
        printf "%s systemctl enable %s\n" "$DRY" "$svc"
        return 0
    fi
    local was_enabled
    was_enabled=$(systemctl is-enabled "$svc.service" 2>/dev/null || echo disabled)
    sudo systemctl enable "$svc.service" >>"$DWM_LOG" 2>&1
    if [ "$was_enabled" != "enabled" ]; then
        register_undo "sudo systemctl disable \"$svc.service\""
    fi
    log "enabled $svc"
}

# ----- network retry helpers ------------------------------------------------
# Exponential-backoff retry for any command, plus opinionated wrappers around
# `git clone` and `curl` so a single slow mirror or transient network blip
# doesn't kill a multi-phase install.
#
# Tunables (env vars):
#   ARCHNEXUS_RETRY_MAX       default 3   — attempt count
#   ARCHNEXUS_RETRY_BASE      default 2   — first delay in seconds
#   ARCHNEXUS_GIT_NO_SHALLOW  default 0   — set to 1 to disable --depth=1
#   ARCHNEXUS_CURL_CONNECT    default 30  — --connect-timeout seconds
#   ARCHNEXUS_CURL_MAX        default 600 — --max-time seconds
archnexus_retry() {
    local max="${ARCHNEXUS_RETRY_MAX:-3}"
    local delay="${ARCHNEXUS_RETRY_BASE:-2}"
    local attempt=1 rc=0
    while [ "$attempt" -le "$max" ]; do
        "$@"
        rc=$?
        [ "$rc" -eq 0 ] && return 0
        if [ "$attempt" -lt "$max" ]; then
            printf "%s attempt %d/%d failed (rc=%d); retrying in %ds: %s\n" \
                "${WARN:-[WARN]}" "$attempt" "$max" "$rc" "$delay" "$1" >&2
            sleep "$delay"
            delay=$((delay * 2))
        fi
        attempt=$((attempt + 1))
    done
    printf "%s gave up after %d attempts: %s\n" "${ERROR:-[ERROR]}" "$max" "$1" >&2
    return "$rc"
}

# Internal sanity guard so a buggy caller can't `rm -rf` something critical.
_archnexus_safe_dest() {
    local d="$1"
    [ -z "$d" ] && return 1
    case "$d" in
        /|/etc|/etc/*|/usr|/usr/*|/var|/var/*|/lib|/lib/*|/lib64|/lib64/*) return 1 ;;
        /bin|/bin/*|/sbin|/sbin/*|/boot|/boot/*|/root|/home|/dev|/dev/*) return 1 ;;
        /proc|/proc/*|/sys|/sys/*|/run|/run/*) return 1 ;;
    esac
    [ "${#d}" -lt 4 ] && return 1
    return 0
}

# safe_git_clone <repo-url> <dest-dir> [extra git args]
# Idempotent: returns 0 if dest already contains a git repo. Retries with
# exponential backoff. Cleans the dest between attempts so a partial clone
# doesn't poison the retry.
safe_git_clone() {
    local repo="$1" dest="$2"; shift 2 || true
    if [ -d "$dest/.git" ]; then
        return 0
    fi
    if ! _archnexus_safe_dest "$dest"; then
        printf "%s safe_git_clone: refusing unsafe dest=%s\n" "${ERROR:-[ERROR]}" "$dest" >&2
        return 1
    fi
    local -a depth_args=()
    [ "${ARCHNEXUS_GIT_NO_SHALLOW:-0}" = "0" ] && depth_args=(--depth=1)
    mkdir -p "$(dirname "$dest")"
    local max="${ARCHNEXUS_RETRY_MAX:-3}"
    local delay="${ARCHNEXUS_RETRY_BASE:-2}"
    local attempt=1 rc=0
    while [ "$attempt" -le "$max" ]; do
        rm -rf "$dest"
        # `command git` is defensive in case a future shim wraps git globally.
        command git clone "${depth_args[@]}" "$@" "$repo" "$dest"
        rc=$?
        [ "$rc" -eq 0 ] && return 0
        if [ "$attempt" -lt "$max" ]; then
            printf "%s git clone failed (attempt %d/%d, rc=%d); retrying in %ds: %s\n" \
                "${WARN:-[WARN]}" "$attempt" "$max" "$rc" "$delay" "$repo" >&2
            sleep "$delay"
            delay=$((delay * 2))
        fi
        attempt=$((attempt + 1))
    done
    printf "%s safe_git_clone gave up: %s\n" "${ERROR:-[ERROR]}" "$repo" >&2
    return "$rc"
}

# safe_curl_download <url> <dest-file> [extra curl args]
# -fL by default, with connection + total timeouts. Replaces dest atomically.
safe_curl_download() {
    local url="$1" dest="$2"; shift 2 || true
    [ -z "$url" ] && return 1
    [ -z "$dest" ] && return 1
    mkdir -p "$(dirname "$dest")"
    local tmp="${dest}.partial.$$"
    local ct="${ARCHNEXUS_CURL_CONNECT:-30}"
    local mt="${ARCHNEXUS_CURL_MAX:-600}"
    if archnexus_retry curl -fL --connect-timeout "$ct" --max-time "$mt" "$@" -o "$tmp" "$url"; then
        mv -f "$tmp" "$dest"
        return 0
    fi
    rm -f "$tmp"
    return 1
}

# ----- pre-flight diagnostics ------------------------------------------------
# Read-only checks that catch the failure modes we now log tails for. Returns
# the count of HARD errors found (0 = green to go). Caller decides whether to
# abort, warn, or continue. Honors:
#   ARCHNEXUS_PREFLIGHT_STRICT=1   escalate warnings to errors
#   ARCHNEXUS_PREFLIGHT_NO_NET=1   skip the mirror reachability check
archnexus_preflight() {
    local min_gb="${1:-5}"
    local errs=0 warns=0
    local I="${INFO:-[INFO]}" W="${WARN:-[WARN]}" E="${ERROR:-[ERROR]}" O="${OK:-[OK]}"
    printf "%s ===== pre-flight diagnostics =====\n" "$I"

    # Disk space in $HOME — fonts/themes/build dirs all live there.
    local free_gb
    free_gb=$(df -BG --output=avail "$HOME" 2>/dev/null | awk 'NR==2 {gsub("G",""); print $1}')
    if [ -z "$free_gb" ]; then
        printf "%s could not determine free disk space in \$HOME\n" "$W"
        warns=$((warns + 1))
    elif [ "$free_gb" -lt "$min_gb" ]; then
        printf "%s low disk space: %sGB available in \$HOME, %sGB recommended\n" \
            "$E" "$free_gb" "$min_gb"
        errs=$((errs + 1))
    else
        printf "%s disk space: %sGB available in \$HOME (>= %sGB needed)\n" \
            "$O" "$free_gb" "$min_gb"
    fi

    # dpkg / apt lock — held by another live process?
    local lock=/var/lib/dpkg/lock-frontend
    if [ -e "$lock" ]; then
        local holder=""
        if command -v fuser >/dev/null 2>&1; then
            holder=$(sudo -n fuser "$lock" 2>/dev/null | tr -s ' ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        fi
        if [ -n "$holder" ]; then
            printf "%s dpkg lock-frontend held by pid(s): %s — close apt/unattended-upgrades first\n" "$E" "$holder"
            errs=$((errs + 1))
        else
            printf "%s dpkg lock-frontend present but idle (OK)\n" "$O"
        fi
    fi

    # apt-get check — broken deps surface here before they cascade.
    if command -v apt-get >/dev/null 2>&1; then
        local check_out
        check_out=$(apt-get check 2>&1 || true)
        if printf '%s' "$check_out" | grep -qiE "unmet dep|broken|you have held"; then
            printf "%s apt-get check reports broken packages — run 'sudo apt-get -f install' before proceeding\n" "$E"
            printf '%s\n' "$check_out" | sed 's/^/    /' | head -10
            errs=$((errs + 1))
        else
            printf "%s apt-get check passed\n" "$O"
        fi
    fi

    # Tools the installer assumes are on PATH (apt will install missing ones,
    # but if they're missing at preflight a system-update is overdue).
    local t miss=""
    for t in git curl make; do
        command -v "$t" >/dev/null 2>&1 || miss="$miss $t"
    done
    if [ -n "$miss" ]; then
        printf "%s prerequisite tool(s) missing:%s — installer will try to apt them but please rerun 'apt update' if it fails\n" "$W" "$miss"
        warns=$((warns + 1))
    fi

    # Network reach — short HEAD against multiple mirrors; pass if any works.
    if [ "${ARCHNEXUS_PREFLIGHT_NO_NET:-0}" != "1" ] && command -v curl >/dev/null 2>&1; then
        if curl --silent --head --connect-timeout 5 --max-time 8 https://deb.debian.org/   >/dev/null 2>&1 \
        || curl --silent --head --connect-timeout 5 --max-time 8 https://http.kali.org/    >/dev/null 2>&1 \
        || curl --silent --head --connect-timeout 5 --max-time 8 https://github.com/       >/dev/null 2>&1; then
            printf "%s network reachable\n" "$O"
        else
            printf "%s no mirror reachable — apt + git clone will likely fail\n" "$W"
            warns=$((warns + 1))
        fi
    fi

    if [ "${ARCHNEXUS_PREFLIGHT_STRICT:-0}" = "1" ]; then
        errs=$((errs + warns))
    fi

    if [ "$errs" -gt 0 ]; then
        printf "%s pre-flight FAILED with %d hard error(s) (%d warning(s))\n" "$E" "$errs" "$warns" >&2
    elif [ "$warns" -gt 0 ]; then
        printf "%s pre-flight passed with %d warning(s)\n" "$W" "$warns"
    else
        printf "%s pre-flight passed clean\n" "$O"
    fi
    return "$errs"
}

# ----- pre/post-phase hook runner -------------------------------------------
# Drop a script at install-scripts/hooks/<name>.sh and it auto-runs.
#
# Recognised names (called by run_phase / execute_script):
#   pre-all          before EVERY phase  (ctx = phase name)
#   post-all         after  EVERY phase  (ctx = "<name>=<rc>")
#   pre-<phase>      before a specific phase
#   post-<phase>     after  a specific phase (ctx = rc)
#
# Failures: soft by default (warn + continue). Set STRICT_HOOKS=1 to abort.
# Skip everything with NO_HOOKS=1.
archnexus_run_hooks() {
    [ "${NO_HOOKS:-0}" = "1" ] && return 0
    local hook="$1" ctx="${2:-}"
    local hook_dir="${ARCHNEXUS_HOOK_DIR:-install-scripts/hooks}"
    local hook_file="$hook_dir/${hook}.sh"
    [ -f "$hook_file" ] || return 0
    [ -x "$hook_file" ] || chmod +x "$hook_file" 2>/dev/null
    printf "%s ⛓  hook: %s\n" "${INFO:-[INFO]}" "$hook"
    # `$?` is reset to 0 by `if cmd; then ...; fi`, so capture rc directly.
    "$hook_file" "$ctx"
    local rc=$?
    [ "$rc" -eq 0 ] && return 0
    if [ "${STRICT_HOOKS:-0}" = "1" ]; then
        printf "%s hook failed (STRICT_HOOKS=1): %s rc=%d\n" "${ERROR:-[ERROR]}" "$hook" "$rc" >&2
        return $rc
    fi
    printf "%s hook failed (continuing): %s rc=%d\n" "${WARN:-[WARN]}" "$hook" "$rc"
    return 0
}

# ----- desktop notifications ------------------------------------------------
# Fire notify-send if a D-Bus session is reachable; silent no-op otherwise
# (TTY installs, CI, headless servers). Honors NOTIFY=0 to disable.
archnexus_notify() {
    [ "${NOTIFY:-1}" = "0" ] && return 0
    command -v notify-send >/dev/null 2>&1 || return 0
    [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}${DBUS_SESSION_BUS_ADDRESS:-}" ] && return 0
    local title="$1" body="${2:-}" urgency="${3:-normal}"
    notify-send -u "$urgency" -a "archnexus-installer" "$title" "$body" >/dev/null 2>&1 || true
}

# ----- optional pre-install snapshot ----------------------------------------
# Detects timeshift / snapper / raw-btrfs and ASKS the user (whiptail or plain
# read) whether to take a snapshot before this install. Default = no — the
# user has to opt in. Saves the snapshot identifier to a log line so it can
# be rolled back manually if anything breaks.
#
# Honors:
#   NON_INTERACTIVE=1   auto-decline (no prompt, no snapshot)
#   ARCHNEXUS_AUTO_SNAPSHOT=1   auto-accept (still detects + snaps if backend exists)
archnexus_offer_snapshot() {
    [ "${NON_INTERACTIVE:-0}" = "1" ] && return 0

    local backend=""
    if command -v timeshift >/dev/null 2>&1; then
        backend="timeshift"
    elif command -v findmnt >/dev/null 2>&1 && findmnt -t btrfs / >/dev/null 2>&1; then
        if command -v snapper >/dev/null 2>&1; then
            backend="snapper"
        elif command -v btrfs >/dev/null 2>&1; then
            backend="btrfs"
        fi
    fi

    if [ -z "$backend" ]; then
        return 0   # No snapshot tooling — silently skip.
    fi

    local prompt="${backend} detected.

Take a snapshot of / before this install so you can roll back
if anything breaks? Snapshots cost some disk space but save sanity.

Default: NO (you must opt in)."

    local accept=0
    if [ "${ARCHNEXUS_AUTO_SNAPSHOT:-0}" = "1" ]; then
        accept=1
    elif command -v whiptail >/dev/null 2>&1 && [ -t 0 ]; then
        if whiptail --title "Pre-install snapshot (optional)" \
                    --defaultno --yesno "$prompt" 14 70; then
            accept=1
        fi
    else
        printf "\n%s %s\n" "${INFO:-[INFO]}" "$prompt"
        read -rp "Take snapshot? [y/N]: " _ans
        case "${_ans,,}" in y|yes) accept=1 ;; esac
    fi

    [ "$accept" -eq 1 ] || { printf "%s snapshot declined (continuing without)\n" "${INFO:-[INFO]}"; return 0; }

    local stamp; stamp="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
    local id=""
    case "$backend" in
        timeshift)
            if sudo timeshift --create --comments "archnexus pre-install $stamp" --tags D 2>&1 \
                 | tee -a "${LOG:-/dev/null}" "${DWM_LOG:-/dev/null}" >/dev/null; then
                id="timeshift:$stamp"
            fi ;;
        snapper)
            local snap_id
            snap_id=$(sudo snapper -c root create -d "archnexus pre-install $stamp" --print-number 2>/dev/null)
            id="snapper:${snap_id:-?}" ;;
        btrfs)
            sudo mkdir -p /.archnexus-snapshots 2>/dev/null
            local dest="/.archnexus-snapshots/pre-$stamp"
            if sudo btrfs subvolume snapshot -r / "$dest" 2>&1 \
                 | tee -a "${LOG:-/dev/null}" "${DWM_LOG:-/dev/null}" >/dev/null; then
                id="btrfs:$dest"
            fi ;;
    esac

    if [ -n "$id" ]; then
        printf "%s snapshot taken: %s\n" "${OK:-[OK]}" "$id"
        # Record for the user; uninstall flow can read this line.
        if [ -n "${DWM_MANIFEST:-}" ] && [ -f "${DWM_MANIFEST}" ]; then
            echo "# pre-install snapshot: $id" >> "$DWM_MANIFEST"
        fi
        if [ -n "${LOG:-}" ]; then
            echo "[snapshot] $id" >> "$LOG"
        fi
    else
        printf "%s snapshot command failed; continuing without\n" "${WARN:-[WARN]}"
    fi
}
