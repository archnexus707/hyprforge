#!/bin/bash
# 💫 https://github.com/archnexus707 💫 #
# Global Functions for Scripts #

# pipefail is required so `install_package "$X" | tee -a "$LOG"` actually
# propagates install_package's return code instead of always seeing tee's 0.
# Without it, a failed apt install in a piped caller silently looks like a
# success and the phase reports [OK] with the package missing.
set -eo pipefail

# Set some colors for output messages (be resilient in non-interactive shells)
if tput sgr0 >/dev/null 2>&1; then
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
else
  OK="[OK]"; ERROR="[ERROR]"; NOTE="[NOTE]"; INFO="[INFO]"; WARN="[WARN]"; CAT="[ACTION]"
  MAGENTA=""; ORANGE=""; WARNING=""; YELLOW=""; GREEN=""; BLUE=""; SKY_BLUE=""; RESET=""
fi

# Create Directory for Install Logs
if [ ! -d Install-Logs ]; then
    mkdir Install-Logs
fi

# Shared build output root (override with BUILD_ROOT env). A failure here is
# fatal: every downstream `cd "$SRC_DIR"` would either silently land in the
# wrong place or trip set -e mid-script with no useful context.
BUILD_ROOT="${BUILD_ROOT:-$PWD/build}"
mkdir -p "$BUILD_ROOT" || { echo "[ERROR] cannot create BUILD_ROOT=$BUILD_ROOT (check permissions / disk)"; exit 1; }
SRC_ROOT="${SRC_ROOT:-$BUILD_ROOT/src}"
mkdir -p "$SRC_ROOT"   || { echo "[ERROR] cannot create SRC_ROOT=$SRC_ROOT (check permissions / disk)"; exit 1; }

# Prime sudo once for the whole install session so that backgrounded apt jobs
# (whose stderr is redirected to the log) don't silently stall on an invisible
# password prompt. A background keep-alive refreshes the timestamp every 60s so
# long source-build phases don't let credentials expire mid-install.
#
# Safe to source-and-call from sub-scripts: idempotent — if a keep-alive already
# exists in this shell, the function returns without spawning another.
_ARCHNEXUS_SUDO_KEEPALIVE_PID="${_ARCHNEXUS_SUDO_KEEPALIVE_PID:-}"
archnexus_sudo_prime() {
    [ -n "${_ARCHNEXUS_SUDO_KEEPALIVE_PID:-}" ] && return 0
    if sudo -n true 2>/dev/null; then
        :
    else
        printf "%s installer needs sudo for apt/build/install. Enter your password once:\n" "${INFO}"
        if ! sudo -v; then
            printf "%s sudo authentication failed; aborting before any modification\n" "${ERROR}" >&2
            exit 2
        fi
    fi
    ( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null || exit; sleep 60; done ) &
    _ARCHNEXUS_SUDO_KEEPALIVE_PID=$!
    export _ARCHNEXUS_SUDO_KEEPALIVE_PID
    # Best-effort cleanup; don't trap in sub-scripts that source this file
    # (only the entry-point install.sh sets the trap).
    return 0
}

archnexus_sudo_cleanup() {
    if [ -n "${_ARCHNEXUS_SUDO_KEEPALIVE_PID:-}" ]; then
        kill "$_ARCHNEXUS_SUDO_KEEPALIVE_PID" 2>/dev/null || true
        _ARCHNEXUS_SUDO_KEEPALIVE_PID=""
    fi
}

# Dump the tail of $LOG to the terminal so the user sees the real apt error
# (broken deps, network, dpkg interrupted, etc.) instead of just a generic
# "failed to install" line. Called by install_package on hard failure.
_archnexus_dump_log_tail() {
    local n="${1:-20}"
    [ -f "$LOG" ] || return 0
    printf "%s ---- last %d lines of %s ----\n" "${ERROR}" "$n" "$LOG" >&2
    tail -n "$n" "$LOG" 2>/dev/null | sed 's/^/    /' >&2
    printf "%s ---- end of log tail ----\n" "${ERROR}" >&2
}

