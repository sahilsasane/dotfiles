if [[ -x "$HOME/.dataos/v2/bin/dataos-ctl" && $+functions[compdef] -eq 1 ]]; then
  source <("$HOME/.dataos/v2/bin/dataos-ctl" completion zsh)
  compdef _dataos-ctl ds
fi
