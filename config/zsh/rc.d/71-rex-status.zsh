# Rex: when a command that ran 10s or more fails, mark its tab as failed.
# Uses the Program Status Protocol (OSC 7501). Rex shows the error on the tab,
# and sends a macOS notification when Rex is in the background.
[[ "${TERM_PROGRAM:-}" == rex ]] || return 0

zmodload zsh/datetime
autoload -Uz add-zsh-hook

typeset -gi REX_STATUS_MIN_SECONDS=${REX_STATUS_MIN_SECONDS:-10}
# Interactive programs that often exit non-zero when you quit them.
typeset -ga REX_STATUS_IGNORE=(nvim vim vi ssh claude codex less man lazygit yazi htop btop top tmux fzf)

_rex_status_preexec() {
  typeset -g _rex_status_cmd=$1 _rex_status_start=$EPOCHSECONDS
}

_rex_status_precmd() {
  local code=$? cmd=${_rex_status_cmd:-} start=${_rex_status_start:-}
  unset _rex_status_cmd _rex_status_start
  [[ -n $start ]] || return 0
  # 130 is Ctrl-C and 148 is Ctrl-Z: you stopped it, so it did not fail.
  (( code != 0 && code != 130 && code != 148 )) || return 0
  (( EPOCHSECONDS - start >= REX_STATUS_MIN_SECONDS )) || return 0
  local -a words=(${(z)cmd})
  (( ${REX_STATUS_IGNORE[(Ie)${words[1]}]} )) && return 0

  local msg="exit $code: ${cmd[1,80]}"
  printf '\e]7501;state=error:msg=%s\e\\' "$(print -rn -- "$msg" | base64 | tr -d '\n')"
}

add-zsh-hook preexec _rex_status_preexec
# First in line, so $? is still the command's exit code.
precmd_functions=(_rex_status_precmd ${precmd_functions:#_rex_status_precmd})
