#!/bin/bash
# List all symbols in a file with their types

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ $# -eq 0 ]]; then
  echo "Usage: symbols.sh <file>" >&2
  exit 1
fi

root="$(find_project_root)"
if [[ -z "$root" ]]; then
  echo "Error: No project root found" >&2
  exit 1
fi

target=$(resolve_file_path "$root" "$1") || {
  echo "Error: file '$1' not found" >&2
  exit 1
}

output=$(run_query "$root" scip-query outline "$target" --json) || exit 1

has_results=$(echo "$output" | jq -r '.result | length' 2>/dev/null || echo "0")
if [[ "$has_results" == "0" ]]; then
  echo "No symbols found in '$target'" >&2
  exit 1
fi

echo "$output" | jq -r '
  .result[0].children[] |
  .signature as $sig |
  ($sig | split(" ") | .[0]) as $kind |
  ($sig | split(" ") | .[1] | rtrimstr(":")) as $name |
  "\(.startLine) \($kind) \($name) \($sig)"
'
