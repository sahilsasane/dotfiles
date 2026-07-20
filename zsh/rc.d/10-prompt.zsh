__dotfiles_theme_apply_shell() {
  local state="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles-theme/effective"
  local theme_dir="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles-theme"
  local effective=dark
  [[ -r "$state" && "$(<"$state")" == light ]] && effective=light

  if [[ "$effective" == light ]]; then
    typeset -g OMP_CONFIG="${DOTFILES_ZSH_DIR}/oh-my-posh/theme-latte.omp.json"
    export EZA_CONFIG_DIR="${DOTFILES_ZSH_DIR}/../eza/themes/latte"
    export BAT_THEME="Catppuccin Latte"
    export LS_COLORS="$(vivid generate catppuccin-latte 2>/dev/null)"
    typeset -g DOTFILES_FZF_THEME_OPTS='--color=fg:#4c4f69,bg:-1,hl:#1e66f5
      --color=fg+:#4c4f69,bg+:-1,hl+:#df8e1d
      --color=info:#6c6f85,prompt:#1e66f5,pointer:#df8e1d,marker:#40a02b
      --color=border:#9ca0b0,header:#6c6f85,spinner:#1e66f5
      --color=gutter:-1,preview-bg:-1,preview-border:#9ca0b0
      --color=separator:#bcc0cc,scrollbar:#9ca0b0'
    typeset -gA ZSH_HIGHLIGHT_STYLES=(command 'fg=#1e66f5' builtin 'fg=#8839ef' path 'fg=#179299' unknown-token 'fg=#d20f39')
  else
    typeset -g OMP_CONFIG="${DOTFILES_ZSH_DIR}/oh-my-posh/theme.omp.json"
    export EZA_CONFIG_DIR="${DOTFILES_ZSH_DIR}/../eza"
    export BAT_THEME="Catppuccin Mocha"
    export LS_COLORS="$(vivid generate catppuccin-mocha 2>/dev/null)"
    typeset -g DOTFILES_FZF_THEME_OPTS='--color=fg:#d7dae0,bg:-1,hl:#8fb7ff
      --color=fg+:#f5f7ff,bg+:-1,hl+:#ffd580
      --color=info:#8b93a6,prompt:#8fb7ff,pointer:#ffd580,marker:#7bd88f
      --color=border:#6c7086,header:#8b93a6,spinner:#8fb7ff
      --color=gutter:-1,preview-bg:-1,preview-border:#6c7086
      --color=separator:#45475a,scrollbar:#6c7086'
    typeset -gA ZSH_HIGHLIGHT_STYLES=(command 'fg=#89b4fa' builtin 'fg=#cba6f7' path 'fg=#94e2d5' unknown-token 'fg=#f38ba8')
  fi

  # Older installs still symlink LazyGit's entire config directory into this
  # repo. Point the process at the selected runtime config until install.sh
  # performs its safe directory migration.
  export LG_CONFIG_FILE="${theme_dir}/lazygit.yml"
}

__dotfiles_theme_apply_shell
