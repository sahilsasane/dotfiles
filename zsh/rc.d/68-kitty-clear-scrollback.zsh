if [[ -n "${KITTY_PID:-}" ]]; then
  __dotfiles_kitty_clear_scrollback() {
    emulate -L zsh
    builtin print -rn -- $'\r\e[H\e[3J' >"$TTY"
    zle .reset-prompt
    zle -R
  }

  zle -N __dotfiles_kitty_clear_scrollback
  bindkey -M emacs '\ek' __dotfiles_kitty_clear_scrollback
  bindkey -M viins '\ek' __dotfiles_kitty_clear_scrollback
  bindkey -M vicmd '\ek' __dotfiles_kitty_clear_scrollback
fi
