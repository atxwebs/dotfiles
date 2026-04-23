#!/usr/bin/env bash
# DuckDuckGo HTML search via camoufox-cli (free, unlimited, no CAPTCHAs)
#
# Usage: ddg-search.sh "search query" [--min-seconds N]
# Saves results to $DDG_SEARCH_OUTPUT_DIR (default: /tmp) as {YYYY-MM-DD-HH}-{slug}.jsonl
# Prints summary + top results to stdout

set -euo pipefail

QUERY=""
MIN_SECONDS=""

while [ $# -gt 0 ]; do
  case "$1" in
    --min-seconds) MIN_SECONDS="$2"; shift 2 ;;
    *) if [ -z "$QUERY" ]; then QUERY="$1"; else shift; fi ;;
  esac
done

if [ -z "$QUERY" ]; then
  echo "Usage: ddg-search.sh \"search query\" [--min-seconds N]" >&2
  exit 1
fi

START_TIME=$(date +%s)

CLI="camoufox-cli --session ddg-$$"

trap '$CLI close 2>/dev/null || true' EXIT

# URL-encode the query (pure jq, no python/node)
ENCODED=$(printf '%s' "$QUERY" | jq -sRr @uri)

# Create slug from query
SLUG=$(printf '%s' "$QUERY" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//')

# Include date+hour to avoid collisions
HOUR=$(date +%Y-%m-%d-%H)
OUTPUT_DIR="${DDG_SEARCH_OUTPUT_DIR:-/tmp}"
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/${HOUR}-${SLUG}.jsonl"

# Check cache first, otherwise fetch
if [ -f "$OUTPUT_FILE" ]; then
  RESULT=$(cat "$OUTPUT_FILE")
else
  START_TIME=$(date +%s)
  RESULT=$($CLI open --timeout 120 "https://html.duckduckgo.com/html/?q=${ENCODED}" >/dev/null 2>&1 && \
  $CLI eval '
  var re = new RegExp("[?&]uddg=([^&]+)");
  Array.from(document.querySelectorAll(".result"))
    .filter(function(r) { return !r.classList.contains("result--ad"); })
    .map(function(r) {
      var href = (r.querySelector(".result__a") || {}).href || "";
      var m = href.match(re);
      var url = m ? decodeURIComponent(m[1]) : href;
      var title = ((r.querySelector(".result__a") || {}).textContent || "").trim();
      var snippet = ((r.querySelector(".result__snippet") || {}).textContent || "").trim();
      return JSON.stringify({title: title, url: url, snippet: snippet});
    }).join("\n")' 2>&1)

  # Save results as JSONL (one result per line)
  echo "$RESULT" > "$OUTPUT_FILE"

  # Enforce minimum duration between searches
  if [ -n "$MIN_SECONDS" ]; then
    ELAPSED=$(( $(date +%s) - START_TIME ))
    SLEEP=$(( MIN_SECONDS - ELAPSED ))
    if [ "$SLEEP" -gt 0 ]; then
      sleep "$SLEEP"
    fi
  fi
fi

# Print summary
echo "Saved to: $OUTPUT_FILE"
echo ""

# Print results
echo "$RESULT" | jq -s -r '.[] | "[\(.title)](\(.url))\n> \(.snippet)\n"'
