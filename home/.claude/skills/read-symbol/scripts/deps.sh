#!/bin/bash
# Show what files this file depends on

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ $# -eq 0 ]]; then
  echo "Usage: deps.sh <file>" >&2
  exit 1
fi

target="$1"
root="$(find_project_root)"

if [[ -z "$root" ]]; then
  echo "Error: No project root found" >&2
  exit 1
fi

# Make target relative to root if it's absolute
if [[ "$target" == /* ]]; then
  target="${target#$root/}"
fi

# Check if target exists
if [[ ! -f "$root/$target" ]]; then
  echo "Error: '$target' not found" >&2
  exit 1
fi

output=$(run_query "$root" scip-query deps "$target" --json) || exit 1

echo "$output" | jq -r '.result[].relativePath'
