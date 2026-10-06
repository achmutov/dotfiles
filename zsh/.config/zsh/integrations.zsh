if command -v starship >/dev/null; then
  eval "$(starship init zsh)"
fi

# shellcheck disable=SC1090
if command -v fzf >/dev/null; then
  source <(fzf --zsh)
fi

if command -v direnv >/dev/null; then
  eval "$(direnv hook zsh)"
fi

if command -v fnm >/dev/null; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi
