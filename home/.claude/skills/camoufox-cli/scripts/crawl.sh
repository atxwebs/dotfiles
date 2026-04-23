#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: crawl.sh <url1> [url2] ..." >&2
  exit 1
fi

CLI="camoufox-cli --session crawl-$$"

trap '$CLI close 2>/dev/null || true' EXIT

total=$#
for url in "$@"; do
  $CLI open --timeout 120 "$url" >/dev/null
  [ "$total" -gt 1 ] && echo "URL: $url"
  $CLI eval '
(function() {
// 0. Find the optimal root
var c = document.querySelector("main") ||
  document.querySelector("[role=\"main\"]") ||
  document.querySelector("#main-content") ||
  document.querySelector("#main") ||
  document.querySelector("#content") ||
  document.querySelector("#root") ||
  document.body;

// 1. Remove noisy elements: scripts, styles, navigation, ads, etc.
c.querySelectorAll([
  "script", "style", "noscript", "header", "footer", "nav", "aside", "object", "embed",
  "svg", "iframe", "canvas", "form", "button", "dialog", "img",
  ".infobox", ".mw-editsection", ".navbox", ".metadata", ".reflist",
  ".reference", ".mw-empty-elt", ".ad", ".advertisement", ".social-share",
  "[role=\"complementary\"]", "[role=\"navigation\"]", "[aria-hidden=\"true\"]"
].join(", ")).forEach(el => el.remove());

// 2. Remove elements hidden via computed CSS
var toRemove = [];
c.querySelectorAll("*").forEach(el => {
  var s = getComputedStyle(el);
  if (s.display === "none" || s.visibility === "hidden") toRemove.push(el);
});
toRemove.forEach(el => el.remove());


// 3. Prepend href to link text when not already present (dedup first occurrence wins)
var currentPage = location.origin + location.pathname;
var seen = { [currentPage]: true, [location.href]: true };
c.querySelectorAll("a").forEach(el => {
  var href = (el.href || "").split("#")[0];
  if (href.length <= 3 || seen[href]) { return; }
  seen[href] = true;
  if (!el.textContent.includes(href)) {
    el.insertBefore(document.createTextNode(href + " "), el.firstChild);
  }
});

return c.innerText.replace(/ {2,}/g, " ").replace(/ *\n */g, "\n").replace(/\n{3,}/g, "\n\n").trim();
})()'

  [ "$total" -gt 1 ] && echo "\n---END---"
done
