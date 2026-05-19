#!/usr/bin/env python3
"""Crawl URLs with agent-browser + CloakBrowser binary.

Tab-per-call model:
  - First call spawns the daemon (~600MB), reuses it on subsequent calls
  - Each URL opens a new tab, works on it, then closes the tab
  - Daemon auto-shutdowns after 5 min idle (AGENT_BROWSER_IDLE_TIMEOUT_MS)
  - Concurrent calls share one browser instance, each gets its own tab
"""
import subprocess, sys, os, re, json
from pathlib import Path
from datetime import datetime, timezone

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

BLOCKED_LOG = None

EXTRACT_JS = r"""
(function() {
if (!document.body) return "";
var noisy = [
  "script", "style", "noscript", "header", "footer", "nav", "aside", "object", "embed",
  "svg", "iframe", "canvas", "form", "button", "dialog", "img",
  ".infobox", ".mw-editsection", ".navbox", ".metadata", ".reflist",
  ".reference", ".mw-empty-elt", ".ad", ".advertisement", ".social-share",
  "[role=complementary]", "[role=navigation]", "[aria-hidden=true]"
].join(", ");
document.body.querySelectorAll(noisy).forEach(function(e) { e.remove(); });
var toRemove = [];
document.body.querySelectorAll("*").forEach(function(el) {
  var s = getComputedStyle(el);
  if (s.display === "none" || s.visibility === "hidden") toRemove.push(el);
});
toRemove.forEach(function(el) { el.remove(); });
var currentPage = location.origin + location.pathname;
var seen = {};
seen[currentPage] = true;
seen[location.href] = true;
document.body.querySelectorAll("a").forEach(function(a) {
  var href = (a.href || "").split("#")[0];
  if (seen[href]) return;
  seen[href] = true;
  if (!a.textContent.includes(href)) {
    a.insertBefore(document.createTextNode(href + " "), a.firstChild);
  }
});
var selectors = [
  "main", "[role=main]", "#main-content", "#main", "#content", "#root", "body"
];
for (var i = 0; i < selectors.length; i++) {
  var c = document.querySelector(selectors[i]);
  if (!c) continue;
  var text = c.innerText.replace(/ {2,}/g, " ").replace(/ *\n */g, "\n").replace(/\n{3,}/g, "\n\n").trim();
  if (text) return text;
}
return "";
})()
"""

def init_blocked_log():
    global BLOCKED_LOG
    out = os.environ.get("CLOAKBROWSER_CRAWL_OUTPUT_DIR")
    if out:
        d = os.path.join(out, datetime.now().strftime("%Y-%m-%d"))
        os.makedirs(d, exist_ok=True)
        BLOCKED_LOG = os.path.join(d, "blocked.log")

def log_blocked(url, reason):
    if BLOCKED_LOG:
        ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S")
        with open(BLOCKED_LOG, "a") as f:
            f.write(f"[{ts}] {url} ({reason})\n")

def is_url(s):
    return bool(re.match(r"^https?://", s)) and "." in s

def make_slug(url):
    s = re.sub(r"^https?://", "", url).split("/")[0].split("?")[0]
    return re.sub(r"[^a-z0-9]", "-", s.lower())[:80]

def output_path(url):
    out = os.environ.get("CLOAKBROWSER_CRAWL_OUTPUT_DIR")
    if not out:
        return None
    d = os.path.join(out, datetime.now().strftime("%Y-%m-%d"))
    os.makedirs(d, exist_ok=True)
    return os.path.join(d, f"{datetime.now().strftime('%H')}-{make_slug(url)}.txt")

def _eval_result(r):
    v = r.get("result", {})
    if isinstance(v, dict):
        v = v.get("result", "")
    if isinstance(v, str) and len(v) > 2 and v[0] == '"' and v[-1] == '"':
        return v[1:-1].encode().decode("unicode_escape")
    return str(v) if v else ""

def _get_tab_id(r):
    try:
        return r[0].get("result", {}).get("tabId")
    except (IndexError, AttributeError, KeyError):
        return None

def crawl(url, total_urls):
    r = ab_batch(
        ["tab", "new", url],
        ["wait", "--load", "networkidle", "--timeout", "30000"],
        ["eval", "document.title"],
        ["eval", EXTRACT_JS],
    )
    if r.returncode != 0:
        print(f"[BLOCKED] Failed to open {url}")
        log_blocked(url, "open-failed")
        return

    try:
        results = json.loads(r.stdout.strip())
    except json.JSONDecodeError:
        print(f"[BLOCKED] Failed to parse response for {url}")
        log_blocked(url, "parse-error")
        return

    tab_id = _get_tab_id(results)
    title = _eval_result(results[2]) if len(results) > 2 else "Unknown"
    text = _eval_result(results[3]) if len(results) > 3 else ""

    if "just a moment" in text.lower() or ("cloudflare" in text.lower() and len(text) < 500):
        log_blocked(url, "cloudflare")
        print(f"[BLOCKED: cloudflare]")
        if tab_id:
            ab("tab", "close", tab_id)
        return

    print(f"URL: {url}")
    print(f"# {title}")
    print()
    print(text)

    out = output_path(url)
    if out:
        Path(out).write_text(f"Source: {url}\n\n# {title}\n\n{text}\n")

    # Close our tab — daemon stays alive for next call
    if tab_id:
        ab("tab", "close", tab_id)

    if total_urls > 1:
        print("\n---END---")

def main():
    urls = [a for a in sys.argv[1:] if is_url(a)]
    if not urls:
        print("Usage: crawl.py <url1> [url2] ...", file=sys.stderr)
        sys.exit(1)

    init_blocked_log()
    for u in urls:
        crawl(u, len(urls))

if __name__ == "__main__":
    main()
