#!/usr/bin/env bash

effective=dark
state_file="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles-theme/effective"
[[ -r "$state_file" && "$(<"$state_file")" = light ]] && effective=light

if [[ "$effective" = light ]]; then
  muted_fg='#[fg=#9ca0b0]'; divider_fg='#[fg=#7c7f93]'; charge_fg='#[fg=#df8e1d]'
  attached_fg='#[fg=#4c4f69]'; discharge_fg='#[fg=#1e66f5]'; full_fg='#[fg=#40a02b]'
  high_fg='#[fg=#179299]'; mid_fg='#[fg=#1e66f5]'; okay_fg='#[fg=#df8e1d]'
  warn_fg='#[fg=#fe640b]'; low_fg='#[fg=#d20f39]'; critical_fg='#[fg=#e64553]'
else
  muted_fg='#[fg=#6c7086]'; divider_fg='#[fg=#9399b2]'; charge_fg='#[fg=#f9e2af]'
  attached_fg='#[fg=#cdd6f4]'; discharge_fg='#[fg=#89b4fa]'; full_fg='#[fg=#a6e3a1]'
  high_fg='#[fg=#94e2d5]'; mid_fg='#[fg=#89b4fa]'; okay_fg='#[fg=#f9e2af]'
  warn_fg='#[fg=#fab387]'; low_fg='#[fg=#f38ba8]'; critical_fg='#[fg=#eba0ac]'
fi
