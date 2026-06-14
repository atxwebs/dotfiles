#!/bin/bash
# Verify CLIs listed in installed-clis/SKILL.md are on PATH.
# Parses bullet lines: "- fd (find replacement)" → checks `command -v fd`
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL="${INSTALLED_CLIS_SKILL:-$SCRIPT_DIR/../SKILL.md}"

if [ ! -f "$SKILL" ]; then
  echo "Error: SKILL.md not found at $SKILL" >&2
  exit 1
fi

missing=0

while IFS= read -r line; do
  tool=$(echo "$line" | sed -E 's/^- ([^ (]+).*/\1/')
  if [ -z "$tool" ] || [ "$tool" = "$line" ]; then
    continue
  fi
  if path=$(command -v "$tool" 2>/dev/null); then
    echo "ok  $tool  $path"
  else
    echo "MISSING  $tool"
    missing=$((missing + 1))
  fi
done < <(grep -E '^- [a-z]' "$SKILL")

exit $((missing > 0 ? 1 : 0))
