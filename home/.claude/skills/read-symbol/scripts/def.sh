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

if [[ $# -eq 0 ]]; then
  usage
fi

# Parse options
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

# Normalize type filter
if [[ -n "$type_filter" ]]; then
  type_filter=$(echo "$type_filter" | tr '[:upper:]' '[:lower:]')
  case "$type_filter" in
    typealias) type_filter="type" ;;
    func) type_filter="function" ;;
  esac
fi

for symbol in "$@"; do
  # Use trace to get signature info
  output=$(run_query "$root" scip-query trace "$symbol" --json) || exit 1
  
  # Check if result exists
  has_result=$(echo "$output" | jq -r '.result.definitions | length')
  if [[ "$has_result" == "0" || -z "$has_result" ]]; then
    echo "Symbol '$symbol' not found" >&2
    continue
  fi
  
  # Get first definition
  def=$(echo "$output" | jq -c '.result.definitions[0]')
  signature=$(echo "$def" | jq -r '.signature // ""')
  source_line=$(echo "$def" | jq -r '.source // ""' | head -1)
  
  # Detect kind: try signature first, fall back to source line
  sig_kind=""
  
  # Check if signature starts with a keyword
  case "$signature" in
    "function "*) sig_kind="function" ;;
    "class "*) sig_kind="class" ;;
    "interface "*) sig_kind="interface" ;;
    "type "*) sig_kind="type" ;;
    "enum "*) sig_kind="enum" ;;
    "const "*) sig_kind="variable" ;;
    "let "*) sig_kind="variable" ;;
    "var "*) sig_kind="variable" ;;
    *)
      # Signature is a SCIP path, parse source line
      # Strip modifiers: export, async, static, default, public, private, protected
      source_clean=$(echo "$source_line" | sed -E 's/^(export\s+)?(async\s+|static\s+|default\s+|public\s+|private\s+|protected\s+)*//')
      
      # Check for explicit keywords
      if [[ "$source_clean" =~ ^function[[:space:]] ]]; then
        sig_kind="function"
      elif [[ "$source_clean" =~ ^class[[:space:]] ]]; then
        sig_kind="class"
      elif [[ "$source_clean" =~ ^interface[[:space:]] ]]; then
        sig_kind="interface"
      elif [[ "$source_clean" =~ ^type[[:space:]] ]]; then
        sig_kind="type"
      elif [[ "$source_clean" =~ ^enum[[:space:]] ]]; then
        sig_kind="enum"
      elif [[ "$source_clean" =~ ^(const|let|var)[[:space:]] ]]; then
        sig_kind="variable"
      else
        # No keyword found, likely a method (e.g., "warmup = async (...)")
        sig_kind="method"
      fi
      ;;
  esac
  
  # Apply type filter if specified
  if [[ -n "$type_filter" ]]; then
    # Special case: type filter matches both type and interface
    if [[ "$type_filter" == "type" || "$type_filter" == "interface" ]]; then
      if [[ "$sig_kind" != "type" && "$sig_kind" != "interface" ]]; then
        echo "Symbol '$symbol' is a $sig_kind, not type/interface" >&2
        continue
      fi
    # function filter also matches method
    elif [[ "$type_filter" == "function" ]]; then
      if [[ "$sig_kind" != "function" && "$sig_kind" != "method" ]]; then
        echo "Symbol '$symbol' is a $sig_kind, not function" >&2
        continue
      fi
    elif [[ "$sig_kind" != "$type_filter" ]]; then
      echo "Symbol '$symbol' is a $sig_kind, not $type_filter" >&2
      continue
    fi
  fi
  
  # Format output from trace result
  echo "$def" | jq -r '"\(.relativePath):\(.startLine):\(.endLine)\n\(.source)"'
  
  if [[ $# -gt 1 ]]; then
    echo ""
  fi
done
