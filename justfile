stow:
    stow -t ~      \
        alacritty  \
        awesome    \
        nvim       \
        perfconfig \
        picom      \
        scripts    \
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
rust:
    cargo install --locked ripgrep --features pcre2
    cargo install --locked \
        alacritty          \
        cargo-expand       \
        du-dust            \
        emmylua_ls         \
        fd-find            \
        fnm                \
        just               \
        just-lsp           \
        neocmakelsp        \
        prek               \
        ruff               \
        selene             \
        stylua             \
        taplo              \
        trippy             \
        typos-lsp          \
        uv                 \
        yazi-build
    # sudo setcap CAP_NET_RAW+p $(which trip)

_rust PACKAGE:
    cargo install --locked {{ PACKAGE }}

go:
    #!/usr/bin/env sh
    go install github.com/boyter/scc/v3@latest
    go install github.com/karol-broda/snitch@latest
    go install golang.org/x/tools/gopls@latest
    command -v ttyd 2>&1 >/dev/null && go install github.com/charmbracelet/vhs@latest

node:
    npm i -g \
        pnpm \
        serve

lua:
    luarocks install --local \
        luacheck

py:
    uv tool install debugpy
    uv tool install ty
