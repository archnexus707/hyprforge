#!/usr/bin/env bash
# cli-tools.sh — symlink every script in install-scripts/bin/ into
# ~/.local/bin/ (or LOCAL_BIN env override). Idempotent; safe to re-run.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/safety.sh
. "$SCRIPT_DIR/lib/safety.sh"

SRC_BIN="$SCRIPT_DIR/bin"
DEST_BIN="${LOCAL_BIN:-$HOME/.local/bin}"

printf "\n%s ===== installing archnexus CLI tools =====%s\n" "$YELLOW" "$RESET"

if [ ! -d "$SRC_BIN" ]; then
    printf "%s no bin/ directory found at %s; skipping\n" "$WARN" "$SRC_BIN"
    exit 0
fi

mkdir -p "$DEST_BIN"
register_undo "find \"$DEST_BIN\" -maxdepth 1 -lname \"$SRC_BIN/*\" -delete"

count=0
for src in "$SRC_BIN"/*; do
    [ -f "$src" ] || continue
    name="$(basename "$src")"
    dst="$DEST_BIN/$name"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        continue
    fi
    if [ "$DWM_DRY_RUN" = "1" ]; then
        printf "%s would symlink %s -> %s\n" "$DRY" "$src" "$dst"
        continue
    fi
    chmod +x "$src" 2>/dev/null || true
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        backup_file "$dst"
        rm -f "$dst"
    fi
    ln -sf "$src" "$dst"
    count=$((count + 1))
    log "deployed: $name"
done

if [ "$count" -gt 0 ]; then
    printf "%s deployed %d tool(s) to %s\n" "$OK" "$count" "$DEST_BIN"
else
    printf "%s all tools already deployed\n" "$OK"
fi

# PATH warning
case ":$PATH:" in
    *":$DEST_BIN:"*) ;;
    *) printf "%s NOTE: %s is not on \$PATH. Add: export PATH=\"\$HOME/.local/bin:\$PATH\"\n" "$WARN" "$DEST_BIN" ;;
esac

# ----- deploy systemd user units --------------------------------------------
UNIT_SRC="$SCRIPT_DIR/systemd"
UNIT_DST="$HOME/.config/systemd/user"
if [ -d "$UNIT_SRC" ] && [ "$DWM_DRY_RUN" != "1" ]; then
    mkdir -p "$UNIT_DST"
    for src in "$UNIT_SRC"/*.{service,path,timer}; do
        [ -f "$src" ] || continue
        name=$(basename "$src")
        dst="$UNIT_DST/$name"
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
            continue
        fi
        ln -sf "$src" "$dst"
        log "deployed user unit: $name"
        register_undo "rm -f \"$dst\"; systemctl --user disable --now \"$name\" 2>/dev/null || true"
    done
    systemctl --user daemon-reload 2>/dev/null || true
    # Enable units that should run by default. User can `systemctl --user
    # disable <unit>` to opt out.
    for u in archnexus-watch.service archnexus-display-hotplug.path; do
        [ -f "$UNIT_DST/$u" ] || continue
        systemctl --user enable --now "$u" 2>/dev/null \
            && log "$u enabled" \
            || printf "%s %s could not be enabled (no user systemd? continuing)\n" "$WARN" "$u"
    done
fi
