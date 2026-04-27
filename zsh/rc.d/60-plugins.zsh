export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
DISABLE_AUTO_UPDATE=true
ZSH_DISABLE_COMPFIX=true

# Let Ghostty and iTerm own tab/window titles so OMZ doesn't force
# long user@host:path labels over the top of them.
if [[ -n "${GHOSTTY_RESOURCES_DIR:-}" || "${TERM_PROGRAM:-}" == "ghostty" || "${TERM_PROGRAM:-}" == "iTerm.app" ]]; then
  DISABLE_AUTO_TITLE=true
fi

plugins=(git colored-man-pages)

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

if command -v brew >/dev/null 2>&1; then
  typeset -g BREW_PREFIX="${BREW_PREFIX:-$(brew --prefix 2>/dev/null)}"
fi

if [[ -n "${BREW_PREFIX:-}" && -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [[ -n "${ZSH_CUSTOM:-}" && -f "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [[ -n "${BREW_PREFIX:-}" && -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [[ -n "${ZSH_CUSTOM:-}" && -f "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
