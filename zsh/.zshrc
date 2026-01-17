# ~/.zshrc

case $- in
    *i*) ;;
      *) return;;
esac
export EDITOR=/usr/bin/nvim

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

FPATH="$HOME/.zfunc:${FPATH}"

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

export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

has_path() {
    local paths="$1"
    local path="$2"
    [[ ":$paths:" == *":$dir:"* ]]
}

add_to_path() {
    local dir="$1"
    [ -d "$dir" ]            \
    && ! has_path $PATH $dir \
    && PATH="$dir:$PATH"
}

add_to_ld_library_path() {
    local dir="$1"
    [ -d "$dir" ]                              \
    && ! has_path $LD_LIBRARY_PATH $dir        \
    && LD_LIBRARY_PATH="$dir:$LD_LIBRARY_PATH"
}

source_if_exists() {
    local file="$1"
    [ -s "$file" ] && source "$file"
}

# zsh
source_if_exists "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
source_if_exists "$HOME/.zsh_aliases"

# general
add_to_path            "$HOME/bin"
add_to_path            "$HOME/.local/bin"
add_to_ld_library_path "$HOME/.local/lib"

# python
export NTLK_DATA="$HOME/.local/state/ntlk_data"

# lua
add_to_path "$HOME/.luarocks/bin"

# rust
export RUSTUP_TOOLCHAIN=stable
add_to_path      "$HOME/.cargo/bin"
source_if_exists "$HOME/.cargo/env"

# go
export GOPATH="$HOME/.go"
add_to_path "$GOPATH/bin"

# nvm
# export NVM_DIR="$HOME/.nvm"
# load_nvm () {
#     unset -f npm node nvm
#     source_if_exists "$NVM_DIR/nvm.sh"
#     source_if_exists "$NVM_DIR/bash_completion"
# }
# nvm () {
#     load_nvm
#     nvm $@
# }
# npm () {
#     load_nvm
#     npm $@
# }
# node () {
#     load_nvm
#     node $@
# }

# fnm
[ -x "$(command -v fnm)" ] && eval "`fnm env`"

# zephyr
export ZEPHYR_SDK_INSTALL_DIR="$HOME/.local"

# nvim
if [ -x "$(command -v nvim)" ]; then
    export MANPAGER='nvim +Man!'
fi
