#!/bin/bash
# Find completely orphaned symbols (no references at all)

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

min_loc="${1:-3}"
root="$(find_project_root)"

if [[ -z "$root" ]]; then
  echo "Error: No project root found" >&2
  exit 1
fi

output=$(run_query "$root" scip-query isolated --min-loc "$min_loc" --json) || exit 1

echo "$output" | jq -r '
  .result[] |
  "\(.relativePath):\(.startLine) | \(.loc) LOC | \(.shortName)"
'
