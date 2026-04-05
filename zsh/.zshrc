typeset -g DOTFILES_ZSH_DIR="${${(%):-%N}:A:h}"

for _dotfiles_rc in "$DOTFILES_ZSH_DIR"/rc.d/*.zsh(N); do
  source "$_dotfiles_rc"
done

unset _dotfiles_rc
