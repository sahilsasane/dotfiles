#!/usr/bin/env bash

set -eu
source "$(dirname "$0")/theme.sh"

empty_style="$muted_fg"
reset_style='#[default]'

cpu_percent="$({
  if [ -n "${CPU_USAGE_SAMPLE:-}" ]; then
    printf '%s\n' "$CPU_USAGE_SAMPLE"
  else
    top -l 1 -n 0 2>/dev/null
  fi
} | awk '/^CPU usage:/ {
  gsub(/%/, "", $3)
  gsub(/%/, "", $5)
  printf "%.0f\n", $3 + $5
  exit
}')"

if [ -z "${cpu_percent:-}" ]; then
  printf '󰓅 %s▱▱▱▱▱▱▱▱%s' "$empty_style" "$reset_style"
  exit 0
fi

if [ "$cpu_percent" -lt 0 ]; then
  cpu_percent=0
elif [ "$cpu_percent" -gt 100 ]; then
  cpu_percent=100
fi

filled_style="$full_fg"
if [ "$cpu_percent" -gt 20 ]; then
  filled_style="$high_fg"
fi
if [ "$cpu_percent" -gt 40 ]; then
  filled_style="$mid_fg"
fi
if [ "$cpu_percent" -gt 60 ]; then
  filled_style="$warn_fg"
fi
if [ "$cpu_percent" -gt 80 ]; then
  filled_style="$low_fg"
fi

bars=0
if [ "$cpu_percent" -gt 0 ]; then
  bars=$(((cpu_percent * 8 + 99) / 100))
fi

bar=""
i=1
while [ "$i" -le 8 ]; do
  if [ "$i" -le "$bars" ]; then
    bar="${bar}▰"
  else
    bar="${bar}▱"
  fi
  i=$((i + 1))
done

printf '󰓅 %s%s%s' "$filled_style" "${bar%%▱*}" "$empty_style"
printf '%s%s' "${bar#${bar%%▱*}}" "$reset_style"

self_check() {
  local output

  CPU_USAGE_SAMPLE='CPU usage: 48.12% user, 12.34% sys, 39.54% idle'
  output="$(CPU_USAGE_SAMPLE="$CPU_USAGE_SAMPLE" "$0")"
  printf '%s\n' "$output" | grep -q '▰' || {
    printf 'cpu sample failed\n' >&2
    exit 1
  }
  printf '%s\n' "$output" | grep -q '▰▰▰▰▰▱▱▱' || {
    printf 'cpu gauge length failed\n' >&2
    exit 1
  }
}

if [ "${1:-}" = "--self-check" ]; then
  self_check
fi
