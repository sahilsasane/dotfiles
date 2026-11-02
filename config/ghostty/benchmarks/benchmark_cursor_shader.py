#!/usr/bin/env python3
"""macOS Ghostty CPU comparison; opens and closes only its own test instances.

Run outside the sandbox: python3 benchmark_cursor_shader.py BEFORE AFTER --output results.json
CPU is process user+system time / wall time (100% = one core), excluding the
workload's CPU. Each instance measures idle and deterministic 10 Hz cursor jumps.
Animation is forced to `always` in both test instances to remove focus changes
as a scheduling variable. The terminal config, dimensions and workload match.
"""

import argparse
import ctypes
import hashlib
import json
import os
from pathlib import Path
import signal
import statistics
import subprocess
import sys
import tempfile
import time

GHOSTTY = Path('/Applications/Ghostty.app/Contents/MacOS/ghostty')


def workload(directory):
    directory = Path(directory)
    # Ghostty can resize the PTY after spawning its child during window layout.
    time.sleep(1.5)
    size = os.get_terminal_size()
    (directory / 'ready.json').write_text(json.dumps({
        'ghostty_pid': os.getppid(), 'workload_pid': os.getpid(),
        'columns': size.columns, 'rows': size.lines,
    }))
    print('\033[2J\033[H', end='')
    for row in range(1, size.lines):
        print(f'\033[{row};1H{row:03d}  cursor shader benchmark | static editor-like background'[:size.columns], end='')
    print('\033[?25h\033[4;8H', end='', flush=True)
    positions = [(4, 8), (4, 22), (9, 22), (16, 58), (5, 70), (20, 10)]
    index = updates = 0
    while True:
        mode = (directory / 'mode').read_text()
        if mode == 'stop':
            return
        if mode == 'moving':
            row, column = positions[index % len(positions)]
            print(f'\033[{min(row, size.lines - 1)};{min(column, size.columns - 1)}H', end='', flush=True)
            index += 1
            updates += 1
        actual = os.get_terminal_size()
        (directory / 'heartbeat.tmp').write_text(json.dumps({
            'mode': mode, 'updates': updates, 'columns': actual.columns, 'rows': actual.lines,
        }))
        (directory / 'heartbeat.tmp').replace(directory / 'heartbeat.json')
        time.sleep(0.1)


class Usage(ctypes.Structure):
    _fields_ = [('uuid', ctypes.c_uint8 * 16)] + [
        (name, ctypes.c_uint64) for name in (
            'user', 'system', 'idle_wakeups', 'interrupt_wakeups', 'pageins',
            'wired', 'resident', 'footprint', 'start', 'exit',
        )
    ]


def usage(pid):
    value = Usage()
    lib = ctypes.CDLL('/usr/lib/libproc.dylib', use_errno=True)
    if lib.proc_pid_rusage(pid, 0, ctypes.byref(value)):
        raise OSError(ctypes.get_errno(), 'proc_pid_rusage failed')
    return value


def seconds_per_tick():
    class Timebase(ctypes.Structure):
        _fields_ = [('numer', ctypes.c_uint32), ('denom', ctypes.c_uint32)]
    value = Timebase()
    if ctypes.CDLL('/usr/lib/libSystem.B.dylib').mach_timebase_info(ctypes.byref(value)):
        raise RuntimeError('mach_timebase_info failed')
    return value.numer / value.denom / 1e9


def calibrate_cpu_counter():
    before = usage(os.getpid())
    cpu_before = time.process_time()
    until = time.monotonic() + 0.25
    while time.monotonic() < until:
        pass
    expected = time.process_time() - cpu_before
    after = usage(os.getpid())
    measured = ((after.user + after.system) - (before.user + before.system)) * seconds_per_tick()
    if abs(measured / expected - 1) > 0.05:
        raise RuntimeError(f'CPU counter calibration failed: {measured} vs {expected}')
    return {'process_time_seconds': expected, 'rusage_seconds': measured}


def frontmost_pid():
    ctypes.CDLL('/System/Library/Frameworks/AppKit.framework/AppKit')
    cf = ctypes.CDLL('/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation')
    mode = ctypes.c_void_p.in_dll(cf, 'kCFRunLoopDefaultMode')
    cf.CFRunLoopRunInMode.argtypes = [ctypes.c_void_p, ctypes.c_double, ctypes.c_bool]
    cf.CFRunLoopRunInMode(mode, 0.001, False)
    objc = ctypes.CDLL('/usr/lib/libobjc.A.dylib')
    objc.objc_getClass.restype = ctypes.c_void_p
    objc.sel_registerName.restype = ctypes.c_void_p
    send = ctypes.CFUNCTYPE(ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p)(('objc_msgSend', objc))
    workspace = send(objc.objc_getClass(b'NSWorkspace'), objc.sel_registerName(b'sharedWorkspace'))
    app = send(workspace, objc.sel_registerName(b'frontmostApplication'))
    number = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p)(('objc_msgSend', objc))
    return number(app, objc.sel_registerName(b'processIdentifier'))


def wait_for(path, seconds=15):
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        if path.exists():
            return json.loads(path.read_text())
        time.sleep(0.1)
    raise TimeoutError(f'No workload startup signal: {path}')


