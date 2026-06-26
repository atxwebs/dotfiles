#!/bin/bash
# Show what files this file depends on

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ $# -eq 0 ]]; then
  echo "Usage: deps.sh <file>" >&2
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

output=$(run_query "$root" scip-query deps "$target" --json) || exit 1
echo "$output" | jq -r '.result[].relativePath'
