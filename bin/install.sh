#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

backup_path() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    local backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
    mv "$target" "$backup"
    echo "Backed up $target -> $backup"
  fi
}

link_path() {
  local source="$1"
  local target="$2"
  mkdir -p "$(dirname "$target")"
  backup_path "$target"
  ln -sfn "$source" "$target"
}

clone_or_update() {
  local repo="$1"
  local target="$2"
  if [[ -d "$target/.git" ]]; then
    git -C "$target" pull --ff-only
  else
    mkdir -p "$(dirname "$target")"
    git clone --depth=1 "$repo" "$target"
  fi
}

clone_or_update https://github.com/ohmyzsh/ohmyzsh.git \
  "$HOME/.oh-my-zsh"
clone_or_update https://github.com/romkatv/powerlevel10k.git \
  "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"

clone_or_update https://github.com/tmux-plugins/tpm \
  "$HOME/.tmux/plugins/tpm"
clone_or_update https://github.com/catppuccin/tmux \
  "$HOME/.tmux/plugins/catppuccin"
clone_or_update https://github.com/tmux-plugins/tmux-cpu \
  "$HOME/.tmux/plugins/tmux-cpu"
clone_or_update https://github.com/tmux-plugins/tmux-battery \
  "$HOME/.tmux/plugins/tmux-battery"

link_path "$DOTFILES_ROOT/zsh/.zshrc" "$HOME/.zshrc"
link_path "$DOTFILES_ROOT/zsh/.zshenv" "$HOME/.zshenv"
link_path "$DOTFILES_ROOT/zsh/.zprofile" "$HOME/.zprofile"
link_path "$DOTFILES_ROOT/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

link_path "$DOTFILES_ROOT/git-config/.gitconfig" "$HOME/.gitconfig"
link_path "$DOTFILES_ROOT/git-config/.gitignore_global" "$HOME/.gitignore_global"

link_path "$DOTFILES_ROOT/tmux/.tmux.conf" "$HOME/.tmux.conf"

link_path "$DOTFILES_ROOT/nvim" "$HOME/.config/nvim"
link_path "$DOTFILES_ROOT/eza" "$HOME/.config/eza"
link_path "$DOTFILES_ROOT/fish" "$HOME/.config/fish"
link_path "$DOTFILES_ROOT/git" "$HOME/.config/git"
link_path "$DOTFILES_ROOT/htop" "$HOME/.config/htop"
link_path "$DOTFILES_ROOT/yazi" "$HOME/.config/yazi"
link_path "$DOTFILES_ROOT/iterm2/com.googlecode.iterm2.plist" "$HOME/Library/Preferences/com.googlecode.iterm2.plist"

echo "Linked dotfiles into $HOME."
