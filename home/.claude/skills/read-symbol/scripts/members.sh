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

output=""
if ! output=$(members_json "$root" "$symbol"); then
  resolved=$(resolve_symbol_short_name "$root" "$symbol") || exit 1
  output=$(members_json "$root" "$resolved") || {
    echo "Error: No members found for symbol '$symbol'" >&2
    exit 1
  }
fi

echo "$output" | jq -r '.result[] | "\(.startLine):\(.endLine) \(.kind) \(.shortName)"'
