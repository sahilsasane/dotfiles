#!/usr/bin/env bash
set -euo pipefail

pane="${1:?usage: record-pane.sh pane-id}"
log_file="$(tmux show-option -pqv -t "$pane" @recording_log)"

if [[ "$(tmux display-message -p -t "$pane" '#{pane_pipe}')" == 1 ]]; then
  if [[ -z "$log_file" ]]; then
    tmux display-message -t "$pane" 'Pane already has an output pipe; leave it running'
    exit 1
  fi
  tmux pipe-pane -t "$pane"
  tmux set-option -pu -t "$pane" @recording_log
  tmux display-message -t "$pane" "Recording stopped: $log_file"
else
  umask 077
  log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/tmux/logs"
  mkdir -p "$log_dir"
  log_file="$log_dir/$(date '+%Y%m%d-%H%M%S')-pane-${pane#%}-$$.log"
  : >> "$log_file"
  # pipe-pane runs a shell command; quote the path independently of its contents.
  quoted_log=${log_file//\'/\'\\\'\'}
  tmux pipe-pane -o -t "$pane" "exec cat >> '$quoted_log'"
  tmux set-option -p -t "$pane" @recording_log "$log_file"
  tmux display-message -t "$pane" "Recording started: $log_file"
fi

tmux refresh-client -S 2>/dev/null || true
