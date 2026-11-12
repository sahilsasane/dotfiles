# dotfiles

Personal macOS development setup for zsh, Neovim, Rex, tmux, Git, and terminal
tools. Configs live in this repository and are linked into the home directory.
Theme selections and application state live outside the repository.

This setup includes personal Git settings, DataOS integrations, and some
Apple Silicon and user-specific paths. Review those before using it on another
machine.

## Workspace map

| Path                                                                                                                                 | Contents                                                                        |
| ------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------- |
| [`Brewfile`](Brewfile)                                                                                                               | Homebrew packages, casks, VS Code extensions, and Go, Cargo, and npm packages   |
| [`bin/`](bin/)                                                                                                                       | Bootstrap, installer, theme controller, and command-line helpers                |
| [`home/.zshenv`](home/.zshenv)                                                                                                       | XDG directories and `ZDOTDIR=~/.config/zsh`                                     |
| [`config/zsh/`](config/zsh/)                                                                                                         | Ordered shell modules, Oh My Posh prompts, completions, fzf, and aliases        |
| [`config/nvim/`](config/nvim/)                                                                                                       | Neovim settings, plugin specs, custom Git line history, and plugin lockfile     |
| [`config/rex/`](config/rex/)                                                                                                         | Rex actions, pane bindings, Neovim scrollback viewer, and Extrakto picker       |
| [`config/tmux/`](config/tmux/)                                                                                                       | Pane and session workflow, plugins, themes, recording, and agent-status helpers |
| [`config/git/`](config/git/)                                                                                                         | Git aliases, Delta, global ignore rules, and gitk themes                        |
| [`config/kitty/`](config/kitty/), [`config/ghostty/`](config/ghostty/)                                                               | Terminal settings, themes, Kitty tab bar assets, and Ghostty cursor shaders     |
| [`config/atuin/`](config/atuin/), [`config/lazygit/`](config/lazygit/)                                                               | History search and Git UI settings with light and dark variants                 |
| [`config/yazi/`](config/yazi/)                                                                                                       | File manager settings and bundled Catppuccin flavors                            |
| [`config/tldr/`](config/tldr/), [`config/eza/`](config/eza/), [`config/ripgrep/`](config/ripgrep/), [`config/procs/`](config/procs/) | CLI themes and output settings                                                  |
| [`config/fastfetch/`](config/fastfetch/), [`config/htop/`](config/htop/), [`config/fish/`](config/fish/)                             | System-info settings, process viewer settings, and a fish uv snippet            |
| [`macos/`](macos/)                                                                                                                   | iTerm2 preferences, theme launch agent, and optional Karabiner rule             |
| [`fonts/sahil-mono/`](fonts/sahil-mono/README.md)                                                                                    | Reproducible JetBrains Mono variant for Rex                                     |
| [`benchmarks/rex-copy-mode/`](benchmarks/rex-copy-mode/README.md)                                                                    | Historical copy-mode measurements, fixtures, and benchmark script               |

## Set up a machine

Install Homebrew first. The full `Brewfile` also includes packages that use
Go, Cargo, npm, and VS Code. Have those tools available or adjust the manifest
for the machine.

Review [`config/git/config`](config/git/config) before linking it. It sets a
personal author name and email and rewrites GitHub and Bitbucket HTTPS URLs to
SSH. Shell, terminal, and DataOS settings also contain paths specific to this
Mac, including `/opt/homebrew` and `/Users/sahilsasane`.

From the repository root, run:

```sh
./bin/bootstrap
```

Bootstrap runs `brew bundle --file Brewfile`, then `bin/install.sh`. To rerun
the installer without the package bundle, use:

```sh
./bin/install.sh
```

The installer:

- Clones or fast-forwards Oh My Zsh into `~/.local/share/oh-my-zsh`.
- Clones or fast-forwards TPM, Catppuccin, tmux-cpu, and tmux-battery under
  `~/.local/share/tmux/plugins`, plus standalone Extrakto under
  `~/.local/share/extrakto`.
- Links `home/.zshenv` to `~/.zshenv` and configs to `~/.config/<tool>`.
  Atuin, Git, Kitty, and Lazygit keep real directories with selected child
  files linked into them.
