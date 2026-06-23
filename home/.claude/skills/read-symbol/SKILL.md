---
name: read-symbol
description: Read when needing to find symbols in code files
---

To run any script use `~/.claude/skills/read-symbol/scripts/<script> <args>`.

### def.sh — Get Definition

```bash
def.sh [--type <kind>] <symbol> [symbol2 ...]
```

Kinds: `function`, `class`, `interface`, `type`, `method`, `variable`

- `--type type` matches both `type` and `interface`
- `--type function` matches both functions and methods
- `--type variable` matches `const`, `let`, `var`
- Multiple symbols: `def.sh foo bar baz`

Output:
```
src/index.ts:4:6
async function main() {
  await sess.start()
}
```

### refs.sh — Get References

```bash
refs.sh <symbol> [symbol2 ...]
```

Output:
```
src/index.ts:12
src/utils.ts:45
```

### symbols.sh — File Symbol Overview

```bash
symbols.sh <file>
```

Lists all symbols in a file with their types and signatures.

Output:
```
38 var BUILT_IN_TOOLS var BUILT_IN_TOOLS: Tool[]
40 class Session class Session
389 type Event type Event
391 type Listener type Listener
```

Format: `line kind name signature`

### search.sh — Discover Symbols by Pattern

```bash
search.sh [--kind <kind>] <pattern>
```

Find symbols matching a pattern using wildcards (`*`, `?`).

**Important:** Quote patterns containing wildcards to prevent shell expansion:
- ✅ `search.sh '*'` or `search.sh "*"`
- ❌ `search.sh *` (shell expands to filenames)

Examples:
- `search.sh 'handle*'` — find all symbols starting with "handle"
- `search.sh 'User*'` — find all symbols starting with "User"
- `search.sh --kind function '*Handler'` — find functions ending with "Handler"
- `search.sh --kind class '*'` — find all classes

Kinds: `function`, `class`, `interface`, `type`, `method`, `variable`

Output:
```
src/session/Session.ts:40 Class src:session:Session:Session
src/session/Session.ts:104 Method src:session:Session:Session:<constructor>()
src/session/Session.ts:117 Method src:session:Session:Session:on()
```

Format: `file:line kind shortName`

Returns up to 50 matches.

## Dependency Analysis

### deps.sh / rdeps.sh

Show what files a file depends on (`deps.sh <file>`) or what files depend on it (`rdeps.sh <file>`).

```bash
deps.sh src/session/Session.ts
rdeps.sh src/session/Session.ts
```

### members.sh

List all members of a symbol (methods, fields, nested types). Requires full short name (e.g. `src:util:Logger`). Use `search.sh` to find it.

**Limitations:** Does not work with enums or interfaces (scip-query limitation). Use `def.sh` to see interface definitions.

```bash
members.sh src:session:Session:Session
```

Output:
```
104:110 method src:session:Session:Session:<constructor>()
117:119 method src:session:Session:Session:on()
```

## Codebase Health

### hotspots.sh

Show most-referenced symbols in the codebase.

```bash
hotspots.sh [limit]
```

Default limit: 30

### isolated.sh

Find completely orphaned symbols (no references at all).

```bash
isolated.sh [min_loc]
```

Default min_loc: 3

### dead.sh

Find dead code (no cross-file references).

```bash
dead.sh [min_loc]
```

Default min_loc: 5

## How It Works

- Walks up from $PWD to find project root (package.json, tsconfig.json, etc.)
- Auto-indexes on first query if no index exists
- Index stored in `~/.cache/scip-query/projects/` (not in project)
- Re-indexes only when source files change

## Supported Languages

TypeScript/JavaScript (primary). Python, Rust, Go supported if their SCIP indexers are installed.
