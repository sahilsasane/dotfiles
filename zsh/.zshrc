typeset -g DOTFILES_ZSH_DIR="${${(%):-%N}:A:h}"

# tmux panes usually start interactive non-login shells, so bootstrap the core
# PATH/Homebrew environment here as well instead of assuming .zprofile ran.
for _dotfiles_profile in \
  "$DOTFILES_ZSH_DIR"/profile.d/10-homebrew.zsh \
  "$DOTFILES_ZSH_DIR"/profile.d/20-path-core.zsh \
  "$DOTFILES_ZSH_DIR"/profile.d/30-path-optional.zsh; do
  [[ -r "$_dotfiles_profile" ]] && source "$_dotfiles_profile"
done

for _dotfiles_rc in "$DOTFILES_ZSH_DIR"/rc.d/*.zsh(N); do
  source "$_dotfiles_rc"
done

unset _dotfiles_profile
unset _dotfiles_rc

if command -v atuin >/dev/null 2>&1; then
  bindkey '^R' atuin-search 2>/dev/null
fi
