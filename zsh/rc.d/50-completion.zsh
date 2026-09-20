autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

fpath=("$HOME/.docker/completions" $fpath)
autoload -Uz compinit
compinit
