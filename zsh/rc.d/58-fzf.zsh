if command -v fzf >/dev/null 2>&1; then
  # Keep the global defaults friendly for stdin pipelines; add previews only
  # to file-oriented widgets so `... | fzf` stays fast and uncluttered.
  export FZF_DEFAULT_OPTS="
    --ansi
    --height=55%
    --layout=reverse
    --border
    --info=inline-right
    --cycle
    --prompt='❯ '
    --pointer='▶'
    --marker='✓'
    --bind=ctrl-j:down,ctrl-k:up,ctrl-d:half-page-down,ctrl-u:half-page-up
    --color=fg:#d7dae0,bg:#151821,hl:#8fb7ff
    --color=fg+:#f5f7ff,bg+:#2d3f5a,hl+:#ffd580
    --color=info:#8b93a6,prompt:#8fb7ff,pointer:#ffd580,marker:#7bd88f
    --color=border:#4a5263,header:#8b93a6,spinner:#8fb7ff
  "

  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range=:300 {} 2>/dev/null || cat {}'"
  export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
  export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -100'"

  if [[ -o interactive ]]; then
    source <(fzf --zsh)
  fi
fi

fat() {
  __dotfiles_require_cmd fzf || return 1
  __dotfiles_require_cmd bat || return 1

  local file="${1:A}"
  local selection line editor_cmd

  [[ -n "$1" ]] || {
    echo "Usage: fat <file>"
    return 1
  }

  [[ -f "$file" ]] || {
    echo "Not a file: $1"
    return 1
  }

  selection="$(
    bat --style=plain --color=always --paging=never -- "$file" |
      awk '{printf "%d\t%s\n", NR, $0}' |
      fzf \
        --ansi \
        --delimiter=$'\t' \
        --nth=2.. \
        --no-sort \
        --tiebreak=index \
        --prompt="$(basename "$file") > " \
        --preview "bat --style=numbers --color=always --highlight-line {1} -- ${(q)file}" \
        --preview-window='right,70%,border-left,+{1}+3/3,~3'
  )" || return 0

  line="${selection%%$'\t'*}"
  line="${line//[[:space:]]/}"
  [[ -n "$line" ]] || return 0

  if [[ -n "${EDITOR:-}" ]]; then
    editor_cmd="${EDITOR}"
    "${=editor_cmd}" "+${line}" -- "$file"
  elif command -v nvim >/dev/null 2>&1; then
    nvim "+${line}" -- "$file"
  else
    less "+${line}g" -- "$file"
  fi
}

fcat() {
  __dotfiles_require_cmd fzf || return 1
  __dotfiles_require_cmd bat || return 1

  local file="${1:A}"

  [[ -n "$1" ]] || {
    echo "Usage: fcat <file>"
    return 1
  }

  [[ -f "$file" ]] || {
    echo "Not a file: $1"
    return 1
  }

  bat --style=plain --color=always --paging=never -- "$file" |
    fzf --ansi --prompt="$(basename "$file") > "
}
