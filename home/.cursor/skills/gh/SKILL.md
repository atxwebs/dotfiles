---
name: gh
description: Use GitHub CLI for reading CI/CD logs, run status, PR comments. Use when debugging CI, monitoring deployments, or reviewing PR feedback.
---
# gh (GitHub CLI)

**🚨 NEVER make changes without explicit approval.** Read-only only.

**Output:** `--json field1,field2` | jq. `--log`, `--log-failed` for run logs.

**Scripts:** [status.sh](./scripts/status.sh), [logs.sh](./scripts/logs.sh), [failed-logs.sh](./scripts/failed-logs.sh), [pr-comments.sh](./scripts/pr-comments.sh)

This file is in `~/.cursor/skills/gh/`. References:
- [ci-deployments](./references/ci-deployments.md)
- [pr-comments](./references/pr-comments.md)
