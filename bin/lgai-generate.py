#!/usr/bin/env python3
"""Run aichat and append response usage and USD cost to the dotfiles ledger."""

from datetime import datetime, timezone
from decimal import Decimal
import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory


PRICING_URL = "https://developers.openai.com/api/docs/pricing"
PRICING_CHECKED = "2026-11-11"
# GPT-6 Luna USD per million tokens: input, cached input, output.
LUNA_RATES = tuple(Decimal(value) for value in ("0.10", "0.01", "0.50"))
TIER_MULTIPLIERS = {
    "default": Decimal(1),
    "flex": Decimal("0.5"),
    "priority": Decimal(2),
    "fast": Decimal(2),
}


def cost_for_response(response):
    usage = response.get("usage") or {}
    cost = usage.get("cost")
    if cost is None:
        cost = response.get("cost")
    if cost is not None:
        cost = Decimal(str(cost))
        if not cost.is_finite() or cost < 0:
            raise ValueError("invalid cost in API response")
        return {"cost_usd": float(cost), "cost_source": "response"}

    tier = response.get("service_tier") or "default"
    details = usage.get("prompt_tokens_details") or {}
    if (
        response.get("model") != "gpt-6-luna"
        or tier not in TIER_MULTIPLIERS
        or details.get("cache_write_tokens", 0)
        or "prompt_tokens" not in usage
        or "completion_tokens" not in usage
    ):
        return {"cost_usd": None, "cost_source": "unavailable"}

    input_rate, cached_rate, output_rate = LUNA_RATES
    cached = details.get("cached_tokens", 0)
    cost = (
        (usage["prompt_tokens"] - cached) * input_rate
        + cached * cached_rate
        + usage["completion_tokens"] * output_rate
    )
    cost *= TIER_MULTIPLIERS[tier] / 1_000_000
    return {
        "cost_usd": float(cost),
        "cost_source": "estimated",
        "pricing_url": PRICING_URL,
        "pricing_checked": PRICING_CHECKED,
    }


def record_responses(response_log, cost_file, repository):
    recorded = 0
    for line in response_log.read_text().splitlines():
        marker = "non-stream-data: "
        if marker not in line:
            continue
        response = json.loads(line.split(marker, 1)[1])
        entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "repository": str(repository),
            "response_id": response.get("id"),
            "model": response.get("model"),
            "service_tier": response.get("service_tier"),
            "usage": response.get("usage"),
            **cost_for_response(response),
        }
        with cost_file.open("a") as ledger:
            fcntl.flock(ledger, fcntl.LOCK_EX)
            ledger.write(json.dumps(entry) + "\n")
        recorded += 1
        if entry["cost_usd"] is None:
            print("lgai: usage saved, but no cost or supported pricing was available.", file=sys.stderr)
        else:
            print(f"lgai: ${entry['cost_usd']:.8f} USD ({entry['cost_source']})", file=sys.stderr)
    return recorded


def generate(prompt, cost_file, repository):
    with TemporaryDirectory(prefix="lgai-response-") as directory:
        response_log = Path(directory) / "response.log"
        env = dict(
            os.environ,
            AICHAT_LOG_LEVEL="debug",
            AICHAT_LOG_FILTER="aichat::client::openai",
            AICHAT_LOG_PATH=str(response_log),
        )
        # Non-streaming gives us one complete usage object. Only OpenAI response
        # logs are enabled; the temporary raw response is deleted after recording.
        result = subprocess.run(["aichat", "--no-stream", prompt], env=env)
        try:
            recorded = record_responses(response_log, cost_file, repository)
            if result.returncode == 0 and recorded == 0:
                print("lgai: no API usage found; cost was not recorded.", file=sys.stderr)
        except (OSError, ValueError, ArithmeticError) as error:
            print(f"lgai: could not record cost: {error}", file=sys.stderr)
        return result.returncode


if __name__ == "__main__":
    ledger = Path(__file__).resolve().parents[1] / ".lgai-costs.jsonl"
    repository = subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()
    sys.exit(generate(sys.argv[1], ledger, repository))
