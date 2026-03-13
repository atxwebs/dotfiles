---
name: gh
description: Use GitHub CLI for reading CI/CD logs, run status, PR comments. Use when debugging CI, monitoring deployments, or reviewing PR feedback.
---
# gh (GitHub CLI)

**🚨 NEVER make changes without explicit approval.** Read-only only.

**Output:** `--json field1,field2` | jq. `--log`, `--log-failed` for run logs.

**`gh run watch`:** Always use `--compact` to limit output. When capturing (agent context), pipe to `awk '!seen[$0]++'` for pseudo-uniq — watch re-prints every 3s so without dedup each refresh bloats context.

**Scripts:** [status.sh](./scripts/status.sh), [logs.sh](./scripts/logs.sh), [failed-logs.sh](./scripts/failed-logs.sh), [pr-comments.sh](./scripts/pr-comments.sh)

This file is in `~/.cursor/skills/gh/`. References:
- [ci-deployments](./references/ci-deployments.md)
- [pr-comments](./references/pr-comments.md)
