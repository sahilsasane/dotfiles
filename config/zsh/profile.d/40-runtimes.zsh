export NVM_DIR="$HOME/.nvm"

if [[ -n "${NVM_BIN:-}" ]]; then
  # Reload the functions without reselecting an already active Node version.
  source "$BREW_PREFIX/opt/nvm/nvm.sh" --no-use
else
  source "$BREW_PREFIX/opt/nvm/nvm.sh"
fi
source "$BREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"

if [[ -f "$HOME/.local/bin/env" ]]; then
  . "$HOME/.local/bin/env"
fi
