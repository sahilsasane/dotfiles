if [[ -n "${KITTY_PID:-}" ]]; then
  __dotfiles_kitty_clear_screen() {
    emulate -L zsh
    builtin print -rn -- $'\r\e[0J\e[H\e[22J' >"$TTY"
    zle .reset-prompt
  }

  __dotfiles_kitty_clear_scrollback() {
    emulate -L zsh

    if [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
      tmux clear-history -t "${TMUX_PANE:-}" 2>/dev/null
    fi

    builtin print -rn -- $'\r\e[H\e[2J\e[3J' >"$TTY"
    zle .reset-prompt
  }

  zle -N __dotfiles_kitty_clear_screen
  zle -N __dotfiles_kitty_clear_scrollback
  bindkey -M emacs '^L' __dotfiles_kitty_clear_screen
  bindkey -M viins '^L' __dotfiles_kitty_clear_screen
  bindkey -M vicmd '^L' __dotfiles_kitty_clear_screen
  bindkey -M emacs '\ek' __dotfiles_kitty_clear_scrollback
  bindkey -M viins '\ek' __dotfiles_kitty_clear_scrollback
  bindkey -M vicmd '\ek' __dotfiles_kitty_clear_scrollback
fi
