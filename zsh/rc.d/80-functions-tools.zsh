rc() {
  __dotfiles_require_cmd uv || return 1
  uv run ruff check "$@"
}

rcf() {
  __dotfiles_require_cmd uv || return 1
  uv run ruff check --fix "$@"
}

rf() {
  __dotfiles_require_cmd uv || return 1
  uv run ruff format "$@"
}

imcp() {
  __dotfiles_require_cmd npx || return 1
  npx @modelcontextprotocol/inspector "$@"
}


ter3001() {
  __dotfiles_require_cmd text-embeddings-router || return 1
  text-embeddings-router --model-id "$TER_MODEL_ID" --port 3001 "$@"
}

ds() {
  local dataos_ctl="$HOME/.dataos/v2/bin/dataos-ctl"
  [[ -x "$dataos_ctl" ]] || { echo "dataos-ctl is not installed."; return 1; }
  "$dataos_ctl" "$@"
}

dg()  { ds rs get -t "$1" -n "$2" "${@:3}"; }

dsfl() {
  [[ -n $1 ]] || { print -u2 'usage: dsfl <service-name>'; return 2; }

  local runtime group
  runtime=$(ds rs ls -t service -n "$1" runtime) || return
  group=$(print -r -- "$runtime" |
    awk -F'|' '$1 ~ /^[[:space:]]*service/ { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1); print $1; exit }')
  [[ -n $group ]] || { print -u2 "No service container group found for $1."; return 1; }

  ds rs -t service -n "$1" --container-group "$group" logs --follow
}

v() {
  local venv="${1:-.venv}"
  local activate_file="$venv/bin/activate"

  if [[ ! -d "$venv" ]]; then
    echo "Directory does not exist: $venv" >&2
    return 1
  fi

  if [[ ! -f "$activate_file" ]]; then
    echo "Not a valid virtual environment: $venv" >&2
    return 1
  fi

  source "$activate_file"
}

y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

ter() {
  __dotfiles_require_cmd text-embeddings-router || return 1

  local port="${1:-3001}"
  text-embeddings-router --model-id "$TER_MODEL_ID" --port "$port"
}

terp() {
  __dotfiles_require_cmd text-embeddings-router || return 1
  __dotfiles_require_cmd lsof || return 1

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
