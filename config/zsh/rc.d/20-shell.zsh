export CLICOLOR=1
unset NO_COLOR
export EDITOR="nvim"
export VISUAL="$EDITOR"
export FCEDIT="$EDITOR"
unset LSCOLORS
export CLAUDE_CODE_NO_FLICKER=1
# Keeps tmux session titles. Not in Rex: this flag also stops Claude's
# OSC 7501 status, which Rex needs for tab activity and notifications.
if [[ "${TERM_PROGRAM:-}" == rex ]]; then
  unset CLAUDE_CODE_DISABLE_TERMINAL_TITLE
else
  export CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1
fi
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

bindkey -v
# Allow 10 ms for an Escape-prefixed Option key sequence.
KEYTIMEOUT=1

bindkey -M viins '^[^M' self-insert-unmeta
# Allow deletion across the point where insert mode began.
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^B' backward-char
bindkey -M viins '^F' forward-char
bindkey -M viins '^[b' backward-word
bindkey -M viins '^[f' forward-word
# Ghostty sends these for Cmd+Left and Cmd+Right.
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line

vi-yank-to-clipboard() {
  zle vi-yank
  print -rn -- "$CUTBUFFER" | pbcopy
}
zle -N vi-yank-to-clipboard
bindkey -M visual 'y' vi-yank-to-clipboard

HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000000
SAVEHIST=1000000
