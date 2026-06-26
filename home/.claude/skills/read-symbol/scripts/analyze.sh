#!/bin/bash
# Code analysis - auto-detects scope from argument

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

usage() {
  echo "Usage: analyze.sh [target]" >&2
  echo "" >&2
  echo "Auto-detects scope:" >&2
  echo "  No args        — Global analysis (cycles, bottlenecks, stale code)" >&2
  echo "  File path      — File analysis (change surface, unused imports)" >&2
  echo "  Symbol name    — Symbol analysis (blast radius, complexity)" >&2
  exit 1
}

root="$(find_project_root)"
if [[ -z "$root" ]]; then
  echo "Error: No project root found" >&2
  exit 1
fi

# No args = global
if [[ $# -eq 0 ]]; then
  echo "=== Cycles ==="
  run_query "$root" scip-query cycles 2>/dev/null || echo "(none)"
  echo ""
  echo "=== Bottlenecks (coupling hubs) ==="
  run_query "$root" scip-query bottlenecks 2>/dev/null || echo "(none)"
  echo ""
  echo "=== Stale Abstractions ==="
  run_query "$root" scip-query stale-abstractions 2>/dev/null || echo "(none)"
  echo ""
  echo "=== Hotspots (most referenced) ==="
  run_query "$root" scip-query hotspots 2>/dev/null || echo "(none)"
  echo ""
  echo "=== Isolated (orphaned symbols) ==="
  run_query "$root" scip-query isolated 2>/dev/null || echo "(none)"
  echo ""
  echo "=== Dead Code ==="
  run_query "$root" scip-query dead 2>/dev/null || echo "(none)"
  exit 0
fi

target="$1"

if [[ "$target" == */* || "$target" == *.* ]] && target=$(resolve_file_path "$root" "$target" 2>/dev/null); then
  echo "=== Change Surface (exports, consumers, risk) ==="
  run_query "$root" scip-query change-surface "$target" 2>/dev/null || echo "(none)"
  echo ""
  echo "=== Unused Imports ==="
  run_query "$root" scip-query unused-imports "$target" 2>/dev/null || echo "(none)"
else
  echo "=== Affected (blast radius) ==="
  run_query "$root" scip-query affected "$target" 2>/dev/null || echo "(none)"
  echo ""
  echo "=== Complexity ==="
  run_query "$root" scip-query complexity "$target" 2>/dev/null || echo "(none)"
fi