- Links `lgai`, `tmx`, `ds`, and `dotfiles-theme` into `~/.local/bin`.
- Links the iTerm2 plist into `~/Library/Preferences`.
- Applies the selected theme and installs the macOS launch agent
  `com.sahilsasane.dotfiles-theme`.

Existing non-symlink targets are moved to `.backup.<timestamp>` before
replacement. Existing symlinks are replaced. The four real config directories
above retain unrelated files such as Lazygit's `state.yml`.

Finish setup after installation:

1. Start a new login shell with `exec zsh -l`.
2. Open `nvim` so lazy.nvim installs plugins. Mason installs the configured
   language servers and tools. `config/nvim/lazy-lock.json` pins plugin revisions.
3. Start tmux and press `Ctrl-Space`, then `Shift-I` to install the remaining
   plugins through TPM. These include Resurrect, Continuum, Floax, and SessionX.
4. Create `~/.zshrc.local` if the machine needs overrides. Use
   [`config/zsh/.zshrc.local.example`](config/zsh/.zshrc.local.example) as a starting point.

Additional setup is manual:

- Rex, Ghostty, Kitty, Karabiner-Elements, and fonts are not installed by
  `Brewfile`. Rex appearance is configured in the app's Settings.
- Build and install [Sahil Mono](fonts/sahil-mono/README.md) separately if you
  want the configured character variants in Rex. Keep Rex's Ligatures enabled.
- The optional [Fn prefix rule](macos/karabiner/README.md) has its own
  Karabiner installation steps.
- Kitty's custom `tab_bar.py` is tracked but not linked by the installer.
  Link it into `~/.config/kitty` if you use the configured custom tab bar.
- `bin/tmxp` and `bin/dsbox` remain repo-local. Link them manually if you want
  them on `PATH`. The shell's global `DS` alias expects `dsbox` on `PATH`.
- The installer does not link Navi cheat sheets or install DataOS CLI, uv,
  credentials, or local services used by the shell helpers.

## Use the shell and helpers

Zsh loads login settings from `config/zsh/profile.d/*.zsh` and interactive
settings from `config/zsh/rc.d/*.zsh`, in filename order. Non-login interactive
shells also load the environment and runtime modules. Oh My Zsh supplies the
Git plugin, while Oh My Posh renders the prompt, including the active DataOS
instance and tenant when local context files are available.

| Command or key                    | Action                                                                                         |
| --------------------------------- | ---------------------------------------------------------------------------------------------- |
| `rl`                              | Replace the current shell with a new login shell                                               |
| `Ctrl-R`                          | Search history with Atuin                                                                      |
| `Ctrl-T`                          | Find a file with fzf and a Bat preview                                                         |
| `Alt-C`                           | Find a directory with fzf                                                                      |
| `Ctrl-G` after `git diff` or `gd` | Insert a commit hash or a range selected with fzf                                              |
| `Ctrl-Y` / `Ctrl-]`               | Accept or clear a shell autosuggestion                                                         |
| `lg` / `lzd`                      | Open Lazygit or Lazydocker                                                                     |
| `v [directory]` / `vd`            | Activate `.venv` or the supplied environment, or deactivate the current environment            |
| `y`                               | Open Yazi and return to its selected directory                                                 |
| `fat <file>`                      | Pick a line with fzf and open it in the editor                                                 |
| `fcat <file>`                     | Browse a file through fzf                                                                      |
| `tmx`                             | Attach to or create a tmux session named after the Git root or current directory               |
| `./bin/tmxp`                      | Create a project session with code, services, cursor, and test windows, or attach if it exists |
| `ds`                              | Run DataOS CLI                                                                                 |
| `dg <type> <name> [args...]`      | Get a DataOS resource                                                                          |
| `dsfl <service-name>`             | Find a service container group and stream its logs                                             |
| `./bin/dsbox`                     | Redraw piped DataOS tables with rounded borders                                                |

Interactive output uses Bat, eza, ripgrep, procs, and shell wrappers for
`pwd`, `history`, `jobs`, and `du`. Set `NO_COLOR=1` on a wrapper invocation
when you need plain output:

```sh
NO_COLOR=1 history > history.txt
NO_COLOR=1 du -sh .
```

Help and manual-page helpers resolve command aliases such as `k` to `kubectl`:

```sh
kubectl H    # Highlight --help output with Bat
kubectl HP   # Highlight the help subcommand's output
man k
tldr k
```

