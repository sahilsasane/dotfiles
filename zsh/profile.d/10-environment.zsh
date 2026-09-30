if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
eval "$(thefuck --alias)"

typeset -aU path
path=(
  "$HOME/.dataos/v2/bin"
  "$HOME/.antigravity/antigravity/bin"
  "$HOME/.cargo/bin"
  /opt/homebrew/opt/libpq/bin
  "$HOME/bin"
  "$HOME/bin/rapidfort"
  "$HOME/.local/bin"
  /usr/local/bin
  $path
  /usr/local/go/bin
)

export LDFLAGS="-L/opt/homebrew/opt/libpq/lib -L/opt/homebrew/opt/openssl@3/lib ${LDFLAGS}"
export CPPFLAGS="-I/opt/homebrew/opt/libpq/include -I/opt/homebrew/opt/openssl@3/include ${CPPFLAGS}"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libpq/lib/pkgconfig:/opt/homebrew/opt/openssl@3/lib/pkgconfig:${PKG_CONFIG_PATH}"
export PG_CONFIG="/opt/homebrew/opt/libpq/bin/pg_config"
export LIBRARY_PATH="${LIBRARY_PATH:+$LIBRARY_PATH:}/usr/local/opt/openssl/lib/"
export PATH
