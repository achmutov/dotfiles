stow:
    stow -t ~     \
        alacritty \
        awesome   \
        nvim      \
        scripts   \
        tmux      \
        trippy    \
        zathura   \
        zsh

install: nvim tmux zsh

clean: tmux-clean zsh-clean

clone-or-pull REPO DIR:
    #!/usr/bin/env sh
    if [ -d "{{DIR}}" ]; then
        pushd {{DIR}}
        git pull
        popd
    else
        git clone {{REPO}} {{DIR}}
    fi

########
# NVIM #
########

nvim:
    nvim --headless        \
        "+Lazy! restore"   \
        "+MasonUpdate"     \
        "+MasonInstallAll" \
        "+TSInstallAll"    \
        "+TSUpdate"        \
        +qa

########
# TMUX #
########

export TMUX_PLUGINS_HOME := justfile_directory() / "tmux/.config/tmux"

tmux:
    just clone-or-pull "https://github.com/tmux-plugins/tpm" "$TMUX_PLUGINS_HOME/plugins/tpm"
    cd "$TMUX_PLUGINS_HOME" && ./plugins/tpm/scripts/install_plugins.sh

tmux-clean:
    rm -rf "$TMUX_PLUGINS_HOME/plugins"

#######
# ZSH #
#######

zsh:
    just clone-or-pull "https://github.com/zsh-users/zsh-autosuggestions" "$HOME/.zsh/zsh-autosuggestions"

zsh-clean:
    rm -rf "~/.zsh"

########
# PKGS #
########

rust:
    cargo install --locked ripgrep --features pcre2
    cargo install --locked \
        alacritty          \
        cargo-expand       \
        fd-find            \
        just               \
        trippy             \
        uv                 \
        yazi-build
    # sudo setcap CAP_NET_RAW+p $(which trip)

go:
    go install github.com/boyter/scc/v3@latest
    go install github.com/karol-broda/snitch@latest

node:
    npm i -g \
        pnpm \
        serve

lua:
    luarocks install --local \
        luacheck
