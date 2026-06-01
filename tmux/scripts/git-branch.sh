#!/usr/bin/env bash

set -eu

pane_path="${1:-}"

if [ -z "$pane_path" ] || ! [ -d "$pane_path" ]; then
  exit 0
fi

if ! git -C "$pane_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

branch="$(
  git -C "$pane_path" symbolic-ref --quiet --short HEAD 2>/dev/null ||
    git -C "$pane_path" rev-parse --short HEAD 2>/dev/null ||
    true
)"

if [ -z "$branch" ]; then
  exit 0
fi

printf '#[fg=#cdd6f4] %s#[default] ' "$branch"
