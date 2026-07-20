if [[ ! -o interactive ]]; then
  return
fi

if ! command -v oh-my-posh >/dev/null 2>&1; then
  return
fi

if [[ ! -r "${OMP_CONFIG:-}" ]]; then
  return
fi

if (( ${+widgets} )) && (( $+functions[_omp_create_widget] || $+functions[enable_poshtooltips] )); then
  # Remove any previously initialized OMP widget wrappers before reloading.
  typeset _dotfiles_omp_widget _dotfiles_omp_backup _dotfiles_omp_func

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

  for _dotfiles_omp_widget in ${(k)widgets}; do
    [[ $_dotfiles_omp_widget == ._omp_original::* ]] && zle -D "$_dotfiles_omp_widget" 2>/dev/null
  done

  for _dotfiles_omp_func in ${(k)functions}; do
    [[ $_dotfiles_omp_func == _omp_* ]] && unfunction "$_dotfiles_omp_func" 2>/dev/null
  done

  unset _dotfiles_omp_widget _dotfiles_omp_backup _dotfiles_omp_func
fi

eval "$(oh-my-posh init zsh --config "$OMP_CONFIG")"
