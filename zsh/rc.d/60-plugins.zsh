export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
DISABLE_AUTO_UPDATE=true
ZSH_DISABLE_COMPFIX=true

if [[ -o interactive ]] && (( ${+widgets} )) && (( $+functions[_omp_create_widget] || $+functions[enable_poshtooltips] )); then
  # If Oh My Posh was previously loaded in this shell, restore the original
  # ZLE widgets so disabling it does not leave stale wrappers behind.
  typeset _dotfiles_omp_widget _dotfiles_omp_backup
  for _dotfiles_omp_widget in ${(k)widgets}; do
    [[ $_dotfiles_omp_widget == ._omp_original::* ]] && continue
    case ${widgets[$_dotfiles_omp_widget]:-} in
      user:_omp_*)
        _dotfiles_omp_backup="._omp_original::${_dotfiles_omp_widget}"
        if [[ -n ${widgets[$_dotfiles_omp_backup]:-} ]]; then
          zle -A "$_dotfiles_omp_backup" "$_dotfiles_omp_widget"
        else
          zle -D "$_dotfiles_omp_widget" 2>/dev/null
        fi
        ;;
    esac
  done

  for _dotfiles_omp_backup in ${(k)widgets}; do
    [[ $_dotfiles_omp_backup == ._omp_original::* ]] && zle -D "$_dotfiles_omp_backup" 2>/dev/null
  done

  unfunction \
    _omp_accept-line \
    _omp_zle-line-init \
    _omp_render_tooltip \
    _omp_restore_rprompt \
    _omp_call_widget \
    _omp_create_widget \
    enable_poshtooltips \
    enable_poshtransientprompt \
    2>/dev/null
  unset _dotfiles_omp_widget _dotfiles_omp_backup
fi

# Let Ghostty and iTerm own tab/window titles so OMZ doesn't force
# long user@host:path labels over the top of them.
if [[ -n "${GHOSTTY_RESOURCES_DIR:-}" || "${TERM_PROGRAM:-}" == "ghostty" || "${TERM_PROGRAM:-}" == "iTerm.app" ]]; then
  DISABLE_AUTO_TITLE=true
fi

plugins=(git colored-man-pages)

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

if command -v brew >/dev/null 2>&1; then
  typeset -g BREW_PREFIX="${BREW_PREFIX:-$(brew --prefix 2>/dev/null)}"
fi

if [[ -n "${BREW_PREFIX:-}" && -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [[ -n "${ZSH_CUSTOM:-}" && -f "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [[ -n "${BREW_PREFIX:-}" && -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [[ -n "${ZSH_CUSTOM:-}" && -f "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
