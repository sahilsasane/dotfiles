if [[ "${TERM_PROGRAM:-}" == rex ]]; then
  __dotfiles_ignore_shift_enter() { :; }
  zle -N __dotfiles_ignore_shift_enter

  for _dotfiles_keymap in emacs viins vicmd; do
    bindkey -M "$_dotfiles_keymap" $'\e[27;2;13~' __dotfiles_ignore_shift_enter
  done
  unset _dotfiles_keymap
fi
