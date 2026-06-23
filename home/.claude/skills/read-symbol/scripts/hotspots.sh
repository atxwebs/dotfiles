#!/bin/bash
# Find most-referenced symbols (hotspots)

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

limit="${1:-30}"
root="$(find_project_root)"

if [[ -z "$root" ]]; then
  echo "Error: No project root found" >&2
  exit 1
fi

output=$(run_query "$root" scip-query hotspots --limit "$limit" --json) || exit 1

echo "$output" | jq -r '
  .result[] |
  "\(.refCount) refs, \(.fileCount) files | \(.definedIn) | \(.shortName)"
'
