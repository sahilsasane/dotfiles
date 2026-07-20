theme() {
  if (( $# > 1 )) || [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
    print -u2 'usage: theme {light|dark|auto|toggle|status}'
    return $(( $# > 1 ? 2 : 0 ))
  fi

  local controller
  controller="$(command -v dotfiles-theme 2>/dev/null)"
  [[ -n "$controller" ]] || controller="${DOTFILES_ZSH_DIR}/../bin/dotfiles-theme"
  [[ -x "$controller" ]] || {
    print -u2 "theme: controller not executable: $controller"
    return 127
  }

  "$controller" "${1:-status}" || return $?
  [[ "${1:-status}" == status ]] && return 0

  __dotfiles_theme_apply_shell
  source "${DOTFILES_ZSH_DIR}/rc.d/58-fzf.zsh"
  source "${DOTFILES_ZSH_DIR}/rc.d/90-oh-my-posh.zsh"
}
