export XDG_CACHE_HOME=${HOME}/.cache
export XDG_CONFIG_HOME=${HOME}/.config
export XDG_DATA_HOME=${HOME}/.local/share
export XDG_STATE_HOME=${HOME}/.local/state

_source_if_exists() {
  local file=$1
  # shellcheck disable=SC1090
  [[ -s $file ]] && source "$file"
}

# plugins
export ZSH_PLUGIN_DIR=${XDG_DATA_HOME}/zsh/plugins
_source_if_exists "${ZSH_PLUGIN_DIR}/zsh-autosuggestions/zsh-autosuggestions.zsh"
_source_if_exists "${ZSH_PLUGIN_DIR}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# autocompletion
mkdir -p "${XDG_CACHE_HOME}/zsh"
autoload -Uz compinit && compinit -d "${XDG_CACHE_HOME}/zsh/zcompdump"

source "${ZDOTDIR}/options.zsh"
source "${ZDOTDIR}/zle-setup.zsh"

# shellcheck disable=SC2128,SC2206
fpath=("${ZDOTDIR}/functions" $fpath)
autoload -Uz \
  cheat \
  weather \
  weather2 \
  _git-path-from-args \
  clone \
  cloned \
  y

#############
# Functions #
#############

dev_dir=~/dev
workspace_dir=${dev_dir}/_workspaces
self_handle=achmutov

new_dev_dir=~/src
HOSTS_DIR="${new_dev_dir}/hosts"
WT_DIR="${new_dev_dir}/wt"

# fzf bare repos
_dev() {
  local base_directory="$1"
  local info_text="$2"
  fd ".*packed-refs$" -C "$base_directory" --strip-cwd-prefix -t f -HI -x echo '{//}' |
    fzf --ghost="gh repo" --info-command="printf '%s | %s' \"\$FZF_INFO\" \"$info_text\""
}

# cd
devh() {
  local base_directory="$HOSTS_DIR"
  local git_path
  git_path=$(_dev "$base_directory" bare) || return
  [ -n "$git_path" ] && cd -- "${base_directory}/${git_path}" || return
}

devw() {
  local preview_opt=()
  if [ "$1" = "p" ]; then
    preview_opt+=(--preview="[ -d '$WT_DIR'/{} ] && git -C '$WT_DIR'/{} status")
  fi

  local fd_opts=(--strip-cwd-prefix -t f -HI)
  local git_path
  # shellcheck disable=SC2016
  git_path=$(
    {
      fd "${fd_opts[@]}" '^config$' -C "$HOSTS_DIR" -x printf '%s\t%s\n' bare '{//}'
      fd "${fd_opts[@]}" '^\.git$' -C "$WT_DIR" -x printf '%s\t%s\n' worktree '{//}'
    } |
      awk -F '\t' '
        { type[$2] = $1 }
        END {
          for (path in type) {
            if (type[path] == "bare")
              printf "\033[2m%s\033[22m\n", path
            else
              print path
          }
        }
      ' |
      fzf \
        --ansi \
        --info-command='printf "%s | worktrees" "$FZF_INFO"' \
        --ghost="gh repo" \
        --cycle \
        --preview '[ -d '$WT_DIR'/{} ] && "$CARGO_HOME/bin/eza" -al -F=auto --color=always '$WT_DIR'/{} ' \
        --bind 'ctrl-s:preview([ -d '$WT_DIR'/{} ] && git -C '$WT_DIR'/{} status)' \
        --delimiter=$'\t' \
        --nth=1 \
        --accept-nth=1 | xargs
  ) || return
  [ -z "$git_path" ] && return 1

  if [ -d "${WT_DIR}/${git_path}" ]; then
    cd -- "${WT_DIR}/${git_path}" || return
  elif [ -n "$git_path" ]; then
    local bare_repo_dir="${HOSTS_DIR}/${git_path}"
    git -C "$bare_repo_dir" worktree add "${WT_DIR}/${git_path}" "$(git -C "$bare_repo_dir" symbolic-ref --short HEAD)" || return
    cd -- "${WT_DIR}/${git_path}" || return
  fi
}

# browse
devb() {
  local base_directory="$HOSTS_DIR"

  local item="$1"
  case "$item" in
  i) item=issues ;;
  a) item=actions ;;
  r) item=releases ;;
  p) item=pulls ;;
  t) item=tags ;;
  m) item=milestones ;;
  esac

  local git_path
  git_path=$(_dev "$base_directory" "browse${item:+ $item}") || return

  [ -n "$git_path" ] && [[ ! "$git_path" =~ ^priv ]] && xdg-open "https://${git_path}/${item}"
}

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

source "${ZDOTDIR}/env.zsh"
source "${ZDOTDIR}/integrations.zsh"
source "${ZDOTDIR}/aliases.zsh"

unset -f _source_if_exists
