---
name: gh
description: Use GitHub CLI (gh) for reading CI/CD logs, checking run status, and querying repository information. Use when debugging CI failures, monitoring deployments, or checking GitHub Actions workflows.
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

Token-efficient scripts in `scripts/`: `status.sh`, `logs.sh`, `failed-logs.sh`
- Use if they fit the task, otherwise use custom bash commands directly.
- Create new scripts in `scripts/` if you notice recurring patterns.

## Use Case References

For specific GitHub workflows, see:
- **CI/CD Deployments**: [ci-deployments.md](ci-deployments.md) - Monitoring deployments, comparing run timing, debugging CI failures, viewing logs
