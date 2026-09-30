typeset -g DOTFILES_ZSH_DIR="${${(%):-%N}:A:h}"

# tmux panes can start non-login shells.
source "$DOTFILES_ZSH_DIR/profile.d/10-environment.zsh"

for _dotfiles_rc in "$DOTFILES_ZSH_DIR"/rc.d/*.zsh; do
  source "$_dotfiles_rc"
done

unset _dotfiles_rc

if command -v atuin >/dev/null 2>&1; then
  bindkey '^R' atuin-search 2>/dev/null
fi

path=("$HOME/.bend/bin" "$HOME/.local/bin" "$HOME/.opencode/bin" $path)
