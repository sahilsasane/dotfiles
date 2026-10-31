typeset -g DOTFILES_ZSH_DIR="${${(%):-%N}:A:h}"

# Login shells already ran .zprofile; tmux can also start non-login shells.
if [[ ! -o login ]]; then
  source "$DOTFILES_ZSH_DIR/profile.d/10-environment.zsh"
  source "$DOTFILES_ZSH_DIR/profile.d/40-runtimes.zsh"
fi

for _dotfiles_rc in "$DOTFILES_ZSH_DIR"/rc.d/*.zsh; do
  source "$_dotfiles_rc"
done

unset _dotfiles_rc

bindkey '^R' atuin-search

path=("$HOME/.bend/bin" "$HOME/.local/bin" "$HOME/.opencode/bin" $path)
