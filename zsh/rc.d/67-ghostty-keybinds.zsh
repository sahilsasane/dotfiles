if [[ -n "${GHOSTTY_RESOURCES_DIR:-}" || "${TERM_PROGRAM:-}" == "ghostty" ]]; then
  # Ignore Ghostty's Cmd-T -> Ctrl-A c sequence at the shell prompt when tmux is
  # not handling it. This keeps Cmd-T from inserting a literal `c` outside tmux.
  __dotfiles_ignore_ghostty_cmd_t() {
    zle redisplay
  }

  zle -N __dotfiles_ignore_ghostty_cmd_t
  bindkey -M emacs $'\x01c' __dotfiles_ignore_ghostty_cmd_t
  bindkey -M viins $'\x01c' __dotfiles_ignore_ghostty_cmd_t
  bindkey -M vicmd $'\x01c' __dotfiles_ignore_ghostty_cmd_t
fi
