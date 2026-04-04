# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
# bindkey '^I' autosuggest-accept
# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

export CLICOLOR=1
export TERM=xterm-256color

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

unsetopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# Catppuccin Mocha ls colors
# Ex=Blue(dir) Fx=Pink(symlink) Gx=Teal(socket) dx=Yellow(pipe)
# Cx=Green(exec) Dx=Yellow(block) Bx=Red(char) + special dir combos
export LSCOLORS="ExFxGxdxCxDxBxabagacad"

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

. "$HOME/.local/bin/env"

export OPENAI_API_KEY=$(security find-generic-password -a "$USER" -s openai_api_key -w 2>/dev/null)
export OPENAI_MODEL="${OPENAI_MODEL:-gpt-5-nano-2025-08-07}"
export TER_MODEL_ID="BAAI/bge-small-en-v1.5"

# Local-only secrets and machine-specific overrides.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

export CLAUDE_CODE_NO_FLICKER=1

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH=$PATH:/usr/local/go/bin
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
export LIBRARY_PATH=$LIBRARY_PATH:/usr/local/opt/openssl/lib/

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
alias reload='source ~/.zshrc'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -pv'
alias ports='lsof -i -P -n | grep LISTEN'

# completion
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'


# plugins
[[ -f "20 20 12 61 79 80 81 98 702 33 100 204 250 395 398 399 400brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "20 20 12 61 79 80 81 98 702 33 100 204 250 395 398 399 400brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

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

unalias gcai 2>/dev/null

gcai() {
  git rev-parse --git-dir >/dev/null 2>&1 || {
    echo "Not a git repository."
    return 1
  }

  if git diff --staged --quiet; then
    echo "No staged changes."
    return 1
  fi

  if [ -z "$OPENAI_API_KEY" ]; then
    echo "OPENAI_API_KEY is not set."
    return 1
  fi

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
    --arg reasoning "{"effort":"low"}" \
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
    [
      .output[]?
      | select(.type=="message")
      | .content[]?
      | select(.type=="output_text")
      | .text
    ] | join("")
  ')"

  if [[ -z "$msg" || "$msg" == "null" ]]; then
    echo "Could not extract commit message."
    return 1
  fi

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

  if [ -z "$msg" ]; then
    echo "gca: empty commit message after edit"
    return 1
  fi

  gcmsg "$msg"
}
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

