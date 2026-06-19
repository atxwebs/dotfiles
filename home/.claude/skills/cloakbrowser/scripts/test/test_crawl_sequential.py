#!/usr/bin/env python3
"""Sequential crawl: one connect_cdp, one tab, multiple page.goto() calls.

Verifies:
  - E2E subprocess: crawl.py output sections match URLs in order
  - connect_cdp / disconnect_cdp each called exactly once for N URLs
"""
import io
import os
import re
import subprocess
import sys
import tempfile
from contextlib import redirect_stderr, redirect_stdout
from unittest import mock

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.dirname(__file__))
from test_lib import SITES, CRAWL_SCRIPT, TestRun, check_page_content, exit_with


def parse_crawl_sections(stdout):
    return [s.strip() for s in stdout.split("---END---") if s.strip()]


def test_e2e(run):
    urls = [s["url"] for s in SITES]
    proc = subprocess.run(
        [sys.executable, CRAWL_SCRIPT, *urls],
        capture_output=True, text=True, timeout=120,
    )
    if proc.returncode != 0:
        run.fail(f"E2E exit {proc.returncode}: {proc.stderr[:200]}")
        return

    sections = parse_crawl_sections(proc.stdout)
    run.check(
        len(sections) == len(SITES),
        f"E2E — {len(sections)} output sections",
        f"E2E — expected {len(SITES)} sections, got {len(sections)}",
    )

    timings = re.findall(r"\[TIMING\]", proc.stderr)
    run.check(
        len(timings) == len(SITES),
        f"E2E — {len(timings)} timing lines (one per URL)",
        f"E2E — expected {len(SITES)} [TIMING] lines, got {len(timings)}",
    )

    for site, section in zip(SITES, sections):
        run.check(
            section.startswith(f"URL: {site['url']}"),
            f"E2E {site['name']} — URL header",
            f"E2E {site['name']} — bad header: {section[:80]!r}",
        )
        check_page_content(
            run, f"E2E {site['name']}", site["url"], site["host"],
            section, site["marker"], site["forbidden"],
        )


def test_single_connection(run):
    import crawl
    from browser_lib import ensure_daemon as real_ensure

    urls = [s["url"] for s in SITES]
    connect_calls = []
    disconnect_calls = []
    real_connect = crawl.connect_cdp
    real_disconnect = crawl.disconnect_cdp

    def counting_connect(ws_url, *args, **kwargs):
        connect_calls.append(ws_url)
        return real_connect(ws_url, *args, **kwargs)

    def counting_disconnect(pw, browser, page=None):
        disconnect_calls.append(page)
        return real_disconnect(pw, browser, page)

    with mock.patch.object(crawl, "connect_cdp", side_effect=counting_connect), \
         mock.patch.object(crawl, "disconnect_cdp", side_effect=counting_disconnect), \
         mock.patch.object(crawl, "ensure_daemon", side_effect=lambda u: real_ensure("about:blank")), \
         mock.patch.object(sys, "argv", ["crawl.py", *urls]):
        with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
            crawl.main()

    run.check(
        len(connect_calls) == 1,
        "single-connect — connect_cdp called once",
        f"single-connect — connect_cdp called {len(connect_calls)} times",
    )
    run.check(
        len(disconnect_calls) == 1,
        "single-connect — disconnect_cdp called once",
        f"single-connect — disconnect_cdp called {len(disconnect_calls)} times",
    )
    run.check(
        disconnect_calls[0] is not None,
        "single-connect — disconnect received page",
        "single-connect — disconnect_cdp called without page",
    )


def main():
    runs = []
    for title, fn in [
        ("test_crawl_e2e", test_e2e),
        ("test_crawl_single_connection", test_single_connection),
    ]:
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