def run_one(shader, seconds):
    with tempfile.TemporaryDirectory(prefix='ghostty-shader-') as temp:
        directory = Path(temp)
        (directory / 'mode').write_text('idle')
        log = directory / 'stderr.log'
        subprocess.run([
            'open', '-na', '/Applications/Ghostty.app', '--stdout', str(directory / 'stdout.log'),
            '--stderr', str(log), '--args', f'--custom-shader={shader}',
            '--custom-shader-animation=always', '--shell-integration=none',
            '--window-save-state=never', '--quit-after-last-window-closed=true',
            '--initial-window=true', '--confirm-close-surface=false',
            '--maximize=false', '--window-width=100', '--window-height=28',
            '--font-size=18', '--window-inherit-font-size=false',
            '--notify-on-command-finish=never', '--keybind=clear',
            '--title=Cursor Shader Benchmark', '-e', sys.executable, str(Path(__file__).resolve()),
            '--workload', str(directory),
        ], check=True, capture_output=True, text=True)
        pid = None
        try:
            ready = wait_for(directory / 'ready.json')
            pid = ready['ghostty_pid']
            for _ in range(5):
                info = subprocess.check_output(['ps', '-p', str(pid), '-o', 'ppid=', '-o', 'comm='], text=True).strip()
                parent, name = info.split(maxsplit=1)
                if name == str(GHOSTTY):
                    break
                if name not in ('/usr/bin/login', '/bin/zsh', '/bin/sh'):
                    raise RuntimeError(f'Unexpected workload ancestor: {name}')
                pid = int(parent)
            else:
                raise RuntimeError('Ghostty not found in workload ancestors')
            dimensions = (ready['columns'], ready['rows'])
            if ready['columns'] != 100 or not 28 <= ready['rows'] <= 30:
                raise RuntimeError(f'Unexpected test dimensions: {ready}')
            result = {'pid': pid, 'dimensions': [ready['columns'], ready['rows']], 'phases': {}}
            for mode in ('idle', 'moving'):
                (directory / 'mode').write_text(mode)
                time.sleep(2)
                heartbeat_before = json.loads((directory / 'heartbeat.json').read_text())
                before = usage(pid)
                started = time.monotonic()
                focus = []
                while time.monotonic() - started < seconds:
                    focus.append(frontmost_pid())
                    time.sleep(0.25)
                elapsed = time.monotonic() - started
                after = usage(pid)
                heartbeat = json.loads((directory / 'heartbeat.json').read_text())
                updates = heartbeat['updates'] - heartbeat_before['updates']
                if heartbeat['mode'] != mode or (mode == 'moving' and updates < seconds * 8):
                    raise RuntimeError(f'Workload did not run: {heartbeat}, updates={updates}')
                if (heartbeat['columns'], heartbeat['rows']) != dimensions:
                    raise RuntimeError(f'Test window resized: {heartbeat}')
                result['phases'][mode] = {
                    'wall_seconds': elapsed,
                    'cpu_percent_one_core': 100 * ((after.user + after.system) - (before.user + before.system)) * seconds_per_tick() / elapsed,
                    'idle_wakeups_per_second': (after.idle_wakeups - before.idle_wakeups) / elapsed,
                    'interrupt_wakeups_per_second': (after.interrupt_wakeups - before.interrupt_wakeups) / elapsed,
                    'cursor_updates': updates, 'focus_samples': len(focus),
                    'focused_samples': sum(active == pid for active in focus),
                }
            time.sleep(0.2)
            result['stderr'] = log.read_text() if log.exists() else ''
            failures = [line for line in result['stderr'].splitlines()
                        if any(word in line.lower() for word in ('error', 'failed'))]
            if failures:
                raise RuntimeError(f'Ghostty reported errors: {failures}')
            return result
        finally:
            (directory / 'mode').write_text('stop')
            if pid:
                # Only the PID obtained from this run's own child is eligible.
                time.sleep(0.3)
                try:
                    os.kill(ready['workload_pid'], signal.SIGTERM)
                except ProcessLookupError:
                    pass


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('before', nargs='?', type=Path)
    parser.add_argument('after', nargs='?', type=Path)
    parser.add_argument('--workload')
    parser.add_argument('--rounds', type=int, default=5)
    parser.add_argument('--seconds', type=float, default=6)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    if args.workload:
        workload(args.workload)
        return
    if not args.before or not args.output:
        parser.error('BEFORE and --output are required')
    variants = {'before': args.before.resolve()}
    if args.after:
        variants['after'] = args.after.resolve()
    report = {
        'ghostty_version': subprocess.check_output([str(GHOSTTY), '+version'], text=True),
        'platform': subprocess.check_output(['sw_vers'], text=True),
        'cpu_count': os.cpu_count(), 'load_before': os.getloadavg(),
        'cpu_counter_calibration': calibrate_cpu_counter(),
        'seconds_per_mach_tick': seconds_per_tick(),
        'seconds_per_phase': args.seconds,
        'animation_override': 'always',
        'shader_sha256': {key: hashlib.sha256(path.read_bytes()).hexdigest() for key, path in variants.items()},
        'runs': [],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    for index in range(args.rounds):
        for variant, shader in variants.items():
            print(f'round={index + 1} variant={variant}', flush=True)
            result = run_one(shader, args.seconds)
            if report['runs'] and result['dimensions'] != report['runs'][0]['dimensions']:
                raise RuntimeError('Window dimensions differed between variants; discard this report')
            report['runs'].append({'round': index + 1, 'variant': variant, **result})
            args.output.write_text(json.dumps(report, indent=2) + '\n')
            print(json.dumps(result['phases']), flush=True)
    report['summary'] = {}
    for variant in variants:
        report['summary'][variant] = {}
        for phase in ('idle', 'moving'):
            values = [run['phases'][phase]['cpu_percent_one_core'] for run in report['runs'] if run['variant'] == variant]
            report['summary'][variant][phase] = {
                'median_cpu_percent': statistics.median(values), 'min': min(values), 'max': max(values),
            }
    report['load_after'] = os.getloadavg()
    args.output.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report['summary'], indent=2), flush=True)


if __name__ == '__main__':
    main()
