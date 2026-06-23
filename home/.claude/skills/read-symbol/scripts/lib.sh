#!/bin/bash
# Shared helpers for read-symbol scripts

# Walk up from $1 (or $PWD) to find a project root with known markers
find_project_root() {
  local dir="${1:-$PWD}"
  dir="$(cd "$dir" && pwd)"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/package.json" || -f "$dir/tsconfig.json" || -f "$dir/pyproject.toml" || -f "$dir/Cargo.toml" || -f "$dir/go.mod" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

# Detect language from project markers
detect_language() {
  local root="$1"
  if [[ -f "$root/tsconfig.json" || -f "$root/package.json" ]]; then
    echo "typescript"
  elif [[ -f "$root/pyproject.toml" || -f "$root/setup.py" ]]; then
    echo "python"
  elif [[ -f "$root/Cargo.toml" ]]; then
    echo "rust"
  elif [[ -f "$root/go.mod" ]]; then
    echo "go"
  else
    echo "typescript"  # default
  fi
}

# Run a scip-query command, auto-indexing if needed.
# Retries with backoff when another indexer is running.
# Usage: run_query <root> <command> <args...>
run_query() {
  local root="$1"
  shift
  local output exit_code max_wait=60 waited=0

  output=$(cd "$root" && "$@" 2>&1)
  exit_code=$?

  if [[ $exit_code -ne 0 ]] && echo "$output" | grep -q "No index.db found"; then
    local lang
    lang="$(detect_language "$root")"
    echo "Auto-indexing $root ($lang)..." >&2
    (cd "$root" && scip-query reindex --language "$lang" 2>&1) >&2 || true
    output=$(cd "$root" && "$@" 2>&1)
    exit_code=$?
  fi

  while [[ $exit_code -ne 0 ]] && echo "$output" | grep -q "already running"; do
    if [[ $waited -ge $max_wait ]]; then
      echo "Timeout waiting for concurrent indexer to finish (${max_wait}s)" >&2
      echo "$output" >&2
      return 1
    fi
    echo "Another indexer is running, waiting... (${waited}s)" >&2
    sleep 3
    waited=$((waited + 3))
    output=$(cd "$root" && "$@" 2>&1)
    exit_code=$?
  done

  if [[ $exit_code -ne 0 ]]; then
    echo "$output" >&2
    return 1
  fi

  echo "$output"
}

# Format scip-query code --json into token-efficient output
format_def() {
  jq -r '.result | "\(.relativePath):\(.startLine):\(.endLine)\n\(.source)"'
}

# Format scip-query trace --json into token-efficient output
format_trace() {
  jq -r '
    .result as $r |
    ($r.definitions[] | "\(.relativePath):\(.startLine):\(.endLine)\n\(.source)"),
    "",
    ($r.referencedBy[] | "\(.relativePath):\(.line)")
  '
}

# Format scip-query trace --json refs only
format_refs() {
  jq -r '.result.referencedBy[] | "\(.relativePath):\(.line)"'
}
