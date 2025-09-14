export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
export NTLK_DATA="$HOME/.local/state/ntlk_data"
export RUSTUP_TOOLCHAIN=stable

[ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
                                . "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
[ -f "$HOME/.zsh_aliases" ] &&  . "$HOME/.zsh_aliases"
[ -f "$HOME/.cargo/env" ] &&    . "$HOME/.cargo/env"
[ -d "$HOME/bin" ] &&           PATH="$HOME/bin:$PATH"
[ -d "$HOME/.cargo/bin" ] &&    PATH="$HOME/.cargo/bin:$PATH"
[ -d "$HOME/go/bin" ] &&        PATH="$HOME/go/bin:$PATH"
