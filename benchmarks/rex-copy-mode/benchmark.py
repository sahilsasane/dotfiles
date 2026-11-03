#!/usr/bin/env python3
"""Compare complete copy-mode startup using fixed output in disposable Rex sessions."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import statistics
import subprocess
import sys
import tempfile
import time


HERE = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--rex", default=shutil.which("rex") or "/Applications/Rex Beta.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex")
parser.add_argument("--before", type=Path, default=HERE / "before")
parser.add_argument("--after", type=Path, default=HERE.parents[1] / "config/rex")
parser.add_argument("--before-only", action="store_true")
parser.add_argument("--profile", action="store_true", help="run separate, instrumented stage diagnostics")
parser.add_argument("--runs", type=int, default=7)
parser.add_argument("--lines", type=int, nargs="+", default=[100, 10000])
parser.add_argument("--output", type=Path, default=HERE / "results.json")
args = parser.parse_args()
if args.runs < 1 or any(lines < 1 for lines in args.lines):
    parser.error("runs and line counts must be positive")

base = [args.rex, "--autostart=false"]


def rex(*command, env=None, json_output=False):
    result = subprocess.run(base + list(command), env=env, capture_output=True, text=True, timeout=20)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip())
    return json.loads(result.stdout) if json_output else result.stdout


report = {
    "measurement": "CLI action dispatch to first captured Neovim frame containing the end marker and correct line total; excludes native app paint/animation",
    "poll_sleep_ms": 5,
    "logical_cpus": os.cpu_count(),
    "load_average_start": os.getloadavg(),
    "rex": rex("version", "--json", json_output=True),
    "variants": {},
    "fixtures": [],
    "profiles": [],
    "samples": [],
    "errors": [],
}


def wait_for(predicate, timeout=15):
    deadline = time.perf_counter() + timeout
    while time.perf_counter() < deadline:
        value = predicate()
        if value:
            return value
        time.sleep(0.005)
    raise TimeoutError("Rex did not reach the expected state")


def snapshot(source, name, work, profile=False):
    config_home = work / name
    directory = config_home / "rex"
    directory.mkdir(parents=True)
    for filename in ("init.lua", "copy-mode.lua"):
        shutil.copy2(source / filename, directory / filename)
    if profile:
        init = directory / "init.lua"
        code = init.read_text()
        capture_line = 'rex capture -s "$1" -b "$2" --trim --unwrap > "$scrollback"'
        assert code.count("set -eu\n") == 1 and code.count(capture_line) == 1
        code = code.replace("set -eu\n", "set -eu\n: > " + shlex.quote(str(config_home / "shell-entry")) + "\n")
        code = code.replace(capture_line, capture_line + "\n: > " + shlex.quote(str(config_home / "capture-complete")))
        init.write_text(code)
        viewer = directory / "copy-mode.lua"
        with viewer.open("a") as file:
            file.write('\nvim.api.nvim_create_autocmd("VimEnter", { callback = function() vim.schedule(function() vim.cmd("redraw!"); vim.fn.writefile({}, ' + json.dumps(str(config_home / "nvim-redraw")) + ') end) end })\n')
    return config_home


def trial(name, config_home, session, source, marker, line_total, profile=False):
    started_wall = time.time_ns()
    started = time.perf_counter_ns()
    created = rex("do", str(config_home / "rex/init.lua"), "--action", "copy_mode", "-s", session, "-b", source, "--json", env=dict(os.environ, XDG_CONFIG_HOME=str(config_home)), json_output=True)
    action_ms = (time.perf_counter_ns() - started) / 1e6
    viewer = created["block_ids"][0]
    polls = 0
    last_screen = ""

    def ready():
        nonlocal polls, last_screen
        polls += 1
        screen = rex("capture", "-s", session, "-b", viewer, "--trim")
        last_screen = screen
        footer = re.search(r"\b(\d+)/(\d+)\s*$", screen)
        return marker in screen and "v/V/C-v select" in screen and footer and int(footer[2]) == line_total

    try:
        wait_for(ready)
    except TimeoutError as error:
        raise TimeoutError(f"{error}; last terminal frame: {last_screen[-500:]!r}") from error
    ready_ms = (time.perf_counter_ns() - started) / 1e6
    ready_wall = time.time_ns()
    size = rex("block", "call", "-s", session, "-b", viewer, "size", json_output=True)
    record = {"variant": name, "ready_ms": ready_ms, "action_ms": action_ms, "polls": polls, "columns": size["columns"], "rows": size["rows"], "verified_line_total": line_total}
    if profile:
        shell = (config_home / "shell-entry").stat().st_mtime_ns
        capture = (config_home / "capture-complete").stat().st_mtime_ns
        redraw = wait_for(lambda: (config_home / "nvim-redraw").exists())
        redraw = (config_home / "nvim-redraw").stat().st_mtime_ns
        record["stages_ms"] = {"dispatch_and_shell_start": (shell - started_wall) / 1e6, "capture": (capture - shell) / 1e6, "nvim_start_and_redraw": (redraw - capture) / 1e6, "frame_observation": (ready_wall - redraw) / 1e6}
    rex("send-key", "-s", session, "-b", viewer, "q")

    def closed():
        window = rex("session", "inspect", session, "--json", json_output=True)["windows"][0]
        return len(window["layers"]) == 1 and window["focused_block_id"] == source

    try:
        wait_for(closed)
    except TimeoutError as error:
        window = rex("session", "inspect", session, "--json", json_output=True)["windows"][0]
        process = rex("block", "call", "-s", session, "-b", viewer, "process", json_output=True)
        raise TimeoutError(f"Overlay cleanup/focus failed: process={process}; window={window}") from error
    return record


try:
    with tempfile.TemporaryDirectory(prefix="rex-copy-bench-") as temporary:
        work = Path(temporary)
        sources = {"before": args.before.resolve()}
        if not args.before_only:
            sources["after"] = args.after.resolve()
        configs = {name: snapshot(source, name, work) for name, source in sources.items()}
        for name, source in sources.items():
            report["variants"][name] = {filename: hashlib.sha256((source / filename).read_bytes()).hexdigest() for filename in ("init.lua", "copy-mode.lua")}
        fixture = work / "fixture.py"
        fixture.write_text("import signal, sys\nn=int(sys.argv[1])\nfor i in range(n): print(f'{i:05d} alpha beta gamma needle ' + 'sample text '*3)\nprint('REX_COPY_BENCH_END', flush=True)\nsignal.pause()\n")
        for lines in args.lines:
            created = rex("new", f"rex-copy-bench-{os.getpid()}-{lines}", "--shell=none", "--json", "--", sys.executable, "-u", str(fixture), str(lines), json_output=True)
            session = created["session_id"]
            source = created["initial_windows"][0]["block_ids"][0]
            try:
                marker = "REX_COPY_BENCH_END"
                captured = wait_for(lambda: (content if marker in (content := rex("capture", "-s", session, "-b", source, "--trim", "--unwrap")) else None))
                line_total = len(captured.splitlines())
                assert line_total == lines + 1, (lines, line_total)
                report["fixtures"].append({"output_lines": lines, "captured_lines": line_total, "captured_bytes": len(captured.encode())})
                if args.profile:
                    for name, path in sources.items():
                        config_home = snapshot(path, f"{name}-profile-{lines}", work, profile=True)
                        diagnostic = trial(name, config_home, session, source, marker, line_total, profile=True)
                        diagnostic["output_lines"] = lines
                        report["profiles"].append(diagnostic)
                        print("PROFILE", lines, name, json.dumps(diagnostic["stages_ms"]), flush=True)
                for iteration in range(args.runs):
                    for name, config_home in configs.items():
                        sample = trial(name, config_home, session, source, marker, line_total)
                        sample.update(output_lines=lines, iteration=iteration + 1)
                        report["samples"].append(sample)
                        print(f"{lines:>6} lines  {name:>6}  #{iteration + 1}  {sample['ready_ms']:.1f} ms", flush=True)
            finally:
                rex("kill", session)
except Exception as error:
    report["errors"].append(f"{type(error).__name__}: {error}")
finally:
    report["load_average_end"] = os.getloadavg()
    report["summary"] = []
    for lines in args.lines:
        dimensions = {(sample["columns"], sample["rows"]) for sample in report["samples"] if sample["output_lines"] == lines}
        if len(dimensions) > 1:
            report["errors"].append(f"Terminal size changed for {lines} lines: {dimensions}")
        for name in report["variants"]:
            samples = [sample for sample in report["samples"] if sample["variant"] == name and sample["output_lines"] == lines]
            if not samples:
                continue
            timings = [sample["ready_ms"] for sample in samples]
            summary = {"output_lines": lines, "variant": name, "runs": len(timings), "median_ms": statistics.median(timings), "min_ms": min(timings), "max_ms": max(timings)}
            report["summary"].append(summary)
            print(json.dumps(summary), flush=True)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Errors: {len(report['errors'])}; results: {args.output}", flush=True)
    if report["errors"]:
        raise SystemExit(report["errors"][0])
