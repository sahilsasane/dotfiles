#!/usr/bin/env bash
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

ln -sf "$DOTFILES/zsh/.zshrc"   "$HOME/.zshrc"
ln -sf "$DOTFILES/zsh/.zshenv"  "$HOME/.zshenv"
ln -sf "$DOTFILES/zsh/.zprofile" "$HOME/.zprofile"

mkdir -p "$HOME/.config/zsh"
for f in "$DOTFILES/zsh/config/"*.zsh; do
  ln -sf "$f" "$HOME/.config/zsh/$(basename "$f")"
done

git clone https://github.com/zsh-users/zsh-autosuggestions \
  $ZSH_CUSTOM/plugins/zsh-autosuggestions 2>/dev/null || \
  git -C $ZSH_CUSTOM/plugins/zsh-autosuggestions pull

git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  $ZSH_CUSTOM/plugins/zsh-syntax-highlighting 2>/dev/null || \
  git -C $ZSH_CUSTOM/plugins/zsh-syntax-highlighting pull

echo "Linked."
