_dotfiles_vi_cursor() {
  emulate -L zsh
  [[ -n "${TTY:-}" && -w "$TTY" ]] || return 0

  case ${KEYMAP:-main} in
    vicmd|visual) builtin print -rn -- $'\e[2 q' > "$TTY" ;;
    *) builtin print -rn -- $'\e[6 q' > "$TTY" ;;
  esac
}

_dotfiles_vi_cursor_reset() {
  emulate -L zsh
  [[ -n "${TTY:-}" && -w "$TTY" ]] || return 0
  builtin print -rn -- $'\e[6 q' > "$TTY"
}

autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-init _dotfiles_vi_cursor
add-zle-hook-widget keymap-select _dotfiles_vi_cursor
add-zle-hook-widget line-finish _dotfiles_vi_cursor_reset
