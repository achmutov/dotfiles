_add_to_path() {
  local dir="$1"
  [ -d "$dir" ] && [[ ":$PATH:" != *":$dir:"* ]] && PATH="${dir}:${PATH}"
}

_add_to_path ~/.local/bin

export CARGO_HOME=${XDG_DATA_HOME}/cargo
export RUSTUP_HOME=${XDG_DATA_HOME}/rustup
_source_if_exists "${CARGO_HOME}/env"
_add_to_path "${CARGO_HOME}/bin"

export GOPATH=${XDG_DATA_HOME}/go
export GOMODCACHE=${XDG_CACHE_HOME}/go/mod
_add_to_path "${GOPATH}/bin"
_add_to_path "/usr/local/go/bin"

export NPM_CONFIG_USERCONFIG=${XDG_CONFIG_HOME}/npm/npmrc
export YARN_GLOBAL_FOLDER=${XDG_CACHE_HOME}/yarn/berry
export PNPM_HOME=${XDG_DATA_HOME}/pnpm
export NODE_REPL_HISTORY=${XDG_STATE_HOME}/node/history
export BUN_INSTALL=${XDG_DATA_HOME}/bun
export BUN_INSTALL_CACHE_DIR=${XDG_CACHE_HOME}/bun
_add_to_path "${PNPM_HOME}/bin"
_add_to_path "${BUN_INSTALL}/bin"
mkdir -p "${NODE_REPL_HISTORY:h}"

export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker
export APPTAINER_CONFIGDIR=${XDG_CONFIG_HOME}/apptainer
export APPTAINER_CACHEDIR=${XDG_CACHE_HOME}/apptainer

export PYTHON_HISTORY=${XDG_STATE_HOME}/python/history
export IPYTHONDIR=${XDG_DATA_HOME}/ipython
export NTLK_DATA=${XDG_DATA_HOME}/ntlk_data
export RENPY_PATH_TO_SAVES=${XDG_STATE_HOME}/renpy
export RENPY_MULTIPERSISTENT=${RENPY_PATH_TO_SAVES}/multipersistent
mkdir -p "${PYTHON_HISTORY:h}"

export ZEPHYR_SDK_INSTALL_DIR=${XDG_DATA_HOME}/zephyr

export CUDA_CACHE_PATH=${XDG_CACHE_HOME}/nvidia

export PERF_CONFIG=${XDG_CONFIG_HOME}/perf/config

export W3M_DIR=${XDG_STATE_HOME}/w3m
export W3M_CONF_DIR=${XDG_CONFIG_HOME}/w3m

export DOTNET_CLI_HOME=${XDG_DATA_HOME}/dotnet
export NUGET_PACKAGES=${XDG_CACHE_HOME}/nuget/packages

export CODEX_HOME=${XDG_DATA_HOME}/codex

export EIXRC=${XDG_CONFIG_HOME}/eix/eixrc

export SQLITE_HISTORY=${XDG_STATE_HOME}/sqlite_history

export TEXMFHOME=$XDG_DATA_HOME/texmf
export TEXMFVAR=$XDG_CACHE_HOME/texlive/texmf-var
export TEXMFCONFIG=$XDG_CONFIG_HOME/texlive/texmf-config

if command -v nvim >/dev/null; then
  export EDITOR=nvim
  export MANPAGER="nvim +Man!"
fi

if command -v moor >/dev/null; then
  export SYSTEMD_PAGERSECURE=1
  export PAGER="moor --terminal-fg"
fi

if command -v helium-desktop >/dev/null; then
  export BROWSER=helium-desktop
fi

unset -f _add_to_path
