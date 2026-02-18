---
name: lint
description: For fast iterations use Cursor's read_lints tool as you refactor
disable-model-invocation: true
---
For fast iterations use Cursor's `read_lints` tool as you refactor.
Use `npm run lint:full:silent` to check compilation and linting errors at the end.
It also fixes lint warnings like spaces/commas for you, don't waste time fixing warnings yourself.
Don't `cd`, run all from root
If it doesn't exist (few projects), switch to `npm run lint:full`. If neither, then `npm run lint:fix`. Then stick to it.

This file is in `~/.cursor/skills/lint/` - take all paths as relative to it.
