__dotfiles_has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

__dotfiles_missing_cmd() {
  echo "$1 is not installed."
  return 1
}

__dotfiles_require_cmd() {
  __dotfiles_has_cmd "$1" || {
    __dotfiles_missing_cmd "$1"
    return 1
  }
}

pwd() {
  local value
  value="$(builtin pwd "$@")" || return $?

  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    print -Pn '%F{cyan}'
    print -rn -- "$value"
    print -P '%f'
  else
    print -r -- "$value"
  fi
}

unalias history 2>/dev/null
__dotfiles_colorize_history() {
  command awk '{
    line = $0
    if (match(line, /^[[:space:]]*[0-9]+[[:space:]]+/)) {
      prefix = substr(line, RSTART, RLENGTH)
      rest = substr(line, RSTART + RLENGTH)
      if (match(rest, /^[^[:space:]]+/)) {
        cmd = substr(rest, RSTART, RLENGTH)
        args = substr(rest, RSTART + RLENGTH)
        printf "\033[33m%s\033[0m\033[36m%s\033[0m%s\n", prefix, cmd, args
      } else {
        printf "\033[33m%s\033[0m\n", line
      }
    } else {
      print line
    }
  }'
}

history() {
  local arg
  local -a statuses

  if [[ -z "${NO_COLOR:-}" ]]; then
    for arg in "$@"; do
      if [[ "$arg" == -c ]]; then
        omz_history "$@"
        return
      fi
    done

    omz_history "$@" | __dotfiles_colorize_history
    statuses=("${pipestatus[@]}")
    (( statuses[1] != 0 )) && return "${statuses[1]}"
    return "${statuses[2]}"
  else
    omz_history "$@"
  fi
}

jobs() {
  local -a statuses

  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    builtin jobs "$@" |
      command sed -E \
        -e $'s/(Running)/\033[32m\\1\033[0m/g' \
        -e $'s/(Stopped|Suspended)/\033[33m\\1\033[0m/g' \
        -e $'s/(Done)/\033[36m\\1\033[0m/g' \
        -e $'s/(Terminated|Killed)/\033[31m\\1\033[0m/g'
    statuses=("${pipestatus[@]}")
    (( statuses[1] != 0 )) && return "${statuses[1]}"
    return "${statuses[2]}"
  else
    builtin jobs "$@"
  fi
}

du() {
  local arg
  local -a statuses

  for arg in "$@"; do
    [[ "$arg" == -0 || "$arg" == --null ]] && {
      command du "$@"
      return
    }
  done

  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    command du "$@" |
      command awk '{
        line = $0
        if (match(line, /^[^[:space:]]+/)) {
          size = substr(line, RSTART, RLENGTH)
          rest = substr(line, RSTART + RLENGTH)
          printf "\033[36m%s\033[0m%s\n", size, rest
        } else {
          print line
        }
      }'
    statuses=("${pipestatus[@]}")
    (( statuses[1] != 0 )) && return "${statuses[1]}"
    return "${statuses[2]}"
  else
    command du "$@"
  fi
}

chpwd() {
  pwd
  eza --group-directories-first
}

if command -v procs >/dev/null 2>&1; then
  procs() {
    local arg config="${DOTFILES_ZSH_DIR}/../procs/config.toml"
    for arg in "$@"; do
      [[ "$arg" == --load-config || "$arg" == --load-config=* ]] && {
        command procs "$@"
        return
      }
    done

    if [[ -r "$config" ]]; then
      command procs --load-config "$config" "$@"
    else
      command procs "$@"
    fi
  }
fi


tlb() {
  command tldr --raw "$@" |
    bat --style=plain --language=markdown --color=always --paging=always
}
