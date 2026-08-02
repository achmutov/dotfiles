# ~/.zshrc

case $- in
    *i*) ;;
      *) return;;
esac
export EDITOR=nvim

###########
#   Zsh   #
###########

HISTCONTROL=ignoredups
HISTFILE=~/.zsh_history
setopt appendhistory
setopt share_history
unsetopt beep
HISTSIZE=1000
SAVEHIST=2000

zstyle ':completion:::*:default' menu no select

FPATH="$HOME/.zfunc:${FPATH}"

autoload -Uz compinit
compinit

set -o emacs
autoload edit-command-line
zle -N edit-command-line
bindkey '^X^e' edit-command-line

cmp-to-clip() { xclip -sel c <<< "$BUFFER" }
zle -N cmp-to-clip
bindkey '^Y' cmp-to-clip

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
eval "$(starship init zsh)"
eval "$(direnv hook zsh)"

#############
# Functions #
#############

cheat() { curl cheat.sh/$1 }
weather() { curl wttr.in/$1 }
weather2() { curl v2.wttr.in/$1 }

wk() {
    BASE_DIRECTORY="$HOME/dev/_workspaces/"
    DIR=$(fd --base-directory "$BASE_DIRECTORY" -d 1 -H | fzf)
    [ "$DIR" = "" ] || cd "$BASE_DIRECTORY/$DIR"
}
dwk() { cd "$HOME/dev/_workspaces"}

dev() {
    BASE_DIRECTORY="$HOME/dev/"
    DIR=$(fd --base-directory "$BASE_DIRECTORY" "(\.git)$" -d 3 -H   \
        | awk '!/^_workspaces/ { sub(/\/\.git\/$/, "", $0); print }' \
        | fzf                                                        \
    )
    [ "$DIR" = "" ] || cd "$BASE_DIRECTORY/$DIR"
}
ddev() { cd "$HOME/dev/" }

deva() {
    BASE_DIRECTORY="$HOME/dev/achmutov/"
    DIR=$(fd --base-directory "$BASE_DIRECTORY" -d 1 -H | fzf)
    [ "$DIR" = "" ] || cd "$BASE_DIRECTORY/$DIR"
}
ddeva() { cd "$HOME/dev/achmutov/" }

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
source_if_exists    "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
source              "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source_if_exists    "$HOME/.zsh_aliases"

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

# js
export PNPM_HOME="$HOME/.local/share/pnpm"
add_to_path $PNPM_HOME

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
[ -x "$(command -v fnm)" ] && eval "$(fnm env --use-on-cd --shell zsh)"

# zephyr
export ZEPHYR_SDK_INSTALL_DIR="$HOME/.local"

# nvim
if [ -x "$(command -v nvim)" ]; then
    export MANPAGER='nvim +Man!'
fi
