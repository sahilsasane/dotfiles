_dotfiles_terminal_write() {
  emulate -L zsh -o no_aliases
  local sequence="$1"
  if [[ -n "${TMUX:-}" ]]; then
    local escaped=${sequence//$'\e'/$'\e\e'}
    print -rn -- $'\ePtmux;'"$escaped"$'\e\\' > /dev/tty
  else
    print -rn -- "$sequence" > /dev/tty
  fi
}

if [[ -n "${KITTY_PID:-}" || -n "${KITTY_INSTALLATION_DIR:-}" ]]; then
  typeset -g KITTY_INSTALLATION_DIR="${KITTY_INSTALLATION_DIR:-/Applications/kitty.app/Contents/Resources/kitty}"

  export KITTY_SHELL_INTEGRATION="${KITTY_SHELL_INTEGRATION:-no-title}"
  autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
  kitty-integration
  unfunction kitty-integration

  notify-me() {
    emulate -L zsh -o no_aliases
    local title="${1:-Alert}"
    (( $# )) && shift
    local sequence
    sequence="$(command kitten notify --only-print-escape-code "$title" "$@")" || return
    _dotfiles_terminal_write "$sequence"
  }
fi

if [[ -n "${TMUX:-}" ]]; then
  # tmux consumes raw OSC 133 for its own prompt tracking. Send a wrapped copy
  # so kitty and Ghostty can still track command boundaries and notify on finish.
  _dotfiles_tmux_precmd() {
    local cmd_status=$?
    emulate -L zsh -o no_aliases
    _dotfiles_terminal_write $'\e]133;D;'"$cmd_status"$'\a'
    _dotfiles_terminal_write $'\e]133;A\a'
  }

  _dotfiles_tmux_preexec() {
    emulate -L zsh -o no_aliases
    local cmdline=${(q)1}
    _dotfiles_terminal_write $'\e]133;C;cmdline='"$cmdline"$'\a'
  }

  typeset -ga precmd_functions preexec_functions
  precmd_functions=(_dotfiles_tmux_precmd ${precmd_functions:#_dotfiles_tmux_precmd})
  preexec_functions=(_dotfiles_tmux_preexec ${preexec_functions:#_dotfiles_tmux_preexec})
fi
