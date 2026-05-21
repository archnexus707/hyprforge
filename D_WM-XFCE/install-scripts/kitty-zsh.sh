#!/usr/bin/env bash
# kitty-zsh.sh — terminal + shell stack: kitty, zsh, oh-my-zsh, powerlevel10k,
# pokemon-colorscripts, fastfetch, eza, bat, btop.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/safety.sh
. "$SCRIPT_DIR/lib/safety.sh"

term_pkgs=(
    kitty
    zsh
    fastfetch
    eza
    bat
    btop
    starship
)

printf "\n%s ===== kitty + zsh stack =====%s\n" "$YELLOW" "$RESET"

apt_install_safe "${term_pkgs[@]}" || die "terminal/shell apt packages failed (see $DWM_LOG)"

# ----- oh-my-zsh (non-interactive) -------------------------------------------
OMZ_DIR="$HOME/.oh-my-zsh"
if [ -d "$OMZ_DIR/.git" ]; then
    log "oh-my-zsh already installed at $OMZ_DIR"
else
    if [ "$DWM_DRY_RUN" = "1" ]; then
        printf "%s would install oh-my-zsh into %s\n" "$DRY" "$OMZ_DIR"
    else
        log "installing oh-my-zsh (with retry on network failure)"
        # Download the installer first so we can retry on network blips, then
        # invoke it with sh. RUNZSH=no CHSH=no prevents launching zsh or chsh'ing.
        _omz_installer=$(mktemp)
        if safe_curl_download \
            "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" \
            "$_omz_installer" >>"$DWM_LOG" 2>&1 && \
           RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$_omz_installer" >>"$DWM_LOG" 2>&1; then
            register_undo "rm -rf \"$OMZ_DIR\""
            log "oh-my-zsh installed"
        else
            printf "%s oh-my-zsh install failed after retries (offline?). Skipping.\n" "$WARN"
        fi
        rm -f "$_omz_installer"
    fi
fi

# ----- powerlevel10k theme ---------------------------------------------------
P10K_DIR="${ZSH_CUSTOM:-$OMZ_DIR/custom}/themes/powerlevel10k"
if [ -d "$P10K_DIR/.git" ]; then
    log "powerlevel10k already installed"
else
    if [ "$DWM_DRY_RUN" = "1" ]; then
        printf "%s would clone powerlevel10k into %s\n" "$DRY" "$P10K_DIR"
    elif [ -d "$OMZ_DIR" ]; then
        log "cloning powerlevel10k (with retry on network failure)"
        if safe_git_clone https://github.com/romkatv/powerlevel10k.git "$P10K_DIR" \
            >>"$DWM_LOG" 2>&1; then
            register_undo "rm -rf \"$P10K_DIR\""
        else
            printf "%s powerlevel10k clone failed after retries.\n" "$WARN"
        fi
    fi
fi

# ----- zsh plugins (autosuggestions + syntax-highlighting) -------------------
for plug in zsh-autosuggestions zsh-syntax-highlighting; do
    case "$plug" in
        zsh-autosuggestions)    repo=https://github.com/zsh-users/zsh-autosuggestions    ;;
        zsh-syntax-highlighting) repo=https://github.com/zsh-users/zsh-syntax-highlighting ;;
    esac
    dest="${ZSH_CUSTOM:-$OMZ_DIR/custom}/plugins/$plug"
    if [ -d "$dest/.git" ]; then
        log "$plug already installed"
        continue
    fi
    if [ "$DWM_DRY_RUN" = "1" ]; then
        printf "%s would clone %s into %s\n" "$DRY" "$plug" "$dest"
        continue
    fi
    [ -d "$OMZ_DIR" ] || continue
    if safe_git_clone "$repo" "$dest" >>"$DWM_LOG" 2>&1; then
        register_undo "rm -rf \"$dest\""
        log "installed plugin $plug"
    else
        printf "%s plugin clone failed after retries: %s\n" "$WARN" "$plug"
    fi
done

# ----- pokemon-colorscripts --------------------------------------------------
PKMN_DIR="$HOME/.cache/dwm-xfce/pokemon-colorscripts"
if command -v pokemon-colorscripts >/dev/null 2>&1; then
    log "pokemon-colorscripts already installed"
else
    if [ "$DWM_DRY_RUN" = "1" ]; then
        printf "%s would clone + install pokemon-colorscripts\n" "$DRY"
    else
        mkdir -p "$(dirname "$PKMN_DIR")"
        if safe_git_clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git \
            "$PKMN_DIR" >>"$DWM_LOG" 2>&1; then
            log "installing pokemon-colorscripts (uses sudo)"
            if (cd "$PKMN_DIR" && sudo ./install.sh) >>"$DWM_LOG" 2>&1; then
                register_undo "sudo rm -f /usr/local/bin/pokemon-colorscripts; sudo rm -rf /usr/local/opt/pokemon-colorscripts"
                log "pokemon-colorscripts installed"
            else
                printf "%s pokemon-colorscripts install failed.\n" "$WARN"
            fi
        else
            printf "%s pokemon-colorscripts clone failed (gitlab offline?).\n" "$WARN"
        fi
    fi
fi

# ----- change default shell to zsh (with confirmation) -----------------------
if [ "$SHELL" != "$(command -v zsh)" ] && command -v zsh >/dev/null 2>&1; then
    if confirm "Set zsh as your default login shell? (chsh -s $(command -v zsh) $USER)"; then
        if [ "$DWM_DRY_RUN" = "1" ]; then
            printf "%s would chsh -s %s\n" "$DRY" "$(command -v zsh)"
        else
            previous_shell="$(getent passwd "$USER" | awk -F: '{print $7}')"
            register_undo "chsh -s \"$previous_shell\" \"$USER\""
            chsh -s "$(command -v zsh)" "$USER" >>"$DWM_LOG" 2>&1 || \
                printf "%s chsh failed (you may need to run it manually).\n" "$WARN"
        fi
    else
        log "kept current shell ($SHELL); change later with: chsh -s $(command -v zsh)"
    fi
fi

printf "%s kitty + zsh stack complete.\n" "$OK"