`MANPAGER` removes manpage overstrike characters with `col -b` before passing
the text to Bat. `ATUIN_CONFIG_DIR` points to `~/.config/atuin`, and
`TLRC_CONFIG` points to the theme-selected tldr configuration.

## Use Rex and tmux

Both use `Ctrl-Space` as the prefix. Press and release it before the next key.
The current Rex pane bindings differ from tmux:

| Action                                     | Rex                          | tmux                                      |
| ------------------------------------------ | ---------------------------- | ----------------------------------------- |
| Focus a pane                               | `Alt-h/j/k/l`                | Prefix, then `h/j/k/l`                    |
| Resize a pane                              | Prefix, then `h/j/k/l`       | Prefix, then `Shift-h/j/k/l`              |
| Move a pane                                | Prefix, then `Shift-h/j/k/l` | No custom directional binding             |
| New tab or window in the current directory | Prefix, then `c`             | Prefix, then `c`                          |
| Zoom pane                                  | Prefix, then `z`             | Prefix, then `z`                          |
| Open scrollback copy mode                  | Prefix, then `[`             | Prefix, then `[`                          |
| Open Extrakto                              | Prefix, then `Ctrl-E`        | Prefix, then `Ctrl-E`                     |
| Open a floating shell                      | Prefix, then `Ctrl-P`        | Prefix, then `Shift-P` through Floax      |
| Browse sessions                            | Prefix, then `e` or `Ctrl-F` | Prefix, then `e`, or `f` through SessionX |
| Reload config                              | Prefix, then `r`             | Prefix, then `r`                          |

In Rex, the first resize or directional move enters resize mode. Continue
with `h/j/k/l` to resize or `Shift-h/j/k/l` to move. Press `Enter` or `q` to
leave that mode. New panes, tabs, and floating shells use the focused pane's
directory. `Cmd-K` clears shell scrollback and redraws the prompt, and
`Cmd-Backspace` sends `Ctrl-U` to clear the input line.

Rex copy mode opens a styled scrollback snapshot in a disposable Neovim
overlay. Use `v`, `V`, or `Ctrl-V` to select, then `Enter` to copy the selection
to the macOS clipboard and close. Use `/`, `?`, `n`, and `N` to search, or `s`
for Flash jumps. Flash loads on demand from the normal Neovim plugin
installation. Press `q` or normal-mode `Esc` to dismiss the viewer.

Rex's Extrakto picker uses the standalone filters installed under
`~/.local/share/extrakto`. `Tab` pastes the selection into the source pane,
`Enter` copies it, and `Ctrl-F` cycles word, all, and line filters. The picker
reads the active fzf palette without loading shell startup files.

In tmux, prefix followed by `|` or `-` splits in the current directory.
Copy mode uses vi keys, with `v` to start selecting, `Ctrl-V` to toggle a
rectangle, and `y` to copy and exit. Prefix followed by `Shift-R` toggles pane
recording to `${XDG_STATE_HOME:-~/.local/state}/tmux/logs`. The status line
also renders activity recorded by the Claude and Codex agent-status helpers.

## Use Neovim

The leader key is `Space`. Plugin specifications live in
`config/nvim/lua/plugins/`. Yazi handles directories, Snacks supplies search
pickers, Harpoon pins files, and Diffview and Lazygit handle Git workflows.

| Key or command                           | Action                                                                                 |
| ---------------------------------------- | -------------------------------------------------------------------------------------- |
| `<leader>e` or `-`                       | Open Yazi at the current file                                                          |
| `<leader>sf` / `<leader>sg`              | Find files or search text                                                              |
| `<leader>sF` / `<leader>sG`              | Include hidden and ignored files in file or text search                                |
| `<leader>sR`                             | Open project search and replace, using the word or visual selection                    |
| `<leader>a` / `Ctrl-E`                   | Pin a file or open the Harpoon menu                                                    |
| `grd`, `grr`, `gri`, `grt`               | Find definitions, references, implementations, or type definitions                     |
| `<leader>gg`                             | Open Lazygit                                                                           |
| `<leader>gd` / `<leader>gD`              | Open or close Diffview                                                                 |
| `<leader>gh` / `<leader>gH`              | Browse file or repository history                                                      |
| `<leader>gl`                             | Show Git history for the current line or selected lines through Delta                  |
| `<leader>f`                              | Format the buffer                                                                      |
| `:W` or `:WriteNoFormat`                 | Save once without automatic formatting                                                 |
| `<leader>tw` / `<leader>th`              | Toggle diagnostics or inlay hints globally                                             |
| `<leader>rs`, `<leader>rS`, `<leader>rl` | Restore the current directory's session, choose a session, or restore the last session |
| `:Rlc`, `:ReloadConfig`, or `<leader>tr` | Reload options, keymaps, and changed plugin specs                                      |
| `:Dls` in a YAML buffer                  | Attach the locally installed DataOS resource language server                           |

