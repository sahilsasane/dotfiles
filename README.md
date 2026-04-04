# dotfiles

Personal macOS/Linux-ish dotfiles and terminal setup.

## What's here

- `nvim/`: Neovim config, keymaps, plugins, UI
- `zsh/`: shell config and Powerlevel10k prompt
- `tmux/`: tmux config
- `git-config/`: Git config and global ignore
- `git/`: extra Git UI config
- `fish/`: fish shell snippets
- `htop/`: htop config
- `iterm2/`: iTerm2 preferences plist
- `bin/`: small helper scripts

## Sync from current machine

Run:

```bash
./bin/sync-dotfiles
```

This copies the current local config into this repo and keeps the repo copy sanitized.

## Secrets

Do not put local secrets directly in tracked config.

For zsh, keep machine-specific secrets in:

```bash
~/.zshrc.local
```

Example values are shown in:

```bash
zsh/.zshrc.local.example
```

## Notes

- Runtime/app state such as caches, sqlite files, plugin directories, and backups are intentionally ignored.
- `nvim/lazy-lock.json` is tracked so Neovim plugin versions stay pinned across machines.
