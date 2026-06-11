# Script testing

Inputs are usually dynamic (PR numbers, issue keys, site IDs). Test against a **real safe target** — no fixture files.

## Read-only / idempotent

Run for real. Check exit code and spot-check output shape.

```bash
./scripts/list-items.sh | head -1 | jq -c .
./scripts/bundle.sh 12345 | jq -c '{id, status}'
```

JSONL: confirm each line parses and expected keys exist on a sample line.

## Mutating scripts

### `--dry-run` contract

- Parse `--dry-run` early; set `DRY_RUN=1`
- Run all reads and branching as normal
- Replace mutating commands with preview:

```bash
run_mutate() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "DRY-RUN: $*" >&2
    return 0
  fi
  "$@"
}
```

- Dry-run output should be copy-pasteable or clearly labeled
- Document in script header: `Usage: ./foo.sh [--dry-run]`

### Test order

1. Dry-run (mutating scripts)
2. User approves
3. Real run

Never skip testing because "it's obvious."
