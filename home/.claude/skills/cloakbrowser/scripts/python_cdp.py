#!/usr/bin/env python3
"""Connect Playwright to agent-browser daemon (CloakBrowser) via CDP.

Usage:
    python_cdp.py <url>              # Open URL, print title + text
    python_cdp.py <url> --eval <js>  # Run JS and print result
    python_cdp.py <url> --snapshot   # Print accessibility snapshot

Pattern: agent-browser daemon launches CloakBrowser → Python connects via
connect_over_cdp() → Python disconnects → daemon auto-shutdowns after idle.
"""

import argparse
import os
import subprocess
import sys

from playwright.sync_api import sync_playwright

CLOAK_BIN = os.path.expanduser("~/.cloakbrowser/chromium-146.0.7680.177.5/chrome")
# Fallback to any version if the specific one doesn't exist
if not os.path.exists(CLOAK_BIN):
    import glob
    matches = glob.glob(os.path.expanduser("~/.cloakbrowser/chromium-*/chrome"))
    CLOAK_BIN = matches[-1] if matches else CLOAK_BIN


def ensure_daemon(url: str) -> str:
    """Start agent-browser daemon with CloakBrowser if not running, return CDP URL."""
    env = {
        **os.environ,
        "AGENT_BROWSER_EXECUTABLE_PATH": CLOAK_BIN,
        "AGENT_BROWSER_ARGS": "--no-sandbox,--fingerprint=12345,--fingerprint-platform=windows",
        "AGENT_BROWSER_IDLE_TIMEOUT_MS": "300000",
    }
    subprocess.run(
        ["agent-browser", "open", url],
        capture_output=True, text=True, env=env, timeout=30,
    )
    ws_url = subprocess.run(
        ["agent-browser", "get", "cdp-url"],
        capture_output=True, text=True, env=env, timeout=10,
    ).stdout.strip()
    return ws_url


def main():
    parser = argparse.ArgumentParser(description="Python CDP connection to CloakBrowser daemon")
    parser.add_argument("url", help="URL to open")
    parser.add_argument("--eval", dest="js", help="JavaScript to evaluate")
    parser.add_argument("--snapshot", action="store_true", help="Print accessibility snapshot")
    parser.add_argument("--html", action="store_true", help="Print page HTML")
    parser.add_argument("--text", action="store_true", help="Print page text content")
    args = parser.parse_args()

    ws_url = ensure_daemon(args.url)

    pw = sync_playwright().start()
    try:
        browser = pw.chromium.connect_over_cdp(ws_url)
        context = browser.contexts[0]
        page = context.pages[0] if context.pages else context.new_page()

        page.goto(args.url, wait_until="networkidle", timeout=30000)

        if args.snapshot:
            print(subprocess.run(
                ["agent-browser", "snapshot"],
                capture_output=True, text=True, timeout=15,
            ).stdout)
        elif args.js:
            result = page.evaluate(args.js)
            print(result)
        elif args.html:
            print(page.content())
        elif args.text:
            print(page.text_content("body"))
        else:
            print(f"Title: {page.title()}")
            print(f"URL: {page.url}")

        browser.close()
    finally:
        pw.stop()


if __name__ == "__main__":
    main()
