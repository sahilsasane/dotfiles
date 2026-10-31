# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:$HOME/.docker/bin"
# End of Docker Desktop section.

typeset -g DOTFILES_ZSH_DIR="${${(%):-%N}:A:h}"

for _dotfiles_profile in "$DOTFILES_ZSH_DIR"/profile.d/*.zsh(N); do
  source "$_dotfiles_profile"
done

unset _dotfiles_profile
