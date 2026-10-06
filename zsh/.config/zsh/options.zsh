# parameters
HISTFILE=${XDG_STATE_HOME}/zsh/history
mkdir -p "${HISTFILE:h}"
HISTSIZE=20000
SAVEHIST=10000
FPATH=:${FPATH}
fpath=("${XDG_DATA_HOME}/zsh/site-functions/" $fpath)

# options
setopt AUTO_CD
setopt NO_AUTO_MENU # no cycling
setopt COMPLETE_IN_WORD
setopt NO_LIST_AMBIGUOUS # show list even on unambiguous prefix completion
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt NO_BEEP
setopt EMACS
