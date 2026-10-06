autoload edit-command-line
zle -N edit-command-line
bindkey "^X^e" edit-command-line

cmp-to-clip() { xclip -sel c <<<"$BUFFER"; }
zle -N cmp-to-clip
bindkey "^Y" cmp-to-clip

bindkey "^U" backward-kill-line

backward-kill-path() { WORDCHARS=${WORDCHARS//\//} zle backward-kill-word; }
zle -N backward-kill-path
bindkey "^[w" backward-kill-path

forward-path() { WORDCHARS=${WORDCHARS//\//} zle .forward-word; }
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=(forward-path)
zle -N forward-path
bindkey "^[e" forward-path

backward-path() { WORDCHARS=${WORDCHARS//\//} zle .backward-word; }
zle -N backward-path
bindkey "^[g" backward-path
