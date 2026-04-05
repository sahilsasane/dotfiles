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

vulcan() {
  __dotfiles_require_cmd docker || return 1
  docker run --network=vulcan --rm -v .:/workspace tmdcio/vulcan-snowflake:0.228.1.10 vulcan "$@"
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

dockrm() {
  __dotfiles_require_cmd docker || return 1

  local id name ans
  local -a lines
  lines=("${(@f)$(docker ps -a --format '{{.ID}}\t{{.Names}}')}")

  for line in "${lines[@]}"; do
    IFS=$'\t' read -r id name <<< "$line"
    printf "Delete container '%s' (%s)? [y/N]: " "$name" "$id"
    read -r ans
    if [[ "$ans" == [yY] ]]; then
      docker rm "$id"
    else
      echo "Skipped $name"
    fi
  done
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

gcai() {
  __dotfiles_require_cmd git || return 1
  __dotfiles_require_cmd jq || return 1
  __dotfiles_require_cmd curl || return 1
  __dotfiles_require_cmd pbcopy || return 1

  git rev-parse --git-dir >/dev/null 2>&1 || { echo "Not a git repository."; return 1; }
  if git diff --staged --quiet; then echo "No staged changes."; return 1; fi
  if [ -z "$OPENAI_API_KEY" ]; then echo "OPENAI_API_KEY is not set."; return 1; fi

  local diff recent prompt payload resp http_status body msg

  diff="$(git diff --staged --patch --minimal | head -c 120000)"
  recent="$(git log -n 20 --pretty=format:%s 2>/dev/null | sed 's/^/- /' | head -c 4000)"

  prompt=$'Write a git commit message for the STAGED diff.\n'\
$'Follow Conventional Commits strictly.\n\n'\
$'Allowed types: feat, fix, refactor, perf, docs, test, chore, build, ci, style, revert\n\n'\
$'Output MUST be EXACTLY ONE LINE in this format:\n'\
$'<type>: subject\n\n'\
$'Hard rules:\n'\
$'- Output ONLY that single line (no blank lines)\n'\
$'- Do NOT include a body, bullets, or any extra text\n'\
$'- Imperative mood\n'\
$'- Subject <= 72 characters\n\n'\
$'Recent commit subjects:\n'\
"${recent:-"- none"}"\
$'\n\nSTAGED DIFF:\n'\
"$diff"

  payload="$(jq -n \
    --arg model "${OPENAI_MODEL:-gpt-5.2-mini}" \
    --arg input "$prompt" \
    '{model:$model, input:$input}')"

  resp="$(curl -sS -w $'\n%{http_code}' https://api.openai.com/v1/responses \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload")"

  http_status="${resp##*$'\n'}"
  body="${resp%$'\n'*}"

  if [[ "$http_status" != "200" ]]; then
    printf '%s' "$body" | jq -r '.error.message // .message // .error // "OpenAI API error."'
    return 1
  fi

  msg="$(printf '%s' "$body" | jq -r '
    [.output[]? | select(.type=="message") | .content[]? | select(.type=="output_text") | .text] | join("")
  ')"

  if [[ -z "$msg" || "$msg" == "null" ]]; then echo "Could not extract commit message."; return 1; fi

  printf '%s' "$msg" | pbcopy
}

gcaa() {
  __dotfiles_require_cmd pbpaste || return 1

  gcai || return 1

  local tmp msg
  tmp="$(mktemp)"
  pbpaste > "$tmp"
  ${EDITOR:-vi} "$tmp" || { rm -f "$tmp"; return 1; }
  msg="$(cat "$tmp")"
  rm -f "$tmp"

  if [ -z "$msg" ]; then
    echo "gca: empty commit message after edit"
    return 1
  fi

  gcmsg "$msg"
}
