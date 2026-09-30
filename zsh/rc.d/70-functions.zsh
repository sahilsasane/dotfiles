unalias l la ll lsa tre 2>/dev/null

alias ls='eza --icons --group-directories-first --color=always'
alias l='eza -la --git --icons --group-directories-first --color=always'
alias la='eza -a --git --icons --group-directories-first --color=always'
alias ll='eza -lh --git --icons --group-directories-first --color=always'
alias tre='eza --tree --git --icons --color=always'
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

procs() {
  local arg config="${DOTFILES_ZSH_DIR}/../procs/config.toml"
  for arg in "$@"; do
    [[ "$arg" == --load-config || "$arg" == --load-config=* ]] && {
      command procs "$@"
      return
    }
  done

  command procs --load-config "$config" "$@"
}


tlb() {
  command tldr --raw "$@" |
    bat --style=plain --language=markdown --color=always --paging=always
}
rc() {
  uv run ruff check "$@"
}

rcf() {
  uv run ruff check --fix "$@"
}

rf() {
  uv run ruff format "$@"
}

imcp() {
  npx @modelcontextprotocol/inspector "$@"
}


ter3001() {
  text-embeddings-router --model-id "$TER_MODEL_ID" --port 3001 "$@"
}

ds() { command dataos-ctl "$@"; }

dg()  { ds rs get -t "$1" -n "$2" "${@:3}"; }

dsfl() {
  [[ -n $1 ]] || { print -u2 'usage: dsfl <service-name>'; return 2; }

  local runtime group
  runtime=$(ds rs ls -t service -n "$1" runtime) || return
  group=$(print -r -- "$runtime" |
    awk -F'|' '$1 ~ /^[[:space:]]*service/ { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1); print $1; exit }')
  [[ -n $group ]] || { print -u2 "No service container group found for $1."; return 1; }

  ds rs -t service -n "$1" --container-group "$group" logs
}

v() {
  source "${1:-.venv}/bin/activate"
}

y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

ter() {
  local port="${1:-3001}"
  text-embeddings-router --model-id "$TER_MODEL_ID" --port "$port"
}

terp() {
  local port="3001"
  if [[ "$1" == "--port" && -n "$2" ]]; then
    port="$2"
    shift 2
  elif [[ -n "$1" && "$1" == <-> ]]; then
    port="$1"
    shift
  fi

  local prom_port=9000
  while lsof -i ":$prom_port" >/dev/null 2>&1; do
    ((prom_port++))
    if [[ $prom_port -gt 9100 ]]; then
      echo "Error: Could not find available prometheus port between 9000-9100"
      return 1
    fi
  done

  if [[ $prom_port -ne 9000 ]]; then
    echo "Note: Using prometheus port $prom_port (9000 was occupied)"
  fi

  text-embeddings-router --model-id "$TER_MODEL_ID" --port "$port" --prometheus-port "$prom_port" "$@"
}
