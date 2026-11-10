if [[ "${TERM_PROGRAM:-}" == rex ]]; then
  __dotfiles_rex_cursor_beam() {
    print -rn -- $'\e[6 q'
  }

  # Avoid wrapping Oh My Posh's wrapper again when this file is re-sourced.
  if (( ! ${+widgets[__dotfiles_rex_cursor_beam]} )); then
    autoload -Uz add-zle-hook-widget
    add-zle-hook-widget line-init __dotfiles_rex_cursor_beam
  fi

  __dotfiles_ignore_shift_enter() { :; }
  zle -N __dotfiles_ignore_shift_enter

  for _dotfiles_keymap in emacs viins vicmd; do
    bindkey -M "$_dotfiles_keymap" $'\e[27;2;13~' __dotfiles_ignore_shift_enter
  done
  unset _dotfiles_keymap
fi
