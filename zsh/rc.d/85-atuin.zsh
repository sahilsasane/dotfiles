if command -v atuin >/dev/null 2>&1; then
  export ATUIN_SEARCH_MODE="${ATUIN_SEARCH_MODE:-fuzzy}"
  export ATUIN_STYLE="${ATUIN_STYLE:-compact}"
  eval "$(atuin init zsh)"
fi
