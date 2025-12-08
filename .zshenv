export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

[ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ] \
                                  && . "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
[ -f "$HOME/.zsh_aliases" ]       && . "$HOME/.zsh_aliases"

# general
[ -d "$HOME/bin" ]                && PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ]         && PATH="$HOME/.local/bin:$PATH"

# python
export NTLK_DATA="$HOME/.local/state/ntlk_data"

# rust
export RUSTUP_TOOLCHAIN=stable
[ -d "$HOME/.cargo/bin" ]         && PATH="$HOME/.cargo/bin:$PATH"
[ -f "$HOME/.cargo/env" ]         && . "$HOME/.cargo/env"

# go
export GOPATH="$HOME/.go"
[ -d "$HOME/go/bin" ]             && PATH="$GOPATH/bin:$PATH"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ]          && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
