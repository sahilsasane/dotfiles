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

prepare_runtime_dir() {
  local target="$1"
  if [[ -L "$target" ]]; then
    rm "$target"
  elif [[ -e "$target" ]]; then
    backup_path "$target"
  fi
  mkdir -p "$target"
}

migrate_lazygit_dir() {
  local target="$1" state_backup=""
  if [[ -f "$target/state.yml" ]]; then
    state_backup="$(mktemp)"
    cp -p "$target/state.yml" "$state_backup"
  fi
  prepare_runtime_dir "$target"
  if [[ -n "$state_backup" ]]; then
    cp -p "$state_backup" "$target/state.yml"
    rm "$state_backup"
  fi
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

link_path "$DOTFILES_ROOT/git-config/.gitconfig" "$HOME/.gitconfig"
link_path "$DOTFILES_ROOT/git-config/.gitignore_global" "$HOME/.gitignore_global"

link_path "$DOTFILES_ROOT/tmux/.tmux.conf" "$HOME/.tmux.conf"

link_path "$DOTFILES_ROOT/bin/lgai" "$HOME/.local/bin/lgai"
link_path "$DOTFILES_ROOT/bin/dotfiles-theme" "$HOME/.local/bin/dotfiles-theme"

# These applications need a real config directory so the theme controller can
# switch only their selected child files. Existing real directories are backed
# up, and Lazygit's local state is copied forward.
migrate_lazygit_dir "$HOME/Library/Application Support/lazygit"
link_path "$HOME/.config/dotfiles-theme/lazygit.yml" "$HOME/Library/Application Support/lazygit/config.yml"
migrate_lazygit_dir "$HOME/.config/lazygit"
link_path "$HOME/.config/dotfiles-theme/lazygit.yml" "$HOME/.config/lazygit/config.yml"

prepare_runtime_dir "$HOME/.config/atuin"
link_path "$HOME/.config/dotfiles-theme/atuin.toml" "$HOME/.config/atuin/config.toml"
mkdir -p "$HOME/.config/atuin/themes"
link_path "$DOTFILES_ROOT/atuin/themes/sahil-slate.toml" "$HOME/.config/atuin/themes/sahil-slate.toml"
link_path "$DOTFILES_ROOT/atuin/themes/sahil-latte.toml" "$HOME/.config/atuin/themes/sahil-latte.toml"

prepare_runtime_dir "$HOME/.config/eza"
link_path "$DOTFILES_ROOT/eza/theme.yml" "$HOME/.config/eza/theme.yml"

prepare_runtime_dir "$HOME/.config/git"
link_path "$DOTFILES_ROOT/git/ignore" "$HOME/.config/git/ignore"
link_path "$HOME/.config/dotfiles-theme/gitk" "$HOME/.config/git/gitk"

# Kitty and Ghostty read the runtime includes written by dotfiles-theme.
prepare_runtime_dir "$HOME/.config/kitty"
link_path "$DOTFILES_ROOT/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
link_path "$DOTFILES_ROOT/ghostty/config.ghostty" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"

link_path "$DOTFILES_ROOT/nvim" "$HOME/.config/nvim"
link_path "$DOTFILES_ROOT/fish" "$HOME/.config/fish"
link_path "$DOTFILES_ROOT/htop" "$HOME/.config/htop"
link_path "$DOTFILES_ROOT/yazi" "$HOME/.config/yazi"
link_path "$DOTFILES_ROOT/iterm2/com.googlecode.iterm2.plist" "$HOME/Library/Preferences/com.googlecode.iterm2.plist"

mkdir -p "$HOME/.config/dotfiles-theme" "$HOME/.cache"
"$DOTFILES_ROOT/bin/dotfiles-theme" apply

if [[ "$(uname)" = Darwin ]]; then
  launch_agent="$HOME/Library/LaunchAgents/com.sahilsasane.dotfiles-theme.plist"
  mkdir -p "$(dirname "$launch_agent")"
  sed "s#__HOME__#$HOME#g" "$DOTFILES_ROOT/launchd/com.sahilsasane.dotfiles-theme.plist" > "$launch_agent"
  launchctl bootout "gui/$(id -u)/com.sahilsasane.dotfiles-theme" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$launch_agent"
fi

echo "Linked dotfiles into $HOME."
