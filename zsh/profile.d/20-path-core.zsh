typeset -aU path

path=(
  "$HOME/bin"
  "$HOME/bin/rapidfort"
  "$HOME/.local/bin"
  /usr/local/bin
  $path
)

# Homebrew's libpq/openssl build flags are macOS-only; on Linux the system
# libraries live in standard paths and need no extra flags.
if [[ -d /opt/homebrew/opt/libpq ]]; then
  export LDFLAGS="-L/opt/homebrew/opt/libpq/lib -L/opt/homebrew/opt/openssl@3/lib ${LDFLAGS}"
  export CPPFLAGS="-I/opt/homebrew/opt/libpq/include -I/opt/homebrew/opt/openssl@3/include ${CPPFLAGS}"
  export PKG_CONFIG_PATH="/opt/homebrew/opt/libpq/lib/pkgconfig:/opt/homebrew/opt/openssl@3/lib/pkgconfig:${PKG_CONFIG_PATH}"
  export PG_CONFIG="/opt/homebrew/opt/libpq/bin/pg_config"
fi

export PATH
