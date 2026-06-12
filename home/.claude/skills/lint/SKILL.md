---
name: lint
description: For fast iterations use Cursor's read_lints tool as you refactor; run project lint before calling work done
---
For fast iterations use Cursor's `read_lints` tool as you refactor.

**Before calling a task done:** always run the project's full lint (below) after you changed code, fix any failures, then finish. Do not skip this when you edited source.

Use `npm run lint:full:silent` to check compilation and linting errors at the end.
It also fixes lint warnings like spaces/commas for you, don't waste time fixing warnings yourself.
Don't `cd`, run all from root
If it doesn't exist (few projects), switch to `npm run lint:full`. If neither, then `npm run lint:fix`. Then stick to it.
