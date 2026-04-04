typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git)
source $ZSH/oh-my-zsh.sh

# Terminal
export CLICOLOR=1
export TERM=xterm-256color
export LSCOLORS="ExFxGxdxCxDxBxabagacad"
export CLAUDE_CODE_NO_FLICKER=1

# History
HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
unsetopt SHARE_HISTORY
setopt INC_APPEND_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# uv
. "$HOME/.local/bin/env"

# Secrets
export OPENAI_API_KEY=$(security find-generic-password -a "$USER" -s openai_api_key -w 2>/dev/null)
export OPENAI_MODEL="${OPENAI_MODEL:-gpt-5-nano-2025-08-07}"
export TER_MODEL_ID="BAAI/bge-small-en-v1.5"

# Local-only secrets and machine-specific overrides.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Aliases
alias v='source .venv/bin/activate'
alias vd='deactivate 2>/dev/null || true'
alias rc='uv run ruff check'
alias rcf='uv run ruff check --fix'
alias rf='uv run ruff format'
alias stapp='streamlit run'
alias imcp='npx @modelcontextprotocol/inspector'
alias vulcan="docker run --network=vulcan --rm -v .:/workspace tmdcio/vulcan-snowflake:0.228.1.10 vulcan"
alias ter3001='text-embeddings-router --model-id "$TER_MODEL_ID" --port 3001'
alias size='du -sh -- *(DN) 2>/dev/null | sort -rh'
alias ds="$HOME/.dataos/v2/bin/dataos-ctl"
alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='echo $PATH | tr ":" "\n"'
alias reload='source ~/.zprofile && source ~/.zshrc'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -pv'
alias ports='lsof -i -P -n | grep LISTEN'

# Completions
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' '' 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Plugins — hardcoded paths, no brew binary needed
source "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Functions
dockrm() {
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

gcai() {
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
  gcai || return 1
  local tmp msg
  tmp="$(mktemp)"
  pbpaste > "$tmp"
  ${EDITOR:-vi} "$tmp" || { rm -f "$tmp"; return 1; }
  msg="$(cat "$tmp")"
  rm -f "$tmp"
  if [ -z "$msg" ]; then echo "gca: empty commit message after edit"; return 1; fi
  gcmsg "$msg"
}

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
