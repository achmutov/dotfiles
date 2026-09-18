stow:
    stow -t ~      \
        X11        \
        alacritty  \
        awesome    \
        git        \
        mpv        \
        nvim       \
        perfconfig \
        picom      \
        scripts    \
        starship   \
        stylua     \
        tmux       \
        trippy     \
        yazi       \
        zathura    \
        zsh

install: nvim tmux zsh

clean: tmux-clean zsh-clean

clone-or-pull REPO DIR:
    #!/usr/bin/env sh
    if [ -d "{{ DIR }}" ]; then
        pushd {{ DIR }}
        git pull
        popd
    else
        git clone {{ REPO }} {{ DIR }}
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
    just clone-or-pull "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$HOME/.zsh/zsh-syntax-highlighting"

zsh-clean:
    rm -rf "~/.zsh"

########
# PKGS #
########

export CARGO_TARGET_DIR := x"$HOME/.cache/cargo-install"

rust: rust-core rust-dev-utils rust-dev-pm rust-dev-editor rust-misc-utils

rust-core:
    cargo install --locked ripgrep --features pcre2
    cargo install --locked \
        alacritty          \
        fd-find            \
        just               \
        starship           \
        tree-sitter-cli    \
        yazi-build

rust-dev-utils:
    cargo install --locked \
        cargo-expand       \
        hexyl              \
        hyperfine          \
        prek

rust-dev-pm:
    cargo install --locked \
        fnm                \
        uv

rust-dev-editor:
    cargo install --locked \
        emmylua_ls         \
        just-lsp           \
        neocmakelsp        \
        ruff               \
        selene             \
        stylua             \
        taplo-cli          \
        typos-lsp

rust-misc-utils:
    cargo install --locked \
        cyme               \
        du-dust            \
        emlop              \
        trippy

_rust PACKAGE:
    cargo install --locked {{ PACKAGE }}

rust-js:
    cargo install                                \
        --git https://github.com/oxc-project/oxc \
        --tag apps_v1.81.0                       \
        --locked                                 \
        --features allocator                     \
        oxlint

    cargo install                                \
        --git https://github.com/oxc-project/oxc \
        --tag apps_v1.81.0                       \
        --locked                                 \
        --no-default-features                    \
        --features allocator                     \
        oxfmt

go: go-misc-utils go-dev-editor-tools go-dev-editor

go-misc-utils:
    go install github.com/walles/moor/v2/cmd/moor@latest
    go install github.com/boyter/scc/v4@latest
    go install github.com/karol-broda/snitch@latest
    go install github.com/charmbracelet/vhs@latest # ttyd required

go-dev-editor-tools:
    go install mvdan.cc/sh/v3/cmd/shfmt@latest
    go install github.com/go-delve/delve/cmd/dlv@latest

go-dev-editor:
    go install golang.org/x/tools/gopls@latest
    go install -x -a github.com/microsoft/TypeScript/tsc/cmd/tsc@e95d8e57a89f
    go install github.com/docker/docker-language-server/cmd/docker-language-server@latest

node:
    npm i -g \
        pnpm \
        serve

py:
    uv tool install -U debugpy
    uv tool install -U ty
