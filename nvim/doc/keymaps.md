# Neovim Keymaps & Workflow Reference

## 1. The Core Fundamentals (Normal Mode)

### Basic Navigation

- `h` / `j` / `k` / `l` — Left, Down, Up, Right
- `w` / `b` — Jump forward/backward by **w**ord
- `W` / `B` — Jump forward/backward by **W**ord (ignores punctuation)
- `e` / `ge` — Jump to **e**nd of word (forward/backward)
- `0` — Absolute beginning of line
- `^` or `_` — First non-blank character of line
- `$` — End of line
- `gg` / `G` — Top of file / Bottom of file

### Screen Navigation

- `H` / `M` / `L` — Move cursor to **H**igh, **M**iddle, or **L**ow point of the visible screen
- `zz` — Center the screen on the cursor
- `zt` / `zb` — Put cursor line at the **T**op / **B**ottom of screen
- `Ctrl + d` / `Ctrl + u` — Scroll **D**own / **U**p half a page (cursor stays centered)

---

## 2. Advanced Horizontal Motions (Precision)

- `f{char}` / `F{char}` — **F**ind next/previous occurrence of `{char}`
- `t{char}` / `T{char}` — Jump **t**ill (just before/after) `{char}`
- `;` — Repeat last `f/t` motion forward
- `,` — Repeat last `f/t` motion backward
- `*` / `#` — Search forward/backward for the word under the cursor

---

## 3. Text Objects (The "Primeagen" Secret Sauce)

*Format: [Command] + [Inner/Around] + [Object]*

### The "I" (Inner) and "A" (Around) Objects

- `viw` — Select **i**nner **w**ord
- `vaw` — Select **a**round **w**ord (includes space)
- `vi"` — Select inside double quotes
- `ci{` — Change inside curly braces (deletes content + insert mode)
- `da(` — Delete around parentheses (includes the parens)
- `yiq` — Yank inside quotes (works in many plugins for any quote type)

### Paragraph & Block Motions

- `}` / `{` — Jump to next/previous empty line (Paragraph)
- `vip` — Select **i**nner **p**aragraph
- `dap` — Delete **a**round **p**aragraph (includes trailing newline)
- `%` — Jump between matching pairs (brackets, parens, tags)

---

## 4. Editing & Efficiency

- `x` — Delete character
- `u` / `Ctrl + r` — Undo / Redo
- `.` — **The Dot Command:** Repeat the last editing action
- `==` — Auto-indent current line
- `=ap` — Auto-indent the entire paragraph
- `>ap` — Indent paragraph / `<ap` — Outdent paragraph
- `Ctrl + a` / `Ctrl + x` — Increment / Decrement the next number
- `g Ctrl + a` — Sequential increment (useful for lists)

### Line Movement (Remapped)

- `Alt + j` — Move current line / selection **down**
- `Alt + k` — Move current line / selection **up**

> Works in both normal and visual mode. In visual mode, reselects after moving.

---

## 5. Selection & Registers (Copy/Paste)

