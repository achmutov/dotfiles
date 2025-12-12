stow:
    stow -t ~ \
        alacritty \
        awesome \
        nvim \
        tmux \
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
    nvim --headless "+Lazy! sync" +qa

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
    cargo install ripgrep --features pcre2
    cargo install \
        alacritty \
        cargo-expand \
        fd-find \
        just \
        uv \
        yazi-build

go:
    go install \
        github.com/boyter/scc/v3@latest

node:
    npm i -g \
        pnpm \
        serve

lua:
    luarocks install --local \
        luacheck
