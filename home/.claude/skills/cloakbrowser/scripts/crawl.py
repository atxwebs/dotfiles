#!/usr/bin/env python3
"""Crawl URLs with agent-browser daemon + Playwright CDP + CloakBrowser humanize.

Single-tab model:
  - One daemon + one Playwright tab for all URLs in a run
  - Sequential page.goto() per URL on the same tab
  - Daemon auto-shutdowns after idle (AGENT_BROWSER_IDLE_TIMEOUT_MS)
"""
import sys, os, re, time
from datetime import datetime, timezone
from pathlib import Path

# Ensure sibling modules (browser_lib) are importable regardless of cwd
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from browser_lib import ensure_daemon, connect_cdp, disconnect_cdp, is_challenge_page, wait_for_challenge, write_output

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


def make_slug(url):
    # Strip protocol only, keep path and query string
    s = re.sub(r"^https?://", "", url)
    # Now s is like "example.com/path/to/page?query=value"
    return re.sub(r"[^a-z0-9]", "-", s.lower()).strip("-")[:80]


def log_blocked(url, reason):
    out_dir = os.environ.get("CRAWL_OUTPUT_DIR")
    if not out_dir:
        return
    d = Path(out_dir) / datetime.now().strftime("%Y-%m-%d")
    d.mkdir(parents=True, exist_ok=True)
    blocked_log = d / "blocked.log"
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S")
    with open(blocked_log, "a") as f:
        f.write(f"[{ts}] {url} ({reason})\n")


def is_url(s):
    return bool(re.match(r"^https?://", s)) and "." in s


def crawl_url(page, url):
    timed_out = False
    start_time = time.time()
    try:
        try:
            page.goto(url, wait_until="load", timeout=30000)
            if not wait_for_challenge(page):
                text = page.evaluate("document.body?.innerText || ''") or ""
                if is_challenge_page(text):
                    log_blocked(url, "cloudflare")
                    print("[BLOCKED: cloudflare]")
                    return
        except Exception as nav_err:
            err_msg = str(nav_err).lower()
            if "timeout" in err_msg:
                timed_out = True
                print(f"[TIMEOUT] {url}: {nav_err}", file=sys.stderr)
            else:
                log_blocked(url, f"navigation failed: {nav_err}")
                print(f"[ERROR] {url}: {nav_err}")
                return

        elapsed = time.time() - start_time
        print(f"[TIMING] {url}: {elapsed:.2f}s{' (timeout)' if timed_out else ''}", file=sys.stderr)

        try:
            title = page.evaluate("document.title") if not timed_out else url
        except Exception as eval_err:
            title = url

        # SPA race: load event fires before JS renders — retry extraction briefly
        text, jsonld = "", ""
        for attempt in range(4):
            try:
                jsonld = page.evaluate(EXTRACT_JSONLD_JS) or ""
                text = page.evaluate(EXTRACT_JS) or ""
            except Exception as eval_err:
                log_blocked(url, f"evaluation failed: {eval_err}")
                print(f"[ERROR] {url}: {eval_err}")
                return
            if text:
                break
            time.sleep(0.5)

        if is_challenge_page(text):
            log_blocked(url, "cloudflare")
            print("[BLOCKED: cloudflare]")
            return

        if not text:
            log_blocked(url, "empty content")
            print(f"[ERROR] {url}: no content extracted after {attempt + 1} attempts")
            return

        content = f"URL: {url}\n# {title}\n"
        if jsonld:
            content += f"\n## JSON-LD\n\n{jsonld}\n"
        content += f"\n{text}\n"
        print(content)

        write_output("CRAWL_OUTPUT_DIR", content, make_slug(url), "txt")

    except Exception as e:
        elapsed = time.time() - start_time
        print(f"[TIMING] {url}: {elapsed:.2f}s (FAILED)", file=sys.stderr)
        print(f"[ERROR] {url}: {e}")
        log_blocked(url, f"exception: {e}")


def main():
    urls = [a for a in sys.argv[1:] if is_url(a)]
    if not urls:
        print("Usage: crawl.py <url1> [url2] ...", file=sys.stderr)
        sys.exit(1)

    pw, browser, page = None, None, None
    try:
        for u in urls:
            if pw is None:
                ws_url = ensure_daemon("about:blank")
                pw, browser, _, page = connect_cdp(ws_url)
            crawl_url(page, u)
            if len(urls) > 1:
                print("\n---END---")
    finally:
        if pw:
            disconnect_cdp(pw, browser, page)


if __name__ == "__main__":
    main()
