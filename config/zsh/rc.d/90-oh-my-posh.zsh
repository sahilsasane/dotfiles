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
  local dataos_dir="$HOME/.dataos/v2"
  local context_name tenancy host tenant
  export DATAOS_TENANT='' DATAOS_INSTANCE='' DATAOS_INSTANCE_URL=''
  (( $+commands[yq] )) || return 0

  context_name="$(command yq -er '.contexts.current_context_name // ""' \
    "$dataos_dir/dataos.context.yaml" 2>/dev/null)" || return 0
  [[ -n "$context_name" ]] || return 0
  tenancy="$(command yq -r '.tenancy | [.dataos_fqdn // "", .dataos_tenant // ""] | @tsv' \
    "$dataos_dir/$context_name/.dataos.tenancy.config.yaml" 2>/dev/null)" || return 0
  IFS=$'\t' read -r host tenant <<< "$tenancy"
  [[ -n "$host" && -n "$tenant" ]] || return 0

  export DATAOS_TENANT="$tenant"
  export DATAOS_INSTANCE="${host%%.*}"
  export DATAOS_INSTANCE_URL="$host"
}
