#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: crawl.sh <url1> [url2] ..." >&2
  exit 1
fi

CLI="camoufox-cli --session crawl-$$"

trap '$CLI close 2>/dev/null || true' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Optional crawl output dir (same pattern as DDG_SEARCH_OUTPUT_DIR)
DATE_DIR=$(date +%Y-%m-%d)
HOUR=$(date +%H)
OUTPUT_DIR="${CAMOUFOX_CRAWL_OUTPUT_DIR:-}"
if [ -n "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR/$DATE_DIR"
  BLOCKED_LOG="$OUTPUT_DIR/$DATE_DIR/blocked.log"
else
  BLOCKED_LOG="/dev/null"
fi

# Check if a string looks like a valid URL
is_url() {
  [[ "$1" =~ ^https?:// ]] && [[ "$1" == *.* ]]
}

total=0
for url in "$@"; do
  # Skip non-URL args (common AI hallucination: DDG flags leaking into crawl)
  if ! is_url "$url"; then
    if [ -n "$OUTPUT_DIR" ]; then
      echo "[$(date -u +%Y-%m-%dT%H:%M:%S)] SKIPPING non-URL arg: $url" >> "$BLOCKED_LOG"
    fi
    continue
  fi
  total=$((total + 1))
done

if [ "$total" -eq 0 ]; then
  echo "No valid URLs provided." >&2
  exit 1
fi

for url in "$@"; do
  # Skip non-URL args
  if ! is_url "$url"; then
    continue
  fi

  # Create slug from URL for output filename
  SLUG=$(printf '%s' "$url" | sed 's|https\?://||' | sed 's|^www\.||' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\{2,\}/-/g' | sed 's/^-//;s/-$//' | cut -c1-80)
  OUTPUT_FILE=""
  if [ -n "$OUTPUT_DIR" ]; then
    OUTPUT_FILE="$OUTPUT_DIR/$DATE_DIR/${HOUR}-${SLUG}.txt"
  fi

  if ! timeout 30 $CLI open --timeout 60 "$url" >/dev/null 2>&1; then
    echo "URL: $url"
    echo "[BLOCKED] Failed to open $url"
    echo "[$(date -u +%Y-%m-%dT%H:%M:%S)] $url (open-failed)" >> "$BLOCKED_LOG"
    if [ -n "$OUTPUT_FILE" ]; then
      echo "Source: $url" > "$OUTPUT_FILE"
      echo "" >> "$OUTPUT_FILE"
      echo "# Failed to open" >> "$OUTPUT_FILE"
      echo "" >> "$OUTPUT_FILE"
      echo "[BLOCKED] Failed to open $url" >> "$OUTPUT_FILE"
    fi
    continue
  fi

  # Helper: eval with timeout so a hanging eval doesn't block the whole crawl
  cli_eval() { timeout 10 $CLI eval "$@" 2>/dev/null || echo ""; }

  # Handle JS-based redirects: wait if page is empty (no title, minimal body text)
  body_check=$(cli_eval 'document.body ? document.body.innerText.trim().length : 0')
  if [ -n "$body_check" ] && [ "$body_check" -le 5 ] 2>/dev/null; then
    $CLI wait 3000 >/dev/null 2>&1
  fi

  title=$(cli_eval 'document.title')
  [ -z "$title" ] && title="Unknown"

  # Check for Cloudflare challenge page title
  is_cf_challenge="0"
  if echo "$title" | grep -qiE 'just a moment|security check|attention required'; then
    is_cf_challenge="1"
  fi

  # Realistic page interaction before extraction — helps with lighter bot detection.
  # Random delay (1.5–4s) + small scroll simulates a human arriving and glancing at the page.
  # Skip for CF challenges — they never auto-resolve (Turnstile requires human click).
  if [ "$is_cf_challenge" = "0" ]; then
    DELAY=$(( RANDOM % 26 + 15 ))  # 1500-4000ms
    $CLI wait "$DELAY"00 >/dev/null 2>&1
    $CLI scroll down 200 >/dev/null 2>&1
  fi

  # Pre-check: capture raw HTML length BEFORE text extraction strips the DOM.
  # Used to detect login walls (massive HTML, zero visible text after extraction).
  raw_html_len=$(cli_eval 'document.body ? document.body.innerHTML.length : 0')

  text=$(cli_eval '
(function() {
if (!document.body) return "";

// 1. Remove noisy elements
var noisy = [
  "script", "style", "noscript", "header", "footer", "nav", "aside", "object", "embed",
  "svg", "iframe", "canvas", "form", "button", "dialog", "img",
  ".infobox", ".mw-editsection", ".navbox", ".metadata", ".reflist",
  ".reference", ".mw-empty-elt", ".ad", ".advertisement", ".social-share",
  "[role=complementary]", "[role=navigation]", "[aria-hidden=true]"
].join(", ");
document.body.querySelectorAll(noisy).forEach(function(e) { e.remove(); });

// 2. Remove elements hidden via computed CSS
var toRemove = [];
document.body.querySelectorAll("*").forEach(function(el) {
  var s = getComputedStyle(el);
  if (s.display === "none" || s.visibility === "hidden") toRemove.push(el);
});
toRemove.forEach(function(el) { el.remove(); });

// 3. Prepend href to link text
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

// 4. Find matching container and return text
var selectors = [
  "main",
  "[role=main]",
  "#main-content",
  "#main",
  "#content",
  "#root",
  "body"
];

for (var i = 0; i < selectors.length; i++) {
  var c = document.querySelector(selectors[i]);
  if (!c) continue;
  var text = c.innerText.replace(/ {2,}/g, " ").replace(/ *\n */g, "\n").replace(/\n{3,}/g, "\n\n").trim();
  if (text) return text;
}
return "";
})()')

  echo "URL: $url"
  echo "# $title"
  echo ""
  echo "$text"

  # Get navigation status
  status=$(cli_eval 'var n = performance.getEntriesByType("navigation")[0]; n ? (n.responseStatus || n.type || "unknown") : "no-nav-entry"')
  [ -z "$status" ] && status="unknown"

  # Determine block category (empty = no block, just print output above)
  block_category=""
  block_label=""

  # 1. HTTP error status (4xx/5xx) — check status code FIRST, before content heuristics
  if echo "$status" | grep -qE '^[45][0-9][0-9]$'; then
    block_category="http-error"
    # Special labels for common codes
    case "$status" in
      403) block_label="403 forbidden" ;;
      404) block_label="404: $title" ;;
      5*)  block_label="status: $status" ;;
      *)   block_label="status: $status" ;;
    esac

  # 2. Cloudflare challenge (title-based)
  elif [ "$is_cf_challenge" = "1" ]; then
    block_category="cloudflare"
    block_label="cloudflare"

  # 3. Text-based Cloudflare/WAF detection
  elif echo "$text" | grep -qiE 'just a moment|performing security verification|security service to protect|ddos protection'; then
    block_category="cloudflare"
    block_label="cloudflare"

  # 4. Empty or near-empty text — check for specific causes
  elif [ -z "$text" ] || [ ${#text} -lt 100 ]; then
    # 4a. Cloudflare/WAF via HTML patterns
    is_blocked=$(cli_eval '(function() {
      var html = (document.body && document.body.innerHTML) || "";
      var patterns = [
        "challenge-container", "cf-challenge", "cf-turnstile",
        "challenge-platform", "Just a moment",
        "DDoS protection by Cloudflare",
        "Enable JavaScript and cookies to continue",
        "checking if the site connection is secure"
      ];
      var lower = html.toLowerCase();
      for (var i = 0; i < patterns.length; i++) {
        if (lower.includes(patterns[i].toLowerCase())) return "1";
      }
      return "0";
    })()')
    [ -z "$is_blocked" ] && is_blocked="0"
    if [ "$is_blocked" = "1" ]; then
      block_category="cloudflare"
      block_label="cloudflare"
    # 4b. Login wall: substantial HTML but zero text
    elif [ ${#text} -lt 10 ] && [ "$raw_html_len" -gt 50000 ]; then
      block_category="login-wall"
      block_label="login-wall"
    # 4c. Parked/abandoned domain: tiny HTML, no content
    elif [ ${#text} -lt 10 ] && [ "$raw_html_len" -lt 2000 ]; then
      block_category="empty"
      block_label="empty (parked/no content)"
    fi
  fi

  # Log blocked pages
  if [ -n "$block_category" ]; then
    echo "[$(date -u +%Y-%m-%dT%H:%M:%S)] $url ($block_label)" >> "$BLOCKED_LOG"
    # Print block marker in stdout for agent visibility
    echo ""
    echo "[BLOCKED: $block_label]"
    # Skip saving .txt file only for HTTP errors (real 4xx/5xx status codes)
    if [ "$block_category" = "http-error" ]; then
      OUTPUT_FILE=""
    fi
  fi

  if [ "$total" -gt 1 ]; then echo "\\n---END---"; fi

  # Save crawl output to file with source URL (skipped if blocked — OUTPUT_FILE cleared above)
  if [ -n "$OUTPUT_FILE" ]; then
    {
      echo "Source: $url"
      echo ""
      echo "# $title"
      echo ""
      echo "$text"
    } > "$OUTPUT_FILE"
  fi
done
