#!/usr/bin/env python3
"""Pane-scoped Claude progress for Ghostty; idle watchers sleep in tmux wait-for."""
import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time

OPTION = '@dotfiles_claude_progress'
CHANNEL = 'dotfiles-claude-progress'


def tmux(*args):
    return subprocess.check_output(['tmux', *args], text=True, stderr=subprocess.DEVNULL).strip()


def emit(tty, state, progress=0):
    try:
        fd = os.open(tty, os.O_WRONLY | os.O_NOCTTY | os.O_NONBLOCK)
        try:
            os.write(fd, f'\033]9;4;{state};{progress}\007'.encode())
        finally:
            os.close(fd)
    except OSError:
        pass  # A client can detach between listing it and opening its terminal.


def alive(pid):
    try:
        os.kill(int(pid), 0)
        return True
    except (ValueError, ProcessLookupError):
        return False


def watch():
    socket = tmux('display-message', '-p', '#{socket_path}')
    identity = hashlib.sha256(socket.encode()).hexdigest()[:16]
    lock = Path(tempfile.gettempdir()) / f'dotfiles-progress-{os.getuid()}-{identity}.lock'
    fd = os.open(lock, os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        os.close(fd)
        return
    showing = {}
    try:
        while True:
            rows = tmux(
                'list-panes', '-a', '-F', f'P\t#{{pane_id}}\t#{{{OPTION}}}',
                ';', 'list-clients', '-F',
                f'C\t#{{client_tty}}\t#{{client_termname}}\t#{{pane_id}}\t#{{pane_pb_state}}\t#{{pane_pb_progress}}',
            ).splitlines()
            busy = set()
            clients = []
            for row in rows:
                fields = row.split('\t')
                if fields[0] == 'P' and len(fields) == 3 and fields[2]:
                    if alive(fields[2]):
                        busy.add(fields[1])
                    else:
                        tmux('set-option', '-pu', '-t', fields[1], OPTION)
                elif fields[0] == 'C' and len(fields) == 6:
                    clients.append(fields[1:])
            now = time.monotonic()
            current = set()
            for tty, terminal, pane, native_state, progress in clients:
                current.add(tty)
                if terminal == 'xterm-ghostty' and pane in busy:
                    if tty not in showing or now - showing[tty] >= 3:
                        emit(tty, 3)
                        showing[tty] = now
                elif tty in showing:
                    # Restore another application's native tmux progress, if any.
                    state = {'normal': 1, 'error': 2, 'indeterminate': 3, 'paused': 4}.get(native_state, 0)
                    emit(tty, state, int(progress or 0))
                    del showing[tty]
            for tty in showing.keys() - current:
                emit(tty, 0)
                del showing[tty]
            if busy:
                time.sleep(0.5)
            else:
                tmux('wait-for', CHANNEL)
    except subprocess.CalledProcessError:
        pass  # The tmux server has exited.
    finally:
        for tty in showing:
            emit(tty, 0)
        os.close(fd)


def hook():
    if not os.environ.get('TMUX') or not os.environ.get('TMUX_PANE'):
        return
    event = json.load(sys.stdin)
    if event.get('agent_id'):
        return
    name = event.get('hook_event_name')
    busy = name in ('UserPromptSubmit', 'PreToolUse', 'PostToolUse', 'PostToolUseFailure')
    if name == 'PreToolUse' and event.get('tool_name') == 'AskUserQuestion':
        busy = False
    if event.get('is_interrupt'):
        busy = False
    pane = os.environ['TMUX_PANE']
    if busy:
        # The hook command uses exec, so its parent is the owning Claude process.
        tmux('set-option', '-p', '-t', pane, OPTION, str(os.getppid()))
        subprocess.Popen(
            [sys.executable, str(Path(__file__).resolve()), '--watch'],
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    else:
        tmux('set-option', '-pu', '-t', pane, OPTION)
    tmux('wait-for', '-S', CHANNEL)


if __name__ == '__main__':
    try:
        watch() if sys.argv[1:] == ['--watch'] else hook()
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        pass  # Progress must never block a Claude turn.
