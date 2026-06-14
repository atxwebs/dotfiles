"""Shared Playwright CDP + CloakBrowser library.

All cloakbrowser scripts should use this. Provides:
  - ensure_daemon(url)      → Start agent-browser daemon with CloakBrowser, return CDP WebSocket URL
  - connect_cdp(ws_url)     → Connect Playwright, apply humanize patches, return (pw, browser, context, page)
  - disconnect_cdp(pw, br, page) → Close tab, disconnect Playwright; daemon stays alive
  - wait_for_challenge(page) → Detect Cloudflare/Turnstile, wait and try free checkbox click
  - is_challenge_page(text) → True if page looks like a bot challenge
  - idle(sec)               → Human-like pause with micro-movement between actions
  - CLOAK_BIN               → Resolved CloakBrowser binary path
"""
import os
import random
import subprocess
import time
from datetime import datetime
from pathlib import Path

from playwright.sync_api import sync_playwright

from cloakbrowser import build_args
from cloakbrowser.config import DEFAULT_VIEWPORT
from cloakbrowser.human import patch_browser, resolve_config

# ─── Configuration ──────────────────────────────────────────────────────────

CLOAK_BIN = os.environ.get("CLOAKBROWSER_BINARY_PATH") or next(
    (str(p) for p in Path.home().glob(".cloakbrowser/chromium-*/chrome")), ""
)

IDLE_TIMEOUT = os.environ.get("AGENT_BROWSER_IDLE_TIMEOUT_MS", "180000")  # 3 min

CHALLENGE_MARKERS = (
    "just a moment",
    "checking your browser",
    "verify you are human",
    "attention required",
    "cf-turnstile",
)

# Don't block fonts — breaks Kasada/Akamai emoji canvas checks (library README)
BLOCKED_RESOURCE_TYPES = {"image", "media", "stylesheet"}


def _time_fingerprint() -> str:
    """Stable seed per ~10min daemon session (overrides library's random --fingerprint)."""
    now = datetime.now()
    return now.strftime("%y%m%d%H") + str(now.minute // 10)


def daemon_args() -> str:
    """Official agent-browser integration + time-based fingerprint override only.

    Matches examples/integrations/agent_browser.sh — get_default_stealth_args()
    via build_args(), nothing else. Time fingerprint replaces random seed for
    daemon session stability.
    """
    headed = os.environ.get("AGENT_BROWSER_HEADED", "0") in ("1", "true")
    extra = [f"--fingerprint={_time_fingerprint()}"]
    return ",".join(build_args(stealth_args=True, extra_args=extra, headless=not headed))


def _ensure_viewport(page) -> None:
    """Only if CDP reports no viewport — humanize needs it. Otherwise binary handles dimensions."""
    if not page.viewport_size:
        page.set_viewport_size(DEFAULT_VIEWPORT)


# ─── Daemon lifecycle ───────────────────────────────────────────────────────

def ensure_daemon(url: str) -> str:
    """Start agent-browser daemon with CloakBrowser, return CDP WebSocket URL."""
    env = {
        **os.environ,
        "AGENT_BROWSER_EXECUTABLE_PATH": CLOAK_BIN,
        "AGENT_BROWSER_ARGS": daemon_args(),
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

def connect_cdp(ws_url: str, idle_delays: bool = True, block: bool = True):
    """Connect Playwright to CDP, create a fresh page, apply humanize patches.

    humanize=True equivalent — README recommends for behavioral detection.
    https://github.com/CloakHQ/CloakBrowser#humanize

    Always creates a new page (tab) so concurrent callers don't share state.
    Returns (pw, browser, context, page).
    """
    pw = sync_playwright().start()
    browser = pw.chromium.connect_over_cdp(ws_url)
    context = browser.contexts[0]
    page = context.new_page()
    cfg = resolve_config("default", {"idle_between_actions": idle_delays})
    patch_browser(browser, cfg)  # humanize=True equivalent (library rec)
    _ensure_viewport(page)

    if block:
        def _block(route):
            if route.request.resource_type in BLOCKED_RESOURCE_TYPES:
                route.abort()
            else:
                route.continue_()
        page.route("**/*", _block)

    return pw, browser, context, page


def disconnect_cdp(pw, browser, page=None):
    """Close the page/tab, disconnect Playwright. Daemon stays alive for idle timeout."""
    if page:
        try:
            page.close()
        except Exception:
            pass
    try:
        pw.stop()
    except Exception:
        pass


# ─── Challenge detection / bypass ───────────────────────────────────────────

def is_challenge_page(text: str) -> bool:
    """True if page body looks like Cloudflare or similar bot challenge."""
    if not text:
        return False
    lower = text.lower()
    if any(m in lower for m in CHALLENGE_MARKERS):
        return True
    if "cloudflare" in lower and len(text) < 800:
        return True
    return False


def _try_click_turnstile(page) -> bool:
    """Click Turnstile checkbox in challenge iframes. Returns True if clicked."""
    selectors = (
        "input[type=checkbox]",
        "#cf-turnstile",
        ".ctp-checkbox-label",
        "label.ctp-checkbox-label",
        "[role=checkbox]",
    )
    for frame in page.frames:
        url = frame.url or ""
        if "challenges.cloudflare.com" not in url and "turnstile" not in url:
            continue
        for sel in selectors:
            try:
                loc = frame.locator(sel)
                if loc.count() > 0 and loc.first.is_visible(timeout=500):
                    loc.first.click(timeout=5000)
                    return True
            except Exception:
                continue
    return False


def wait_for_challenge(page, timeout: float = 45) -> bool:
    """Wait for Cloudflare/Turnstile to clear. Tries free checkbox click, then waits.

    Returns True if challenge appears resolved, False if still blocked after timeout.
    """
    deadline = time.time() + timeout
    clicked = False

    while time.time() < deadline:
        try:
            text = page.evaluate("document.body?.innerText || ''") or ""
        except Exception:
            text = ""

        if not is_challenge_page(text):
            return True

        if not clicked:
            clicked = _try_click_turnstile(page)
            if clicked:
                idle(1.5, 3.0)
                continue

        idle(0.8, 1.5)

    try:
        text = page.evaluate("document.body?.innerText || ''") or ""
    except Exception:
        text = ""
    return not is_challenge_page(text)


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
