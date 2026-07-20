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
    ${DOTFILES_FZF_THEME_OPTS}
  "

  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range=:1500 {} 2>/dev/null || cat {}'"
  export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -100'"
  # export FZF_COMPLETION_TRIGGER=''

  __dotfiles_git_commit_range() {
    emulate -L zsh

    local left=$1 right=$2
    [[ -n "$left" && -n "$right" ]] || return 1

    if git merge-base --is-ancestor "$left" "$right" >/dev/null 2>&1; then
      printf '%s..%s' "$left" "$right"
    elif git merge-base --is-ancestor "$right" "$left" >/dev/null 2>&1; then
      printf '%s..%s' "$right" "$left"
    else
      printf '%s..%s' "$left" "$right"
    fi
  }

  # In `git diff` or `gd`, press Ctrl-G to insert one commit hash, or mark up
  # to two commits with Tab and insert the resulting `A..B` range on Enter.
  __dotfiles_fzf_git_diff_commit_widget() {
    emulate -L zsh

    __dotfiles_require_cmd git || return 0
    __dotfiles_require_cmd fzf || return 0

    if [[ "$BUFFER" != git\ diff(|\ *) && "$BUFFER" != gd(|\ *) ]]; then
      zle -M 'Use Ctrl-G after typing: git diff or gd '
      return 0
    fi

    git rev-parse --git-dir >/dev/null 2>&1 || {
      zle -M 'Not a git repository.'
      return 0
    }

    local -a selections hashes
    local selection hash range suffix
    selection="$(
      git log \
        --color=always \
        --date=short \
        --decorate=short \
        --pretty=format:$'%h\t%C(green)%ad%C(reset) %C(yellow)%h%C(reset) %s %C(auto)%d%C(reset)' \
        --all |
        fzf \
          --multi=2 \
          --ansi \
          --delimiter=$'\t' \
          --with-nth=2.. \
          --no-sort \
          --tiebreak=index \
          --prompt='Hashes > ' \
          --header='TAB marks up to 2 commits, ENTER inserts hash/range, Ctrl-S toggles sort' \
          --preview "sh -c 'if [ \"\$#\" -ge 2 ]; then if git merge-base --is-ancestor \"\$1\" \"\$2\" >/dev/null 2>&1; then left=\$1 right=\$2; elif git merge-base --is-ancestor \"\$2\" \"\$1\" >/dev/null 2>&1; then left=\$2 right=\$1; else left=\$1 right=\$2; fi; git diff --color=always --stat --patch \"\$left..\$right\"; else git show --color=always --stat --patch --format=fuller \"\$1\"; fi' sh {+1}" \
          --preview-window='right,55%,border-none'
    )" || return 0

    selections=("${(@f)selection}")
    [[ ${#selections[@]} -gt 0 ]] || return 0

    local entry
    for entry in "${selections[@]}"; do
      hash="${entry%%$'\t'*}"
      [[ -n "$hash" ]] && hashes+=("$hash")
    done

    [[ ${#hashes[@]} -gt 0 ]] || return 0

    if (( ${#hashes[@]} >= 2 )); then
      range="$(__dotfiles_git_commit_range "${hashes[1]}" "${hashes[2]}")" || return 0

      if [[ "$LBUFFER" == (#b)(*git\ diff\ )([^[:space:]]##) && "${match[2]}" != *..* ]]; then
        LBUFFER="${match[1]}${range}"
      elif [[ "$LBUFFER" == (#b)(*gd\ )([^[:space:]]##) && "${match[2]}" != *..* ]]; then
        LBUFFER="${match[1]}${range}"
      else
        suffix=""
        [[ -n "$LBUFFER" && "$LBUFFER" != *[[:space:]] ]] && suffix=" "
        LBUFFER+="${suffix}${range}"
      fi

      zle redisplay
      return 0
    fi

    hash="${hashes[1]}"

    if [[ "$LBUFFER" == (#b)(*git\ diff\ )([^[:space:]]##) && "${match[2]}" != *..* ]]; then
      LBUFFER="${match[1]}${match[2]}..${hash}"
    elif [[ "$LBUFFER" == (#b)(*gd\ )([^[:space:]]##) && "${match[2]}" != *..* ]]; then
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
