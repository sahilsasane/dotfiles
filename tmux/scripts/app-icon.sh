#!/usr/bin/env bash

set -eu

cmd="${1:-}"
cmd="${cmd##*/}"
cmd="$(printf '%s' "$cmd" | tr '[:upper:]' '[:lower:]')"

case "$cmd" in
  vi)
    printf ''
    ;;
  nvim|vim)
    printf ''
    ;;
  zsh|bash|fish|sh|nu)
    printf ''
    ;;
  claude|claude-code)
    printf ''
    ;;
  codex)
    printf '◎'
    ;;
  git|lazygit)
    printf ''
    ;;
  python|python3|ipython)
    printf ''
    ;;
  node|npm|pnpm|yarn|bun)
    printf '󰎙'
    ;;
  docker|docker-compose)
    printf ''
    ;;
  ssh|mosh)
    printf '󰣀'
    ;;
  *)
    printf ''
    ;;
esac
