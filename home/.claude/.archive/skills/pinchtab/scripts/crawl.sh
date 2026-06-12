#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: crawl.sh <url1> [url2] ..." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Crawl output dir (same pattern as camoufox-cli)
DATE_DIR=$(date +%Y-%m-%d)
HOUR=$(date +%H)
OUTPUT_DIR="${PINCHTAB_CRAWL_OUTPUT_DIR:-}"
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

# Run pinchtab command, discard output (fire-and-forget)
pinch() {
  pinchtab "$@" >/dev/null 2>&1 || true
}

total=0
for url in "$@"; do
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

# Create a session for isolated tab context across CLI calls
SESSION_JSON=$(pinchtab session create --agent-id crawl --json)
export PINCHTAB_SESSION=$(echo "$SESSION_JSON" | jq -r '.sessionToken')
SESSION_ID=$(echo "$SESSION_JSON" | jq -r '.id')

cleanup() {
  [ -n "${TAB:-}" ] && pinch tab close "$TAB"
  [ -n "${SESSION_ID:-}" ] && "$SCRIPT_DIR/api.sh" "/sessions/$SESSION_ID/revoke" POST >/dev/null 2>&1 || true
}
trap cleanup EXIT

TAB=""
for url in "$@"; do
  if ! is_url "$url"; then
    continue
  fi

  # Create slug from URL for output filename
  SLUG=$(printf '%s' "$url" | sed 's|https\?://||' | sed 's|^www\.||' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\{2,\}/-/g' | sed 's/^-//;s/-$//' | cut -c1-80)
  OUTPUT_FILE=""
  if [ -n "$OUTPUT_DIR" ]; then
    OUTPUT_FILE="$OUTPUT_DIR/$DATE_DIR/${HOUR}-${SLUG}.txt"
  fi

  TAB=$(pinchtab nav "$url" --block-images --block-ads --tab "$TAB")
  if [ -z "$TAB" ]; then
    echo "[BLOCKED] Failed to open $url"
    echo "[$(date -u +%Y-%m-%dT%H:%M:%S)] $url (open-failed)" >> "$BLOCKED_LOG"
    if [ -n "$OUTPUT_FILE" ]; then
      echo "Failed to open: $url" >> "$OUTPUT_FILE"
    fi
    continue
  fi

  # Wait for page to settle
  pinch wait --load networkidle --timeout 10000

  # Auto-detect and solve any challenges
  SOLVE_RESULT=$("$SCRIPT_DIR/api.sh" /solve POST '{"maxAttempts":3,"timeout":15000}' 2>/dev/null || true)

  title=$(pinchtab eval 'document.title' 2>/dev/null || echo 'Unknown')

  # Check if solve detected a challenge
  is_cf_challenge="0"
  if echo "$SOLVE_RESULT" | grep -q '"solved"'; then
    CHALLENGE_TYPE=$(echo "$SOLVE_RESULT" | jq -r '.challengeType // ""')
    if [ -n "$CHALLENGE_TYPE" ]; then
      is_cf_challenge="1"
    fi
  fi

  # Realistic page interaction
  if [ "$is_cf_challenge" = "0" ]; then
    DELAY=$(( RANDOM % 26 + 15 ))  # 1500-4000ms
    pinch wait ${DELAY}0
    pinch scroll down 200
  fi

  text=$(pinchtab eval '
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
      a.insertBefore(document.createTextNode(" " + href + " "), a.firstChild);
    }
  });

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

  status=$(pinchtab eval 'var n = performance.getEntriesByType("navigation")[0]; n ? (n.responseStatus || n.type || "unknown") : "no-nav-entry"' 2>/dev/null || echo "unknown")

  # ---- BLOCKED DETECTION ----

  if [ "$is_cf_challenge" = "1" ]; then
    echo "[$(date -u +%Y-%m-%dT%H:%M:%S)] $url (cloudflare)" >> "$BLOCKED_LOG"

  elif [ -z "$text" ] || [ ${#text} -lt 100 ]; then
    is_blocked=$(pinchtab eval '(function() {
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
    })()' 2>/dev/null || echo "0")
    if [ "$is_blocked" = "1" ]; then
      echo "[$(date -u +%Y-%m-%dT%H:%M:%S)] $url (cloudflare)" >> "$BLOCKED_LOG"
    elif [ "$status" != "200" ] && [ "$status" != "202" ]; then
      echo "[$(date -u +%Y-%m-%dT%H:%M:%S)] $url (status: $status)" >> "$BLOCKED_LOG"
    fi

  elif echo "$text" | grep -qiE 'just a moment|performing security verification|security service to protect|ddos protection'; then
    echo "[$(date -u +%Y-%m-%dT%H:%M:%S)] $url (cloudflare)" >> "$BLOCKED_LOG"

  elif echo "$text" | grep -qiE '^(403 forbidden|access (denied|unavailable)|forbidden|request is blocked|service unavailable)' || echo "$title" | grep -qiE '^(403|404|503|forbidden|blocked)'; then
    echo "[$(date -u +%Y-%m-%dT%H:%M:%S)] $url (status: ${status}-text-block)" >> "$BLOCKED_LOG"

  elif echo "$status" | grep -qE '^5[0-9][0-9]$'; then
    echo "[$(date -u +%Y-%m-%dT%H:%M:%S)] $url (status: $status)" >> "$BLOCKED_LOG"
  fi

  if [ "$total" -gt 1 ]; then echo "\\n---END---"; fi

  # Save crawl output to file with source URL
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
