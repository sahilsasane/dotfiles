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

# vulcan() {
#   __dotfiles_require_cmd docker || return 1
#   docker run --network=vulcan -p 8000:8000 --rm -v .:/workspace tmdcio/vulcan-snowflake:0.228.1.23 vulcan "$@"
# }

ter3001() {
  __dotfiles_require_cmd text-embeddings-router || return 1
  text-embeddings-router --model-id "$TER_MODEL_ID" --port 3001 "$@"
}

ds() {
  local dataos_ctl="$HOME/.dataos/v2/bin/dataos-ctl"
  [[ -x "$dataos_ctl" ]] || { echo "dataos-ctl is not installed."; return 1; }
  "$dataos_ctl" "$@"
}

dsg()  { ds rs get -t "$1" -n "$2" "${@:3}"; }
dsrt() { ds rs get runtime -t "$1" -n "$2" "${@:3}"; }
dslg() { ds rs log -t "$1" -n "$2" "${@:3}"; }

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

 
tmx() {
  PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  PROJECT=$(basename "$PROJECT_DIR")
  
  tmux new-session -d -s "$PROJECT" -n code -c "$PROJECT_DIR"
  tmux attach-session -t "$PROJECT"
}
