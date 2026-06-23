#!/bin/bash
# Find dead code (no cross-file references)

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

min_loc="${1:-5}"
root="$(find_project_root)"

if [[ -z "$root" ]]; then
  echo "Error: No project root found" >&2
  exit 1
fi

output=$(run_query "$root" scip-query dead --min-loc "$min_loc" --json) || exit 1

echo "$output" | jq -r '
  .result.symbols[] |
  "\(.relativePath):\(.startLine) | \(.loc) LOC | \(.kind) | \(.shortName)"
'
