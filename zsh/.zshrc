typeset -g DOTFILES_ZSH_DIR="${${(%):-%N}:A:h}"

for _dotfiles_rc in "$DOTFILES_ZSH_DIR"/rc.d/*.zsh(N); do
  source "$_dotfiles_rc"
done

unset _dotfiles_rc

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

if command -v atuin >/dev/null 2>&1; then
  bindkey '^R' atuin-search 2>/dev/null
  bindkey '^[[A' up-line-or-history 2>/dev/null
  bindkey '^[OA' up-line-or-history 2>/dev/null
fi
