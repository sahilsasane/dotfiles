alias v='source .venv/bin/activate'
alias vd='deactivate 2>/dev/null || true'
alias size='du -sh -- *(DN) 2>/dev/null | sort -rh'
alias c='clear'
alias cls="printf '\033[2J\033[3J\033[H'"
alias h='history'
alias j='jobs -l'
alias path='echo $PATH | tr ":" "\n"'
alias rl='source ~/.zprofile && source ~/.zshrc && exec zsh'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -pv'
alias ports='lsof -i -P -n | grep LISTEN'
alias cd='z'
alias lg='lazygit'
alias lzd='lazydocker'
alias tk='tmux kill-session -t'
alias t='tmux attach -t'
alias k='kubectl'
alias rg='rg --color=always'
alias f='fzf --preview="bat --color=always {}"'
alias vim='nvim'
alias gal='git add --all'
alias ff='fastfetch --config "$DOTFILES_ZSH_DIR/../fastfetch/config.jsonc"'
alias cat='bat --style=plain'

alias -s md='bat'
alias -s yaml='bat'
alias -s yml='bat'
alias -s py='nvim'
alias -s json='jless'
alias -s txt='bat --color=always'

alias -g NE='2>/dev/null'
alias -g DN='> /dev/null'
alias -g NUL='>/dev/null 2>&1'
alias -g C='| pbcopy'
alias -g JQ='| jq'
alias -g F='| fzf'
alias -g R='| rg'
alias -g L='| less -R'
alias -g H='--help | bat --style=plain --language=help --color=always'
alias -g HL='--help 2>&1 | bat --style=plain --language=help --color=always | less -R'
alias -g V='--version'

__dotfiles_doc_command() {
  local name="$1" alias_value
  local -a alias_words

  alias_value="${aliases[$name]-}"
  if [[ -z "$alias_value" ]]; then
    print -r -- "$name"
    return 0
  fi

  alias_words=("${(z)alias_value}")
  if (( ${#alias_words[@]} == 0 )) || [[ "${alias_words[1]}" == -* ]]; then
    print -r -- "$name"
    return 0
  fi

  print -r -- "${alias_words[1]}"
}

tldr() {
  local -a args=("$@")
  if (( $# > 0 )) && [[ "$1" != -* ]]; then
    args[1]="$(__dotfiles_doc_command "$1")"
  fi
  command tldr "${args[@]}"
}

man() {
  local -a args=("$@")
  if (( $# > 0 )) && [[ "$1" != -* ]]; then
    args[1]="$(__dotfiles_doc_command "$1")"
  fi
  MANPAGER="${MANPAGER:-bat --style=plain --language=man}" command man "${args[@]}"
}
