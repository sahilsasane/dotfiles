#!/usr/bin/env python3
"""Use Extrakto's standalone filters with a Rex terminal and fzf."""

import os
from pathlib import Path
import json
import subprocess
import sys


def rex(session, *args, **kwargs):
    return subprocess.run(["rex", *args, "-s", session], check=True, text=True, **kwargs)


def fzf_env():
    config_home = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    try:
        effective = (config_home / "dotfiles-theme/effective").read_text().strip()
    except FileNotFoundError:
        effective = "dark"
    theme = "light" if effective == "light" else "dark"
    palette = (config_home / "zsh/fzf" / f"{theme}.opts").read_text()
    env = os.environ.copy()
    env["FZF_DEFAULT_OPTS"] = env.get("FZF_DEFAULT_OPTS", "") + "\n" + palette
    return env


def pick(session, block):
    data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
    engine = data_home / "extrakto"
    if not (engine / "extrakto.py").is_file():
        raise FileNotFoundError(f"Extrakto's standalone filters are missing from {engine}")
    sys.path.insert(0, str(engine))
    from extrakto import Extrakto, get_lines

    text = rex(session, "capture", "-b", block, "--trim", "--unwrap", capture_output=True).stdout
    modes = ("word", "all", "line")
    mode = 0
    query = ""
    env = fzf_env()
    while True:
        name = modes[mode]
        if name == "line":
            candidates = get_lines(text)
        else:
            extractor = Extrakto(alt=name == "all")
            filters = extractor.all() if name == "all" else ["word"]
            candidates = [value for filter_name in filters for value in extractor[filter_name].filter(text)]
        candidates = list(dict.fromkeys(reversed(candidates)))
        result = subprocess.run(
            ["fzf", "--multi", "--no-height", "--layout=reverse", "--border=rounded", "--print-query",
             "--expect=enter,tab,ctrl-f", "--tiebreak=index", f"--query={query}",
             f"--header=Extrakto [{name}] | Tab insert | Enter copy | Ctrl-f filter | Esc close"],
            input="\n".join(candidates), capture_output=False, stdout=subprocess.PIPE, text=True, env=env,
        )
        if result.returncode == 130:
            return
        if result.returncode not in (0, 1):
            raise RuntimeError(f"fzf exited with status {result.returncode}")
        output = result.stdout.splitlines()
        if len(output) < 2:
            return
        query, key, *selected = output
        if key == "ctrl-f":
            mode = (mode + 1) % len(modes)
            continue
        if not selected:
            return
        value = (" " if name == "word" else "\n").join(selected)
        if key == "enter":
            subprocess.run(["pbcopy"], input=value, text=True, check=True)
        elif key == "tab":
            # A paste event preserves bracketed paste in shells and editors.
            event = {"block_id": block, "event": {"type": "paste", "payload": {"text": value}}}
            rex(session, "api", "call", "block.event", "-", input=json.dumps(event), stdout=subprocess.DEVNULL)
        return


if __name__ == "__main__":
    session, block, zoomed = sys.argv[1:]
    try:
        pick(session, block)
    except KeyboardInterrupt:
        pass
    except (OSError, subprocess.CalledProcessError, RuntimeError) as error:
        print(f"Extrakto: {error}", file=sys.stderr)
        input("Press Enter to close.")
    finally:
        restore = ["zoom", block, "--on"] if zoomed == "true" else ["focus", block]
        subprocess.run(["rex", *restore, "-s", session], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
