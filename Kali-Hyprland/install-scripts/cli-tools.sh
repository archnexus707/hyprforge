#!/bin/bash
# cli-tools.sh — symlink every script in install-scripts/bin/ into
# ~/.local/bin/ (or LOCAL_BIN env override). Idempotent; safe to re-run.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || exit 1

# shellcheck source=Global_functions.sh
if ! source "$SCRIPT_DIR/Global_functions.sh"; then
    echo "Failed to source Global_functions.sh"
    exit 1
fi

LOG="Install-Logs/install-$(date +%d-%H%M%S)_cli-tools.log"

SRC_BIN="$SCRIPT_DIR/bin"
DEST_BIN="${LOCAL_BIN:-$HOME/.local/bin}"

printf "\n%s - Deploying ${SKY_BLUE}archnexus CLI tools${RESET}\n" "${NOTE}"

if [ ! -d "$SRC_BIN" ]; then
    printf "%s no bin/ directory found at %s; skipping\n" "${WARN}" "$SRC_BIN"
    exit 0
fi

mkdir -p "$DEST_BIN"

count=0
for src in "$SRC_BIN"/*; do
    [ -f "$src" ] || continue
    name="$(basename "$src")"
    dst="$DEST_BIN/$name"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        continue
    fi
    chmod +x "$src" 2>/dev/null || true
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        cp -a "$dst" "$dst.backup-$(date +%s)" 2>/dev/null || true
        rm -f "$dst"
    fi
    ln -sf "$src" "$dst"
    count=$((count + 1))
    echo "${OK} deployed: ${YELLOW}$name${RESET}" | tee -a "$LOG"
done

if [ "$count" -eq 0 ]; then
    echo "${OK} all archnexus tools already deployed at $DEST_BIN" | tee -a "$LOG"
else
    echo "${OK} deployed $count archnexus tool(s) to $DEST_BIN" | tee -a "$LOG"
fi

case ":$PATH:" in
    *":$DEST_BIN:"*) ;;
    *) echo "${WARN} NOTE: $DEST_BIN is not on \$PATH. Add 'export PATH=\"\$HOME/.local/bin:\$PATH\"' to your shell rc." | tee -a "$LOG" ;;
esac

# ----- deploy systemd user units --------------------------------------------
UNIT_SRC="$SCRIPT_DIR/systemd"
UNIT_DST="$HOME/.config/systemd/user"
if [ -d "$UNIT_SRC" ]; then
    mkdir -p "$UNIT_DST"
    for src in "$UNIT_SRC"/*.{service,path,timer}; do
        [ -f "$src" ] || continue
        name=$(basename "$src")
        dst="$UNIT_DST/$name"
        [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ] && continue
        ln -sf "$src" "$dst"
        echo "${OK} deployed user unit: ${YELLOW}$name${RESET}" | tee -a "$LOG"
    done
    systemctl --user daemon-reload 2>/dev/null || true
    for u in archnexus-watch.service archnexus-display-hotplug.path; do
        [ -f "$UNIT_DST/$u" ] || continue
        systemctl --user enable --now "$u" 2>/dev/null \
            && echo "${OK} $u enabled" | tee -a "$LOG" \
            || echo "${WARN} $u could not be enabled (no user systemd? continuing)" | tee -a "$LOG"
    done
fi
