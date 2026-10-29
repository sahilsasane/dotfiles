"""Exercise real tmux clients without starting Claude or making model calls."""
import json
import os
from pathlib import Path
import pty
import re
import select
import shlex
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / 'tmux/scripts/claude-progress.py'
OPTION = '@dotfiles_claude_progress'
PROGRESS = re.compile(rb'\x1b\]9;4;(\d)(?:;\d+)?(?:\x07|\x1b\\)')

with tempfile.TemporaryDirectory(prefix='claude-progress-test-') as directory:
    base = Path(directory)
    command = ['tmux', '-S', str(base / 'socket')]
    clients = []
    streams = []

    def tmux(*args):
        return subprocess.check_output(command + list(args), text=True, stderr=subprocess.PIPE).strip()

    def drain(seconds=0.8):
        output = [b'' for _ in clients]
        end = time.monotonic() + seconds
        while time.monotonic() < end:
            ready, _, _ = select.select([fd for _, fd in clients], [], [], max(0, end - time.monotonic()))
            for fd in ready:
                try:
                    data = os.read(fd, 65536)
                except OSError:
                    data = b''
                for index, (_, client_fd) in enumerate(clients):
                    if fd == client_fd:
                        output[index] += data
        return [[int(state) for state in PROGRESS.findall(data)] for data in output]

    def hook(event, pane, **extra):
        payload = dict(hook_event_name=event, **extra)
        env = dict(os.environ, TMUX=tmux('display-message', '-p', '#{socket_path},#{pid},0'), TMUX_PANE=pane)
        subprocess.run([sys.executable, str(SCRIPT)], env=env, input=json.dumps(payload), text=True, check=True, capture_output=True)

    try:
        panes = []
        for name in ('claude-test', 'other-test'):
            fifo = base / name
            os.mkfifo(fifo)
            streams.append(os.open(fifo, os.O_RDWR | os.O_NONBLOCK))
            panes.append(tmux('-f', '/dev/null', 'new-session', '-d', '-s', name, '-P', '-F', '#{pane_id}', 'exec cat < ' + shlex.quote(str(fifo))))
        tmux('set-option', '-g', 'status', 'off')
        tmux('set-option', '-s', 'escape-time', '10')
        tmux('set-option', '-as', 'terminal-features', ',xterm-ghostty:progressbar')
        bindings = base / 'bindings.conf'
        bindings.write_text('\n'.join(
            line for line in (ROOT / 'tmux/.tmux.conf').read_text().splitlines()
            if line.startswith(('bind -n Escape ', 'bind -n C-c '))
        ) + '\n')
        tmux('source-file', str(bindings))
        assert 'if-shell' in tmux('list-keys', '-T', 'root', 'Escape')
        for name in ('claude-test', 'other-test'):
            pid, fd = pty.fork()
            if pid == 0:
                os.environ['TERM'] = 'xterm-ghostty'
                os.environ['TERMINFO'] = '/Applications/Ghostty.app/Contents/Resources/terminfo'
                os.environ.pop('TMUX', None)
                os.execvp(command[0], command + ['attach-session', '-t', name])
            clients.append((pid, fd))
        drain(0.5)
        for _, fd in clients:
            os.write(fd, b'\x1b[?1;2c')
        drain(0.5)
        routing = tmux('list-clients', '-F', '#{client_tty}\t#{session_name}')
        active_client = next(row.split('\t')[0] for row in routing.splitlines() if row.endswith('\tclaude-test'))
        hook('UserPromptSubmit', panes[0])
        output = drain()
        assert 3 in output[0] and 3 not in output[1], output
        hook('UserPromptSubmit', panes[0])  # Starting twice must not duplicate watchers.
        output = drain(16)
        assert 5 <= len(output[0]) <= 7 and 3 not in output[1], output
        # The keep-alive continues after Ghostty's 15-second expiry window.
        assert 3 in drain(3.5)[0]
        tmux('switch-client', '-c', active_client, '-t', 'other-test')
        output = drain()
        assert 0 in output[0] and 3 not in output[0] and 3 not in output[1], output
        tmux('switch-client', '-c', active_client, '-t', 'claude-test')
        assert 3 in drain()[0]
        os.write(clients[0][1], b'\x1b')
        assert 0 in drain()[0]
        assert not tmux('show-option', '-pqv', '-t', panes[0], OPTION)
        hook('UserPromptSubmit', panes[0])
        assert 3 in drain()[0]
        hook('Stop', panes[0], agent_id='background-agent')
        assert tmux('show-option', '-pqv', '-t', panes[0], OPTION) == str(os.getpid())
        hook('Stop', panes[0])
        assert 0 in drain()[0]
        hook('UserPromptSubmit', panes[0])
        assert 3 in drain()[0]
        hook('PreToolUse', panes[0], tool_name='AskUserQuestion')
        assert 0 in drain()[0]
        hook('PostToolUse', panes[0])
        assert 3 in drain()[0]
        hook('SessionEnd', panes[0])
        assert 0 in drain()[0]
        # A dead owning process must not leave permanent busy state behind.
        tmux('set-option', '-p', '-t', panes[0], OPTION, '99999999')
        tmux('wait-for', '-S', 'dotfiles-claude-progress')
        drain()
        assert not tmux('show-option', '-pqv', '-t', panes[0], OPTION)
        settings = json.loads((ROOT / 'tmux/claude-progress.json').read_text())
        assert settings['terminalProgressBarEnabled'] is False
        assert set(settings['hooks']) >= {'UserPromptSubmit', 'Stop', 'StopFailure', 'SessionEnd'}
        print('PASS: separate clients, session switching, >15s keep-alives, turn/question lifecycle, subagent isolation, owner cleanup')
    finally:
        subprocess.run(command + ['kill-server'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for pid, fd in clients:
            os.close(fd)
            os.waitpid(pid, 0)
        for stream in streams:
            os.close(stream)
