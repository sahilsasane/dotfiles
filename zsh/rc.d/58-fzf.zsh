if command -v fzf >/dev/null 2>&1; then
  # Keep the global defaults friendly for stdin pipelines; add previews only
  # to file-oriented widgets so `... | fzf` stays fast and uncluttered.
  export FZF_DEFAULT_OPTS="
    --ansi
    --height=55%
    --layout=reverse
    --border=none
    --info=inline-right
    --no-separator
    --cycle
    --prompt='❯ '
    --pointer='▶'
    --marker='✓'
    --bind=ctrl-j:down,ctrl-k:up,ctrl-d:half-page-down,ctrl-u:half-page-up
    --color=fg:#d7dae0,bg:-1,hl:#8fb7ff
    --color=fg+:#f5f7ff,bg+:-1,hl+:#ffd580
    --color=info:#8b93a6,prompt:#8fb7ff,pointer:#ffd580,marker:#7bd88f
    --color=border:#6c7086,header:#8b93a6,spinner:#8fb7ff
    --color=gutter:-1,preview-bg:-1,preview-border:#6c7086
    --color=separator:#45475a,scrollbar:#6c7086
  "

  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range=:500 {} 2>/dev/null || cat {}'"
  export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -100'"
  # export FZF_COMPLETION_TRIGGER=''

  # In `git diff`, press Ctrl-G to insert one commit hash, or build `A..B`
  # incrementally by invoking the picker again after the first selection.
  __dotfiles_fzf_git_diff_commit_widget() {
    emulate -L zsh

    __dotfiles_require_cmd git || return 0
    __dotfiles_require_cmd fzf || return 0

    if [[ "$BUFFER" != git\ diff(|\ *) ]]; then
      zle -M 'Use Ctrl-G after typing: git diff '
      return 0
    fi

    git rev-parse --git-dir >/dev/null 2>&1 || {
      zle -M 'Not a git repository.'
      return 0
    }

    local selection hash suffix
    selection="$(
      git log \
        --color=always \
        --date=short \
        --decorate=short \
        --pretty=format:$'%h\t%C(green)%ad%C(reset) %C(yellow)%h%C(reset) %s %C(auto)%d%C(reset)' \
        --all |
        fzf \
          --ansi \
          --delimiter=$'\t' \
          --with-nth=2.. \
          --no-sort \
          --tiebreak=index \
          --prompt='Hashes > ' \
          --header='ENTER inserts hash, Ctrl-S toggles sort' \
          --preview 'git show --color=always --stat --patch --format=fuller {1}' \
          --preview-window='right,65%,border-none'
    )" || return 0

    hash="${selection%%$'\t'*}"
    [[ -n "$hash" ]] || return 0

    if [[ "$LBUFFER" == (#b)(*git\ diff\ )([^[:space:]]##) && "${match[2]}" != *..* ]]; then
      LBUFFER="${match[1]}${match[2]}..${hash}"
    else
      suffix=""
      [[ -n "$LBUFFER" && "$LBUFFER" != *[[:space:]] ]] && suffix=" "
      LBUFFER+="${suffix}${hash}"
    fi

    zle redisplay
  }

  _fzf_comprun() {
    local command=$1
    shift

    case "$command" in
      cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
      export|unset) fzf --preview "eval 'echo \$' {}" "$@";;
      ssh)          fzf --preview 'dig{}' ;;
      *)            fzf --preview "--preview 'bat -n --color=always --line-range :500 {}'" "$@" ;;
    esac
  }

  if [[ -o interactive ]]; then
    zle -N __dotfiles_fzf_git_diff_commit_widget
    bindkey -M emacs '^G' __dotfiles_fzf_git_diff_commit_widget
    bindkey -M viins '^G' __dotfiles_fzf_git_diff_commit_widget
    bindkey -M vicmd '^G' __dotfiles_fzf_git_diff_commit_widget
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
        --preview-window='right,70%,border-none,+{1}+3/3,~3'
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