# Show progress function. tput civis/cnorm only make sense with a real
# terminal; gate them so non-interactive runs (CI, redirected output) don't
# clutter the log with control sequences.
show_progress() {
    local pid=$1
    local package_name=$2
    local spin_chars=("●○○○○○○○○○" "○●○○○○○○○○" "○○●○○○○○○○" "○○○●○○○○○○" "○○○○●○○○○" \
                      "○○○○○●○○○○" "○○○○○○●○○○" "○○○○○○○●○○" "○○○○○○○○●○" "○○○○○○○○○●")
    local n=${#spin_chars[@]} i=0
    local interactive=0
    [ -t 1 ] && interactive=1

    [ "$interactive" -eq 1 ] && tput civis 2>/dev/null
    printf "\r${INFO} Installing ${YELLOW}%s${RESET} ..." "$package_name"

    while ps -p "$pid" &> /dev/null; do
        if [ "$interactive" -eq 1 ]; then
            printf "\r${INFO} Installing ${YELLOW}%s${RESET} %s" "$package_name" "${spin_chars[i]}"
        fi
        i=$(( (i + 1) % n ))
        sleep 0.3
    done

    printf "\r${INFO} Installing ${YELLOW}%s${RESET} ... Done!%-20s \n\n" "$package_name" ""
    [ "$interactive" -eq 1 ] && tput cnorm 2>/dev/null
}


# Function for installing packages with a progress bar
# Accepts optional second argument for log path (backward compat)
install_package() {
  local pkg="$1"
  local pkg_log="${2:-$LOG}"
  if dpkg -l | grep -q -w "^ii  $pkg " ; then
    echo -e "${INFO} ${MAGENTA}$pkg${RESET} is already installed. Skipping..."
    return 0
  fi
  (
    stdbuf -oL sudo apt install -y "$pkg" 2>&1
  ) >> "$pkg_log" 2>&1 &
  PID=$!
  show_progress $PID "$pkg"

  if dpkg -l | grep -q -w "^ii  $pkg " ; then
      echo -e "\e[1A\e[K${OK} Package ${YELLOW}$pkg${RESET} has been successfully installed!"
      return 0
  fi

  # First attempt failed. The two most common recoverable causes on
  # Kali/Debian are an interrupted dpkg state and stale package lists — fix
  # both, then retry once before giving up.
  echo -e "\e[1A\e[K${WARN} ${YELLOW}$pkg${RESET} failed; attempting auto-recovery..."
  sudo dpkg --configure -a >> "$pkg_log" 2>&1 || true
  sudo apt-get update >> "$pkg_log" 2>&1 || true
  sudo apt-get -f install -y >> "$pkg_log" 2>&1 || true
  (
    stdbuf -oL sudo apt install -y "$pkg" 2>&1
  ) >> "$pkg_log" 2>&1 &
  PID=$!
  show_progress $PID "$pkg"

  if dpkg -l | grep -q -w "^ii  $pkg " ; then
      echo -e "\e[1A\e[K${OK} Package ${YELLOW}$pkg${RESET} installed (after recovery)!"
      return 0
  fi
  echo -e "\e[1A\e[K${ERROR} ${YELLOW}$pkg${RESET} failed to install — full log: $pkg_log"
  _archnexus_dump_log_tail 20
  # Record the failed package name in a session-wide side-channel so the
  # orchestrator's execute_script wrapper can detect this even when the caller
  # piped install_package's output through tee (which would otherwise drop our
  # exit code despite pipefail being on).
  if [ -n "${KHYPR_FAIL_FILE:-}" ]; then
      printf '%s\n' "$1" >> "$KHYPR_FAIL_FILE" 2>/dev/null || true
  fi
  return 1
}

# Function for build depencies with a progress bar
build_dep() {
  local pkg="$1"
  local pkg_log="${2:-$LOG}"
  echo -e "${INFO} building dependencies for ${MAGENTA}$pkg${RESET} "
    (
      stdbuf -oL sudo apt build-dep -y "$pkg" 2>&1
    ) >> "$pkg_log" 2>&1 &
    PID=$!
    show_progress $PID "$pkg"
}

# Function for cargo install with a progress bar
cargo_install() {
  local pkg="$1"
  local pkg_log="${2:-$LOG}"
  echo -e "${INFO} installing ${MAGENTA}$pkg${RESET} using cargo..."
    (
      stdbuf -oL cargo install "$pkg" 2>&1
    ) >> "$pkg_log" 2>&1 &
    PID=$!
    show_progress $PID "$pkg"
}

# Function for re-installing packages with a progress bar
re_install_package() {
    local pkg="$1"
    local pkg_log="${2:-$LOG}"
    (
        stdbuf -oL sudo apt install --reinstall -y "$pkg" 2>&1
    ) >> "$pkg_log" 2>&1 &

    PID=$!
    show_progress $PID "$pkg"

    if dpkg -l | grep -q -w "^ii  $pkg " ; then
        echo -e "\e[1A\e[K${OK} Package ${YELLOW}$pkg${RESET} has been successfully re-installed!"
    else
        # Package not found, reinstallation failed
        echo -e "${ERROR} ${YELLOW}$pkg${RESET} failed to re-install. Please check the install.log. You may need to install it manually. Sorry, I have tried :("
    fi
}

# Function for removing packages
uninstall_package() {
  local pkg="$1"

  # Checking if package is installed
  if sudo dpkg -l | grep -q -w "^ii  $1" ; then
    echo -e "${NOTE} removing $pkg ..."
    sudo apt autoremove -y "$1" >> "$LOG" 2>&1 || true
    
    if ! dpkg -l | grep -q -w "^ii *$1 " ; then
      echo -e "\e[1A\e[K${OK} ${MAGENTA}$1${RESET} removed."
    else
      echo -e "\e[1A\e[K${ERROR} $pkg Removal failed. No actions required."
      return 1
    fi
  else
    echo -e "${INFO} Package $pkg not installed, skipping."
  fi
  return 0
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
    local depth=""
    [ "${ARCHNEXUS_GIT_NO_SHALLOW:-0}" = "0" ] && depth="--depth=1"
    mkdir -p "$(dirname "$dest")"
    local max="${ARCHNEXUS_RETRY_MAX:-3}"
    local delay="${ARCHNEXUS_RETRY_BASE:-2}"
    local attempt=1 rc=0
    while [ "$attempt" -le "$max" ]; do
        rm -rf "$dest"
        # `command git` bypasses our git() retry shim — without this, the
        # shim would add a second retry layer (3 outer x 3 inner = 9 attempts).
        # shellcheck disable=SC2086
        command git clone $depth "$@" "$repo" "$dest"
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

# ----- git clone retry shim -------------------------------------------------
# Define a `git` shell function that intercepts ONLY `git clone` (everything
# else passes through unchanged via `command git`). This lets every existing
# `git clone …` in sub-scripts get exponential-backoff retry without touching
# the call sites. The last positional argument is treated as the destination
# directory; on retry-2+ we wipe it so the partial clone from the previous
# attempt doesn't make git refuse with "destination path already exists".
#
# Honors the same ARCHNEXUS_RETRY_* env knobs as archnexus_retry.
git() {
    if [ "${1:-}" != "clone" ]; then
        command git "$@"
        return $?
    fi
    shift
    local max="${ARCHNEXUS_RETRY_MAX:-3}"
    local delay="${ARCHNEXUS_RETRY_BASE:-2}"
    local attempt=1 rc=0
    local dest=""
    if [ "$#" -gt 0 ]; then
        # Skip a trailing pipe-target accident: last positional arg is the dest.
        dest="${@: -1}"
    fi
    while [ "$attempt" -le "$max" ]; do
        if [ "$attempt" -gt 1 ] && [ -n "$dest" ]; then
            case "$dest" in
                /|/etc|/etc/*|/usr|/usr/*|/var|/var/*|/lib|/lib/*|/lib64|/lib64/*) ;;
                /bin|/bin/*|/sbin|/sbin/*|/boot|/boot/*|/root|/home|/dev|/dev/*) ;;
                /proc|/proc/*|/sys|/sys/*|/run|/run/*) ;;
                -*) ;;  # looks like a flag, not a path
                "") ;;
                *) [ "${#dest}" -ge 4 ] && rm -rf "$dest" 2>/dev/null ;;
            esac
        fi
        command git clone "$@"
        rc=$?
        [ "$rc" -eq 0 ] && return 0
        if [ "$attempt" -lt "$max" ]; then
            printf "%s git clone failed (attempt %d/%d, rc=%d); retrying in %ds\n" \
                "${WARN:-[WARN]}" "$attempt" "$max" "$rc" "$delay" >&2
            sleep "$delay"
            delay=$((delay * 2))
        fi
        attempt=$((attempt + 1))
    done
    return "$rc"
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
