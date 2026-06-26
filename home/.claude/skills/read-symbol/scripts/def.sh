#!/bin/bash
# Get symbol definitions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

usage() {
  echo "Usage: def.sh [--type <kind>] <symbol> [symbol2 ...]" >&2
  echo "" >&2
  echo "Kinds: function, class, interface, type, method, variable" >&2
  echo "  type also matches interface" >&2
  echo "  variable matches const, let, var" >&2
  exit 1
}

kind_matches_filter() {
  local sig_kind="$1"
  local type_filter="$2"

  if [[ -z "$type_filter" ]]; then
    return 0
  fi

  if [[ "$type_filter" == "type" || "$type_filter" == "interface" ]]; then
    [[ "$sig_kind" == "type" || "$sig_kind" == "interface" ]]
    return
  fi

  if [[ "$type_filter" == "function" ]]; then
    [[ "$sig_kind" == "function" ]]
    return
  fi

  [[ "$sig_kind" == "$type_filter" ]]
}

print_definition() {
  local root="$1"
  local query_symbol="$2"
  local display_symbol="$3"
  local type_filter="$4"
  local output source_line sig_kind

  output=$(run_query "$root" scip-query code "$query_symbol" --json) || return 1

  if [[ "$(echo "$output" | jq -r '.result.source // ""')" == "" ]]; then
    echo "Symbol '$display_symbol' not found" >&2
    return 1
  fi

  source_line=$(echo "$output" | jq -r '.result.source // ""' | head -1)
  sig_kind=$(detect_sig_kind "" "$source_line")

  if ! kind_matches_filter "$sig_kind" "$type_filter"; then
    echo "Symbol '$display_symbol' is a $sig_kind, not ${type_filter:-any}" >&2
    return 1
  fi

  echo "$output" | format_def
}

if [[ $# -eq 0 ]]; then
  usage
fi

type_filter=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      type_filter="$2"
      shift 2
      ;;
    --type=*)
      type_filter="${1#*=}"
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

root="$(find_project_root)"
if [[ -z "$root" ]]; then
  echo "Error: No project root found" >&2
  exit 1
fi

if [[ -n "$type_filter" ]]; then
  type_filter=$(echo "$type_filter" | tr '[:upper:]' '[:lower:]')
  case "$type_filter" in
    typealias) type_filter="type" ;;
    func) type_filter="function" ;;
  esac
fi

kinds_hint=""
if [[ -n "$type_filter" ]]; then
  kinds_hint="$(kinds_for_type_filter "$type_filter")"
fi

found_any=false
for symbol in "$@"; do
  mapfile -t targets < <(resolve_symbol_targets "$root" "$symbol" "$kinds_hint")
  target_count=${#targets[@]}

  if [[ "$target_count" -gt 1 ]]; then
    echo "# $target_count definitions for '$symbol':"
    echo ""
  fi

  printed_for_symbol=false
  for target in "${targets[@]}"; do
    if [[ "$target_count" -gt 1 ]]; then
      echo "## $target"
    fi

    if print_definition "$root" "$target" "$symbol" "$type_filter"; then
      found_any=true
      printed_for_symbol=true
      if [[ "$target_count" -gt 1 ]]; then
        echo ""
      fi
    elif [[ "$target_count" -eq 1 ]]; then
      :
    fi
  done

  if [[ "$target_count" -gt 1 && "$printed_for_symbol" == "false" ]]; then
    echo "Symbol '$symbol' not found" >&2
  fi

  if [[ $# -gt 1 ]]; then
    echo ""
  fi
done

if [[ "$found_any" == "false" ]]; then
  exit 1
fi
