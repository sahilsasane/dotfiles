#!/usr/bin/env python3
"""Claude and Codex activity per tmux pane, written by their hooks and rendered in status-right."""
import fcntl
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time

FIELDS = ('kind', 'pid', 'phase', 'since', 'subagents')
SNAPSHOT = re.compile(r'/\.(?:claude/shell-snapshots|codex/shell_snapshots)/')
ICON = Path(__file__).with_name('app-icon.sh')
WAITING = 'waiting for you'


def tmux(*args):
    return subprocess.check_output(['tmux', *args], text=True, stderr=subprocess.DEVNULL).strip()


def detail(tool, data):
    if not isinstance(data, dict):
        return ''
    command = data.get('command') or data.get('cmd')
    if command:
        words = command if isinstance(command, list) else str(command).split()
        return Path(words[0]).name if words else ''
    if data.get('description'):
        return str(data['description'])
    path = data.get('file_path') or data.get('path') or data.get('notebook_path')
    return Path(str(path)).name if path else ''


def apply(state, event, now):
    name = event.get('hook_event_name')
    state = dict(state)
    if name in ('SubagentStart', 'SubagentStop'):
        state['subagents'] = str(max(0, int(state.get('subagents') or 0) + (1 if name == 'SubagentStart' else -1)))
        return state
    if event.get('agent_id'):
        return state
    if name in ('SessionStart', 'SessionEnd'):
        return {}
    if name in ('Stop', 'StopFailure') or event.get('is_interrupt'):
        state.update(phase='', since='')
        return state
    if name == 'Notification':
        if state.get('phase'):
            state['phase'] = WAITING
        return state
    if name == 'UserPromptSubmit':
        state.update(phase='thinking', since=str(int(now)))
        return state
    if name == 'PreToolUse':
        tool = event.get('tool_name') or 'tool'
        if tool == 'AskUserQuestion':
            state['phase'] = WAITING
        else:
            state['phase'] = f'{tool} {detail(tool, event.get("tool_input"))}'.strip()
    elif name in ('PostToolUse', 'PostToolUseFailure'):
        state['phase'] = 'thinking'
    if state.get('phase') and not state.get('since'):
        state['since'] = str(int(now))
    return state


def elapsed(seconds):
    seconds = max(0, int(seconds))
    if seconds < 60:
        return f'{seconds}s'
    if seconds < 3600:
        return f'{seconds // 60}m{seconds % 60:02d}'
    return f'{seconds // 3600}h{seconds % 3600 // 60:02d}'


def entry(icon, location, state, shells, now):
    phase = state.get('phase', '')
    subagents = int(state.get('subagents') or 0)
    if not phase and not subagents and not shells:
        return ''
    color = 'yellow' if phase == WAITING else 'blue' if phase else 'brightblack'
    text = f'{icon} {location} {phase[:28] or "idle"}'
    if phase and state.get('since'):
        text += f' {elapsed(now - int(state["since"]))}'
    if subagents:
        text += f' +{subagents}sa'
    if shells:
        text += f' bg{shells}'
    return f'#[fg={color}]{text}#[default]'


def line(panes, processes, now):
    shells = {}
    orphans = 0
    for pid, parent, command in processes:
        if SNAPSHOT.search(command):
            if parent == 1:
                orphans += 1
            else:
                shells[parent] = shells.get(parent, 0) + 1
    parts = [entry(icon, location, state, shells.get(int(state['pid']), 0), now) for icon, location, state in panes]
    if orphans:
        parts.append(f'#[fg=red]orphans {orphans}#[default]')
    parts = [part for part in parts if part]
    return '#[fg=brightblack] · #[default]'.join(parts) + (' | ' if parts else '')


def alive(pid):
    try:
        os.kill(int(pid), 0)
        return True
    except (ValueError, ProcessLookupError):
        return False
    except PermissionError:
        return True


def render():
    format_ = '\t'.join(['#{pane_id}', '#{session_name}:#{window_index}'] + [f'#{{@agent_{field}}}' for field in FIELDS])
    panes = []
    icons = {}
    for row in tmux('list-panes', '-a', '-F', format_).splitlines():
        pane, location, *values = row.split('\t')
        state = dict(zip(FIELDS, values + [''] * len(FIELDS)))
        if not state['kind']:
            continue
        if not alive(state['pid']):
            for field in FIELDS:
                tmux('set-option', '-pu', '-t', pane, f'@agent_{field}')
            continue
        if state['kind'] not in icons:
            icons[state['kind']] = subprocess.run(['bash', str(ICON), state['kind']], capture_output=True, text=True).stdout
        panes.append((icons[state['kind']], location, state))
    processes = []
    for row in subprocess.check_output(['ps', '-axo', 'pid=,ppid=,command='], text=True).splitlines():
        fields = row.split(None, 2)
        if len(fields) == 3:
            processes.append((int(fields[0]), int(fields[1]), fields[2]))
    print(line(panes, processes, time.time()))


def hook(kind):
    pane = os.environ.get('TMUX_PANE')
    if not os.environ.get('TMUX') or not pane:
        return
    event = json.load(sys.stdin)
    lock = Path(tempfile.gettempdir()) / f'dotfiles-agent-{os.getuid()}-{pane.lstrip("%")}.lock'
    fd = os.open(lock, os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        values = tmux('display-message', '-p', '-t', pane, '\t'.join(f'#{{@agent_{field}}}' for field in FIELDS)).split('\t')
        state = {field: value for field, value in zip(FIELDS, values) if value}
        state = apply(state, event, time.time())
        state.update(kind=kind, pid=str(os.getppid()))
        for field in FIELDS:
            if state.get(field):
                tmux('set-option', '-p', '-t', pane, f'@agent_{field}', state[field])
            else:
                tmux('set-option', '-pu', '-t', pane, f'@agent_{field}')
    finally:
        os.close(fd)


if __name__ == '__main__':
    try:
        hook(sys.argv[2]) if sys.argv[1:2] == ['hook'] else render()
    except (subprocess.CalledProcessError, json.JSONDecodeError, OSError):
        pass  # Status must never block an agent turn or the status line.
