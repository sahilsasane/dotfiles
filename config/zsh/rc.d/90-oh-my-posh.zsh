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

set_poshcontext() {
  local tenants line host
  export DATAOS_TENANT='' DATAOS_INSTANCE=''
  (( $+commands[dataos-ctl] )) || return 0
  tenants="$(command dataos-ctl tenant ls 2>/dev/null)" || return 0

  for line in "${(@f)tenants}"; do
    [[ "$line" == \**\(*\) ]] || continue
    export DATAOS_TENANT="${${line##*\(}%\)}"
    host="${${line#* - }%% *}"
    export DATAOS_INSTANCE="${host%%.*}"
    break
  done
}
