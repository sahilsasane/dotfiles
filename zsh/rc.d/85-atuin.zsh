if command -v atuin >/dev/null 2>&1; then
  export ATUIN_SEARCH_MODE="${ATUIN_SEARCH_MODE:-fuzzy}"
  export ATUIN_STYLE="${ATUIN_STYLE:-compact}"
  __dotfiles_inside_current_tmux_pane() {
    [[ -n "${TMUX-}" && -n "${TMUX_PANE-}" ]] || return 1
    command -v tmux >/dev/null 2>&1 || return 1

    local current_tty pane_tty
    current_tty="$(tty 2>/dev/null)" || return 1
    pane_tty="$(tmux display-message -p -t "$TMUX_PANE" '#{pane_tty}' 2>/dev/null)" || return 1
    [[ "$current_tty" == "$pane_tty" ]]
  }

  if [[ -n "${TMUX-}" ]] && ! __dotfiles_inside_current_tmux_pane; then
    export ATUIN_TMUX_POPUP=false
  else
    unset ATUIN_TMUX_POPUP
  fi
  unfunction __dotfiles_inside_current_tmux_pane

  eval "$(atuin init zsh)"
  # Atuin 18 binds `?` to its AI widget; restore normal question mark input.
  bindkey '?' self-insert
fi
