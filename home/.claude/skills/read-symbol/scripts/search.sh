#!/bin/bash
# Search for symbols matching a pattern

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

usage() {
  echo "Usage: search.sh [--kind <kind>] <pattern>" >&2
  echo "" >&2
  echo "Without --kind: searches functions, types, interfaces, and classes." >&2
  echo "Kinds: function, class, interface, type, method, variable" >&2
  exit 1
}

if [[ $# -eq 0 ]]; then
  usage
fi

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

if [[ -n "$kind_filter" ]]; then
  kind_filter=$(echo "$kind_filter" | tr '[:upper:]' '[:lower:]')
  case "$kind_filter" in
    function|func) kind_filter="Function" ;;
    class) kind_filter="Class" ;;
    interface) kind_filter="Interface" ;;
    type|typealias) kind_filter="TypeAlias" ;;
    method) kind_filter="Method" ;;
    variable|var|const|let) kind_filter="Variable" ;;
    *)
      echo "Unknown kind: $kind_filter" >&2
      usage
      ;;
  esac
fi

if [[ -n "$kind_filter" ]]; then
  output=$(by_kind_json "$root" "$kind_filter")
else
  output=$(collect_symbols_json "$root")
fi

filter_matches() {
  local mode="$1"
  echo "$output" | jq -r --arg pattern "$pattern" --arg mode "$mode" '
    def leaf($name):
      ($name | split(":") | last | rtrimstr("()") | ascii_downcase);
    def needle:
      ($pattern | ascii_downcase);
    .result[] |
    select(
      if $mode == "leaf" then
        leaf(.shortName) | contains(needle)
      else
        (.shortName | ascii_downcase) | contains(needle)
      end
    ) |
    "\(.relativePath):\(.startLine) \(.kindName) \(.shortName)"
  ' | head -50
}

matches=$(filter_matches leaf)
if [[ -z "$matches" ]]; then
  matches=$(filter_matches fuzzy)
fi

if [[ -z "$matches" ]]; then
  echo "No symbols found matching '$pattern'" >&2
  exit 1
fi

echo "$matches"
