export CLICOLOR=1
export TERM=xterm-256color
export EDITOR="nvim"
export VISUAL="$EDITOR"
export FCEDIT="$EDITOR"
export EZA_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/eza"
unset LSCOLORS
export LS_COLORS="$(vivid generate catppuccin-mocha)"
export CLAUDE_CODE_NO_FLICKER=1
export BAT_THEME="Catppuccin Mocha"

if command -v security >/dev/null 2>&1; then
  # export OPENAI_API_KEY="$(security find-generic-password -a "$USER" -s openai_api_key -w 2>/dev/null)"
  export HF_TOKEN="$(security find-generic-password -a "$USER" -s hf_token -w 2>/dev/null)"
  export WIZ_CLIENT_ID="$(security find-generic-password -a "$USER" -s wiz_client_id -w 2>/dev/null)"
  export WIZ_CLIENT_SECRET="$(security find-generic-password -a "$USER" -s wiz_client_secret -w 2>/dev/null)"
  # export GITHUB_TOKEN="$(security find-generic-password -a "$USER" -s github_pat_token -w 2>/dev/null)"
fi
export OPENAI_MODEL="${OPENAI_MODEL:-gpt-5-nano-2025-08-07}"
export TER_MODEL_ID="BAAI/bge-small-en-v1.5"
