#!/usr/bin/env python3
"""Crawl URLs with agent-browser + CloakBrowser binary.

Tab-per-call model:
  - First call spawns the daemon (~600MB), reuses it on subsequent calls
  - Each URL opens a new tab, works on it, then closes the tab
  - Daemon auto-shutdowns after 5 min idle (AGENT_BROWSER_IDLE_TIMEOUT_MS)
  - Concurrent calls share one browser instance, each gets its own tab
"""
import sys, os, re, json
from pathlib import Path
from datetime import datetime, timezone

from browser_lib import ab, _eval_result, eval_from_subprocess

BLOCKED_LOG = None
CRAWL_OUTPUT_DIR = Path(os.environ.get("CRAWL_OUTPUT_DIR", "/tmp"))

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
    d = CRAWL_OUTPUT_DIR / datetime.now().strftime("%Y-%m-%d")
    d.mkdir(parents=True, exist_ok=True)
    BLOCKED_LOG = str(d / "blocked.log")

def output_path(url):
    return CRAWL_OUTPUT_DIR / datetime.now().strftime("%Y-%m-%d") / f"{datetime.now().strftime('%H')}-{make_slug(url)}.txt"

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
    return CRAWL_OUTPUT_DIR / datetime.now().strftime("%Y-%m-%d") / f"{datetime.now().strftime('%H')}-{make_slug(url)}.txt"

def read_cached(url):
    p = output_path(url)
    if p.exists() and (content := p.read_text().strip()):
        return content
    return None

def _eval_raw(r):
    """Extract string result from eval output."""
    return eval_from_subprocess(r)

def crawl(url, total_urls):
    cached = read_cached(url)
    if cached:
        print(cached)
        if total_urls > 1:
            print("\n---END---")
        return

    r = ab("tab", "new", url)
    if r.returncode != 0:
        print(f"[BLOCKED] Failed to open {url}")
        log_blocked(url, "open-failed")
        return

    ab("wait", "--load", "networkidle", "--timeout", "30000")
    title = _eval_raw(ab("eval", "document.title"))
    text = _eval_raw(ab("eval", EXTRACT_JS))

    if "just a moment" in text.lower() or ("cloudflare" in text.lower() and len(text) < 500):
        log_blocked(url, "cloudflare")
        print(f"[BLOCKED: cloudflare]")
        ab("tab", "close")
        return

    content = f"URL: {url}\n# {title}\n\n{text}"
    print(content)

    p = output_path(url)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(f"Source: {url}\n\n# {title}\n\n{text}\n")

    # Close our tab — daemon stays alive for next call
    ab("tab", "close")

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
