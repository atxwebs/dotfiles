"""Shared fixtures and helpers for cloakbrowser E2E tests."""
import sys
from pathlib import Path

SCRIPTS_DIR = Path(__file__).resolve().parent.parent
CRAWL_SCRIPT = str(SCRIPTS_DIR / "crawl.py")

# Stable public targets — unique markers + cross-site forbidden strings
SITES = (
    {
        "name": "example",
        "url": "https://example.com",
        "host": "example.com",
        "marker": "Example Domain",
        "forbidden": ("IANA-managed Reserved Domains", "home of the first website"),
    },
    {
        "name": "iana",
        "url": "https://www.iana.org/domains/reserved",
        "host": "www.iana.org",
        "marker": "IANA-managed Reserved Domains",
        "forbidden": ("home of the first website",),
    },
    {
        "name": "cern",
        "url": "https://info.cern.ch",
        "host": "info.cern.ch",
        "marker": "home of the first website",
        "forbidden": ("IANA-managed Reserved Domains",),
    },
)

THREAD_JOIN_TIMEOUT = 60


class TestRun:
    def __init__(self, title):
        self.title = title
        self.passed = 0
        self.failed = 0

    def ok(self, msg):
        print(f"  PASS  {msg}")
        self.passed += 1

    def fail(self, msg):
        print(f"  FAIL  {msg}")
        self.failed += 1

    def check(self, cond, ok_msg, fail_msg):
        if cond:
            self.ok(ok_msg)
        else:
            self.fail(fail_msg)

    def finish(self):
        print(f"\n{self.title}: {self.passed} passed, {self.failed} failed")
        return 1 if self.failed else 0


def check_page_content(run, label, url, host, text, marker, forbidden):
    """Assert URL landed on the right host with the right content, no cross-talk."""
    if not text:
        run.fail(f"{label} ({url}) — empty body")
        return False

    ok = True
    if host not in text and marker not in text:
        run.fail(f"{label} ({url}) — missing host '{host}' and marker '{marker}'")
        ok = False
    for phrase in forbidden:
        if phrase in text:
            run.fail(f"{label} ({url}) — cross-contamination: found '{phrase}'")
            ok = False
    if ok:
        run.ok(f"{label} ({url}) — host={host}, marker present, clean")
    return ok


def exit_with(results):
    total_failed = sum(r.failed for r in results)
    total_passed = sum(r.passed for r in results)
    print(f"\n{'=' * 40}")
    print(f"TOTAL: {total_passed} passed, {total_failed} failed")
    sys.exit(1 if total_failed else 0)