- `v` — Visual mode (character)
- `V` — Visual **Line** mode
- `Ctrl + v` — Visual **Block** mode (Vertical editing)
- `o` — While in visual mode, jump to the **o**ther end of the selection
- `y` / `p` / `P` — Yank, Paste after, Paste before
- `Vy` or `Vd` — Primeagen's preferred way to yank/delete lines (faster than `yy`)
- `"_d` — Delete into the "Void Register" (doesn't overwrite your paste buffer)
- `<leader>p` — Paste from system clipboard (normal and visual mode)

---

## 6. Commands & File Management

- `:w` / `:q` / `:wq` — Write, Quit, Save & Quit
- `:q!` — Force quit without saving
- `:Ex` — Open NetRW file explorer
- `Ctrl + o` — Jump **back** to previous location (jump list) ← use this, not `<C-t>`
- `Ctrl + i` — Jump **forward** in location history
- `:%s/foo/bar/gc` — Search and Replace globally with **c**onfirmation

---

## 7. Window Management

- `<C-h>` / `<C-l>` / `<C-j>` / `<C-k>` — Move focus between splits
- `<leader>h` — Focus NERDTree window
- `<leader>l` — Focus code window (back from NERDTree)

---

## 8. The "Power User" Tools

### Macros

1. `q{register}` — Start recording (e.g., `qa`)
2. `[Your Actions]` — (Pro Tip: Start with `0`, end with `j`)
3. `q` — Stop recording
4. `@{register}` — Play once
5. `@@` — Play last used macro

### Quickfix List (Global Workflow)

- `:grep {pattern}` — Search project for `{pattern}`
- `:copen` — Open results list
- `:cn` / `:cp` — Go to **n**ext / **p**revious result
- `:cdo {cmd}` — Run a command on every line in the list

---

### The Primeagen Mental Model:

1. **Navigate** with `/` or `}`.
2. **Precision** with `f`, `t`, or `10j`.
3. **Edit** with **Text Objects** (`ci"`, `dap`).
4. **Repeat** with `.` or **Macros**.

---

## Code Review Workflow

### 1. Open the project

```
nvim .
```

### 2. Browse project structure

| What | Key |
| --- | --- |
| Toggle file explorer float | `<leader>e` |
| Open Oil in current dir | `-` |
| Show/hide dotfiles | `g.` inside Oil |
| Reveal current file in NERDTree | `<leader>n` |
| Focus NERDTree window | `<leader>h` |
| Focus code window | `<leader>l` |

### 3. Find files & search code

| What | Key |
| --- | --- |
| Find file by name | `<leader>sf` |
| Find ALL files (hidden + gitignored) | `<leader>sF` |
| Live grep across project | `<leader>sg` |
| Live grep with rg args | `<leader>sG` |
| Search word under cursor | `<leader>sw` |
| Search inside current buffer | `<leader>/` |
| Live grep in open buffers | `<leader>s/` |
| Recent files | `<leader>s.` |
| Switch open buffers | `<leader><leader>` |
| Search commands | `<leader>sc` |
| Search keymaps | `<leader>sk` |
| Search help tags | `<leader>sh` |
| Browse Telescope pickers | `<leader>ss` |
| Search nvim config files | `<leader>sn` |

> Add `.ignore` file in project root to exclude folders like `.venv`, `vendor`, `node_modules` from grep.

### 4. Code navigation

| What | Key |
| --- | --- |
| Go to definition | `grd` |
| Go to references | `grr` |
| Go to implementation | `gri` |
| Go to type definition | `grt` |
| Go to declaration | `grD` |
| Rename symbol | `grn` |
| Code action | `gra` |
| Hover docs | `K` |
| Symbols in file | `gO` |
| Symbols in workspace | `gW` |
| Jump back after `grd` | `<C-o>` |

### 5. Diagnostics

| What | Key |
| --- | --- |
| Next diagnostic | `]d` |
| Prev diagnostic | `[d` |
| Search all diagnostics | `<leader>sd` |
| Quickfix list | `<leader>q` |
| Toggle inlay hints | `<leader>th` |

### 6. Pin files with Harpoon

| What | Key |
| --- | --- |
| Pin current file | `<leader>a` |
| Harpoon menu | `<C-e>` |
| Jump to pin 1 | `<C-h>` |
| Jump to pin 2 | `<C-t>` |
| Jump to pin 3 | `<C-n>` |
| Jump to pin 4 | `<C-s>` |

> Note: `<C-h>` and `<C-t>` are claimed by Harpoon. Use `<C-o>` to jump back in the jump list, not `<C-t>`.

### 7. Git

| What | Key |
| --- | --- |
| Open lazygit | `<leader>gg` |

> Git hunk navigation (`]h`, `[h`) and hunk actions (`<leader>hp/hs/hb`) are not currently configured. Add an `on_attach` to gitsigns in `lua/plugins/git.lua` to enable them.

### 8. Formatting & LSP

| What | Key |
| --- | --- |
| Format buffer | `<leader>f` |

### Review mental flow

```
<leader>gg  → check what changed in this PR
<leader>sf  → open a changed file
grd         → dive into a function definition
K           → check what something does
grr         → see all usages
<C-o>       → jump back
<leader>a   → pin files you keep returning to
<leader>sg  → search patterns across codebase
]d / [d     → walk through any diagnostics/errors
Alt+j/k     → move lines around while refactoring
```
