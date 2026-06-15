#!/usr/bin/env bash
# Verify markdown [text](target) links exist on disk.
# Usage: verify-links.sh <file-or-dir>
#   file  — one .md file
#   dir   — all **/*.md under dir
# Skips: http(s), mailto, tel, javascript, data, ftp, {template}, #anchor-only
# Exit 0 all ok · 1 broken links
set -euo pipefail

TARGET=""

usage() {
  sed -n '2,7p' "$0"
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    -*) echo "unknown flag: $1" >&2; usage 1 ;;
    *)
      if [[ -n "$TARGET" ]]; then
        echo "single target only: $TARGET" >&2
        exit 1
      fi
      TARGET="$1"
      ;;
  esac
  shift
done

[[ -n "$TARGET" ]] || usage 1

collect_files() {
  if [[ -f "$TARGET" ]]; then
    [[ "$TARGET" == *.md ]] || { echo "not a .md file: $TARGET" >&2; exit 1; }
    printf '%s\n' "$TARGET"
  elif [[ -d "$TARGET" ]]; then
    local -a files=()
    while IFS= read -r f; do
      [[ -n "$f" ]] && files+=("$f")
    done < <(find "$TARGET" -name '*.md' -type f 2>/dev/null | sort)
    if [[ ${#files[@]} -eq 0 ]]; then
      shopt -s nullglob globstar
      files=("$TARGET"/**/*.md)
      shopt -u nullglob globstar
    fi
    if [[ ${#files[@]} -eq 0 ]]; then
      echo "no .md files under: $TARGET" >&2
      exit 1
    fi
    printf '%s\n' "${files[@]}" | sort -u
  else
    echo "not found: $TARGET" >&2
    exit 1
  fi
}

# Strip optional title, fragment, query; trim whitespace.
normalize_href() {
  local href="$1"
  href="${href#"${href%%[![:space:]]*}"}"
  href="${href%"${href##*[![:space:]]}"}"
  href="${href%%[[:space:]]\"*}"
  href="${href%%[[:space:]]\'*}"
  href="${href%%#*}"
  href="${href%%\?*}"
  printf '%s' "$href"
}

should_skip_href() {
  local href="$1"
  [[ -z "$href" ]] && return 0
  [[ "$href" == *'{'* ]] && return 0
  [[ "$href" == '…' || "$href" == '...' ]] && return 0
  case "$href" in
    target|path|url) return 0 ;;
    http://*|https://*|mailto:*|tel:*|javascript:*|data:*|ftp://*) return 0 ;;
  esac
  return 1
}

resolve_href() {
  local base_dir="$1"
  local href="$2"
  if [[ "$href" == /* ]] || [[ "$href" == '~/'* ]] || [[ "$href" == '~' ]]; then
    local expanded="${href/#\~/$HOME}"
    if [[ -d "$(dirname "$expanded")" ]]; then
      (cd "$(dirname "$expanded")" && printf '%s/%s' "$(pwd)" "$(basename "$expanded")")
    else
      printf '%s' "$expanded"
    fi
  else
    local dir_part base_part
    dir_part="$(dirname "$href")"
    base_part="$(basename "$href")"
    if [[ "$dir_part" == '.' ]]; then
      printf '%s/%s' "$base_dir" "$base_part"
    elif (cd "$base_dir" && cd "$dir_part" 2>/dev/null); then
      printf '%s/%s' "$(cd "$base_dir" && cd "$dir_part" && pwd)" "$base_part"
    else
      printf '%s/%s' "$base_dir" "$href"
    fi
  fi
}

extract_hrefs() {
  perl -ne 'while (/\[[^\]]*\]\(([^)]+)\)/g) { print "$1\n" }' "$1"
}

checked=0
broken=0
declare -A seen=()

while IFS= read -r file; do
  [[ -n "$file" ]] || continue
  base_dir="$(cd "$(dirname "$file")" && pwd)"
  while IFS= read -r raw_href; do
    [[ -n "$raw_href" ]] || continue
    href="$(normalize_href "$raw_href")"
    should_skip_href "$href" && continue

    key="${file}	${href}"
    [[ -n "${seen[$key]:-}" ]] && continue
    seen[$key]=1
    checked=$((checked + 1))

    resolved="$(resolve_href "$base_dir" "$href")"
    if [[ ! -e "$resolved" ]]; then
      echo "broken: $file"
      echo "  link: $raw_href"
      echo "  resolved: $resolved"
      broken=$((broken + 1))
    fi
  done < <(extract_hrefs "$file")
done < <(collect_files)

echo "checked: $checked links in $(collect_files | wc -l | tr -d ' ') files"
if [[ "$broken" -gt 0 ]]; then
  echo "broken: $broken"
  exit 1
fi
echo "ok"
