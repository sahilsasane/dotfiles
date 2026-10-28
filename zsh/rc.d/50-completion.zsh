autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

# compinit runs once, from oh-my-zsh in 60-plugins.zsh
fpath=("$HOME/.docker/completions" $fpath)

# Bind the terminal's Home/End sequences in every ZLE mode.
for _dotfiles_keymap in emacs viins vicmd; do
  [[ -n "${terminfo[khome]:-}" ]] && bindkey -M "$_dotfiles_keymap" "${terminfo[khome]}" beginning-of-line
  [[ -n "${terminfo[kend]:-}" ]] && bindkey -M "$_dotfiles_keymap" "${terminfo[kend]}" end-of-line
done
unset _dotfiles_keymap
