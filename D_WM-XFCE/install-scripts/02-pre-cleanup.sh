#!/usr/bin/env bash
# 02-pre-cleanup.sh — light, safe pre-install cleanup.
# Does NOT touch user data or running services. Only removes prior install
# artefacts that would otherwise cause conflicts.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/safety.sh
. "$SCRIPT_DIR/lib/safety.sh"

printf "\n%s ===== pre-install cleanup =====%s\n" "$YELLOW" "$RESET"

# 1. Remove a previously-installed source-built picom from /usr/local/bin if
#    present, so the new build replaces it cleanly. Backed up first.
if [ -x /usr/local/bin/picom ]; then
    log "removing previous source-built /usr/local/bin/picom (backed up first)"
    backup_file /usr/local/bin/picom
    if [ "$DWM_DRY_RUN" != "1" ]; then
        sudo rm -f /usr/local/bin/picom
        register_undo "echo 'previous picom removed; restore from backup_dir if needed'"
    fi
fi

# 2. Apt picom would conflict with our /usr/local/bin/picom on PATH order.
#    If it's installed, warn and offer to remove — but never silently remove,
#    since users may have intentionally installed it.
if dpkg-query -W -f='${Status}' picom 2>/dev/null | grep -q "install ok installed"; then
    if confirm "apt 'picom' is installed and will be shadowed by our /usr/local/bin/picom-ftlabs build. Remove the apt version?"; then
        apt_remove_safe picom
    else
        log "keeping apt picom; /usr/local/bin/picom (ftlabs build) will take precedence on PATH"
    fi
fi

log "02-pre-cleanup.sh complete"
