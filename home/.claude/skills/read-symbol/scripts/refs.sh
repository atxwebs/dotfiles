#!/bin/bash
# Get symbol references

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [[ $# -eq 0 ]]; then
  echo "Usage: refs.sh <symbol> [symbol2 ...]" >&2
  exit 1
fi

root="$(find_project_root)"
if [[ -z "$root" ]]; then
  echo "Error: No project root found" >&2
  exit 1
fi

found_any=false
for symbol in "$@"; do
  output=$(run_query "$root" scip-query trace "$symbol" --json) || exit 1
  def_count=$(echo "$output" | jq -r '.result.definitions | length')
  if [[ "$def_count" -gt 0 ]]; then
    echo "$output" | format_refs
    found_any=true
  else
    echo "Symbol '$symbol' not found" >&2
  fi
  if [[ $# -gt 1 ]]; then
    echo ""
  fi
done

if [[ "$found_any" == "false" ]]; then
  exit 1
fi
