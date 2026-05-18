#!/usr/bin/env bash

set -eu

empty_style='#[fg=#585b70]'
reset_style='#[default]'

percent_free="$(
  memory_pressure -Q 2>/dev/null |
    awk -F': ' '/System-wide memory free percentage/ {gsub(/%/, "", $2); print $2; exit}'
)"

if [ -z "${percent_free:-}" ]; then
  printf '󰍛 %s▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱%s' "$empty_style" "$reset_style"
  exit 0
fi

pressure=$((100 - percent_free))

filled_style='#[fg=#a6e3a1]'
if [ "$pressure" -gt 20 ]; then
  filled_style='#[fg=#94e2d5]'
fi
if [ "$pressure" -gt 40 ]; then
  filled_style='#[fg=#89b4fa]'
fi
if [ "$pressure" -gt 60 ]; then
  filled_style='#[fg=#fab387]'
fi
if [ "$pressure" -gt 80 ]; then
  filled_style='#[fg=#f38ba8]'
fi

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

printf '󰍛 %s%s%s' "$filled_style" "${bar%%▱*}" "$empty_style"
printf '%s%s' "${bar#${bar%%▱*}}" "$reset_style"
