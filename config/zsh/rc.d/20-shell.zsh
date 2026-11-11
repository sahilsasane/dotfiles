export CLICOLOR=1
unset NO_COLOR
export EDITOR="nvim"
export VISUAL="$EDITOR"
export FCEDIT="$EDITOR"
unset LSCOLORS
export CLAUDE_CODE_NO_FLICKER=1
export CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1
export HOMEBREW_NO_ENV_HINTS=1
export BUN_OPTIONS="${BUN_OPTIONS:+$BUN_OPTIONS }--preload=/Users/sahilsasane/.local/share/no-agent-summary.js"
unalias man 2>/dev/null
export MANPAGER='col -b | bat --style=plain --language=man --color=always'

if [[ "$OSTYPE" == darwin* ]]; then
  export OPENAI_API_KEY="$(security find-generic-password -a "$USER" -s openai_api_key -w 2>/dev/null)"
  export HF_TOKEN="$(security find-generic-password -a "$USER" -s hf_token -w 2>/dev/null)"
  export WIZ_CLIENT_ID="$(security find-generic-password -a "$USER" -s wiz_client_id -w 2>/dev/null)"
  export WIZ_CLIENT_SECRET="$(security find-generic-password -a "$USER" -s wiz_client_secret -w 2>/dev/null)"
  export WAKATIME_API_KEY="$(security find-generic-password -a "$USER" -s wakatime_api_key -w 2>/dev/null)"
fi
export OPENAI_MODEL="${OPENAI_MODEL:-gpt-6-luna}"
export TER_MODEL_ID="BAAI/bge-small-en-v1.5"
export GRANTEE_ID="sahilsasanetmdcio"

bindkey -e

HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000000
SAVEHIST=1000000
