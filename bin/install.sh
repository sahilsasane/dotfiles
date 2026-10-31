#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_HOME="$HOME/.config"
DATA_HOME="$HOME/.local/share"

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
  elif [[ -e "$target" && ! -d "$target" ]]; then
    backup_path "$target"
  fi
  mkdir -p "$target"
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
  "$DATA_HOME/oh-my-zsh"

clone_or_update https://github.com/tmux-plugins/tpm \
  "$DATA_HOME/tmux/plugins/tpm"
clone_or_update https://github.com/catppuccin/tmux \
  "$DATA_HOME/tmux/plugins/catppuccin"
clone_or_update https://github.com/tmux-plugins/tmux-cpu \
  "$DATA_HOME/tmux/plugins/tmux-cpu"
clone_or_update https://github.com/tmux-plugins/tmux-battery \
  "$DATA_HOME/tmux/plugins/tmux-battery"

# .zshenv is the only file zsh reads from $HOME; it points ZDOTDIR at ~/.config/zsh.
link_path "$DOTFILES_ROOT/home/.zshenv" "$HOME/.zshenv"

link_path "$DOTFILES_ROOT/bin/lgai" "$HOME/.local/bin/lgai"
link_path "$DOTFILES_ROOT/bin/tmx" "$HOME/.local/bin/tmx"
link_path "$DOTFILES_ROOT/bin/ds" "$HOME/.local/bin/ds"
link_path "$DOTFILES_ROOT/bin/dotfiles-theme" "$HOME/.local/bin/dotfiles-theme"

# Each config/<tool> becomes ~/.config/<tool>, except the tools below that need
# a real directory.
for source in "$DOTFILES_ROOT"/config/*; do
  case "${source##*/}" in atuin|git|kitty|lazygit) continue ;; esac
  link_path "$source" "$CONFIG_HOME/${source##*/}"
done

# These applications need a real config directory so the theme controller can
# switch only their selected child files. Existing real directories are kept,
# so local state such as Lazygit's state.yml survives.
prepare_runtime_dir "$CONFIG_HOME/lazygit"
link_path "$CONFIG_HOME/dotfiles-theme/lazygit.yml" "$CONFIG_HOME/lazygit/config.yml"

prepare_runtime_dir "$CONFIG_HOME/atuin"
link_path "$CONFIG_HOME/dotfiles-theme/atuin.toml" "$CONFIG_HOME/atuin/config.toml"
link_path "$DOTFILES_ROOT/config/atuin/themes" "$CONFIG_HOME/atuin/themes"

prepare_runtime_dir "$CONFIG_HOME/git"
link_path "$DOTFILES_ROOT/config/git/config" "$CONFIG_HOME/git/config"
link_path "$DOTFILES_ROOT/config/git/ignore" "$CONFIG_HOME/git/ignore"
link_path "$CONFIG_HOME/dotfiles-theme/gitk" "$CONFIG_HOME/git/gitk"

# Kitty reads the runtime include written by dotfiles-theme.
prepare_runtime_dir "$CONFIG_HOME/kitty"
link_path "$DOTFILES_ROOT/config/kitty/kitty.conf" "$CONFIG_HOME/kitty/kitty.conf"

link_path "$DOTFILES_ROOT/macos/iterm2/com.googlecode.iterm2.plist" "$HOME/Library/Preferences/com.googlecode.iterm2.plist"

mkdir -p "$CONFIG_HOME/dotfiles-theme" "$HOME/.cache"
"$DOTFILES_ROOT/bin/dotfiles-theme" apply

if [[ "$(uname)" = Darwin ]]; then
  launch_agent="$HOME/Library/LaunchAgents/com.sahilsasane.dotfiles-theme.plist"
  mkdir -p "$(dirname "$launch_agent")"
  sed "s#__HOME__#$HOME#g" "$DOTFILES_ROOT/macos/launchd/com.sahilsasane.dotfiles-theme.plist" > "$launch_agent"
  launchctl bootout "gui/$(id -u)/com.sahilsasane.dotfiles-theme" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$launch_agent"
fi

echo "Linked dotfiles into $HOME."
