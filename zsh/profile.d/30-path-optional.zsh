typeset -aU path

if [[ -d /opt/homebrew/opt/libpq/bin ]]; then
  path=(/opt/homebrew/opt/libpq/bin $path)
fi

if [[ -d "$HOME/.cargo/bin" ]]; then
  path=("$HOME/.cargo/bin" $path)
fi

if [[ -d "$HOME/.antigravity/antigravity/bin" ]]; then
  path=("$HOME/.antigravity/antigravity/bin" $path)
fi

if [[ -d "$HOME/.dataos/v2/bin" ]]; then
  path=("$HOME/.dataos/v2/bin" $path)
fi

if [[ -d /usr/local/go/bin ]]; then
  path=($path /usr/local/go/bin)
fi

if [[ -d /usr/local/opt/openssl/lib ]]; then
  export LIBRARY_PATH="${LIBRARY_PATH:+$LIBRARY_PATH:}/usr/local/opt/openssl/lib/"
fi

export PATH
