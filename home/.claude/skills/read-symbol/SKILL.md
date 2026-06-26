---
name: read-symbol
description: Read when needing to find symbols in code files
---

TypeScript/JavaScript only (.ts, .tsx, .js, .jsx) — not GraphQL, CSS, or other files.

To run any script use `~/.claude/skills/read-symbol/scripts/<script> <args>`.

## Quick Decision Guide

| Question | Use | What you get |
|----------|-----|--------------|
| "Where is X defined and what does it do?" | `def.sh X` | Functions: full body. Classes: full definition. Multiple exact matches returned together |
| "Where is X used/called?" | `refs.sh X` | All file:line locations (~4s). Ambiguous bare names → first match only |
| "What's in this file?" | `symbols.sh file` | All symbols — bare filename works (`HistoryTab`, `usePatientEntries`) |
| "Find symbols by name" | `search.sh name` | Functions, types, interfaces, classes. Use `--kind variable` for consts |
| "What files does this file depend on?" | `deps.sh file` | Imported files — bare name works |
| "What files depend on this file?" | `rdeps.sh file` | Importers — bare name works |
| "What methods does this class have?" | `members.sh ClassName` | All methods/fields with line ranges |
| Deep analysis / codebase health | `analyze.sh [target]` | See below |

## Gotchas

- **Bare names** resolve functions, types (aliases + interfaces), and classes. Consts/variables need `def.sh --type variable X` or `search.sh --kind variable X`. Class methods need `members.sh ClassName`, not bare `def.sh methodName`.
- **Ambiguous types** (e.g. `Opts` in multiple hooks) — `def.sh` returns all; `refs.sh` picks the first and warns. Use `search.sh` or a qualified `src:…` name to disambiguate.
- **`refs.sh` is slow** (~4s per symbol) — inherent to the indexer. Batch carefully.
- **First run** in a project may auto-index (one-time wait).
- **Precision escape hatch**: qualified names like `src:hooks:usePatientEntries:usePatientEntries()` always work.

## analyze.sh

```bash
analyze.sh [target]
```

| Argument | Runs |
|----------|------|
| *(none)* | Cycles, bottlenecks, stale abstractions, hotspots, isolated, dead code |
| File path (has `/` or `.`) | Change surface, unused imports |
| Symbol name | Blast radius, complexity |

## Details

### def.sh

```bash
def.sh [--type <kind>] <symbol> [symbol2 ...]
```

Kinds: `function`, `class`, `interface`, `type`, `method`, `variable` — use `--type` when the bare name isn't in the default set above.

Pass multiple symbols in one call (`def.sh Foo Bar Baz`) — index is fetched once and reused, faster than separate invocations.
