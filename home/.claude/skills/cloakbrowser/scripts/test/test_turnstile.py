#!/usr/bin/env python3
"""Turnstile / challenge bypass smoke tests.

Local CF dummy sitekeys (no IP risk) plus live demo URLs when network allows.

Set CLOAK_TURNSTILE_INTERACTIVE=1 to run the headed local-interactive case
(3x...FF dummy — flaky, opens a visible browser).
"""
import http.server
import os
import socket
import subprocess
import sys
import threading
import time

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.dirname(__file__))
from test_lib import TestRun, exit_with

from browser_lib import (
    connect_cdp,
    disconnect_cdp,
    ensure_daemon,
    is_challenge_page,
    wait_for_challenge,
    _try_click_turnstile,
)

NAV_TIMEOUT_MS = 30_000
CHALLENGE_TIMEOUT = 45
TOKEN_WAIT = 30
DAEMON_RETRIES = 2

HTML_ALWAYS_PASS = """<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>turnstile-pass</title></head>
<body>
<h1 id="status">loading</h1>
<div class="cf-turnstile" data-sitekey="1x00000000000000000000AA" data-callback="onPass"></div>
<script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
<script>
function onPass(token) {
  document.getElementById("status").textContent = "passed:" + token.slice(0, 12);
}
</script>
</body></html>"""

HTML_INTERACTIVE = """<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>turnstile-interactive</title></head>
<body>
<h1 id="status">loading</h1>
<div class="cf-turnstile" data-sitekey="3x00000000000000000000FF" data-callback="onPass"></div>
<script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
<script>
function onPass(token) {
  document.getElementById("status").textContent = "passed:" + token.slice(0, 12);
}
</script>
</body></html>"""

EXTERNAL_SITES = (
    {
        "name": "cf-troubleshooter",
        "url": "https://browser-compat.turnstile.workers.dev/",
        "min_len": 40,
    },
    {
        "name": "peet-non-interactive",
        "url": "https://peet.ws/turnstile-test/non-interactive.html",
        "min_len": 20,
    },
    {
        "name": "nopecha",
        "url": "https://nopecha.com/demo/turnstile",
        "min_len": 20,
    },
    {
        "name": "2captcha",
        "url": "https://2captcha.com/demo/cloudflare-turnstile",
        "min_len": 20,
    },
)


def free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def start_local_server(html: str):
    port = free_port()
    body = html.encode()

    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *args):
            pass

    httpd = http.server.HTTPServer(("127.0.0.1", port), Handler)
    thread = threading.Thread(target=httpd.serve_forever, daemon=True)
    thread.start()
    return httpd, f"http://127.0.0.1:{port}/"


def stop_local_server(httpd):
    httpd.shutdown()


def headed_available() -> bool:
    return bool(os.environ.get("DISPLAY") or os.environ.get("WAYLAND_DISPLAY"))


def close_daemon():
    subprocess.run(["agent-browser", "close"], capture_output=True, timeout=15)


def open_daemon(url: str) -> str:
    last_err = None
    for attempt in range(DAEMON_RETRIES):
        try:
            return ensure_daemon(url)
        except subprocess.TimeoutExpired as e:
            last_err = e
            close_daemon()
            if attempt + 1 < DAEMON_RETRIES:
                time.sleep(2)
    raise last_err


def wait_for_token(page, timeout: float = TOKEN_WAIT) -> str:
    deadline = time.time() + timeout
    while time.time() < deadline:
        token = page.evaluate(
            "() => document.querySelector('[name=cf-turnstile-response]')?.value || ''"
        ) or ""
        if token:
            return token
        _try_click_turnstile(page)
        wait_for_challenge(page, timeout=5)
        time.sleep(1)
    return ""


def visit(url: str, expect_token: bool = False) -> dict:
    """Navigate with CloakBrowser; return {ok, text, blocked, token, error}."""
    result = {"ok": False, "text": "", "blocked": True, "token": "", "error": ""}
    pw = browser = page = None
    try:
        ws_url = open_daemon(url)
        pw, browser, _ctx, page = connect_cdp(ws_url, block=False)
        page.goto(url, wait_until="load", timeout=NAV_TIMEOUT_MS)

        cleared = wait_for_challenge(page, timeout=CHALLENGE_TIMEOUT)
        text = page.evaluate("document.body?.innerText || ''") or ""
        token = wait_for_token(page) if expect_token else (
            page.evaluate("() => document.querySelector('[name=cf-turnstile-response]')?.value || ''") or ""
        )

        blocked = not cleared or is_challenge_page(text)
        result.update(ok=not blocked, text=text, blocked=blocked, token=token)
    except Exception as e:
        result["error"] = str(e)
    finally:
        if pw is not None:
            disconnect_cdp(pw, browser, page)
    return result


def test_local_dummy(run, name: str, html: str, expect_token: bool, headed: bool = False):
    if headed and not headed_available():
        run.skip(f"{name} — no DISPLAY (interactive dummy needs headed)")
        return

    prev_headed = os.environ.get("AGENT_BROWSER_HEADED")
    if headed:
        close_daemon()
        os.environ["AGENT_BROWSER_HEADED"] = "1"

    httpd, url = start_local_server(html)
    try:
        r = visit(url, expect_token=expect_token)
        if r["error"]:
            run.fail(f"{name} — {r['error']}")
            return
        if r["blocked"]:
            run.fail(f"{name} — still blocked after wait_for_challenge")
            return
        if expect_token and not r["token"]:
            run.fail(f"{name} — no turnstile token (status: {r['text'][:80]!r})")
            return
        detail = f"token={r['token'][:12]}..." if r["token"] else f"len={len(r['text'])}"
        run.ok(f"{name} — not blocked ({detail})")
    finally:
        stop_local_server(httpd)
        if headed:
            close_daemon()
            if prev_headed is None:
                os.environ.pop("AGENT_BROWSER_HEADED", None)
            else:
                os.environ["AGENT_BROWSER_HEADED"] = prev_headed


def test_external(run, site: dict):
    r = visit(site["url"])
    label = site["name"]
    if r["error"]:
        run.fail(f"{label} — {r['error']}")
        return
    if r["blocked"]:
        run.fail(f"{label} — blocked ({r['text'][:120]!r})")
        return
    if len(r["text"]) < site["min_len"]:
        run.fail(f"{label} — body too short ({len(r['text'])} chars)")
        return
    run.ok(f"{label} — not blocked (len={len(r['text'])})")


def interactive_enabled() -> bool:
    return os.environ.get("CLOAK_TURNSTILE_INTERACTIVE", "0") in ("1", "true")


def main():
    runs = []
    cases = [
        ("test_turnstile_local_pass", lambda run: test_local_dummy(
            run, "local-pass", HTML_ALWAYS_PASS, expect_token=True)),
    ]
    if interactive_enabled():
        cases.append((
            "test_turnstile_local_interactive",
            lambda run: test_local_dummy(
                run, "local-interactive", HTML_INTERACTIVE, expect_token=True, headed=True),
        ))
    for site in EXTERNAL_SITES:
        cases.append((
            f"test_turnstile_{site['name']}",
            lambda run, s=site: test_external(run, s),
        ))

    for title, fn in cases:
        print(f"\n{'─' * 40}\n{title}\n")
        run = TestRun(title)
        try:
            fn(run)
        except Exception as e:
            run.fail(f"uncaught: {e}")
        runs.append(run)
        print()
        run.finish()

    exit_with(runs)


if __name__ == "__main__":
    main()
