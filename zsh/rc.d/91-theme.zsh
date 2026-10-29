theme() {
  if (( $# > 1 )) || [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
    print -u2 'usage: theme {light|dark|auto|toggle|status}'
    return $(( $# > 1 ? 2 : 0 ))
  fi

  command dotfiles-theme "${1:-status}" || return $?
  [[ "${1:-status}" == status ]] && return 0

  __dotfiles_theme_apply_shell
  source "${DOTFILES_ZSH_DIR}/rc.d/58-fzf.zsh"
  bindkey '^R' atuin-search
  source "${DOTFILES_ZSH_DIR}/rc.d/90-oh-my-posh.zsh"
}
