export CLICOLOR=1
unset NO_COLOR
export EDITOR="nvim"
export VISUAL="$EDITOR"
export FCEDIT="$EDITOR"
unset LSCOLORS
export CLAUDE_CODE_NO_FLICKER=1
unalias man 2>/dev/null
export MANPAGER='col -b | bat --style=plain --language=man --color=always'

if command -v security >/dev/null 2>&1; then
  # export OPENAI_API_KEY="$(security find-generic-password -a "$USER" -s openai_api_key -w 2>/dev/null)"
  export HF_TOKEN="$(security find-generic-password -a "$USER" -s hf_token -w 2>/dev/null)"
  export WIZ_CLIENT_ID="$(security find-generic-password -a "$USER" -s wiz_client_id -w 2>/dev/null)"
  export WIZ_CLIENT_SECRET="$(security find-generic-password -a "$USER" -s wiz_client_secret -w 2>/dev/null)"
  # export GITHUB_TOKEN="$(security find-generic-password -a "$USER" -s github_pat_token -w 2>/dev/null)"
fi
export OPENAI_MODEL="${OPENAI_MODEL:-gpt-5.6-luna}"
export TER_MODEL_ID="BAAI/bge-small-en-v1.5"
