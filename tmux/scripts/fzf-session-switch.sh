#!/usr/bin/env bash

set -euo pipefail

TMUX_FZF_CLIENT="${TMUX_FZF_CLIENT:-}"
PREVIEW_SCRIPT="/Users/sahilsasane/dotfiles/tmux/scripts/fzf-session-preview.sh"

tmux_display_args=()
if [[ -n "$TMUX_FZF_CLIENT" ]]; then
  tmux_display_args=(-t "$TMUX_FZF_CLIENT")
fi

current_session="$(tmux display-message "${tmux_display_args[@]}" -p '#S')"
session_rows="$(tmux list-sessions -F '#{session_name}|#{session_windows}')"

sessions="$(printf '%s\n' "$session_rows" | awk -F '|' -v current="$current_session" '$1 != current { printf "%s: %s windows\n", $1, $2 }')"
[[ -z "$sessions" ]] && exit 0

fzf_args=(-p -w 62% -h 38% -m)
if [[ -n "${TMUX_FZF_OPTIONS:-}" ]]; then
  read -r -a fzf_args <<< "$TMUX_FZF_OPTIONS"
fi

if ! selected="$(printf '%s\n' "$sessions" | fzf-tmux "${fzf_args[@]}" \
  --preview="$PREVIEW_SCRIPT {}" \
  --preview-window=right:50%)"; then
  # fzf returns 130 when the picker is cancelled with Esc or Ctrl-C.
  exit 0
fi
[[ -z "$selected" ]] && exit 0

target="${selected%%: *}"
switch_args=()
if [[ -n "$TMUX_FZF_CLIENT" ]]; then
  switch_args=(-c "$TMUX_FZF_CLIENT")
fi
tmux switch-client "${switch_args[@]}" -t "$target"
