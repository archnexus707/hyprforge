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
alias cat='bat --paging=never'
alias top='btop'
alias grep='grep --color=auto'
alias df='df -h'
alias free='free -h'

# ── fastfetch on terminal launch ──────────────────────────────────────────────
if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi

export EDITOR=nano
export VISUAL=nano
