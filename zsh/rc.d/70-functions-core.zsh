__dotfiles_has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

__dotfiles_missing_cmd() {
  echo "$1 is not installed."
  return 1
}

__dotfiles_require_cmd() {
  __dotfiles_has_cmd "$1" || {
    __dotfiles_missing_cmd "$1"
    return 1
  }
}

chpwd() {
  eza --group-directories-first
}
