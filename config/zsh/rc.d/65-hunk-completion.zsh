#compdef hunk
compdef _hunk hunk

_hunk() {
  local cur="$words[CURRENT]" node="" word valueFlag="" positional=0 fast=0 argStart=2 i
  local curcontext="$curcontext" state state_descr CURRENT="$CURRENT"
  local -a words=("${words[@]}")
  local -a args items line
  local -A opt_args
  for ((i = 2; i < CURRENT; i++)); do
    word="$words[i]"
    if [[ -n $valueFlag ]]; then
      valueFlag=""
      continue
    fi
    if [[ $word == -- ]]; then
      if [[ $node == " session reload" ]]; then
        node=""; fast=0; argStart=$((i + 1))
        continue
      fi
      positional=1
      break
    fi
    if [[ -z $node && $word == --fast ]]; then
      fast=1
      continue
    fi
    case "$node $word" in
      ' open'|' diff'|' show'|' status'|' log'|' stash'|' stash show'|' patch'|' pager'|' difftool'|' completion'|' completion bash'|' completion zsh'|' markup'|' markup render'|' markup guide'|' skill'|' skill path'|' skill show'|' extension'|' extension install'|' extension list'|' extension update'|' extension remove'|' ext'|' ext install'|' ext list'|' ext update'|' ext remove'|' update'|' daemon'|' daemon serve'|' daemon status'|' daemon restart'|' mcp'|' mcp serve'|' session'|' session list'|' session get'|' session context'|' session review'|' session navigate'|' session reload'|' session comment'|' session comment add'|' session comment apply'|' session comment list'|' session comment rm'|' session comment clear'|' session highlight'|' session highlight add'|' session highlight clear') node="$node $word"; argStart=$((i + 1)); continue ;;
    esac
    if [[ -z $node ]] && (( fast )); then
      case "$word" in
        '-h'|'--help'|'-v'|'--version'|'--experimental'|'--fast'|'--extension'|'--extension='*|'--no-extensions'|'--disable-extension'|'--disable-extension='*|'--enable-extension'|'--enable-extension='*) ;;
        *) node=" diff" ;;
      esac
    fi
    case "$node ${word%%=*}" in
      ' --extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' --disable-extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' --enable-extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' open --theme') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' open -x') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' open --tab-width') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' diff --mode') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' diff --cursor-line') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' diff --theme') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' diff --agent-context') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' diff -x') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' diff --tab-width') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' diff --file-gap') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' diff --hunk-gap') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' diff --wheel-scroll-lines') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' diff --scroll-off') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' diff --extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' diff --disable-extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' diff --enable-extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' diff --files') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' show --mode') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' show --cursor-line') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' show --theme') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' show --agent-context') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' show -x') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' show --tab-width') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' show --file-gap') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' show --hunk-gap') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' show --wheel-scroll-lines') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' show --scroll-off') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' show --extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' show --disable-extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' show --enable-extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' status --mode') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' status --cursor-line') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' status --theme') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' status -x') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' status --tab-width') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' status --file-gap') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' status --hunk-gap') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' status --wheel-scroll-lines') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' status --scroll-off') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' status --extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' status --disable-extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' status --enable-extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' status --vcs') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' status --color') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' log -n') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' log --max-count') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' log --author') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' log --grep') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' log --since') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' log --until') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' log --color') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' log --format') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' log --theme') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' log --vcs') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' log --extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' log --disable-extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' log --enable-extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' stash show --mode') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' stash show --cursor-line') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' stash show --theme') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' stash show --agent-context') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' stash show -x') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' stash show --tab-width') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' stash show --file-gap') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' stash show --hunk-gap') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' stash show --wheel-scroll-lines') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' stash show --scroll-off') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' stash show --extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' stash show --disable-extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' stash show --enable-extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' patch --mode') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' patch --cursor-line') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' patch --theme') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' patch --agent-context') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' patch -x') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' patch --tab-width') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' patch --file-gap') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' patch --hunk-gap') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' patch --wheel-scroll-lines') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' patch --scroll-off') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' patch --extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' patch --disable-extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' patch --enable-extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' pager --mode') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' pager --cursor-line') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' pager --theme') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' pager --agent-context') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' pager -x') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' pager --tab-width') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' pager --file-gap') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' pager --hunk-gap') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' pager --wheel-scroll-lines') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' pager --scroll-off') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' pager --extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' pager --disable-extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' pager --enable-extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' difftool --mode') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' difftool --cursor-line') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' difftool --theme') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' difftool --agent-context') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' difftool -x') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' difftool --tab-width') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' difftool --file-gap') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' difftool --hunk-gap') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' difftool --wheel-scroll-lines') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' difftool --scroll-off') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' difftool --extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' difftool --disable-extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' difftool --enable-extension') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' markup render --width') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' markup render --color') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' markup render --theme') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' update --method') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session get --repo') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session context --repo') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session review --repo') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session navigate --file') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session navigate --repo') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session navigate --hunk') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session navigate --old-line') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session navigate --new-line') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session navigate --comment') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session reload --repo') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session reload --session-path') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session reload --source') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session comment add --file') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session comment add --reply-to') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session comment add --summary') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session comment add --repo') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session comment add --old-line') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session comment add --new-line') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session comment add --rationale') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session comment add --markup') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session comment add --author') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session comment apply --repo') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session comment list --repo') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session comment list --file') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session comment list --type') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session comment rm --repo') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session comment clear --repo') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session comment clear --file') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session highlight add --file') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session highlight add --start') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session highlight add --end') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session highlight add --repo') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session highlight add --old-line') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session highlight add --new-line') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session highlight add --tone') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session highlight clear --repo') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
      ' session highlight clear --file') [[ $word != *=* ]] && valueFlag="$word"; continue ;;
    esac
  done
  if [[ -z $node ]] && (( fast )) && [[ -z $cur || $cur == -* ]]; then
    node=" diff"
  fi
  if (( positional )); then
    _files
    return
  fi
  case "$node" in
    '') args=('*-h[show help]' '*--help[show help]' '*-v[show version]' '*--version[show version]' '*--experimental[enable experimental features (currently STML agent-note markup)]' '*--fast[deprecated no-op; worker highlighting is now the default]' '*--extension=[load an extension entry file or directory (repeatable)]:value:_files' '*--no-extensions[disable user extensions for this run]' '*--disable-extension=[disable one bundled or user extension for this run (repeatable)]:value:_files' '*--enable-extension=[re-enable one extension for this run (repeatable)]:value:_files' '1:command:->command' '*:path:->path'); items=('open:view a complete file or browse a directory' 'diff:review diffs or compare two concrete files' 'show:review the last commit or a given ref' 'status:inspect the current workspace and sibling worktrees' 'log:browse repository history' 'stash' 'patch:review a patch file, or read a patch from stdin' 'pager:general Git pager wrapper with diff detection' 'difftool:review Git difftool file pairs' 'completion:print a shell completion script' 'markup' 'skill' 'extension' 'ext' 'update:update Hunk with the package manager that installed it' 'daemon' 'mcp' 'session') ;;
    ' open') args=('*-h[show help]' '*--help[show help]' '*--theme=[named theme override]:value:_files' '*--line-numbers[show line numbers]' '*--no-line-numbers[hide line numbers]' '*--sidebar[show the directory tree]' '*--no-sidebar[hide the directory tree]' '*--wrap[wrap long document lines]' '*--no-wrap[keep long document lines on one row]' '*-x+[tab stop width\: 1-16]:value:_files' '*--tab-width=[tab stop width\: 1-16]:value:_files' '*:path:->path'); items=() ;;
    ' diff') args=('*-h[show help]' '*--help[show help]' '*--mode=[layout mode\: auto, split, unified]:value:(auto split unified)' '*--cursor-line=[current-line marker\: row, number, off]:value:(row number off)' '*--theme=[named theme override]:value:_files' '*--agent-context=[JSON sidecar with agent rationale]:value:_files' '*--pager[use pager-style chrome]' '*--experimental[enable experimental features (currently STML agent-note markup)]' '*--line-numbers[show line numbers]' '*--no-line-numbers[hide line numbers]' '*-x+[tab stop width\: 1-16]:value:_files' '*--tab-width=[tab stop width\: 1-16]:value:_files' '*--file-gap=[file separator rows, including the ─ rule\: 0-8]:value:_files' '*--hunk-gap=[blank rows before each later hunk\: 0-8]:value:_files' '*--wheel-scroll-lines=[rows per wheel event\: auto or 1-10]:value:_files' '*--scroll-off=[rows the current line keeps clear of the viewport edge\: 0-40]:value:_files' '*--wrap[wrap long diff lines]' '*--no-wrap[truncate long diff lines to one row]' '*--hunk-headers[show hunk metadata rows]' '*--no-hunk-headers[hide hunk metadata rows]' '*--sidebar[show files pane]' '*--no-sidebar[hide files pane]' '*--agent-notes[show agent notes by default]' '*--no-agent-notes[hide agent notes by default]' '*--transparent-bg[let terminal background show through Hunk surfaces]' '*--no-transparent-bg[paint Hunk surfaces with the active theme]' '*--extension=[load an extension entry file or directory (repeatable)]:value:_files' '*--no-extensions[disable user extensions for this run]' '*--disable-extension=[disable one bundled or user extension for this run (repeatable)]:value:_files' '*--enable-extension=[re-enable one extension for this run (repeatable)]:value:_files' '*--watch[auto-reload when the current diff input changes]' '*--files=[compare exactly two concrete files\: --files <left> <right>]:value:_files' '*--staged[show staged changes instead of the working tree]' '*--cached[alias for --staged]' '*--exclude-untracked[exclude untracked files from working tree reviews]' '*:path:->path'); items=() ;;
    ' show') args=('*-h[show help]' '*--help[show help]' '*--mode=[layout mode\: auto, split, unified]:value:(auto split unified)' '*--cursor-line=[current-line marker\: row, number, off]:value:(row number off)' '*--theme=[named theme override]:value:_files' '*--agent-context=[JSON sidecar with agent rationale]:value:_files' '*--pager[use pager-style chrome]' '*--experimental[enable experimental features (currently STML agent-note markup)]' '*--line-numbers[show line numbers]' '*--no-line-numbers[hide line numbers]' '*-x+[tab stop width\: 1-16]:value:_files' '*--tab-width=[tab stop width\: 1-16]:value:_files' '*--file-gap=[file separator rows, including the ─ rule\: 0-8]:value:_files' '*--hunk-gap=[blank rows before each later hunk\: 0-8]:value:_files' '*--wheel-scroll-lines=[rows per wheel event\: auto or 1-10]:value:_files' '*--scroll-off=[rows the current line keeps clear of the viewport edge\: 0-40]:value:_files' '*--wrap[wrap long diff lines]' '*--no-wrap[truncate long diff lines to one row]' '*--hunk-headers[show hunk metadata rows]' '*--no-hunk-headers[hide hunk metadata rows]' '*--sidebar[show files pane]' '*--no-sidebar[hide files pane]' '*--agent-notes[show agent notes by default]' '*--no-agent-notes[hide agent notes by default]' '*--transparent-bg[let terminal background show through Hunk surfaces]' '*--no-transparent-bg[paint Hunk surfaces with the active theme]' '*--extension=[load an extension entry file or directory (repeatable)]:value:_files' '*--no-extensions[disable user extensions for this run]' '*--disable-extension=[disable one bundled or user extension for this run (repeatable)]:value:_files' '*--enable-extension=[re-enable one extension for this run (repeatable)]:value:_files' '*--watch[auto-reload when the current diff input changes]' '*:path:->path'); items=() ;;
    ' status') args=('*-h[show help]' '*--help[show help]' '*--mode=[layout mode\: auto, split, unified]:value:(auto split unified)' '*--cursor-line=[current-line marker\: row, number, off]:value:(row number off)' '*--theme=[named theme override]:value:_files' '*--experimental[enable experimental features (currently STML agent-note markup)]' '*--line-numbers[show line numbers]' '*--no-line-numbers[hide line numbers]' '*-x+[tab stop width\: 1-16]:value:_files' '*--tab-width=[tab stop width\: 1-16]:value:_files' '*--file-gap=[file separator rows, including the ─ rule\: 0-8]:value:_files' '*--hunk-gap=[blank rows before each later hunk\: 0-8]:value:_files' '*--wheel-scroll-lines=[rows per wheel event\: auto or 1-10]:value:_files' '*--scroll-off=[rows the current line keeps clear of the viewport edge\: 0-40]:value:_files' '*--wrap[wrap long diff lines]' '*--no-wrap[truncate long diff lines to one row]' '*--hunk-headers[show hunk metadata rows]' '*--no-hunk-headers[hide hunk metadata rows]' '*--sidebar[show files pane]' '*--no-sidebar[hide files pane]' '*--agent-notes[show agent notes by default]' '*--no-agent-notes[hide agent notes by default]' '*--transparent-bg[let terminal background show through Hunk surfaces]' '*--no-transparent-bg[paint Hunk surfaces with the active theme]' '*--extension=[load an extension entry file or directory (repeatable)]:value:_files' '*--no-extensions[disable user extensions for this run]' '*--disable-extension=[disable one bundled or user extension for this run (repeatable)]:value:_files' '*--enable-extension=[re-enable one extension for this run (repeatable)]:value:_files' '*--vcs=[select a VCS status provider]:value:_files' '*--static[print one snapshot, paging when needed]' '*--json[emit a version 1 JSON snapshot]' '*--color=[color output\: auto, always, never]:value:_files' '*:path:->path'); items=() ;;
    ' log') args=('*-h[show help]' '*--help[show help]' '*--all[include history from every provider-visible head]' '*--first-parent[follow only the first parent of merge commits]' '*-n+[stop after this many commits]:value:_files' '*--max-count=[stop after this many commits]:value:_files' '*--author=[limit commits by author]:value:_files' '*--grep=[limit commits by subject or message]:value:_files' '*--since=[show commits newer than a provider date]:value:_files' '*--until=[show commits older than a provider date]:value:_files' '*--color=[color output\: auto, always, never]:value:_files' '*--format=[static record format\: medium or compact]:value:_files' '*--oneline[alias for static --format compact]' '*--theme=[use the same theme as Hunk review]:value:_files' '*--ascii[use an ASCII graph]' '*--static[print static output, paging when needed]' '*--vcs=[select a VCS history provider]:value:_files' '*--extension=[load an extension entry file or directory (repeatable)]:value:_files' '*--no-extensions[disable user extensions for this run]' '*--disable-extension=[disable one bundled or user extension for this run (repeatable)]:value:_files' '*--enable-extension=[re-enable one extension for this run (repeatable)]:value:_files' '*:path:->path'); items=() ;;
    ' stash') args=('*-h[show help]' '*--help[show help]' '1:command:->command' '*:path:->path'); items=('show:review a stash entry as a full Hunk changeset') ;;
    ' stash show') args=('*-h[show help]' '*--help[show help]' '*--mode=[layout mode\: auto, split, unified]:value:(auto split unified)' '*--cursor-line=[current-line marker\: row, number, off]:value:(row number off)' '*--theme=[named theme override]:value:_files' '*--agent-context=[JSON sidecar with agent rationale]:value:_files' '*--pager[use pager-style chrome]' '*--experimental[enable experimental features (currently STML agent-note markup)]' '*--line-numbers[show line numbers]' '*--no-line-numbers[hide line numbers]' '*-x+[tab stop width\: 1-16]:value:_files' '*--tab-width=[tab stop width\: 1-16]:value:_files' '*--file-gap=[file separator rows, including the ─ rule\: 0-8]:value:_files' '*--hunk-gap=[blank rows before each later hunk\: 0-8]:value:_files' '*--wheel-scroll-lines=[rows per wheel event\: auto or 1-10]:value:_files' '*--scroll-off=[rows the current line keeps clear of the viewport edge\: 0-40]:value:_files' '*--wrap[wrap long diff lines]' '*--no-wrap[truncate long diff lines to one row]' '*--hunk-headers[show hunk metadata rows]' '*--no-hunk-headers[hide hunk metadata rows]' '*--sidebar[show files pane]' '*--no-sidebar[hide files pane]' '*--agent-notes[show agent notes by default]' '*--no-agent-notes[hide agent notes by default]' '*--transparent-bg[let terminal background show through Hunk surfaces]' '*--no-transparent-bg[paint Hunk surfaces with the active theme]' '*--extension=[load an extension entry file or directory (repeatable)]:value:_files' '*--no-extensions[disable user extensions for this run]' '*--disable-extension=[disable one bundled or user extension for this run (repeatable)]:value:_files' '*--enable-extension=[re-enable one extension for this run (repeatable)]:value:_files' '*--watch[auto-reload when the current diff input changes]' '*:path:->path'); items=() ;;
    ' patch') args=('*-h[show help]' '*--help[show help]' '*--mode=[layout mode\: auto, split, unified]:value:(auto split unified)' '*--cursor-line=[current-line marker\: row, number, off]:value:(row number off)' '*--theme=[named theme override]:value:_files' '*--agent-context=[JSON sidecar with agent rationale]:value:_files' '*--pager[use pager-style chrome]' '*--experimental[enable experimental features (currently STML agent-note markup)]' '*--line-numbers[show line numbers]' '*--no-line-numbers[hide line numbers]' '*-x+[tab stop width\: 1-16]:value:_files' '*--tab-width=[tab stop width\: 1-16]:value:_files' '*--file-gap=[file separator rows, including the ─ rule\: 0-8]:value:_files' '*--hunk-gap=[blank rows before each later hunk\: 0-8]:value:_files' '*--wheel-scroll-lines=[rows per wheel event\: auto or 1-10]:value:_files' '*--scroll-off=[rows the current line keeps clear of the viewport edge\: 0-40]:value:_files' '*--wrap[wrap long diff lines]' '*--no-wrap[truncate long diff lines to one row]' '*--hunk-headers[show hunk metadata rows]' '*--no-hunk-headers[hide hunk metadata rows]' '*--sidebar[show files pane]' '*--no-sidebar[hide files pane]' '*--agent-notes[show agent notes by default]' '*--no-agent-notes[hide agent notes by default]' '*--transparent-bg[let terminal background show through Hunk surfaces]' '*--no-transparent-bg[paint Hunk surfaces with the active theme]' '*--extension=[load an extension entry file or directory (repeatable)]:value:_files' '*--no-extensions[disable user extensions for this run]' '*--disable-extension=[disable one bundled or user extension for this run (repeatable)]:value:_files' '*--enable-extension=[re-enable one extension for this run (repeatable)]:value:_files' '*--watch[auto-reload when the current diff input changes]' '*:path:->path'); items=() ;;
    ' pager') args=('*-h[show help]' '*--help[show help]' '*--mode=[layout mode\: auto, split, unified]:value:(auto split unified)' '*--cursor-line=[current-line marker\: row, number, off]:value:(row number off)' '*--theme=[named theme override]:value:_files' '*--agent-context=[JSON sidecar with agent rationale]:value:_files' '*--pager[use pager-style chrome]' '*--experimental[enable experimental features (currently STML agent-note markup)]' '*--line-numbers[show line numbers]' '*--no-line-numbers[hide line numbers]' '*-x+[tab stop width\: 1-16]:value:_files' '*--tab-width=[tab stop width\: 1-16]:value:_files' '*--file-gap=[file separator rows, including the ─ rule\: 0-8]:value:_files' '*--hunk-gap=[blank rows before each later hunk\: 0-8]:value:_files' '*--wheel-scroll-lines=[rows per wheel event\: auto or 1-10]:value:_files' '*--scroll-off=[rows the current line keeps clear of the viewport edge\: 0-40]:value:_files' '*--wrap[wrap long diff lines]' '*--no-wrap[truncate long diff lines to one row]' '*--hunk-headers[show hunk metadata rows]' '*--no-hunk-headers[hide hunk metadata rows]' '*--sidebar[show files pane]' '*--no-sidebar[hide files pane]' '*--agent-notes[show agent notes by default]' '*--no-agent-notes[hide agent notes by default]' '*--transparent-bg[let terminal background show through Hunk surfaces]' '*--no-transparent-bg[paint Hunk surfaces with the active theme]' '*--extension=[load an extension entry file or directory (repeatable)]:value:_files' '*--no-extensions[disable user extensions for this run]' '*--disable-extension=[disable one bundled or user extension for this run (repeatable)]:value:_files' '*--enable-extension=[re-enable one extension for this run (repeatable)]:value:_files' '*:path:->path'); items=() ;;
    ' difftool') args=('*-h[show help]' '*--help[show help]' '*--mode=[layout mode\: auto, split, unified]:value:(auto split unified)' '*--cursor-line=[current-line marker\: row, number, off]:value:(row number off)' '*--theme=[named theme override]:value:_files' '*--agent-context=[JSON sidecar with agent rationale]:value:_files' '*--pager[use pager-style chrome]' '*--experimental[enable experimental features (currently STML agent-note markup)]' '*--line-numbers[show line numbers]' '*--no-line-numbers[hide line numbers]' '*-x+[tab stop width\: 1-16]:value:_files' '*--tab-width=[tab stop width\: 1-16]:value:_files' '*--file-gap=[file separator rows, including the ─ rule\: 0-8]:value:_files' '*--hunk-gap=[blank rows before each later hunk\: 0-8]:value:_files' '*--wheel-scroll-lines=[rows per wheel event\: auto or 1-10]:value:_files' '*--scroll-off=[rows the current line keeps clear of the viewport edge\: 0-40]:value:_files' '*--wrap[wrap long diff lines]' '*--no-wrap[truncate long diff lines to one row]' '*--hunk-headers[show hunk metadata rows]' '*--no-hunk-headers[hide hunk metadata rows]' '*--sidebar[show files pane]' '*--no-sidebar[hide files pane]' '*--agent-notes[show agent notes by default]' '*--no-agent-notes[hide agent notes by default]' '*--transparent-bg[let terminal background show through Hunk surfaces]' '*--no-transparent-bg[paint Hunk surfaces with the active theme]' '*--extension=[load an extension entry file or directory (repeatable)]:value:_files' '*--no-extensions[disable user extensions for this run]' '*--disable-extension=[disable one bundled or user extension for this run (repeatable)]:value:_files' '*--enable-extension=[re-enable one extension for this run (repeatable)]:value:_files' '*--watch[auto-reload when the current diff input changes]' '*:path:->path'); items=() ;;
    ' completion') args=('*-h[show help]' '*--help[show help]' '1:command:->command' '*:path:->path'); items=('bash:print the bash completion script' 'zsh:print the zsh completion script') ;;
    ' completion bash') args=('*-h[show help]' '*--help[show help]' '*:path:->path'); items=() ;;
    ' completion zsh') args=('*-h[show help]' '*--help[show help]' '*:path:->path'); items=() ;;
    ' markup') args=('*-h[show help]' '*--help[show help]' '1:command:->command' '*:path:->path'); items=('render:preview experimental STML markup as terminal text' 'guide:print the experimental STML authoring guide') ;;
    ' markup render') args=('*-h[show help]' '*--help[show help]' '*--width=[layout width in columns]:value:_files' '*--color=[auto, always, or never]:value:_files' '*--theme=[hunk theme used to resolve colors]:value:_files' '*--json[emit structured JSON]' '*:path:->path'); items=() ;;
    ' markup guide') args=('*-h[show help]' '*--help[show help]' '*:path:->path'); items=() ;;
    ' skill') args=('*-h[show help]' '*--help[show help]' '1:command:->command' '*:path:->path'); items=('path:print a bundled Hunk skill path' 'show:print a bundled Hunk skill') ;;
    ' skill path') args=('*-h[show help]' '*--help[show help]' '*:path:->path'); items=() ;;
    ' skill show') args=('*-h[show help]' '*--help[show help]' '*:path:->path'); items=() ;;
    ' extension') args=('*-h[show help]' '*--help[show help]' '1:command:->command' '*:path:->path'); items=('install:install a shared extension from Git or npm' 'list:list extensions installed with `hunk extension install`' 'update:update managed extension installs from their recorded sources' 'remove:remove one managed extension install') ;;
    ' extension install') args=('*-h[show help]' '*--help[show help]' '*--yes[skip the confirmation prompt (required without a TTY)]' '*:path:->path'); items=() ;;
    ' extension list') args=('*-h[show help]' '*--help[show help]' '*:path:->path'); items=() ;;
    ' extension update') args=('*-h[show help]' '*--help[show help]' '*:path:->path'); items=() ;;
    ' extension remove') args=('*-h[show help]' '*--help[show help]' '*:path:->path'); items=() ;;
    ' ext') args=('*-h[show help]' '*--help[show help]' '1:command:->command' '*:path:->path'); items=('install:install a shared extension from Git or npm' 'list:list extensions installed with `hunk extension install`' 'update:update managed extension installs from their recorded sources' 'remove:remove one managed extension install') ;;
    ' ext install') args=('*-h[show help]' '*--help[show help]' '*--yes[skip the confirmation prompt (required without a TTY)]' '*:path:->path'); items=() ;;
    ' ext list') args=('*-h[show help]' '*--help[show help]' '*:path:->path'); items=() ;;
    ' ext update') args=('*-h[show help]' '*--help[show help]' '*:path:->path'); items=() ;;
    ' ext remove') args=('*-h[show help]' '*--help[show help]' '*:path:->path'); items=() ;;
    ' update') args=('*-h[show help]' '*--help[show help]' '*--method=[install method instead of the detected one\: npm, brew, curl]:value:(npm brew curl)' '*--check[report the installed and available versions without installing]' '*:path:->path'); items=() ;;
    ' daemon') args=('*-h[show help]' '*--help[show help]' '1:command:->command' '*:path:->path'); items=('serve:run the local Hunk session daemon and websocket session broker' 'status:report the running session daemon'\''s build, uptime, and attached windows' 'restart:stop the running session daemon and start one from this Hunk build') ;;
    ' daemon serve') args=('*-h[show help]' '*--help[show help]' '*:path:->path'); items=() ;;
    ' daemon status') args=('*-h[show help]' '*--help[show help]' '*--json[print the status as JSON]' '*:path:->path'); items=() ;;
    ' daemon restart') args=('*-h[show help]' '*--help[show help]' '*--yes[skip the confirmation prompts (required when stdin is not a terminal)]' '*--json[print the result as JSON]' '*:path:->path'); items=() ;;
    ' mcp') args=('*-h[show help]' '*--help[show help]' '1:command:->command' '*:path:->path'); items=('serve:run the local Hunk session daemon and websocket session broker') ;;
    ' mcp serve') args=('*-h[show help]' '*--help[show help]' '*:path:->path'); items=() ;;
    ' session') args=('*-h[show help]' '*--help[show help]' '1:command:->command' '*:path:->path'); items=('list:list live Hunk sessions' 'get:show one live Hunk session' 'context:show the selected file and hunk for one live Hunk session' 'review:export the live review model for one Hunk session' 'navigate:move a live Hunk session to one diff hunk' 'reload:replace the contents of one live Hunk session' 'comment' 'highlight') ;;
    ' session list') args=('*-h[show help]' '*--help[show help]' '*--json[emit structured JSON]' '*:path:->path'); items=() ;;
    ' session get') args=('*-h[show help]' '*--help[show help]' '*--repo=[target the live session whose repo root matches this path]:value:_files' '*--json[emit structured JSON]' '*:path:->path'); items=() ;;
    ' session context') args=('*-h[show help]' '*--help[show help]' '*--repo=[target the live session whose repo root matches this path]:value:_files' '*--json[emit structured JSON]' '*:path:->path'); items=() ;;
    ' session review') args=('*-h[show help]' '*--help[show help]' '*--repo=[target the live session whose repo root matches this path]:value:_files' '*--include-patch[include raw unified diff text for each file in review output]' '*--include-notes[include live review notes in review output]' '*--json[emit structured JSON]' '*:path:->path'); items=() ;;
    ' session navigate') args=('*-h[show help]' '*--help[show help]' '*--file=[diff file path as shown by Hunk]:value:_files' '*--repo=[target the live session whose repo root matches this path]:value:_files' '*--hunk=[1-based hunk number within the file]:value:_files' '*--old-line=[1-based line number on the old side]:value:_files' '*--new-line=[1-based line number on the new side]:value:_files' '*--comment=[jump to the live comment with this id]:value:_files' '*--next-comment[jump to the next annotated hunk]' '*--prev-comment[jump to the previous annotated hunk]' '*--json[emit structured JSON]' '*:path:->path'); items=() ;;
    ' session reload') args=('*-h[show help]' '*--help[show help]' '*--repo=[target the live session whose repo root matches this path]:value:_files' '*--session-path=[target a live session rooted at a different path]:value:_files' '*--source=[load the diff from this directory instead of the session'\''s own]:value:_files' '*--json[emit structured JSON]' '*:path:->path'); items=() ;;
    ' session comment') args=('*-h[show help]' '*--help[show help]' '1:command:->command' '*:path:->path'); items=('add:attach one live inline review note' 'apply:apply many live inline review notes from stdin JSON' 'list:list live inline review notes' 'rm:remove one inline review note' 'clear:clear inline review notes') ;;
    ' session comment add') args=('*-h[show help]' '*--help[show help]' '*--file=[diff file path as shown by Hunk]:value:_files' '*--reply-to=[reply to an existing note at its anchor]:value:_files' '*--summary=[short review note]:value:_files' '*--repo=[target the live session whose repo root matches this path]:value:_files' '*--old-line=[1-based line number on the old side]:value:_files' '*--new-line=[1-based line number on the new side]:value:_files' '*--rationale=[optional longer explanation]:value:_files' '*--markup=[experimental STML body (target session must opt in)]:value:_files' '*--author=[optional author label]:value:_files' '*--focus[add the note and focus the viewport on it]' '*--json[emit structured JSON]' '*:path:->path'); items=() ;;
    ' session comment apply') args=('*-h[show help]' '*--help[show help]' '*--repo=[target the live session whose repo root matches this path]:value:_files' '*--stdin[read the comment batch from stdin as JSON]' '*--focus[apply the batch and focus the first note]' '*--json[emit structured JSON]' '*:path:->path'); items=() ;;
    ' session comment list') args=('*-h[show help]' '*--help[show help]' '*--repo=[target the live session whose repo root matches this path]:value:_files' '*--file=[filter comments to one diff file]:value:_files' '*--type=[filter to live, all, ai, agent, or user comments]:value:_files' '*--json[emit structured JSON]' '*:path:->path'); items=() ;;
    ' session comment rm') args=('*-h[show help]' '*--help[show help]' '*--repo=[target the live session whose repo root matches this path]:value:_files' '*--json[emit structured JSON]' '*:path:->path'); items=() ;;
    ' session comment clear') args=('*-h[show help]' '*--help[show help]' '*--repo=[target the live session whose repo root matches this path]:value:_files' '*--file=[clear only one diff file'\''s comments]:value:_files' '*--include-user[also clear human notes created with the TUI `c` action]' '*--all[clear both live agent comments and human user notes]' '*--yes[confirm destructive comment clearing]' '*--json[emit structured JSON]' '*:path:->path'); items=() ;;
    ' session highlight') args=('*-h[show help]' '*--help[show help]' '1:command:->command' '*:path:->path'); items=('add:paint one attention mark inside a diff line' 'clear:clear agent attention marks') ;;
    ' session highlight add') args=('*-h[show help]' '*--help[show help]' '*--file=[diff file path as shown by Hunk]:value:_files' '*--start=[0-based inclusive start offset into the line'\''s text (UTF-16 code units)]:value:_files' '*--end=[exclusive end offset; must be greater than --start]:value:_files' '*--repo=[target the live session whose repo root matches this path]:value:_files' '*--old-line=[1-based line number on the old side]:value:_files' '*--new-line=[1-based line number on the new side]:value:_files' '*--tone=[mark tone\: match, current, info, warning, error, dim (default match)]:value:_files' '*--focus[add the mark and land the viewport on its line]' '*--json[emit structured JSON]' '*:path:->path'); items=() ;;
    ' session highlight clear') args=('*-h[show help]' '*--help[show help]' '*--repo=[target the live session whose repo root matches this path]:value:_files' '*--file=[clear only one diff file'\''s marks]:value:_files' '*--json[emit structured JSON]' '*:path:->path'); items=() ;;
  esac
  words=(hunk "${(@)words[argStart,-1]}")
  CURRENT=$((CURRENT - argStart + 2))
  _arguments -S -s "${args[@]}" && return
  if [[ $cur != -* ]]; then
    case "$state" in
      command) _describe -t commands command items ;;
      path) _files ;;
    esac
  fi
}

if [ "$funcstack[1]" = "_hunk" ]; then
  _hunk
fi
