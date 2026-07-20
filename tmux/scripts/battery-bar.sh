#!/usr/bin/env bash

set -eu

batt_line="$(pmset -g batt 2>/dev/null | tail -n 1)"
percent="$(printf '%s\n' "$batt_line" | grep -Eo '[0-9]+%' | head -n 1 | tr -d '%')"

if [ -z "${percent:-}" ]; then
  printf '?'
  exit 0
fi

if [ "$percent" -ge 90 ]; then
  icon=""
elif [ "$percent" -ge 65 ]; then
  icon=""
elif [ "$percent" -ge 40 ]; then
  icon=""
elif [ "$percent" -ge 15 ]; then
  icon=""
else
  icon=""
fi

full=$(((percent + 9) / 10))
if [ "$full" -gt 10 ]; then
  full=10
fi

bar=""
i=1
while [ "$i" -le 10 ]; do
  if [ "$i" -le "$full" ]; then
    bar="${bar}▰"
  else
    bar="${bar}▱"
  fi
  i=$((i + 1))
done

printf '%s %s' "$icon" "$bar"
