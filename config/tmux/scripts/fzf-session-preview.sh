#!/usr/bin/env bash

set -euo pipefail

entry="${1:-}"
case "$entry" in
  ""|\[*\]) exit 0 ;;
esac

session="${entry%%: *}"
window="$(tmux list-windows -t "$session" -F '#{window_index}' | head -n 1)"
[[ -z "$window" ]] && exit 0

# Pick the spatially top-left pane in the session's first window.
pane="$(tmux list-panes -t "$session:$window" \
  -F '#{pane_left}|#{pane_top}|#{pane_index}' |
  sort -t '|' -n -k1,1 -k2,2 |
  head -n 1 |
  cut -d '|' -f 3)"
[[ -z "$pane" ]] && exit 0

# Start five visible rows below the top of the selected pane.
tmux capture-pane -e -p -S 5 -t "$session:$window.$pane"
