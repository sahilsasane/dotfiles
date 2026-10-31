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
- `bin/sync-dotfiles`: copy the iTerm2 plist and `~/bin/tmxp` back into the repo
- `home/.zshenv`: the only file linked into `$HOME`; it sets the XDG base
  directories and `ZDOTDIR=~/.config/zsh`
- `config/<tool>/`: mirrors `~/.config/<tool>/`
  - `nvim/`: Neovim config, keymaps, plugins, lockfile
  - `kitty/`: Kitty config plus custom tab bar code
  - `ghostty/`: Ghostty config, themes, and shader experiments
  - `fastfetch/`: Fastfetch configuration
  - `atuin/`: Atuin history search config
  - `lazygit/`: Lazygit config and custom commands
  - `tldr/`: Catppuccin Latte and Mocha configurations for `tldr`
  - `eza/`: eza theme config
  - `ripgrep/`: ripgrep color configuration
  - `procs/`: process-list color and column configuration
  - `yazi/`: Yazi config and flavor assets
  - `zsh/`: shell config split into top-level loaders plus `profile.d/` and `rc.d/`
  - `tmux/`: tmux config, scripts, and themes
  - `rex/`: Rex keybindings that follow the tmux prefix workflow
  - `git/`: Git config, global ignore, theme includes, and gitk config
  - `fish/`: fish snippets
  - `htop/`: htop config
- `macos/`: files macOS reads from outside `~/.config`
  - `iterm2/`: iTerm2 preferences plist
  - `launchd/`: launchd template for automatic theme application

## Bootstrap A New Machine

Run:

```bash
./bin/bootstrap
```

That will:

- install the Homebrew packages in `Brewfile`
- clone `oh-my-zsh` and tmux plugins that the config expects
- symlink tracked config into `$HOME`

After bootstrap:

- open Neovim once so `lazy.nvim` installs plugins
- create `~/.zshrc.local` only if that machine needs local-only env vars
- run a new login shell so the refactored zsh loaders pick up the linked repo files

What `bin/install.sh` links:

- `home/.zshenv` into `~/.zshenv`
- each `config/<tool>` into `~/.config/<tool>`; Atuin, git, Kitty, and Lazygit
  get real directories with linked child files instead
- the iTerm2 plist into `~/Library/Preferences`
- `bin/lgai`, `bin/tmx`, `bin/ds`, and `bin/dotfiles-theme` into `~/.local/bin`

Framework code lives under `~/.local/share`: oh-my-zsh in
`~/.local/share/oh-my-zsh` and tmux plugins in `~/.local/share/tmux/plugins`.

What it does not currently link:

- `bin/tmxp` is tracked but remains repo-local unless linked manually
- Navi cheat sheets; the `navi` binary itself is installed through `Brewfile`
- local `uv/` metadata, which is intentionally ignored

Optional AI commit flow for Lazygit:

- install `aichat`: `brew install aichat`
- run `aichat` once and choose/configure your provider and model
- rerun `./bin/install.sh` if needed so Lazygit's config dir and `~/.local/bin/lgai` are linked
- in Lazygit, stage changes and press `CtrlG` from the files view
- `lgai` sends the staged diff plus recent commit subjects to `aichat`, generates one complete single-line Conventional Commit message covering the full staged change set, then opens it in `$VISUAL` or `$EDITOR` before committing

To switch from a cloud model to Ollama later, update your `aichat` model config. The Lazygit keybinding stays the same.
Because `.zshenv` exports `XDG_CONFIG_HOME`, `lazygit --print-config-dir` resolves to `~/.config/lazygit` on macOS too.

## Theme

Dark mode preserves the existing appearance. Light mode uses Catppuccin Latte
for every visual tool in this repository except iTerm2, which is intentionally
left unchanged. In an interactive zsh shell, use:

```sh
theme light
theme dark
theme auto
theme toggle
theme status
```

`light` and `dark` are manual overrides. `auto` follows macOS appearance every
30 seconds via `com.sahilsasane.dotfiles-theme`; it reads macOS but never changes
the system appearance. The same controller is available outside zsh as
`dotfiles-theme`. Kitty and tmux reload on switch when active; Neovim instances
watch the effective-mode file, while Ghostty, LazyGit, Atuin, eza, Yazi, gitk,
delta, bat, tldr, and htop use the new settings on their next supported reload
or launch.

The controller writes only `~/.config/dotfiles-theme/`. The installer keeps
Lazygit, Atuin, Kitty, and git as real config directories with linked child
files, so local state such as `lazygit/state.yml` stays in place.

## Colored Shell Commands

Interactive zsh applies the active Catppuccin palette to common command output:

- `rg` uses `config/ripgrep/ripgrep.conf` through `RIPGREP_CONFIG_PATH`; the command remains
  `rg` rather than a `batgrep` wrapper.
- `pwd`, `history`, `jobs`, and `du` use shell wrappers for readable interactive
  output. `pwd`, `jobs`, and `du` only add colors when stdout is a terminal;
  `history` can also color piped output.
- `procs` loads `config/procs/config.toml` automatically. `lsof` remains native and is
  not wrapped.
- Command-position highlighting uses bold Catppuccin blue for commands and
  mauve for aliases/builtins, while paths remain teal.

Set `NO_COLOR=1` for a plain invocation, for example:

```sh
NO_COLOR=1 history > history.txt
NO_COLOR=1 du -sh .
```

After changing the linked configuration, reload the shell with `rl` or start a
new login shell.

## Colored Help, Man Pages, and tldr

Help output can be highlighted through the existing global aliases:

```sh
kubectl H
kubectl HL
```

`HL` combines `--help`, stderr capture, Bat's `help` syntax, and the existing
`less` pager. Manual pages use Bat's `man` syntax through `MANPAGER`; `col -b`
removes macOS manpage overstrike control characters before highlighting.

The shell resolves normal command aliases when looking up documentation, so
these refer to the underlying command rather than the alias name:

```sh
tldr k       # tldr kubectl
man k        # man kubectl
tldr k get   # tldr kubectl get
tlb bat      # raw tldr Markdown rendered through Bat
```

The `tldr` client follows the active Catppuccin theme. The source configs are
`tldr/config-latte.toml` and `tldr/config-mocha.toml`; the theme controller
selects the active one at `~/.config/dotfiles-theme/tlrc.toml`.

## Sync From Current Machine

Run:

```bash
./bin/sync-dotfiles
```

Everything under `config/` and `home/` is symlinked, so edits already land in
the repo. The sync script only copies back the iTerm2 plist, which iTerm2
rewrites in binary form, and `~/bin/tmxp`.

## Secrets And Local State

Do not commit local secrets directly in tracked config.

For zsh, keep machine-specific env vars in:

```bash
~/.zshrc.local
```

Example values are in:

```bash
config/zsh/.zshrc.local.example
```

These are intentionally not tracked here:

- Keychain items such as `OPENAI_API_KEY` and Wiz credentials
- Docker auth state
- SSH keys
- kube credentials
- caches, sqlite files, logs, plugin download dirs, and backup dirs

## Notes

- `config/nvim/lazy-lock.json` is tracked so plugin versions stay pinned across machines.
- tmux plugins are installed under `~/.local/share/tmux/plugins`.
- This repo prefers portable paths like `~/.config/tmux/scripts` over machine-specific absolute paths.
- zsh is organized as small ordered modules:
  `config/zsh/profile.d/*.zsh` for login-time env and runtimes, and
  `config/zsh/rc.d/*.zsh` for interactive shell behavior.
- Reload Kitty config from inside a Kitty shell with `kitty @ load-config`.
