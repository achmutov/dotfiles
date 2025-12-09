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

# rust
export RUSTUP_TOOLCHAIN=stable
add_to_path      "$HOME/.cargo/bin"
source_if_exists "$HOME/.cargo/env"

# go
export GOPATH="$HOME/.go"
add_to_path "$GOPATH/bin"

# nvm
export NVM_DIR="$HOME/.nvm"
source_if_exists "$NVM_DIR/nvm.sh"
source_if_exists "$NVM_DIR/bash_completion"

# zephyr
export ZEPHYR_SDK_INSTALL_DIR="$HOME/.local"
