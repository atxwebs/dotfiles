#!/bin/bash
# Shared helpers for read-symbol scripts

# Suppress CLI update notifications (scip-query uses update-notifier)
export NO_UPDATE_NOTIFIER=1

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
  local stderr_file
  stderr_file=$(mktemp)
  trap "rm -f '$stderr_file'" RETURN

  _run() {
    output=$(cd "$root" && "$@" 2>"$stderr_file")
    exit_code=$?
  }

  _run "$@"

  if [[ $exit_code -ne 0 ]] && grep -q "No index.db found" "$stderr_file"; then
    local lang
    lang="$(detect_language "$root")"
    echo "Auto-indexing $root ($lang)..." >&2
    (cd "$root" && scip-query reindex --language "$lang" 2>&1) >&2 || true
    _run "$@"
  fi

  while [[ $exit_code -ne 0 ]] && grep -q "already running" "$stderr_file"; do
    if [[ $waited -ge $max_wait ]]; then
      echo "Timeout waiting for concurrent indexer to finish (${max_wait}s)" >&2
      cat "$stderr_file" >&2
      return 1
    fi
    echo "Another indexer is running, waiting... (${waited}s)" >&2
    sleep 3
    waited=$((waited + 3))
    _run "$@"
  done

  if [[ $exit_code -ne 0 ]]; then
    cat "$stderr_file" >&2
    return 1
  fi

  echo "$output"
}

# Format scip-query code --json into token-efficient output
format_def() {
  jq -r '.result | "\(.relativePath):\(.startLine):\(.endLine)\n\(.source)"'
}

# Format scip-query refs --json
format_refs_json() {
  jq -r '.result[] | "\(.relativePath):\(.line)"'
}

# Bare-name resolution: Function + TypeAlias + Interface + Class.
# Variable: huge, ambiguous — use --type variable. Method: use members.sh.
DEFAULT_SYMBOL_KINDS=(Function TypeAlias Interface Class)

_BY_KIND_CACHE_ROOT=""
declare -A _BY_KIND_CACHE

by_kind_json() {
  local root="$1"
  local kind="$2"
  local output

  if [[ "$_BY_KIND_CACHE_ROOT" != "$root" ]]; then
    _BY_KIND_CACHE=()
    _BY_KIND_CACHE_ROOT="$root"
  fi

  if [[ -n "${_BY_KIND_CACHE[$kind]:-}" ]]; then
    echo "${_BY_KIND_CACHE[$kind]}"
    return 0
  fi

  output=$(run_query "$root" scip-query by-kind "$kind" --limit 2000 --json 2>/dev/null) || output='{"result":[]}'
  _BY_KIND_CACHE[$kind]="$output"
  echo "$output"
}

prefetch_kinds() {
  local root="$1"
  shift
  local kind tmpdir output

  tmpdir=$(mktemp -d)
  trap "rm -rf '$tmpdir'" RETURN

  for kind in "$@"; do
    if [[ -n "${_BY_KIND_CACHE[$kind]:-}" ]]; then
      continue
    fi
    (
      run_query "$root" scip-query by-kind "$kind" --limit 2000 --json 2>/dev/null \
        || echo '{"result":[]}'
    ) > "$tmpdir/$kind" &
  done
  wait

  for kind in "$@"; do
    if [[ -n "${_BY_KIND_CACHE[$kind]:-}" ]]; then
      continue
    fi
    if [[ -f "$tmpdir/$kind" ]]; then
      output=$(<"$tmpdir/$kind")
      _BY_KIND_CACHE[$kind]="$output"
    fi
  done
}

kinds_for_type_filter() {
  case "$1" in
    function) echo "Function" ;;
    class) echo "Class" ;;
    interface) echo "Interface TypeAlias" ;;
    type) echo "TypeAlias Interface" ;;
    method) echo "Method" ;;
    variable) echo "Variable" ;;
  esac
}

detect_sig_kind() {
  local signature="$1"
  local source_line="$2"
  local sig_kind=""
  local source_clean

  case "$signature" in
    "function "*) echo "function"; return ;;
    "class "*) echo "class"; return ;;
    "interface "*) echo "interface"; return ;;
    "type "*) echo "type"; return ;;
    "enum "*) echo "enum"; return ;;
    "const "*) echo "variable"; return ;;
    "let "*) echo "variable"; return ;;
    "var "*) echo "variable"; return ;;
  esac

  source_clean=$(echo "$source_line" | sed -E 's/^(export\s+)?(async\s+|static\s+|default\s+|public\s+|private\s+|protected\s+)*//')

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
    sig_kind="method"
  fi

  echo "$sig_kind"
}

_COLLECT_SYMBOLS_JSON_CACHE_ROOT=""
_COLLECT_SYMBOLS_JSON_CACHE=""

