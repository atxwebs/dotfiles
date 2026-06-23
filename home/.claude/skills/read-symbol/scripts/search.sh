#!/bin/bash
# Search for symbols matching a pattern

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

usage() {
  echo "Usage: search.sh [--kind <kind>] <pattern>" >&2
  echo "" >&2
  echo "Pattern supports wildcards: handle*, User*, *Service" >&2
  echo "Kinds: function, class, interface, type, method, variable" >&2
  exit 1
}

if [[ $# -eq 0 ]]; then
  usage
fi

# Parse options
kind_filter=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --kind)
      kind_filter="$2"
      shift 2
      ;;
    --kind=*)
      kind_filter="${1#*=}"
      shift
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -eq 0 ]]; then
  usage
fi

pattern="$1"
root="$(find_project_root)"

if [[ -z "$root" ]]; then
  echo "Error: No project root found" >&2
  exit 1
fi

# Convert glob pattern to regex
regex_pattern=$(echo "$pattern" | sed 's/\*/.*/g' | sed 's/\?/./g')

# Normalize kind if provided
if [[ -n "$kind_filter" ]]; then
  kind_filter=$(echo "$kind_filter" | tr '[:lower:]' '[:upper:]')
  case "$kind_filter" in
    FUNCTION|FUNC) kind_filter="Function" ;;
    CLASS) kind_filter="Class" ;;
    INTERFACE) kind_filter="Interface" ;;
    TYPE|TYPEALIAS) kind_filter="TypeAlias" ;;
    METHOD) kind_filter="Method" ;;
    VARIABLE|VAR|CONST|LET) kind_filter="Variable" ;;
  esac
fi

# Get symbols
if [[ -n "$kind_filter" ]]; then
  output=$(run_query "$root" scip-query by-kind "$kind_filter" --limit 1000 --json 2>/dev/null) || output='{"result":[]}'
else
  # Query all common kinds and combine
  kinds=("Function" "Class" "Interface" "TypeAlias" "Method" "Variable")
  all_results="[]"

  for kind in "${kinds[@]}"; do
    kind_output=$(run_query "$root" scip-query by-kind "$kind" --limit 1000 --json 2>/dev/null) || continue
    if [[ -n "$kind_output" ]]; then
      kind_results=$(echo "$kind_output" | jq -c '.result // []')
      all_results=$(echo "$all_results" "$kind_results" | jq -s '.[0] + .[1]')
    fi
  done

  output="{\"result\":$all_results}"
fi

# Filter by pattern and format output
matches=$(echo "$output" | jq -r --arg pattern "$regex_pattern" '
  .result[] |
  select(.shortName | test($pattern; "i")) |
  "\(.relativePath):\(.startLine) \(.kindName) \(.shortName)"
' | head -50)

if [[ -z "$matches" ]]; then
  echo "No symbols found matching pattern '$pattern'" >&2
  exit 1
fi

echo "$matches"
