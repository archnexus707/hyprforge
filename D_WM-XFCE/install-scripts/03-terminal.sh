#!/usr/bin/env bash
set -uo pipefail

ok()  { echo -e "\033[38;5;46m[OK]\033[0m $*"; }
log() { echo -e "\033[38;5;226m[..]\033[0m $*"; }
warn(){ echo -e "\033[38;5;196m[WARN]\033[0m $*"; }

log "setting up terminal stack"

# oh-my-zsh
OMZ_DIR="$HOME/.oh-my-zsh"
if [ -d "$OMZ_DIR/.git" ]; then
    log "oh-my-zsh already installed"
else
    log "installing oh-my-zsh"
    omz_log=$(mktemp)
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        </dev/null >"$omz_log" 2>&1 || { warn "oh-my-zsh install failed"; cat "$omz_log"; rm -f "$omz_log"; exit 1; }
    rm -f "$omz_log"
fi

# powerlevel10k
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ -d "$P10K_DIR/.git" ]; then
    log "powerlevel10k already installed"
else
    log "cloning powerlevel10k"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR" \
        >>/dev/null 2>&1 || warn "powerlevel10k clone failed"
fi

# zsh plugins
for plug in zsh-autosuggestions zsh-syntax-highlighting; do
    repo="https://github.com/zsh-users/$plug"
    dest="$OMZ_DIR/custom/plugins/$plug"
    if [ -d "$dest/.git" ]; then
        log "$plug already installed"
        continue
    fi
    git clone --depth=1 "$repo" "$dest" >>/dev/null 2>&1 || warn "$plug clone failed"
done

# make zsh default (ask first, only when TTY available)
if [ "$(basename "$SHELL")" != "zsh" ] && command -v zsh >/dev/null 2>&1; then
    if [ -t 0 ] && [ "${NON_INTERACTIVE:-0}" != "1" ]; then
        printf "Set zsh as default shell? [y/N]: "
        read -r ans
        if [ "$ans" = "y" ] || [ "$ans" = "Y" ] || [ "$ans" = "yes" ]; then
            chsh -s "$(command -v zsh)" "$USER" || warn "chsh failed (try running manually: chsh -s \$(command -v zsh))"
        fi
    else
        log "skipping chsh — non-interactive mode (run: chsh -s \$(command -v zsh))"
    fi
fi

ok "terminal stack complete"
