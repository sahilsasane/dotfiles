export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
DISABLE_AUTO_UPDATE=true
ZSH_DISABLE_COMPFIX=true

# Let Ghostty and iTerm own tab/window titles so OMZ doesn't force
# long user@host:path labels over the top of them.
if [[ -n "${GHOSTTY_RESOURCES_DIR:-}" || "${TERM_PROGRAM:-}" == "ghostty" || "${TERM_PROGRAM:-}" == "iTerm.app" ]]; then
  DISABLE_AUTO_TITLE=true
fi

plugins=(git)

source "$ZSH/oh-my-zsh.sh"
# OMZ lib/key-bindings.zsh runs `bindkey -e`; restore vi mode from 20-shell.zsh
bindkey -v

source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

if (( ${+widgets[autosuggest-accept]} )); then
  bindkey -M emacs '^Y' autosuggest-accept
  bindkey -M viins '^Y' autosuggest-accept
fi

if (( ${+widgets[autosuggest-clear]} )); then
  bindkey -M emacs '^]' autosuggest-clear
  bindkey -M viins '^]' autosuggest-clear
fi

source <("$HOME/.dataos/v2/bin/dataos-ctl" completion zsh)
compdef _dataos-ctl ds

eval "$(zoxide init zsh)"

unsetopt SHARE_HISTORY
setopt INC_APPEND_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE
