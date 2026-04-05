# dotfiles

Personal macOS-focused development dotfiles.

## What this repo is for

This repo is the source of truth for development behavior across machines:

- shell and prompt
- git aliases and diff tooling
- tmux workflow
- Neovim config and pinned plugins
- small terminal helpers
- terminal preferences that are worth carrying across

Secrets, auth, caches, and app state are intentionally out of scope.

## What's here

- `Brewfile`: core packages and casks used by this setup
- `bin/bootstrap`: install packages, clone framework dependencies, and link configs
- `bin/install.sh`: link tracked files into `$HOME`
- `bin/sync-dotfiles`: copy current machine config back into the repo and sanitize it
- `nvim/`: Neovim config, keymaps, plugins, lockfile
- `zsh/`: shell config split into top-level loaders plus `profile.d/` and `rc.d/`
- `tmux/`: tmux config using `~/.tmux.conf` and `~/.tmux/plugins`
- `git-config/`: Git config and global ignore
- `git/`: extra Git UI config
- `fish/`: fish snippets
- `htop/`: htop config
- `iterm2/`: iTerm2 preferences plist

## Bootstrap A New Machine

Run:

```bash
./bin/bootstrap
```

That will:

- install the Homebrew packages in `Brewfile`
- clone `oh-my-zsh`, `powerlevel10k`, and tmux plugins that the config expects
- symlink tracked config into `$HOME`

After bootstrap:

- open Neovim once so `lazy.nvim` installs plugins
- create `~/.zshrc.local` only if that machine needs local-only env vars
- run a new login shell so the refactored zsh loaders pick up the linked repo files

## Sync From Current Machine

Run:

```bash
./bin/sync-dotfiles
```

This copies the current local config into the repo and keeps the tracked copy sanitized and path-stable.
For zsh, the repo is the source of truth, so the sync script preserves the modular layout instead of rebuilding a single monolithic `~/.zshrc`.

## Secrets And Local State

Do not commit local secrets directly in tracked config.

For zsh, keep machine-specific env vars in:

```bash
~/.zshrc.local
```

Example values are in:

```bash
zsh/.zshrc.local.example
```

These are intentionally not tracked here:

- Keychain items such as `OPENAI_API_KEY` and Wiz credentials
- Docker auth state
- SSH keys
- kube credentials
- caches, sqlite files, logs, plugin download dirs, and backup dirs

## Notes

- `nvim/lazy-lock.json` is tracked so plugin versions stay pinned across machines.
- tmux plugins are installed under `~/.tmux/plugins`.
- This repo prefers portable paths like `~/.gitignore_global` over machine-specific absolute paths.
- zsh is organized as small ordered modules:
  `zsh/profile.d/*.zsh` for login-time env and runtimes, and
  `zsh/rc.d/*.zsh` for interactive shell behavior.
