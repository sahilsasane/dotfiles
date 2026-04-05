export NVM_DIR="$HOME/.nvm"

if command -v brew >/dev/null 2>&1; then
  typeset -g BREW_PREFIX="${BREW_PREFIX:-$(brew --prefix 2>/dev/null)}"
  [ -s "$BREW_PREFIX/opt/nvm/nvm.sh" ] && . "$BREW_PREFIX/opt/nvm/nvm.sh"
  [ -s "$BREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && . "$BREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"
fi

if [[ -f "$HOME/.local/bin/env" ]]; then
  . "$HOME/.local/bin/env"
fi
