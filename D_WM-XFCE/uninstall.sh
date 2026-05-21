#!/usr/bin/env bash
# D_WM-XFCE uninstaller — replays an install session's manifest in reverse.
#
# Each manifest line is a shell command that reverses one action. We source
# them in reverse order so the last thing we did is undone first.

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install-scripts/lib/safety.sh
. "$SCRIPT_DIR/install-scripts/lib/safety.sh"

print_help() {
    cat <<EOF
D_WM-XFCE uninstaller — rolls back a previous install session.

USAGE:
  ./uninstall.sh <session-timestamp>
  ./uninstall.sh --latest
  ./uninstall.sh --list

The timestamp is the directory name under ~/.dwm-backup/. Use --list to see
available sessions.
EOF
}

list_sessions() {
    if [ ! -d "$DWM_BACKUP_ROOT" ]; then
        printf "%s no sessions found at %s\n" "$WARN" "$DWM_BACKUP_ROOT"
        return 0
    fi
    printf "%s available sessions in %s:\n" "$INFO" "$DWM_BACKUP_ROOT"
    ls -1 "$DWM_BACKUP_ROOT" 2>/dev/null | sort
}

case "${1:-}" in
    ""|-h|--help) print_help; exit 0 ;;
    --list)       list_sessions; exit 0 ;;
    --latest)
        TS="$(ls -1 "$DWM_BACKUP_ROOT" 2>/dev/null | sort | tail -n1)"
        [ -n "$TS" ] || die "no sessions found"
        ;;
    *) TS="$1" ;;
esac

SESSION_DIR="$DWM_BACKUP_ROOT/$TS"
MANIFEST="$SESSION_DIR/manifest.sh"
[ -d "$SESSION_DIR" ] || die "no session dir: $SESSION_DIR"
[ -f "$MANIFEST" ]   || die "no manifest at $MANIFEST"

printf "%s about to roll back session %s\n" "$WARN" "$TS"
printf "%s manifest: %s\n" "$INFO" "$MANIFEST"
printf "%s undo actions (will run in reverse order):\n" "$INFO"
nl "$MANIFEST" | sed -n '/^[[:space:]]*[0-9]/p'

confirm "Proceed with rollback?" || abort "Rollback cancelled."

# Read manifest in reverse, skipping comments and blanks, execute each line.
# Use process substitution (not a pipe) so `errs` lives in this shell and the
# final exit code reflects the real outcome.
errs=0
while IFS= read -r line; do
    case "$line" in
        ""|"#"*) continue ;;
    esac
    printf "%s undoing: %s\n" "$INFO" "$line"
    if ! bash -c "$line"; then
        printf "%s undo step failed: %s\n" "$WARN" "$line"
        errs=$((errs+1))
    fi
done < <(tac "$MANIFEST")

if [ "$errs" -gt 0 ]; then
    printf "\n%s rollback finished with %d failed undo step(s); session dir kept at %s\n" "$WARN" "$errs" "$SESSION_DIR"
    printf "%s review the messages above; rerun manually for steps that need it\n" "$INFO"
    exit 1
fi

printf "\n%s rollback complete; session dir kept at %s for inspection\n" "$OK" "$SESSION_DIR"
printf "%s if you also want to delete the backup dir, run: rm -rf %s\n" "$INFO" "$SESSION_DIR"
