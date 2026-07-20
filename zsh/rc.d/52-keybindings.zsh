# Let the terminal (or tmux) declare TERM.  Bind its Home/End sequences in
# every ZLE mode so Cmd+Left/Right work through tmux as well as directly.
for _dotfiles_keymap in emacs viins vicmd; do
  [[ -n "${terminfo[khome]:-}" ]] && bindkey -M "$_dotfiles_keymap" "${terminfo[khome]}" beginning-of-line
  [[ -n "${terminfo[kend]:-}" ]] && bindkey -M "$_dotfiles_keymap" "${terminfo[kend]}" end-of-line
done
unset _dotfiles_keymap
