if [[ -n "${GHOSTTY_RESOURCES_DIR:-}" || "${TERM_PROGRAM:-}" == "ghostty" || "${TERM_PROGRAM:-}" == "iTerm.app" ]]; then
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

  typeset -ga precmd_functions chpwd_functions
  precmd_functions=(${precmd_functions:#_dotfiles_terminal_set_title} _dotfiles_terminal_set_title)
  chpwd_functions=(${chpwd_functions:#_dotfiles_terminal_set_title} _dotfiles_terminal_set_title)

  _dotfiles_terminal_set_title
fi
