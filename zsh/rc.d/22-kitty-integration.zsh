if [[ -n "${KITTY_PID:-}" || -n "${KITTY_INSTALLATION_DIR:-}" ]]; then
  typeset -g KITTY_INSTALLATION_DIR="${KITTY_INSTALLATION_DIR:-/Applications/kitty.app/Contents/Resources/kitty}"

  if [[ -r "$KITTY_INSTALLATION_DIR/shell-integration/zsh/kitty-integration" ]]; then
    export KITTY_SHELL_INTEGRATION="${KITTY_SHELL_INTEGRATION:-no-title}"
    autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
    kitty-integration
    unfunction kitty-integration
  fi
fi
