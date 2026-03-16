---
name: aws
description: Use AWS CLI for read-only operations and debugging. Use when working with AWS services, checking status, reading logs, or querying resources.
---
# AWS CLI

**🚨 NEVER make changes without explicit approval.** Read-only only.

**Profile:** `aws_profile` — check before any command. `aws_profile <name>` to switch. `aws_infer_profile` for PWD-based switch.

**Output:** `--output json|table|text`, `--query 'path'`. Pipe to jq.

**Scripts:** [eb-health.sh](./scripts/eb-health.sh), [logs-recent.sh](./scripts/logs-recent.sh), [eb-events.sh](./scripts/eb-events.sh)

This file is in `~/.claude/skills/aws/`. References:
- [cloudwatch-logs](./references/cloudwatch-logs.md)
- [elasticbeanstalk](./references/elasticbeanstalk.md)
- [iam](./references/iam.md)
