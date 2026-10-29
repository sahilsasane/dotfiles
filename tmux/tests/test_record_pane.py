"""Run with python3; uses an isolated tmux server and temporary log files."""
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]
RECORDER = ROOT / 'tmux/scripts/record-pane.sh'


def wait_for(predicate):
    end = time.monotonic() + 5
    while time.monotonic() < end:
        if predicate():
            return
        time.sleep(0.02)
    raise AssertionError('Timed out waiting for pane output')


with tempfile.TemporaryDirectory(prefix='tmux-recording-') as directory:
    base = Path(directory)
    command = ['tmux', '-S', str(base / 'socket')]
    streams = []

    def tmux(*args):
        return subprocess.check_output(command + list(args), text=True, stderr=subprocess.PIPE).strip()

    def option(pane, name):
        return tmux('show-option', '-pqv', '-t', pane, name)

    def emit(index, text):
        os.write(streams[index], (text + '\n').encode())

    try:
        panes = []
        for index in range(2):
            fifo = base / f'input-{index}'
            os.mkfifo(fifo)
            streams.append(os.open(fifo, os.O_RDWR | os.O_NONBLOCK))
            args = ['-f', '/dev/null', 'new-session', '-d', '-s', 'recording'] if index == 0 else ['split-window', '-d']
            panes.append(tmux(*args, '-P', '-F', '#{pane_id}', 'exec cat < ' + shlex.quote(str(fifo))))
        env = dict(os.environ, XDG_STATE_HOME=str(base / "state with ' quote"))
        env['TMUX'] = tmux('display-message', '-p', '-t', panes[0], '#{socket_path},#{pid},0')

        def toggle(pane, check=True):
            return subprocess.run(['bash', str(RECORDER), pane], env=env, check=check, capture_output=True)

        emit(0, 'BEFORE_RECORDING')
        wait_for(lambda: 'BEFORE_RECORDING' in tmux('capture-pane', '-p', '-t', panes[0]))
        logs = []
        for pane in panes:
            toggle(pane)
            logs.append(Path(option(pane, '@recording_log')))
        emit(0, 'FIRST_PANE')
        emit(1, 'SECOND_PANE')
        wait_for(lambda: 'FIRST_PANE' in logs[0].read_text() and 'SECOND_PANE' in logs[1].read_text())
        assert 'BEFORE_RECORDING' not in logs[0].read_text()
        assert 'SECOND_PANE' not in logs[0].read_text()
        assert logs[0] != logs[1]
        assert all(p.stat().st_mode & 0o777 == 0o600 for p in logs)
        for theme in ('dark', 'light'):
            tmux('source-file', str(ROOT / f'tmux/themes/{theme}.conf'))
            assert 'REC' in tmux('display-message', '-p', '-t', panes[0], '#{E:status-left}')
        toggle(panes[0])
        assert tmux('display-message', '-p', '-t', panes[0], '#{pane_pipe}') == '0'
        assert 'REC' not in tmux('display-message', '-p', '-t', panes[0], '#{E:status-left}')
        emit(0, 'AFTER_RECORDING')
        emit(1, 'SECOND_STILL_RECORDING')
        wait_for(lambda: 'SECOND_STILL_RECORDING' in logs[1].read_text())
        wait_for(lambda: 'AFTER_RECORDING' in tmux('capture-pane', '-p', '-t', panes[0]))
        assert 'AFTER_RECORDING' not in logs[0].read_text()
        toggle(panes[1])
        tmux('pipe-pane', '-t', panes[0], 'cat >/dev/null')
        assert toggle(panes[0], check=False).returncode != 0
        assert tmux('display-message', '-p', '-t', panes[0], '#{pane_pipe}') == '1'
        print('PASS: recording boundaries, pane isolation, quoted paths, private logs, theme badges, and existing-pipe protection')
    finally:
        subprocess.run(command + ['kill-server'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for stream in streams:
            os.close(stream)
