#!/usr/bin/env python3
"""Ad-hoc browser exploration via Playwright CDP + CloakBrowser.

Usage:
    custom.py <url>              # Open URL, print title + text
    custom.py <url> --eval <js>  # Run JS and print result
    custom.py <url> --snapshot   # Print accessibility snapshot
    custom.py <url> --html       # Print page HTML
    custom.py <url> --text       # Print page text content
"""
import argparse
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from browser_lib import ensure_daemon, connect_cdp, disconnect_cdp


def main():
    parser = argparse.ArgumentParser(description="Ad-hoc CloakBrowser exploration")
    parser.add_argument("url", help="URL to open")
    parser.add_argument("--eval", dest="js", help="JavaScript to evaluate")
    parser.add_argument("--snapshot", action="store_true", help="Print accessibility snapshot")
    parser.add_argument("--html", action="store_true", help="Print page HTML")
    parser.add_argument("--text", action="store_true", help="Print page text content")
    args = parser.parse_args()

    pw, browser, context, page = None, None, None, None
    try:
        ws_url = ensure_daemon(args.url)
        pw, browser, context, page = connect_cdp(ws_url)

        page.goto(args.url, wait_until="networkidle", timeout=30000)

        if args.snapshot:
            # Use agent-browser CLI for snapshot (not available over Playwright)
            import subprocess
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

    finally:
        if pw:
            disconnect_cdp(pw, browser)


if __name__ == "__main__":
    main()
