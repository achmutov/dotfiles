alias nv="nvim"
alias j="just"
alias grep="grep --color=auto"
if command -v eza >/dev/null; then
  alias ls="eza"
  alias l="eza -al -F=auto"
else
  alias ls="ls --color=auto"
  alias l="ls -alF"
fi
alias fastfetch="fastfetch -c examples/25.jsonc --structure-disabled colors --pipe"
alias zso='source "${ZDOTDIR:-$HOME}/.zshrc"'
