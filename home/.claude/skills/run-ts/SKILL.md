---
name: run-ts
description: Use npm run ts to run TS files
disable-model-invocation: true
---
Use `npm run ts -- bin/*.ts` to run TS files. Run with `--help` (or omit required args) to see usage.
You can create temp scripts at `bin/test/*.ts` and run them. No need to delete them after.
You can also use `npm run exec <code>` for ad-hoc code.

**Important**: Always add `process.exit(0)` at the end of scripts to ensure they terminate promptly and don't hang waiting for async operations.

**Imports**: Bin scripts use the `src` path alias (`import x from 'src/util/foo'`), not relative paths like `../../src/`.

This file is in `~/.claude/skills/run-ts/` - take all paths as relative to it.
