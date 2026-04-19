if command -v atuin >/dev/null 2>&1; then
  export ATUIN_SEARCH_MODE="${ATUIN_SEARCH_MODE:-fuzzy}"
  export ATUIN_STYLE="${ATUIN_STYLE:-compact}"
  # Clear inherited popup disable flags so the current Atuin config decides.
  unset ATUIN_TMUX_POPUP
  eval "$(atuin init zsh)"
  # Atuin 18 binds `?` to its AI widget; restore normal question mark input.
  bindkey '?' self-insert
fi
