#!/bin/bash
# List all members of a symbol (methods, fields, nested types)

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ $# -eq 0 ]]; then
  echo "Usage: members.sh <symbol>" >&2
  exit 1
fi

symbol="$1"
root="$(find_project_root)"

if [[ -z "$root" ]]; then
  echo "Error: No project root found" >&2
  exit 1
fi

output=$(run_query "$root" scip-query members "$symbol" --json) || exit 1

# Check if result is empty
if ! echo "$output" | jq -e '.result | length > 0' >/dev/null 2>&1; then
  echo "Error: No members found for symbol '$symbol'" >&2
  exit 1
fi

echo "$output" | jq -r '.result[] | "\(.startLine):\(.endLine) \(.kind) \(.shortName)"'
