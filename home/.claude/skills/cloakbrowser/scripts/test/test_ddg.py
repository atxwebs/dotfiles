#!/usr/bin/env python3
"""DDG search: browser e2e (default); optional html comparison via --include-html."""
import argparse
import json
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from urllib.parse import urlparse

sys.path.insert(0, os.path.dirname(__file__))

from test_lib import SCRIPTS_DIR, TestRun, exit_with

QUERY = "python web scraping"
MIN_RESULTS = 5
MIN_OVERLAP = 3


def normalize_url(url: str) -> str:
    parsed = urlparse(url)
    host = (parsed.netloc or "").lower().removeprefix("www.")
    path = parsed.path.rstrip("/")
    return f"{host}{path}"


def valid_result(r: dict) -> bool:
    return bool(r.get("title") and r.get("url") and r["url"].startswith("http"))


def read_jsonl_dir(tmp: str) -> list[dict]:
    files = list(Path(tmp).rglob("*.jsonl"))
    if not files:
        return []
    return [
        json.loads(line)
        for line in files[0].read_text().strip().splitlines()
        if line.strip()
    ]


def check_results(run: TestRun, label: str, results: list[dict]):
    run.check(
        len(results) >= MIN_RESULTS,
        f"{label} — {len(results)} results (>={MIN_RESULTS})",
        f"{label} — expected >={MIN_RESULTS} results, got {len(results)}",
    )
    bad = [r for r in results if not valid_result(r)]
    run.check(
        not bad,
        f"{label} — all results have title + http url",
        f"{label} — {len(bad)} invalid results",
    )


def run_ddg_script(script: Path, tmp: str) -> subprocess.CompletedProcess:
    env = {**os.environ, "DDG_SEARCH_OUTPUT_DIR": tmp}
    return subprocess.run(
        [sys.executable, str(script), QUERY],
        capture_output=True,
        text=True,
        timeout=120,
        env=env,
    )


def test_html_e2e(run: TestRun) -> list[dict] | None:
    with tempfile.TemporaryDirectory(prefix="ddg-html-e2e-") as tmp:
        t0 = time.perf_counter()
        proc = run_ddg_script(SCRIPTS_DIR / "ddg-html.py", tmp)
        elapsed = time.perf_counter() - t0
        run.check(
            proc.returncode == 0,
            "html e2e — exit 0",
            f"html e2e — exit {proc.returncode}: {proc.stderr[:200]}",
        )
        results = read_jsonl_dir(tmp)
        check_results(run, "html", results)
        run.ok(f"html — fetched in {elapsed:.2f}s")
        return results


def test_browser_e2e(run: TestRun) -> list[dict] | None:
    with tempfile.TemporaryDirectory(prefix="ddg-browser-e2e-") as tmp:
        t0 = time.perf_counter()
        proc = run_ddg_script(SCRIPTS_DIR / "ddg-search.py", tmp)
        elapsed = time.perf_counter() - t0
        run.check(
            proc.returncode == 0,
            "browser e2e — exit 0",
            f"browser e2e — exit {proc.returncode}: {proc.stderr[:200]}",
        )
        results = read_jsonl_dir(tmp)
        check_results(run, "browser", results)
        run.ok(f"browser — fetched in {elapsed:.2f}s")
        return results


def test_overlap(run: TestRun, html_results: list[dict], browser_results: list[dict]):
    html_urls = {normalize_url(r["url"]) for r in html_results[:10]}
    browser_urls = {normalize_url(r["url"]) for r in browser_results[:10]}
    overlap = html_urls & browser_urls
    run.check(
        len(overlap) >= MIN_OVERLAP,
        f"overlap — {len(overlap)} shared URLs in top 10 (>={MIN_OVERLAP})",
        f"overlap — only {len(overlap)} shared",
    )


def main():
    parser = argparse.ArgumentParser(description="DDG search E2E tests")
    parser.add_argument(
        "--include-html",
        action="store_true",
        help="Also run ddg-html.py tests and html/browser overlap comparison",
    )
    args = parser.parse_args()

    runs = []

    if args.include_html:
        html_run = TestRun("test_ddg_html_e2e")
        print(f"\n{'─' * 40}\ntest_ddg_html_e2e\n")
        html_results = None
        try:
            html_results = test_html_e2e(html_run)
        except Exception as e:
            html_run.fail(f"uncaught: {e}")
        html_run.finish()
        runs.append(html_run)

        overlap_run = TestRun("test_ddg_overlap")
        print(f"\n{'─' * 40}\ntest_ddg_overlap\n")
        try:
            if html_results:
                browser_results = test_browser_e2e(overlap_run)
                if browser_results:
                    test_overlap(overlap_run, html_results, browser_results)
            else:
                overlap_run.skip("overlap — no html results")
        except Exception as e:
            overlap_run.fail(f"uncaught: {e}")
        overlap_run.finish()
        runs.append(overlap_run)
    else:
        browser_run = TestRun("test_ddg_browser_e2e")
        print(f"\n{'─' * 40}\ntest_ddg_browser_e2e\n")
        try:
            test_browser_e2e(browser_run)
        except Exception as e:
            browser_run.fail(f"uncaught: {e}")
        browser_run.finish()
        runs.append(browser_run)

    exit_with(runs)


if __name__ == "__main__":
    main()