# Indexed symbols for search.sh (same scope as bare-name resolution).
collect_symbols_json() {
  local root="$1"
  local kinds=("${DEFAULT_SYMBOL_KINDS[@]}")
  local all_results="[]"
  local kind kind_output kind_results

  if [[ "$_COLLECT_SYMBOLS_JSON_CACHE_ROOT" == "$root" && -n "$_COLLECT_SYMBOLS_JSON_CACHE" ]]; then
    echo "$_COLLECT_SYMBOLS_JSON_CACHE"
    return 0
  fi

  prefetch_kinds "$root" "${kinds[@]}"

  for kind in "${kinds[@]}"; do
    kind_output=$(by_kind_json "$root" "$kind") || continue
    kind_results=$(echo "$kind_output" | jq -c '.result // []')
    all_results=$(echo "$all_results" "$kind_results" | jq -s '.[0] + .[1]')
  done

  _COLLECT_SYMBOLS_JSON_CACHE_ROOT="$root"
  _COLLECT_SYMBOLS_JSON_CACHE="{\"result\":$all_results}"
  echo "$_COLLECT_SYMBOLS_JSON_CACHE"
}

exact_leaf_matches_in_kind() {
  local root="$1"
  local kind="$2"
  local symbol="$3"
  local output

  output=$(by_kind_json "$root" "$kind") || return 0
  echo "$output" | jq -r --arg sym "$symbol" '
    .result[] |
    select((.shortName | split(":") | last | rtrimstr("()")) == $sym) |
    .shortName
  ' | sort -u
}

# Print one qualified shortName per line. Bare names match Function, TypeAlias, Class.
resolve_symbol_targets() {
  local root="$1"
  local symbol="$2"
  local kinds_hint="${3:-}"
  local -a matches=()
  local -a kinds_to_scan=()
  local kind match

  if [[ "$symbol" == *:* ]]; then
    echo "$symbol"
    return 0
  fi

  if [[ -n "$kinds_hint" ]]; then
    read -r -a kinds_to_scan <<< "$kinds_hint"
  else
    kinds_to_scan=("${DEFAULT_SYMBOL_KINDS[@]}")
  fi

  prefetch_kinds "$root" "${kinds_to_scan[@]}"

  for kind in "${kinds_to_scan[@]}"; do
    while IFS= read -r match; do
      [[ -n "$match" ]] && matches+=("$match")
    done < <(exact_leaf_matches_in_kind "$root" "$kind" "$symbol")
  done

  if [[ ${#matches[@]} -eq 0 ]]; then
    echo "$symbol"
    return 0
  fi

  local -a unique=()
  local m u found
  for m in "${matches[@]}"; do
    found=false
    for u in "${unique[@]}"; do
      if [[ "$u" == "$m" ]]; then
        found=true
        break
      fi
    done
    if [[ "$found" == false ]]; then
      unique+=("$m")
    fi
  done

  printf '%s\n' "${unique[@]}"
}

# Back-compat alias
resolve_trace_targets() {
  resolve_symbol_targets "$@"
}

# Resolve file argument to project-relative path.
resolve_file_path() {
  local root="$1"
  local target="$2"
  local output count

  if [[ "$target" == /* ]]; then
    target="${target#$root/}"
  fi

  if [[ -f "$root/$target" ]]; then
    echo "$target"
    return 0
  fi

  output=$(run_query "$root" scip-query files "$target" --json 2>/dev/null) || return 1
  count=$(echo "$output" | jq '.result | length')

  if [[ "$count" -eq 1 ]]; then
    echo "$output" | jq -r '.result[0].relativePath'
    return 0
  fi

  if [[ "$count" -gt 1 ]]; then
    echo "Ambiguous file '$target'. Candidates:" >&2
    echo "$output" | jq -r '.result[].relativePath' | sed 's/^/  /' >&2
    return 1
  fi

  return 1
}

# Resolve a human symbol name to a SCIP shortName for members/hierarchy.
# Returns 0 and prints shortName on success; returns 1 on failure.
resolve_symbol_short_name() {
  local root="$1"
  local symbol="$2"
  local -a matches=()
  local target file outline sn

  if [[ "$symbol" == src:* ]]; then
    echo "$symbol"
    return 0
  fi

  while IFS= read -r target; do
    [[ -n "$target" ]] && matches+=("$target")
  done < <(resolve_symbol_targets "$root" "$symbol")

  for pattern in "${symbol}.ts" "${symbol}.tsx"; do
    local output
    output=$(run_query "$root" scip-query files "$pattern" --json 2>/dev/null) || continue
    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      outline=$(run_query "$root" scip-query outline "$file" --json 2>/dev/null) || continue
      sn=$(echo "$outline" | jq -r '.result[0].shortName // empty')
      [[ -n "$sn" ]] && matches+=("$sn")
    done < <(echo "$output" | jq -r '.result[].relativePath')
  done

  if [[ ${#matches[@]} -eq 0 ]]; then
    return 1
  fi

  local -a unique=()
  local m u found
  for m in "${matches[@]}"; do
    found=false
    for u in "${unique[@]}"; do
      if [[ "$u" == "$m" ]]; then
        found=true
        break
      fi
    done
    if [[ "$found" == false ]]; then
      unique+=("$m")
    fi
  done

  if [[ ${#unique[@]} -eq 1 ]]; then
    echo "${unique[0]}"
    return 0
  fi

  echo "Ambiguous symbol '$symbol'. Candidates:" >&2
  printf '  %s\n' "${unique[@]}" >&2
  return 1
}

# Run scip-query members and return JSON output (empty if no members).
members_json() {
  local root="$1"
  local symbol="$2"
  local output

  output=$(run_query "$root" scip-query members "$symbol" --json 2>/dev/null) || return 1
  if ! echo "$output" | jq -e '.result | length > 0' >/dev/null 2>&1; then
    return 1
  fi
  echo "$output"
}
