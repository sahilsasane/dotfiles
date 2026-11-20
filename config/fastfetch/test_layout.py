import ctypes
import fcntl
import json
import os
from pathlib import Path
import pty
import re
import select
import shutil
import struct
import subprocess
import termios
import time
import unittest


DIRECTORY = Path(__file__).resolve().parent
CONFIG = Path(os.environ.get("FASTFETCH_TEST_CONFIG", DIRECTORY / "config.jsonc"))
FASTFETCH = shutil.which("fastfetch")
ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]|\x1b\][^\x07]*(?:\x07|\x1b\\)")
WCWIDTH = ctypes.CDLL(None).wcwidth
WCWIDTH.argtypes = [ctypes.c_wchar]
WCWIDTH.restype = ctypes.c_int


def cell_width(text):
    return sum(max(0, WCWIDTH(char)) for char in text)


def fetch(columns, config=CONFIG, command=None):
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 40, columns, 0, 0))
    environment = dict(os.environ, TERM="xterm-256color", COLUMNS="999")
    process = subprocess.Popen(
        command or [FASTFETCH, "--config", str(config)],
        stdin=slave,
        stdout=slave,
        stderr=subprocess.PIPE,
        env=environment,
    )
    os.close(slave)
    chunks = []
    deadline = time.monotonic() + 5
    try:
        while time.monotonic() < deadline:
            if select.select([master], [], [], 0.1)[0]:
                try:
                    chunk = os.read(master, 65536)
                except OSError:
                    break
                if not chunk:
                    break
                chunks.append(chunk)
                if b"\x1b[18t" in chunk:
                    os.write(master, f"\x1b[8;40;{columns}t".encode())
                if b"\x1b[6n" in chunk:
                    os.write(master, b"\x1b[1;1R")
            elif process.poll() is not None:
                break
        process.wait(timeout=1)
        errors = process.stderr.read().decode(errors="replace")
        if process.returncode:
            raise AssertionError(f"fastfetch exited {process.returncode}: {errors}")
        return ANSI.sub("", b"".join(chunks).decode()).replace("\r", "")
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
        process.stderr.close()
        os.close(master)


@unittest.skipUnless(FASTFETCH, "fastfetch is required")
class LayoutTest(unittest.TestCase):
    def test_real_terminal_widths(self):
        for columns in (20, 40, 45, 46, 60, 80, 93, 94, 100, 126, 127, 128, 160, 240):
            with self.subTest(columns=columns):
                output = fetch(columns)
                lines = output.splitlines()
                self.assertNotIn("Lua", output)
                self.assertTrue(lines)
                widest = max(map(cell_width, lines))
                self.assertLessEqual(widest, columns, f"{columns} columns: widest output is {widest}")
                self.assertEqual(sum(line.count("│") for line in lines), 48)
                for title in ("MACHINE", "STATUS", "HARDWARE", "ENVIRONMENT"):
                    self.assertIn(title, output)
                self.assertEqual("xNMM" in output, columns >= 127)
                header_lines = [line for line in lines if "╭" in line]
                self.assertEqual(len(header_lines), 2 if columns >= 94 else 4)

    def test_renderer_handles_unicode_and_missing_dimensions(self):
        renderer = json.dumps(str(DIRECTORY / "layout.lua"))
        for columns in (None, 0, 1, 2, 5, 10, 20, 40, 46, 94, 127, 160):
            with self.subTest(columns=columns):
                width = "nil" if columns is None else str(columns)
                script = (
                    f"lua:local layout = dofile({renderer}); "
                    f"return layout.render({width}, "
                    "{host={name=string.rep('界é😀', 30)}})"
                )
                config = {"logo": {"type": "none"}, "modules": [{"type": "custom", "format": script}]}
                process = subprocess.run(
                    [FASTFETCH, "--config", "-"], input=json.dumps(config),
                    text=True, capture_output=True, timeout=5,
                )
                self.assertEqual(process.returncode, 0, process.stderr)
                output = ANSI.sub("", process.stdout)
                self.assertNotIn("Lua", output)
                self.assertTrue(output.strip())
                limit = columns or 80
                self.assertLessEqual(max(map(cell_width, output.splitlines())), limit)

    def test_wide_emoji_values_fit_the_panel(self):
        renderer = json.dumps(str(DIRECTORY / "layout.lua"))
        for value in ("⌚", "☕", "🏻"):
            with self.subTest(value=value):
                script = (
                    f"lua:local layout = dofile({renderer}); "
                    f"return layout.render(46, {{host={{name=string.rep('{value}', 30)}}}})"
                )
                config = {"logo": {"type": "none"}, "modules": [{"type": "custom", "format": script}]}
                process = subprocess.run(
                    [FASTFETCH, "--config", "-"], input=json.dumps(config),
                    text=True, capture_output=True, timeout=5,
                )
                self.assertEqual(process.returncode, 0, process.stderr)
                output = ANSI.sub("", process.stdout)
                self.assertNotIn("Lua", output)
                self.assertLessEqual(max(map(cell_width, output.splitlines())), 46)


if __name__ == "__main__":
    unittest.main()
