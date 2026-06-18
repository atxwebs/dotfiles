#!/usr/bin/env python3
"""DuckDuckGo HTML search via plain HTTP fetch (no browser).

Uses html.duckduckgo.com which returns server-rendered HTML — no JS needed.
"""
import json
import os
import re
import sys
from datetime import datetime
from html import unescape
from pathlib import Path
from urllib.parse import unquote

import requests

UDDG_RE = re.compile(r"[?&]uddg=([^&\"]+)")
TAG_RE = re.compile(r"<[^>]+>")
RESULT_SPLIT_RE = re.compile(r'<div class="result ')
RESULT_A_RE = re.compile(
    r'class="result__a" href="([^"]*)"[^>]*>(.*?)</a>', re.DOTALL
)
SNIPPET_RE = re.compile(
    r'class="result__snippet"[^>]*>(.*?)</a>', re.DOTALL
)
HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml",
    "Accept-Language": "en-US,en;q=0.9",
}


def strip_tags(text: str) -> str:
    return unescape(TAG_RE.sub("", text)).strip()


def decode_ddg_url(href: str) -> str:
    m = UDDG_RE.search(href)
    if m:
        return unquote(m.group(1))
    if href.startswith("//"):
        return "https:" + href
    return href


def parse_results(html: str) -> list[dict]:
    results = []
    for block in RESULT_SPLIT_RE.split(html)[1:]:
        if block.startswith("result--ad"):
            continue

        a_match = RESULT_A_RE.search(block)
        if not a_match:
            continue

        href, title_html = a_match.groups()
        url = decode_ddg_url(href)
        if not url:
            continue

        snippet_match = SNIPPET_RE.search(block)
        snippet = strip_tags(snippet_match.group(1)) if snippet_match else ""

        results.append({
            "title": strip_tags(title_html),
            "url": url,
            "snippet": snippet,
        })

    return results


def read_jsonl(path: Path) -> list[dict]:
    return [
        json.loads(line)
        for line in path.read_text().strip().splitlines()
        if line.strip()
    ]


def fetch_results(query: str, page: int | None) -> list[dict]:
    params = {"q": query}
    if page and page > 1:
        params["s"] = (page - 1) * 20

    resp = requests.get(
        "https://html.duckduckgo.com/html/",
        params=params,
        headers=HEADERS,
        timeout=30,
    )
    resp.raise_for_status()
    if resp.status_code == 202 or "anomaly.js" in resp.text:
        raise RuntimeError(
            "DDG challenge/rate-limit page (HTTP 202) — use ddg-search.py instead"
        )
    return parse_results(resp.text)


def main():
    query, page = "", None
    i = 1
    while i < len(sys.argv):
        if sys.argv[i] == "--page" and i + 1 < len(sys.argv):
            page = int(sys.argv[i + 1])
            i += 2
        elif not query:
            query = sys.argv[i]
            i += 1
        else:
            i += 1

    if not query:
        print('Usage: ddg-html.py "search query" [--page N]', file=sys.stderr)
        sys.exit(1)

    slug = re.sub(r"[^a-z0-9]", "-", query.lower()).strip("-")
    page_suffix = f"-page{page}" if page and page > 1 else ""
    date_dir = datetime.now().strftime("%Y-%m-%d")
    hour = datetime.now().strftime("%H")
    out_dir = os.environ.get("DDG_SEARCH_OUTPUT_DIR", "/tmp")
    out_file = Path(out_dir) / date_dir / f"{hour}-{slug}{page_suffix}.jsonl"

    if out_file.exists() and out_file.read_text().strip():
        results = read_jsonl(out_file)
    else:
        had_error = False
        try:
            results = fetch_results(query, page)
        except Exception as e:
            print(f"[ERROR] {e}", file=sys.stderr)
            had_error = True
            results = []

        if not had_error:
            out_file.parent.mkdir(parents=True, exist_ok=True)
            with open(out_file, "w") as f:
                for r in results:
                    f.write(json.dumps(r, ensure_ascii=False) + "\n")

    print(f"Saved to: {out_file}\n")
    for r in results:
        print(f"[{r['title']}]({r['url']})\n> {r['snippet']}\n")


if __name__ == "__main__":
    main()
