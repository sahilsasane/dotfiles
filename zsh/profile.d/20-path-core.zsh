typeset -aU path

path=(
  "$HOME/bin"
  "$HOME/bin/rapidfort"
  "$HOME/.local/bin"
  /usr/local/bin
  $path
)

export PATH
