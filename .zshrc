# ~/.zshrc

case $- in
    *i*) ;;
      *) return;;
esac


###########
#   Zsh   #
###########

HISTCONTROL=ignoredups
HISTFILE=~/.zsh_history
setopt appendhistory
setopt share_history
HISTSIZE=1000
SAVEHIST=2000

zstyle ':completion:::*:default' menu no select

autoload -Uz compinit
compinit


###########
# Plugins #
###########

# FZF
if command -v fzf 2>&1 >/dev/null; then
    export FZF_CTRL_R_OPTS="
      --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
      --color header:italic
      --header 'Press CTRL-Y to copy command into clipboard'"
    source <(fzf --zsh)
fi

# starship
eval "$(starship init zsh)"


#############
# Functions #
#############

cheat() { curl cheat.sh/$1 }
weather() { curl wttr.in/$1 }
weather2() { curl v2.wttr.in/$1 }

cdz() {
    TEMP_DIR=$(find "${1:-$HOME}" -type d | fzf)
    [ "$TEMP_DIR" = "" ] || cd $TEMP_DIR
}
nvimz() {
    TEMP_DIR=$(find "." -type f | fzf)
    [ "$TEMP_DIR" = "" ] || nvim $TEMP_DIR
}

y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}


###########
#  Other  #
###########

WINIT_X11_SCALE_FACTOR=1
set -o emacs

[ -f /etc/gentoo-release ] && [ -n "${TMUX}" ] && source $HOME/.zshenv
