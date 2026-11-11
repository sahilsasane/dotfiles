import contextlib
from decimal import Decimal
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch


BIN = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("lgai_generate", BIN / "lgai-generate.py")
lgai = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lgai)


def response(**overrides):
    return {
        "id": "chatcmpl-test",
        "model": "gpt-6-luna",
        "service_tier": "default",
        "choices": [{"message": {"content": "private generated message"}}],
        "usage": {
            "prompt_tokens": 1000,
            "completion_tokens": 100,
            "total_tokens": 1100,
            "prompt_tokens_details": {"cached_tokens": 400, "cache_write_tokens": 0},
            "completion_tokens_details": {"reasoning_tokens": 20},
        },
        **overrides,
    }


class CostTest(unittest.TestCase):
    def test_luna_cached_input_and_reasoning_are_billed_once(self):
        cost = lgai.cost_for_response(response())
        self.assertEqual(cost["cost_source"], "estimated")
        self.assertEqual(Decimal(str(cost["cost_usd"])), Decimal("0.000114"))

    def test_service_tier_changes_price(self):
        for tier, expected in (("flex", "0.000057"), ("priority", "0.000228")):
            with self.subTest(tier=tier):
                cost = lgai.cost_for_response(response(service_tier=tier))
                self.assertEqual(Decimal(str(cost["cost_usd"])), Decimal(expected))

    def test_response_cost_including_zero_takes_precedence(self):
        for amount in (0, 0.0123):
            data = response(model="another-model")
            data["usage"]["cost"] = amount
            self.assertEqual(lgai.cost_for_response(data),
                             {"cost_usd": amount, "cost_source": "response"})
        self.assertEqual(lgai.cost_for_response(response(cost=0.01))["cost_source"], "response")

    def test_unknown_pricing_is_not_recorded_as_free(self):
        for changes in ({"model": "another-model"}, {"service_tier": "unknown"}, {"usage": {}}):
            with self.subTest(changes=changes):
                self.assertIsNone(lgai.cost_for_response(response(**changes))["cost_usd"])
        data = response()
        data["usage"]["prompt_tokens_details"]["cache_write_tokens"] = 100
        self.assertIsNone(lgai.cost_for_response(data)["cost_usd"])

    def test_ledger_appends_usage_without_message_content(self):
        with TemporaryDirectory() as directory, contextlib.redirect_stderr(io.StringIO()):
            log = Path(directory) / "response.log"
            ledger = Path(directory) / "costs.jsonl"
            log.write_text("[DEBUG] non-stream-data: " + json.dumps(response()) + "\n")
            lgai.record_responses(log, ledger, "/example/repo")
            lgai.record_responses(log, ledger, "/example/repo")
            entries = [json.loads(line) for line in ledger.read_text().splitlines()]
            self.assertEqual(len(entries), 2)
            self.assertEqual(entries[0]["repository"], "/example/repo")
            self.assertEqual(entries[0]["usage"], response()["usage"])
            self.assertNotIn("private generated message", ledger.read_text())

    def test_logging_failure_preserves_generation_exit_status(self):
        with TemporaryDirectory() as directory, contextlib.redirect_stderr(io.StringIO()) as errors:
            for status in (0, 7):
                with patch.object(lgai.subprocess, "run", return_value=subprocess.CompletedProcess([], status)):
                    result = lgai.generate("prompt", Path(directory) / "costs.jsonl", "/repo")
                self.assertEqual(result, status)
            self.assertIn("could not record cost", errors.getvalue())

    def test_symlinked_lgai_logs_in_dotfiles_before_editor_cancellation(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            dotfiles_bin = root / "dotfiles/bin"
            commands = root / "commands"
            repository = root / "other-repo"
            for path in (dotfiles_bin, commands, repository):
                path.mkdir(parents=True)
            for name in ("lgai", "lgai-generate.py"):
                shutil.copy2(BIN / name, dotfiles_bin / name)
            (commands / "lgai").symlink_to(dotfiles_bin / "lgai")
            fake_aichat = commands / "aichat"
            fake_aichat.write_text(
                f"#!{sys.executable}\n"
                "import json, os\nfrom pathlib import Path\n"
                f"data = {response()!r}\n"
                "Path(os.environ['AICHAT_LOG_PATH']).write_text('[DEBUG] non-stream-data: ' + json.dumps(data) + '\\n')\n"
                "print('feat: add example\\n\\n- Add example content')\n"
            )
            fake_aichat.chmod(0o755)
            for name, body in (("pbcopy", "cat >/dev/null"), ("cancel-editor", "exit 23")):
                command = commands / name
                command.write_text("#!/bin/sh\n" + body + "\n")
                command.chmod(0o755)

            def git(*args):
                return subprocess.check_output(["git", "-C", str(repository), *args], text=True).strip()

            git("init", "-q")
            git("-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "--allow-empty", "-qm", "initial")
            (repository / "example").write_text("example\n")
            git("add", "example")
            initial_head = git("rev-parse", "HEAD")
            env = dict(os.environ, PATH=str(commands) + os.pathsep + os.environ["PATH"],
                       VISUAL=str(commands / "cancel-editor"))
            for _ in range(2):
                result = subprocess.run([str(commands / "lgai")], cwd=repository, env=env,
                                        text=True, capture_output=True)
                self.assertEqual(result.returncode, 23, result.stderr)
            ledger = root / "dotfiles/.lgai-costs.jsonl"
            entries = [json.loads(line) for line in ledger.read_text().splitlines()]
            self.assertEqual(len(entries), 2)
            self.assertEqual(Path(entries[0]["repository"]).resolve(), repository.resolve())
            self.assertFalse((repository / ".lgai-costs.jsonl").exists())
            self.assertEqual(git("rev-parse", "HEAD"), initial_head)


if __name__ == "__main__":
    unittest.main()
