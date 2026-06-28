# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnosterzak"

plugins=( 
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh


# Pokemon + fastfetch greeter (archnexus707 signature). Random pokemon as the
# fastfetch logo; falls back to compact fastfetch if pokemon-colorscripts is
# not installed. Project: https://gitlab.com/phoneybadger/pokemon-colorscripts
if [[ $- == *i* ]] && command -v fastfetch >/dev/null 2>&1; then
    if command -v pokemon-colorscripts >/dev/null 2>&1; then
        pokemon-colorscripts --no-title -s -r | fastfetch -c $HOME/.config/fastfetch/config-pokemon.jsonc \
            --logo-type file-raw --logo-height 10 --logo-width 5 --logo - 2>/dev/null
    else
        fastfetch -c $HOME/.config/fastfetch/config-compact.jsonc
    fi
fi

# Set-up icons for files/directories in terminal using lsd
if command -v lsd >/dev/null 2>&1; then
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
fi

