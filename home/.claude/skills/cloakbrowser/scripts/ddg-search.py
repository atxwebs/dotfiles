#!/usr/bin/env python3
"""DuckDuckGo HTML search via agent-browser + CloakBrowser binary.

Tab-per-call model:
  - First call spawns the daemon (~600MB), reuses it on subsequent calls
  - Each invocation opens a new tab, works on it, then closes the tab
  - Daemon auto-shutdowns after 5 min idle (AGENT_BROWSER_IDLE_TIMEOUT_MS)
  - Concurrent calls share one browser instance, each gets its own tab
"""
import sys, os, re, json, time, subprocess
from datetime import datetime
from pathlib import Path
from urllib.parse import quote

STEALTH_FLAGS = [
    "--disable-blink-features=AutomationControlled",
    "--no-first-run",
    "--no-default-browser-check",
    "--disable-infobars",
]

CLOAK_BIN = os.environ.get("CLOAK_BIN") or next(
    (str(p) for p in Path.home().glob(".cloakbrowser/chromium-*/chrome")), ""
)

IDLE_TIMEOUT = os.environ.get("AGENT_BROWSER_IDLE_TIMEOUT_MS", "300000")  # 5 min

def _cmd():
    return [
        "agent-browser",
        "--executable-path", CLOAK_BIN,
        "--args", ",".join(STEALTH_FLAGS + ["--blink-settings=imagesEnabled=false"]),
    ]

def ab(*args, **kwargs):
    env = {**os.environ, "AGENT_BROWSER_IDLE_TIMEOUT_MS": IDLE_TIMEOUT}
    return subprocess.run(_cmd() + list(args), capture_output=True, text=True, env=env, **kwargs)

def ab_batch(*cmds, **kwargs):
    env = {**os.environ, "AGENT_BROWSER_IDLE_TIMEOUT_MS": IDLE_TIMEOUT}
    return subprocess.run(
        _cmd() + ["batch", "--json"],
        input=json.dumps([list(c) for c in cmds]),
        capture_output=True, text=True, env=env, **kwargs,
    )

def read_jsonl(path):
    return [json.loads(line) for line in path.read_text().strip().splitlines() if line.strip()]

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

def _batch_eval_result(batch_results, cmd_idx):
    """Extract the JS eval result from a batch response."""
    r = batch_results[cmd_idx].get("result", {})
    if isinstance(r, dict):
        r = r.get("result", "")
    if isinstance(r, str):
        try:
            return json.loads(r)
        except json.JSONDecodeError:
            return []
    return r if isinstance(r, list) else []

def _get_tab_id(r):
    try:
        return r[0].get("result", {}).get("tabId")
    except (IndexError, AttributeError, KeyError):
        return None

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

    if out_file.exists():
        results = read_jsonl(out_file)
    else:
        if min_seconds: start = time.time()

        r = ab_batch(
            ["tab", "new", url],
            ["wait", "--load", "networkidle", "--timeout", "15000"],
            ["eval", EXTRACT_JS],
        )
        try:
            batch_out = json.loads(r.stdout.strip())
            tab_id = _get_tab_id(batch_out)
            results = _batch_eval_result(batch_out, 2)
        except (json.JSONDecodeError, IndexError):
            tab_id = None
            results = []

        # Close our tab — daemon stays alive for next call
        if tab_id:
            ab("tab", "close", tab_id)

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
