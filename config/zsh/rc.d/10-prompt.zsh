__dotfiles_theme_apply_shell() {
  local state="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles-theme/effective"
  local theme_dir="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles-theme"
  local effective=dark
  [[ -r "$state" && "$(<"$state")" == light ]] && effective=light
  typeset -g ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
  [[ "$effective" == light ]] && ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#9ca0b0'
  export TLRC_CONFIG="${theme_dir}/tlrc.toml"
  typeset -g DOTFILES_FZF_THEME_OPTS="$(<"${DOTFILES_ZSH_DIR}/fzf/${effective}.opts")"

  if [[ "$effective" == light ]]; then
    typeset -g OMP_CONFIG="${DOTFILES_ZSH_DIR}/oh-my-posh/theme-latte.omp.yaml"
    export EZA_CONFIG_DIR="${DOTFILES_ZSH_DIR}/../eza/themes/latte"
    export BAT_THEME="Catppuccin Latte"
    export LS_COLORS="$(vivid generate catppuccin-latte 2>/dev/null)"
    export RIPGREP_CONFIG_PATH="${RIPGREP_CONFIG_PATH:-${DOTFILES_ZSH_DIR}/../ripgrep/ripgrep.conf}"
    typeset -gA ZSH_HIGHLIGHT_STYLES=(
      command 'fg=#1e66f5,bold'
      builtin 'fg=#8839ef,bold'
      alias 'fg=#8839ef,bold'
      arg0 'fg=#1e66f5,bold'
      path 'fg=#179299'
      unknown-token 'fg=#d20f39'
    )
  else
    typeset -g OMP_CONFIG="${DOTFILES_ZSH_DIR}/oh-my-posh/theme.omp.yaml"
    export EZA_CONFIG_DIR="${DOTFILES_ZSH_DIR}/../eza"
    export BAT_THEME="Catppuccin Mocha"
    export LS_COLORS="$(vivid generate catppuccin-mocha 2>/dev/null)"
    export RIPGREP_CONFIG_PATH="${RIPGREP_CONFIG_PATH:-${DOTFILES_ZSH_DIR}/../ripgrep/ripgrep.conf}"
    typeset -gA ZSH_HIGHLIGHT_STYLES=(
      command 'fg=#89b4fa,bold'
      builtin 'fg=#cba6f7,bold'
      alias 'fg=#cba6f7,bold'
      arg0 'fg=#89b4fa,bold'
      path 'fg=#94e2d5'
      unknown-token 'fg=#f38ba8'
    )
  fi

  # Older installs still symlink LazyGit's entire config directory into this
  # repo. Point the process at the selected runtime config until install.sh
  # performs its safe directory migration.
  export LG_CONFIG_FILE="${theme_dir}/lazygit.yml"
}

__dotfiles_theme_apply_shell
