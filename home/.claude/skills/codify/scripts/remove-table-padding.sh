#!/usr/bin/env bash
# Strip markdown table column-alignment padding (| --- | separators only).
# Usage: remove-table-padding.sh [--dry-run] <file-or-dir>
#   file  — one .md file
#   dir   — all **/*.md under dir (find -name '*.md')
set -euo pipefail

DRY_RUN=0
TARGET=""

usage() {
  sed -n '2,5p' "$0"
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
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

TABLE_SED='
/^\|([[:space:]]*[-:]+[[:space:]]*\|)+[[:space:]]*$/ {
  s/[[:space:]]*[-:]+[[:space:]]*\|/ --- |/g
  b end
}
/^\|/ {
  s/[[:space:]]{2,}\|/ |/g
}
:end
'

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

transform() {
  sed -E "$TABLE_SED" "$1"
}

changed=0
while IFS= read -r file; do
  [[ -n "$file" ]] || continue
  if [[ "$DRY_RUN" -eq 1 ]]; then
    tmp=$(mktemp)
    transform "$file" >"$tmp"
    if ! cmp -s "$file" "$tmp"; then
      echo "would change: $file"
      diff -u "$file" "$tmp" || true
      changed=$((changed + 1))
    fi
    rm -f "$tmp"
  else
    tmp=$(mktemp)
    transform "$file" >"$tmp"
    if ! cmp -s "$file" "$tmp"; then
      mv "$tmp" "$file"
      echo "updated: $file"
      changed=$((changed + 1))
    else
      rm -f "$tmp"
    fi
  fi
done < <(collect_files)

if [[ "$changed" -eq 0 ]]; then
  echo "no changes"
fi
