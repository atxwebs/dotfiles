#!/usr/bin/env python3
"""Concurrent tab isolation: 3 threads, each gets its own tab via connect_cdp.

Verifies:
  - Each thread lands on the correct hostname (not just substring match)
  - No cross-site content leakage between tabs
  - disconnect_cdp runs even on failure (try/finally)
  - Hung threads are reported explicitly
"""
import os
import sys
import threading
import time

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.dirname(__file__))
from browser_lib import ensure_daemon, connect_cdp, disconnect_cdp
from test_lib import SITES, THREAD_JOIN_TIMEOUT, TestRun, check_page_content, exit_with

PAGE_META_JS = """() => ({
  href: location.href,
  host: location.hostname,
  title: document.title,
})"""


def crawl_thread(site, results, run):
    name = site["name"]
    url = site["url"]
    pw, browser, page = None, None, None
    try:
        ws_url = ensure_daemon("about:blank")
        pw, browser, _, page = connect_cdp(ws_url)
        page.goto(url, wait_until="load", timeout=20000)
        meta = page.evaluate(PAGE_META_JS)
        text = page.evaluate("document.body.innerText") or ""
        results[name] = {
            "url": url,
            "host": site["host"],
            "meta": meta,
            "text": text.strip(),
            "marker": site["marker"],
            "forbidden": site["forbidden"],
        }
    except Exception as e:
        results[name] = {"url": url, "error": str(e)}
        run.fail(f"{name} ({url}) — {e}")
    finally:
        if pw:
            disconnect_cdp(pw, browser, page)


def main():
    run = TestRun("test_concurrent")
    results = {}
    threads = [
        threading.Thread(
            target=crawl_thread,
            args=(site, results, run),
            name=f"crawl-{site['name']}",
            daemon=True,
        )
        for site in SITES
    ]

    start = time.time()
    for t in threads:
        t.start()
    hung = []
    for t in threads:
        t.join(timeout=THREAD_JOIN_TIMEOUT)
        if t.is_alive():
            hung.append(t.name)
    elapsed = time.time() - start
    print(f"\nCompleted in {elapsed:.2f}s\n")

    if hung:
        run.fail(f"threads still alive after {THREAD_JOIN_TIMEOUT}s: {', '.join(hung)}")

    for site in SITES:
        got = results.get(site["name"])
        if not got:
            run.fail(f"{site['name']} ({site['url']}) — no result")
            continue
        if "error" in got:
            continue  # already reported in thread

        meta = got["meta"]
        run.check(
            meta.get("host") == site["host"],
            f"{site['name']} — hostname {meta.get('host')}",
            f"{site['name']} ({site['url']}) — wrong host: got '{meta.get('host')}', expected '{site['host']}'",
        )
        run.check(
            site["url"].rstrip("/") in meta.get("href", "").rstrip("/")
            or meta.get("href", "").startswith(site["url"].split("?")[0]),
            f"{site['name']} — href matches",
            f"{site['name']} ({site['url']}) — href mismatch: {meta.get('href')}",
        )
        check_page_content(
            run, site["name"], site["url"], site["host"],
            got["text"], site["marker"], site["forbidden"],
        )

    return run.finish()


if __name__ == "__main__":
    sys.exit(main())
