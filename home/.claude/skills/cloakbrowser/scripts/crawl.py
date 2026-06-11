#!/usr/bin/env python3
"""Crawl URLs with agent-browser daemon + Playwright CDP + CloakBrowser humanize.

Tab-per-call model:
  - First call spawns the daemon (~600MB), reuses it on subsequent calls
  - Each URL gets a Playwright page connected via CDP with humanize patches
  - Daemon auto-shutdowns after idle (AGENT_BROWSER_IDLE_TIMEOUT_MS)
"""
import sys, os, re, time
from datetime import datetime, timezone
from pathlib import Path

# Ensure sibling modules (browser_lib) are importable regardless of cwd
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from browser_lib import ensure_daemon, connect_cdp, disconnect_cdp

CRAWL_OUTPUT_DIR = Path(os.environ.get("CRAWL_OUTPUT_DIR", "/tmp"))

BLOCKED_LOG = None

EXTRACT_JSONLD_JS = r"""
(function() {
  var SKIP_TYPES = ['Organization', 'BreadcrumbList', 'WebSite', 'WebPage'];
  var scripts = document.querySelectorAll('script[type="application/ld+json"]');
  var results = [];
  for (var i = 0; i < scripts.length; i++) {
    try {
      var d = JSON.parse(scripts[i].textContent);
      if (Array.isArray(d)) {
        for (var j = 0; j < d.length; j++) {
          var t = d[j]['@type'] || '';
          if (SKIP_TYPES.indexOf(t) === -1 && t) results.push(JSON.stringify(d[j]));
        }
      } else if (d['@graph']) {
        for (var k = 0; k < d['@graph'].length; k++) {
          var t = d['@graph'][k]['@type'] || '';
          if (SKIP_TYPES.indexOf(t) === -1 && t) results.push(JSON.stringify(d['@graph'][k]));
        }
      } else {
        var t = d['@type'] || '';
        if (SKIP_TYPES.indexOf(t) === -1 && t) results.push(JSON.stringify(d));
      }
    } catch(e) {}
  }
  return results.length ? results.join('\n') : '';
})()
"""

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


def make_slug(url):
    s = re.sub(r"^https?://", "", url).split("/")[0].split("?")[0]
    return re.sub(r"[^a-z0-9]", "-", s.lower())[:80]


def output_path(url):
    return CRAWL_OUTPUT_DIR / datetime.now().strftime("%Y-%m-%d") / f"{datetime.now().strftime('%H')}-{make_slug(url)}.txt"


def log_blocked(url, reason):
    if BLOCKED_LOG:
        ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S")
        with open(BLOCKED_LOG, "a") as f:
            f.write(f"[{ts}] {url} ({reason})\n")


def is_url(s):
    return bool(re.match(r"^https?://", s)) and "." in s


def read_cached(url):
    p = output_path(url)
    if p.exists() and (content := p.read_text().strip()):
        return content
    return None


def crawl(url, total_urls):
    cached = read_cached(url)
    if cached:
        print(cached)
        if total_urls > 1:
            print("\n---END---")
        return

    pw, browser, context, page = None, None, None, None
    timed_out = False
    try:
        ws_url = ensure_daemon("about:blank")
        pw, browser, context, page = connect_cdp(ws_url)

        start_time = time.time()
        try:
            page.goto(url, wait_until="load", timeout=30000)
        except Exception as nav_err:
            err_msg = str(nav_err).lower()
            if "timeout" in err_msg:
                timed_out = True
                print(f"[TIMEOUT] {url}: {nav_err}", file=sys.stderr)
            else:
                # Status error or other navigation failure - abort
                log_blocked(url, f"navigation failed: {nav_err}")
                print(f"[ERROR] {url}: {nav_err}")
                return

        elapsed = time.time() - start_time
        print(f"[TIMING] {url}: {elapsed:.2f}s{' (timeout)' if timed_out else ''}", file=sys.stderr)

        try:
            title = page.evaluate("document.title") if not timed_out else url
            jsonld = page.evaluate(EXTRACT_JSONLD_JS) or ""
            text = page.evaluate(EXTRACT_JS) or ""
        except Exception as eval_err:
            log_blocked(url, f"evaluation failed: {eval_err}")
            print(f"[ERROR] {url}: {eval_err}")
            return

        # Check for Cloudflare challenge
        if "just a moment" in text.lower() or ("cloudflare" in text.lower() and len(text) < 500):
            log_blocked(url, "cloudflare")
            print("[BLOCKED: cloudflare]")
            return

        # Check if we got meaningful content
        if not text or len(text.strip()) < 50:
            log_blocked(url, "empty or insufficient content")
            print(f"[ERROR] {url}: extracted only {len(text.strip())} chars")
            return

        content = f"URL: {url}\n# {title}\n"
        if jsonld:
            content += f"\n## JSON-LD\n\n{jsonld}\n"
        content += f"\n{text}\n"
        print(content)

        p = output_path(url)
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content)

    except Exception as e:
        elapsed = time.time() - start_time
        print(f"[TIMING] {url}: {elapsed:.2f}s (FAILED)", file=sys.stderr)
        print(f"[ERROR] {url}: {e}")
        log_blocked(url, f"exception: {e}")
    finally:
        if pw:
            disconnect_cdp(pw, browser)

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
