"""Shared Playwright CDP + CloakBrowser library.

All cloakbrowser scripts should use this. Provides:
  - ensure_daemon(url)      → Start agent-browser daemon with CloakBrowser, return CDP WebSocket URL
  - connect_cdp(ws_url)     → Connect Playwright, apply humanize patches, return (pw, browser, context, page)
  - disconnect_cdp(pw, br)  → Cleanly disconnect Playwright; daemon keeps browser alive
  - idle(sec)               → Human-like pause with micro-movement between actions
  - CLOAK_BIN               → Resolved CloakBrowser binary path
"""
import os
import random
import subprocess
import time
from pathlib import Path

from playwright.sync_api import sync_playwright

from cloakbrowser.human import patch_browser, resolve_config

# ─── Configuration ──────────────────────────────────────────────────────────

CLOAK_BIN = os.environ.get("CLOAKBROWSER_BINARY_PATH") or next(
    (str(p) for p in Path.home().glob(".cloakbrowser/chromium-*/chrome")), ""
)

IDLE_TIMEOUT = os.environ.get("AGENT_BROWSER_IDLE_TIMEOUT_MS", "180000")  # 3 min

# ─── Daemon lifecycle ───────────────────────────────────────────────────────

def ensure_daemon(url: str) -> str:
    """Start agent-browser daemon with CloakBrowser, return CDP WebSocket URL."""
    env = {
        **os.environ,
        "AGENT_BROWSER_EXECUTABLE_PATH": CLOAK_BIN,
        "AGENT_BROWSER_ARGS": "--no-sandbox,--fingerprint=12345,--fingerprint-platform=windows",
        "AGENT_BROWSER_IDLE_TIMEOUT_MS": IDLE_TIMEOUT,
    }
    cmd = ["agent-browser", "open", url]
    if os.environ.get("AGENT_BROWSER_HEADED", "0") in ("1", "true"):
        cmd.insert(1, "--headed")
    subprocess.run(cmd, capture_output=True, text=True, env=env, timeout=30)
    ws_url = subprocess.run(
        ["agent-browser", "get", "cdp-url"],
        capture_output=True, text=True, env=env, timeout=10,
    ).stdout.strip()
    return ws_url


# ─── CDP connection ─────────────────────────────────────────────────────────

def connect_cdp(ws_url: str, idle_delays: bool = False):
    """Connect Playwright to CDP, apply humanize patches, return (pw, browser, context, page)."""
    pw = sync_playwright().start()
    browser = pw.chromium.connect_over_cdp(ws_url)
    context = browser.contexts[0]
    page = context.pages[0] if context.pages else context.new_page()
    cfg = resolve_config("default", {"idle_between_actions": idle_delays})
    patch_browser(browser, cfg)
    page.set_viewport_size({"width": 1280, "height": 720})
    return pw, browser, context, page


def disconnect_cdp(pw, browser):
    """Cleanly disconnect Playwright; daemon keeps browser alive for idle timeout."""
    try:
        browser.close()
    except Exception:
        pass
    try:
        pw.stop()
    except Exception:
        pass


# ─── Human-like behavior ────────────────────────────────────────────────────

def idle(seconds: float | tuple[float, float] = None):
    """Pause with human-like idle movement. Use between raw mouse.move() calls.

    Args:
        seconds: Fixed duration, or a (min, max) tuple. Default: (0.3, 0.8).
    """
    if seconds is None:
        duration = 0.3 + random.random() * 0.5
    elif isinstance(seconds, tuple):
        duration = seconds[0] + random.random() * (seconds[1] - seconds[0])
    else:
        duration = seconds
    time.sleep(duration)
