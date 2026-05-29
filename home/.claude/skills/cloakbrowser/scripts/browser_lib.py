#!/usr/bin/env python3
"""Shared browser utilities for cloakbrowser scripts.

Provides agent-browser CLI helpers, CloakBrowser binary resolution,
stealth flags, and JS eval extraction — used by crawl.py, ddg-search.py,
mercadolibre.py and other scripts.
"""
import os, re, json, subprocess
from pathlib import Path

FLAGS = [
    "--disable-blink-features=AutomationControlled",
    "--no-first-run",
    "--no-default-browser-check",
    "--disable-infobars",
    "--blink-settings=imagesEnabled=false",
]

CLOAK_BIN = os.environ.get("AGENT_BROWSER_EXECUTABLE_PATH") or next(
    (str(p) for p in Path.home().glob(".cloakbrowser/chromium-*/chrome")), ""
)

IDLE_TIMEOUT = os.environ.get("AGENT_BROWSER_IDLE_TIMEOUT_MS", "180000")


def _cmd(flags=None):
    """Build agent-browser CLI command."""
    f = flags if flags is not None else FLAGS
    return [
        "agent-browser",
        "--executable-path", CLOAK_BIN,
        "--args", ",".join(f),
    ]


def ab(*args, flags=None, **kwargs):
    """Run a single agent-browser CLI command."""
    env = {**os.environ, "AGENT_BROWSER_IDLE_TIMEOUT_MS": IDLE_TIMEOUT}
    return subprocess.run(_cmd(flags) + list(args), capture_output=True, text=True, env=env, **kwargs)


def ab_batch(*cmds, flags=None, **kwargs):
    """Run batch commands via agent-browser batch --json."""
    env = {**os.environ, "AGENT_BROWSER_IDLE_TIMEOUT_MS": IDLE_TIMEOUT}
    return subprocess.run(
        _cmd(flags) + ["batch", "--json"],
        input=json.dumps([list(c) for c in cmds]),
        capture_output=True, text=True, env=env, **kwargs,
    )


def _eval_result(r):
    """Extract string result from a batch eval output entry (JSON dict)."""
    if isinstance(r, str):
        # Already a string (from raw ab('eval', ...) output)
        if len(r) > 2 and r[0] == '"' and r[-1] == '"':
            return r[1:-1].encode().decode("unicode_escape")
        return r
    v = r.get("result", {})
    if isinstance(v, dict):
        v = v.get("result", "")
    if isinstance(v, str) and len(v) > 2 and v[0] == '"' and v[-1] == '"':
        return v[1:-1].encode().decode("unicode_escape")
    return str(v) if v else ""


def is_url(s):
    return bool(re.match(r"^https?://", s)) and "." in s


def eval_from_subprocess(result):
    """Extract string result from a subprocess run stdout (raw CLI eval output)."""
    v = result.stdout.strip()
    if not v:
        return ""
    if len(v) > 2 and v[0] == '"' and v[-1] == '"':
        return v[1:-1].encode().decode("unicode_escape")
    return v


def _get_tab_id(results, index=0):
    """Extract tabId from a batch tab/new result."""
    return results[index].get("result", {}).get("tabId")


def close_tab(tab_id):
    """Close a specific tab if valid."""
    if tab_id:
        ab("tab", "close", tab_id)


def close_all():
    """Close all browser sessions."""
    ab("close")


def open_tab(url):
    """Open a URL in a new tab. Returns tab_id."""
    r = ab_batch(["tab", "new", url])
    results = json.loads(r.stdout.strip())
    return _get_tab_id(results)


def wait_networkidle(timeout=15000):
    """Wait for network idle."""
    ab("wait", "--load", "networkidle", "--timeout", str(timeout))


def scroll_down(px=800):
    """Scroll down by px pixels."""
    ab("scroll", "down", str(px))


def eval_js(js):
    """Run eval and return the string result."""
    return _eval_result(json.loads(ab("eval", js).stdout.strip()))


def eval_batch(js, *pre_cmds, post_cmds=()):
    """Batch: pre_cmds → eval(js) → post_cmds. Returns eval result."""
    cmds = [list(c) for c in pre_cmds] + [["eval", js]] + [list(c) for c in post_cmds]
    r = ab_batch(*(cmds))
    results = json.loads(r.stdout.strip())
    return _eval_result(results[len(pre_cmds)])
