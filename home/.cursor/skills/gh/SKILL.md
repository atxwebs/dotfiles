---
name: gh
description: Use GitHub CLI (gh) for reading CI/CD logs, checking run status, querying repository information, and reviewing PR comments. Use when debugging CI failures, monitoring deployments, or checking GitHub Actions workflows.
disable-model-invocation: true
---
# GitHub CLI Usage

## 🚨 CRITICAL RULE
**NEVER make GitHub changes via CLI without explicit user approval each time.** Only use for read-only debugging and information gathering.

## Output Formats
- `--json` - Structured JSON output (pipe to jq)
- `--log` - Full log output (use `| tail -N` to minimize)
- `--log-failed` - Only failed step logs

## JSON Parsing Tips
```bash
# Use jq with --json flag for structured data
gh <command> --json field1,field2 | jq '.field1'

# Filter arrays
gh <command> --json items | jq '.items[] | select(.status == "completed")'
```

## Helper Scripts

Token-efficient scripts in [scripts/](./scripts/): [status.sh](./scripts/status.sh), [logs.sh](./scripts/logs.sh), [failed-logs.sh](./scripts/failed-logs.sh), [pr-comments.sh](./scripts/pr-comments.sh)
- Use if they fit the task, otherwise use custom bash commands directly.
- Create new scripts in [scripts/](./scripts/) if you notice recurring patterns.

## Use Case References

This file is in `~/.cursor/skills/gh/` - take all paths as relative to it.

For specific GitHub workflows, see:
- **CI/CD Deployments**: [ci-deployments.md](./references/ci-deployments.md) - Monitoring deployments, comparing run timing, debugging CI failures, viewing logs
- **PR Comments**: [pr-comments.md](./references/pr-comments.md) - Reviewing PR comments, filtering Cursor bot comments, optimal review flow
