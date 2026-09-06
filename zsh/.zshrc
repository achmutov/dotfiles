# ~/.zshrc

export EDITOR=nvim
export BROWSER=helium-desktop

###########
#   Zsh   #
###########

# parameters
HISTFILE=~/.zsh_history
HISTSIZE=20000
# shellcheck disable=SC2034
SAVEHIST=10000
FPATH="${HOME}/.zfunc:${FPATH}"

# options
setopt AUTO_CD
setopt NO_AUTO_MENU # no cycling
setopt COMPLETE_IN_WORD
setopt NO_LIST_AMBIGUOUS # show list even on unambiguous prefix completion
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt NO_BEEP
setopt EMACS

# zle
autoload -Uz compinit && compinit

autoload edit-command-line &&
  zle -N edit-command-line &&
  bindkey "^X^e" edit-command-line

cmp-to-clip() { xclip -sel c <<<"$BUFFER"; } &&
  zle -N cmp-to-clip &&
  bindkey "^Y" cmp-to-clip

bindkey "^U" backward-kill-line

#############
# Functions #
#############

cheat() { curl "cheat.sh/$1"; }
weather() { curl "wttr.in/$1"; }
weather2() { curl "v2.wttr.in/$1"; }

dev_dir=~/dev
workspace_dir="${dev_dir}/_workspaces"
self_handle=achmutov

wk() {
  local base_directory="$workspace_dir"
  local dir
  dir=$(fd --base-directory "$base_directory" -d 1 -H | fzf)
  [ "$dir" = "" ] || cd -- "${base_directory}/${dir}" || return
}
dwk() { cd -- "$workspace_dir" || return; }

dev() {
  local base_directory="$dev_dir"
  local dir
  dir=$(
    fd --base-directory "$base_directory" "(\.git)$" -d 3 -HI -t d |
      awk '!/^_workspaces/ { sub(/\/\.git\/$/, "", $0); print }' |
      fzf
  )
  [ "$dir" = "" ] || cd -- "${base_directory}/${dir}" || return
}
ddev() { cd -- "$dev_dir" || return; }

deva() {
  local base_directory="${dev_dir}/${self_handle}"
  local dir
  dir=$(fd --base-directory "$base_directory" -d 1 -HI -t d | fzf)
  [ "$dir" = "" ] || cd -- "${base_directory}/${dir}" || return
}
ddeva() { cd -- "${dev_dir}/${self_handle}" || return; }

y() {
  local tmp cwd
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d "" cwd <"$tmp"
  [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || return
  command rm -f -- "$tmp"
}

###########
#  Other  #
###########

_add_to_path() {
  local dir="$1"
  [ -d "$dir" ] && [[ ":$PATH:" != *":$dir:"* ]] && PATH="${dir}:${PATH}"
}

_source_if_exists() {
  local file="$1"
  [ -s "$file" ] && source "$file"
}

# zsh
_source_if_exists ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
_source_if_exists ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# general
_add_to_path ~/bin
_add_to_path ~/.local/bin

# python
export NTLK_DATA=~/.local/state/ntlk_data

# lua
_add_to_path ~/.luarocks/bin

# rust
_add_to_path ~/.cargo/bin
_source_if_exists ~/.cargo/env

# go
export GOPATH=~/.go
_add_to_path "${GOPATH}/bin"
_add_to_path "/usr/local/go/bin"

# js
export PNPM_HOME=~/.local/share/pnpm
_add_to_path "${PNPM_HOME}/bin"

# zephyr
export ZEPHYR_SDK_INSTALL_DIR=~/.local/state/zephyr

unset -f _add_to_path _source_if_exists

###########
# Plugins #
###########

_c_exists() {
  command -v "$1" >/dev/null
}

_c_exists starship &&
  eval "$(starship init zsh)"

_c_exists fzf &&
  source <(fzf --zsh)

_c_exists direnv &&
  eval "$(direnv hook zsh)"

_c_exists fnm &&
  eval "$(fnm env --use-on-cd --shell zsh)"

_c_exists nvim &&
  export MANPAGER="nvim +Man!"

# Aliases
alias nv="nvim"
alias j="just"
alias grep="grep --color=auto"
if _c_exists eza; then
  alias ls="eza"
  alias l="eza -al -F=auto"
else
  alias ls="ls --color=auto"
  alias l="ls -alF"
fi
alias fastfetch="fastfetch -c examples/25.jsonc --structure-disabled colors --pipe"

unset -f _c_exists
