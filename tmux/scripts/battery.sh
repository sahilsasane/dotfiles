#!/usr/bin/env bash

set -eu

reset_style='#[default]'
source "$(dirname "$0")/theme.sh"

pmset_output() {
  if [ -n "${BATTERY_STATUS_SAMPLE:-}" ]; then
    printf '%b\n' "$BATTERY_STATUS_SAMPLE"
    return
  fi

  pmset -g batt 2>/dev/null
}

charge_tier() {
  if [ "$1" -ge 95 ]; then
    printf '8'
  elif [ "$1" -ge 80 ]; then
    printf '7'
  elif [ "$1" -ge 65 ]; then
    printf '6'
  elif [ "$1" -ge 50 ]; then
    printf '5'
  elif [ "$1" -ge 35 ]; then
    printf '4'
  elif [ "$1" -ge 20 ]; then
    printf '3'
  elif [ "$1" -ge 5 ]; then
    printf '2'
  else
    printf '1'
  fi
}

tier_icon() {
  case "$(charge_tier "$1")" in
    8) printf '█' ;;
    7) printf '▇' ;;
    6) printf '▆' ;;
    5) printf '▅' ;;
    4) printf '▄' ;;
    3) printf '▃' ;;
    2) printf '▂' ;;
    *) printf '▁' ;;
  esac
}

tier_color() {
  case "$(charge_tier "$1")" in
    8) printf '%s' "$full_fg" ;;
    7) printf '%s' "$high_fg" ;;
    6) printf '%s' "$mid_fg" ;;
    5) printf '%s' "$okay_fg" ;;
    4) printf '%s' "$warn_fg" ;;
    3) printf '%s' "$low_fg" ;;
    2) printf '%s' "$critical_fg" ;;
    *) printf '%s' "$low_fg" ;;
  esac
}

render() {
  local line percent state icon accent_fg level_fg charge_icon

  line="$(pmset_output | awk 'NR==2 { print; exit }')"
  percent="$(printf '%s\n' "$line" | grep -Eo '[0-9]+%' | head -n1 | tr -d '%')"
  state="$(printf '%s\n' "$line" | awk -F'; *' 'NR==1 { print tolower($2) }')"

  if [ -z "${percent:-}" ]; then
    printf '%s?%s' "$attached_fg" "$reset_style"
    return
  fi

  icon='?'
  accent_fg="$muted_fg"
  case "$state" in
    *discharging*)
      icon='󰁹'
      accent_fg="$discharge_fg"
      ;;
    *charged*|*not\ charging*|*attached*)
      icon=''
      accent_fg="$attached_fg"
      ;;
    *charging*|*finishing\ charge*)
      icon='⚡'
      accent_fg="$charge_fg"
      ;;
    *unknown*)
      icon='?'
      accent_fg="$muted_fg"
      ;;
  esac

  level_fg="$(tier_color "$percent")"
  charge_icon="$(tier_icon "$percent")"

  printf '%s%s %s| %s%s%% %s%s%s' \
    "$accent_fg" \
    "$icon" \
    "$divider_fg" \
    "${level_fg}#[bold]" \
    "$percent" \
    "$level_fg" \
    "$charge_icon" \
    "$reset_style"
}

self_check() {
  local output

  BATTERY_STATUS_SAMPLE=$'Now drawing from '\''AC Power'\''\n -InternalBattery-0 (id=1)\t90%; charging; 0:33 remaining present: true'
  output="$(render)"
  printf '%s\n' "$output" | grep -q '⚡' || {
    printf 'charging sample failed\n' >&2
    exit 1
  }
  printf '%s\n' "$output" | grep -q '90%' || {
    printf 'charging sample failed\n' >&2
    exit 1
  }
  printf '%s\n' "$output" | grep -q '▇' || {
    printf 'charging sample failed\n' >&2
    exit 1
  }

  BATTERY_STATUS_SAMPLE=$'Now drawing from '\''AC Power'\''\n -InternalBattery-0 (id=1)\t100%; finishing charge; 0:09 remaining present: true'
  output="$(render)"
  printf '%s\n' "$output" | grep -q '⚡' || {
    printf 'finishing charge sample failed\n' >&2
    exit 1
  }
  printf '%s\n' "$output" | grep -q '100%' || {
    printf 'finishing charge sample failed\n' >&2
    exit 1
  }
  printf '%s\n' "$output" | grep -q '█' || {
    printf 'finishing charge sample failed\n' >&2
    exit 1
  }

  BATTERY_STATUS_SAMPLE=$'Now drawing from '\''AC Power'\''\n -InternalBattery-0 (id=1)\t97%; AC attached; not charging present: true'
  output="$(render)"
  printf '%s\n' "$output" | grep -q '' || {
    printf 'attached sample failed\n' >&2
    exit 1
  }
  printf '%s\n' "$output" | grep -q '97%' || {
    printf 'attached sample failed\n' >&2
    exit 1
  }

  BATTERY_STATUS_SAMPLE=$'Now drawing from '\''Battery Power'\''\n -InternalBattery-0 (id=1)\t12%; discharging; 2:00 remaining present: true'
  output="$(render)"
  printf '%s\n' "$output" | grep -q '12%' || {
    printf 'discharging sample failed\n' >&2
    exit 1
  }
  printf '%s\n' "$output" | grep -q '󰁹' || {
    printf 'discharging sample failed\n' >&2
    exit 1
  }
  printf '%s\n' "$output" | grep -q '▂' || {
    printf 'discharging sample failed\n' >&2
    exit 1
  }

  unset BATTERY_STATUS_SAMPLE
}

if [ "${1:-}" = "--self-check" ]; then
  self_check
else
  render
fi
