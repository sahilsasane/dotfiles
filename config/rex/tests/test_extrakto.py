import importlib.util
import json
import os
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location("rex_extrakto", Path(__file__).parents[1] / "extrakto.py")
picker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(picker)


class ExtraktoTest(unittest.TestCase):
    def run_picker(self, results, theme="dark", inherited_opts=""):
        calls = []

        def run(command, **kwargs):
            calls.append((command, kwargs))
            if "capture" in command:
                return subprocess.CompletedProcess(command, 0, "alpha βeta https://example.com/a /tmp/example.txt\nsecond line\n")
            if command[0] == "fzf":
                self.assertEqual(os.environ["FZF_DEFAULT_OPTS"], inherited_opts)
                status, output = results.pop(0)
                return subprocess.CompletedProcess(command, status, output)
            return subprocess.CompletedProcess(command, 0, "")

        with TemporaryDirectory() as directory:
            config_home = Path(directory)
            palettes = config_home / "zsh/fzf"
            palettes.mkdir(parents=True)
            (palettes / "dark.opts").write_text("--color=prompt:#123456\n")
            (palettes / "light.opts").write_text("--color=prompt:#abcdef\n")
            if theme is not None:
                (config_home / "dotfiles-theme").mkdir()
                (config_home / "dotfiles-theme/effective").write_text(theme + "\n")
            with patch.dict(os.environ, {"XDG_CONFIG_HOME": directory, "FZF_DEFAULT_OPTS": inherited_opts}):
                with patch.object(picker.subprocess, "run", side_effect=run):
                    picker.pick("session:test", "block:source")
        return calls

    def test_copy_multiple_words_preserves_text_without_submitting_it(self):
        calls = self.run_picker([(0, "\nenter\nalpha\nβeta\n")])
        copies = [options["input"] for command, options in calls if command[0] == "pbcopy"]
        self.assertEqual(copies, ["alpha βeta"])
        self.assertFalse(any("block.event" in command for command, _ in calls))

    def test_insert_uses_a_paste_event_with_literal_text(self):
        text = "$(example); unsafe-looking text"
        calls = self.run_picker([(0, "\ntab\n" + text + "\n")])
        events = [json.loads(options["input"]) for command, options in calls if "block.event" in command]
        self.assertEqual(events, [{"block_id": "block:source", "event": {"type": "paste", "payload": {"text": text}}}])
        self.assertFalse(any(command[0] == "pbcopy" for command, _ in calls))

    def test_switching_filters_keeps_the_query_and_line_breaks(self):
        calls = self.run_picker([(1, "needle\nctrl-f\n"), (0, "needle\nctrl-f\n"), (0, "needle\nenter\nfirst line\nsecond line\n")])
        copies = [options["input"] for command, options in calls if command[0] == "pbcopy"]
        self.assertEqual(copies, ["first line\nsecond line"])
        fuzzy_calls = [command for command, _ in calls if command[0] == "fzf"]
        self.assertTrue(all("--query=needle" in command for command in fuzzy_calls[1:]))

    def test_cancel_leaves_clipboard_and_source_untouched(self):
        calls = self.run_picker([(130, "")])
        self.assertFalse(any(command[0] == "pbcopy" or "block.event" in command for command, _ in calls))

    def test_fzf_child_uses_the_selected_palette(self):
        for theme, color in (("dark", "#123456"), ("light", "#abcdef")):
            with self.subTest(theme=theme):
                calls = self.run_picker([(130, "")], theme=theme)
                command, options = next((c, o) for c, o in calls if c[0] == "fzf")
                self.assertEqual(options["env"]["FZF_DEFAULT_OPTS"].strip(), "--color=prompt:" + color)
                self.assertIn("--no-height", command)

    def test_missing_theme_state_uses_dark_palette(self):
        calls = self.run_picker([(130, "")], theme=None)
        options = next(o for c, o in calls if c[0] == "fzf")
        self.assertEqual(options["env"]["FZF_DEFAULT_OPTS"].strip(), "--color=prompt:#123456")

    def test_palette_follows_inherited_flags_without_changing_parent_environment(self):
        inherited = "--height=55% --color=prompt:#000000 --cycle"
        calls = self.run_picker([(130, "")], inherited_opts=inherited)
        options = next(o for c, o in calls if c[0] == "fzf")
        self.assertEqual(options["env"]["FZF_DEFAULT_OPTS"], inherited + "\n--color=prompt:#123456\n")


if __name__ == "__main__":
    unittest.main()
