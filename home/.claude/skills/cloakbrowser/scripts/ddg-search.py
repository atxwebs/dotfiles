#!/usr/bin/env python3
"""DuckDuckGo HTML search via agent-browser daemon + Playwright CDP + CloakBrowser humanize.

Tab-per-call model:
  - First call spawns the daemon (~600MB), reuses it on subsequent calls
  - Each invocation gets a Playwright page connected via CDP with humanize patches
  - Daemon auto-shutdowns after idle (AGENT_BROWSER_IDLE_TIMEOUT_MS)
"""
import sys, os, re, json, time
from datetime import datetime
from pathlib import Path
from urllib.parse import quote

from browser_lib import ensure_daemon, connect_cdp, disconnect_cdp

EXTRACT_JS = r"""
(() => {
  const re = /[?&]uddg=([^&]+)/;
  return [...document.querySelectorAll('.result')]
    .filter(r => !r.classList.contains('result--ad'))
    .map(r => {
      const a = r.querySelector('.result__a');
      const href = (a || {}).href || '';
      const m = href.match(re);
      const url = m ? decodeURIComponent(m[1]) : href;
      if (!url) return null;
      return { title: (a ? a.textContent : '').trim(), url, snippet: ((r.querySelector('.result__snippet') || {}).textContent || '').trim() };
    }).filter(Boolean);
})()
"""


def read_jsonl(path):
    return [json.loads(line) for line in path.read_text().strip().splitlines() if line.strip()]


def main():
    query, min_seconds = "", None
    i = 1
    while i < len(sys.argv):
        if sys.argv[i] == "--min-seconds" and i + 1 < len(sys.argv):
            min_seconds = int(sys.argv[i + 1]); i += 2
        elif not query:
            query = sys.argv[i]; i += 1
        else:
            i += 1

    if not query:
        print('Usage: ddg-search.py "search query" [--min-seconds N]', file=sys.stderr)
        sys.exit(1)

    start = time.time()
    url = f"https://html.duckduckgo.com/html/?q={quote(query)}"

    slug = re.sub(r"[^a-z0-9]", "-", query.lower()).strip("-")
    date_dir = datetime.now().strftime("%Y-%m-%d")
    hour = datetime.now().strftime("%H")
    out_dir = os.environ.get("DDG_SEARCH_OUTPUT_DIR", "/tmp")
    out_file = Path(out_dir) / date_dir / f"{hour}-{slug}.jsonl"

    if out_file.exists() and (lines := out_file.read_text().strip()):
        results = read_jsonl(out_file)
    else:
        if min_seconds:
            start = time.time()

        pw, browser, context, page = None, None, None, None
        try:
            ws_url = ensure_daemon(url)
            pw, browser, context, page = connect_cdp(ws_url)

            page.wait_for_load_state("networkidle")
            raw = page.evaluate(EXTRACT_JS)

            try:
                results = raw if isinstance(raw, list) else json.loads(raw)
            except (json.JSONDecodeError, TypeError):
                results = []

        except Exception as e:
            print(f"[ERROR] {e}", file=sys.stderr)
            results = []
        finally:
            if pw:
                disconnect_cdp(pw, browser)

        if out_file:
            out_file.parent.mkdir(parents=True, exist_ok=True)
            with open(out_file, "w") as f:
                for r in results:
                    f.write(json.dumps(r, ensure_ascii=False) + "\n")

        if min_seconds:
            remaining = min_seconds - (time.time() - start)
            if remaining > 0:
                time.sleep(remaining)

    print(f"Saved to: {out_file}\n")
    for r in results:
        print(f"[{r['title']}]({r['url']})\n> {r['snippet']}\n")


if __name__ == "__main__":
    main()
