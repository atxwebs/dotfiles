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
  mapfile -t targets < <(resolve_symbol_targets "$root" "$symbol")
  target_count=${#targets[@]}

  if [[ "$target_count" -gt 1 ]]; then
    echo "Ambiguous symbol '$symbol' ($target_count matches). Showing refs for ${targets[0]} only — use search.sh or a qualified name for others." >&2
    targets=("${targets[0]}")
    target_count=1
  fi

  printed_for_symbol=false
  for target in "${targets[@]}"; do
    output=$(run_query "$root" scip-query refs "$target" --json) || exit 1

    if [[ "$(echo "$output" | jq -r '.result | length')" == "0" ]]; then
      code_output=$(run_query "$root" scip-query code "$target" --json 2>/dev/null) || code_output=""
      if [[ "$(echo "$code_output" | jq -r '.result.source // ""')" == "" ]]; then
        continue
      fi
    fi

    found_any=true
    printed_for_symbol=true

    refs=$(echo "$output" | format_refs_json)
    if [[ -n "$refs" ]]; then
      echo "$refs"
    fi
  done

  if [[ "$printed_for_symbol" == "false" ]]; then
    echo "Symbol '$symbol' not found" >&2
  fi

  if [[ $# -gt 1 ]]; then
    echo ""
  fi
done

if [[ "$found_any" == "false" ]]; then
  exit 1
fi