Line history requires a saved, tracked file whose selected lines match `HEAD`.
It opens `git log -L` output in a Delta pager. Press `q` to return to the file.
Session restoration is manual. Starting plain `nvim` does not restore a session.

Conform formats on save except for C and C++. Python uses ty as its default
language server and Ruff for import organization, fixes, and formatting.
Trusted project-local `.nvim.lua` files can set `vim.g.python_lsp` to `ty` or
`none`, and `vim.g.python_type_checker` to `lsp`, `ty`, or `none`. Choosing `ty`
as the type checker runs `ty check` through nvim-lint, preferring the project's
`.venv/bin/ty` when available.

The [Neovim workflow reference](config/nvim/doc/keymaps.md) covers more
navigation and editing commands. The Lua mappings are the source of truth.

## Generate a commit message

`aichat` is included in `Brewfile`. Run it once to configure a provider and
model. Stage changes, then press `Ctrl-G` in Lazygit's files view or run `lgai`
from the repository being committed.

`lgai` sends the staged file summary, a size-limited patch, lockfile version
changes, and recent commit subjects to the configured model. It generates a
Conventional Commit subject and bullet body, copies the message to the
clipboard, and opens it in `$VISUAL` or `$EDITOR` before running `git commit`.
Delete the message to cancel the commit. Change the provider in `aichat` to
use a different model without changing the Lazygit binding.

[`bin/lgai-generate.py`](bin/lgai-generate.py) records available OpenAI response
usage and cost in `.lgai-costs.jsonl` at the dotfiles repository root. The ledger
is ignored by Git. Costs come from the response when present or from the
helper's supported pricing estimate. Missing usage or unsupported pricing is
reported without blocking the commit flow.

## Switch themes

In an interactive zsh shell, use:

```sh
theme light
theme dark
theme auto
theme toggle
theme status
```

Use `dotfiles-theme` with the same arguments outside zsh, or `:Theme light`
and `:Theme dark` inside Neovim. The default is dark until you select a mode.
Light mode selects Catppuccin Latte for supported tools. Dark mode retains the
configured dark palettes.

`light` and `dark` are manual overrides. `auto` follows macOS appearance through
the launch agent every 30 seconds. The controller reads the system appearance
without changing it and writes selections under `~/.config/dotfiles-theme/`.
Rex appearance and iTerm2 preferences are configured separately.

Kitty reloads when invoked from a Kitty environment with remote control
available. Active tmux servers reload, and Neovim watches the effective-mode
file. The zsh `theme` function refreshes the current shell palette, fzf, and
prompt. Other open shells need `rl` or their own `theme` invocation. Ghostty,
Lazygit, Atuin, Git, and other CLI tools use their selected settings on the next
supported reload or launch. Reload Kitty manually with `kitty @ load-config`.

## Keep configs in sync

Edits through the installed config symlinks already change this repository.
For the files copied or rewritten outside those links, run:

```sh
./bin/sync-dotfiles
git status --short
git diff --check
```

The sync script copies `~/bin/tmxp` back when present and converts the installed
iTerm2 preferences to the repository's XML plist. Review the diff before
committing. It does not export other applications' state.

Keep credentials and machine-specific overrides in `~/.zshrc.local` or macOS
Keychain. The shell reads its configured API credentials from Keychain.
SSH keys, Docker auth, kube credentials, caches, logs, virtual environments,
plugin downloads, and the `lgai` cost ledger belong outside tracked config.

See [Contributing](CONTRIBUTING.md) for change and validation guidance, the
[Security Policy](.github/SECURITY.md) for vulnerability reports, and
[LICENSE](LICENSE) for licensing.
