# .zshrc — D_WM-XFCE cyberpunk shell

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    sudo
    zsh-autosuggestions
    zsh-syntax-highlighting
    z
    extract
)

[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh" || echo "oh-my-zsh not found — run 03-terminal.sh first" >&2

# ── aliases ───────────────────────────────────────────────────────────────────
alias ls='eza --icons --group-directories-first'
alias ll='eza -lah --icons --group-directories-first'
alias la='eza -a --icons --group-directories-first'
alias tree='eza --tree --icons'
# Debian/Kali ship `bat` as the `batcat` binary; prefer it, fall back gracefully.
if command -v batcat >/dev/null 2>&1; then
  alias cat='batcat --paging=never'
elif command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
fi
alias top='btop'
alias grep='grep --color=auto'
alias df='df -h'
alias free='free -h'

# ── pokemon + fastfetch greeter on terminal launch ────────────────────────────
# Random pokemon as the fastfetch logo (the archnexus707 signature greeter).
# Falls back to plain fastfetch if pokemon-colorscripts isn't installed.
if [[ $- == *i* ]] && command -v fastfetch >/dev/null 2>&1; then
    if command -v pokemon-colorscripts >/dev/null 2>&1; then
        pokemon-colorscripts --no-title -s -r | fastfetch -c "$HOME/.config/fastfetch/config-pokemon.jsonc" \
            --logo-type file-raw --logo-height 10 --logo-width 5 --logo - 2>/dev/null
    else
        fastfetch
    fi
fi

export EDITOR=nano
export VISUAL=nano
