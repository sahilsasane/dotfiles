#!/usr/bin/env bash

set -eu

percent_free="$(
  memory_pressure -Q 2>/dev/null |
    awk -F': ' '/System-wide memory free percentage/ {gsub(/%/, "", $2); print $2; exit}'
)"

if [ -z "${percent_free:-}" ]; then
  printf '󰍛 ▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱'
  exit 0
fi

pressure=$((100 - percent_free))

bars=0
if [ "$pressure" -gt 0 ]; then
  bars=$(((pressure + 6) / 7))
fi

bar=""
i=1
while [ "$i" -le 15 ]; do
  if [ "$i" -le "$bars" ]; then
    bar="${bar}▰"
  else
    bar="${bar}▱"
  fi
  i=$((i + 1))
done

printf '󰍛 %s' "$bar"
