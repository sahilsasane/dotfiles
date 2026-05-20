if [[ -n "${GHOSTTY_RESOURCES_DIR:-}" || -n "${KITTY_PID:-}" || "${TERM_PROGRAM:-}" == "ghostty" || "${TERM_PROGRAM:-}" == "iTerm.app" ]]; then
  _dotfiles_terminal_set_title() {
    emulate -L zsh

    local title
    if [[ "$PWD" == "$HOME" ]]; then
      title='~'
    else
      title="${PWD:t}"
    fi

    # Set both tab and window titles to the current directory name only.
    print -Pn "\e]1;${title:q}\a"
    print -Pn "\e]2;${title:q}\a"
  }

  _dotfiles_ghostty_reset_mouse_modes() {
    emulate -L zsh

    [[ -n "${GHOSTTY_RESOURCES_DIR:-}" || "${TERM_PROGRAM:-}" == "ghostty" ]] || return 0

    # Some TUIs can leave mouse/alternate-scroll modes enabled, which makes
    # wheel events reach zsh as up/down keys instead of scrolling scrollback.
    print -Pn "\e[?1000l\e[?1002l\e[?1003l\e[?1005l\e[?1006l\e[?1015l\e[?1007l"
  }

  typeset -gi _dotfiles_terminal_hooks_ready=0
  _dotfiles_terminal_precmd() {
    emulate -L zsh

    if (( ! _dotfiles_terminal_hooks_ready )); then
      _dotfiles_terminal_hooks_ready=1
      return 0
    fi

    _dotfiles_terminal_set_title
    _dotfiles_ghostty_reset_mouse_modes
  }

  typeset -ga precmd_functions chpwd_functions
  precmd_functions=(${precmd_functions:#_dotfiles_terminal_set_title})
  precmd_functions=(${precmd_functions:#_dotfiles_ghostty_reset_mouse_modes})
  precmd_functions=(${precmd_functions:#_dotfiles_terminal_precmd} _dotfiles_terminal_precmd)
  chpwd_functions=(${chpwd_functions:#_dotfiles_terminal_set_title} _dotfiles_terminal_set_title)
fi
