---
name: aws
description: Use AWS CLI for read-only operations and debugging. Use when working with AWS services, checking status, reading logs, or querying resources.
disable-model-invocation: true
---
# AWS CLI Usage

## 🚨 CRITICAL RULE
**NEVER make AWS changes via CLI without explicit user approval each time.** Only use for read-only debugging and information gathering.

## ⚠️ MULTI-PROFILE SETUP
**This system uses multiple AWS profiles for different accounts/users.** The active profile is controlled by the `AWS_PROFILE` environment variable.

**BEFORE running any AWS command:**
1. **ALWAYS check the current profile** using `aws_profile` (no arguments)
2. **Verify it's the correct profile** for the task at hand
3. **If unsure which profile to use, STOP and ask the user explicitly**
4. **Never assume** - using the wrong profile could affect the wrong AWS account

### Profile Management Functions
- `aws_profile` - List current and available profiles
- `aws_profile <name>` - Switch to profile (e.g., `aws_profile flesler`)
- `aws_infer_profile` - On-demand profile switch based on current `$PWD` directory

### Profile Auto-Switching
Profiles automatically switch on shell startup based on the working directory. You can run `aws_infer_profile` once to switch, your shell should already auto-switch

**If you're unsure which profile is correct, always ask the user before proceeding.**

## Output Formats
- `--output table` - Human readable tables
- `--output text` - Plain text (good for scripts)
- `--output json` - Full JSON (pipe to jq)
- Use `--query` to filter fields and minimize output

## JSON Parsing Tips
```bash
# Use jq for complex JSON parsing
aws <service> <command> --output json | jq '.Field.Path'

# Use --query for simple filtering
aws <service> <command> --query 'Items[].PropertyName'
```

## Helper Scripts

Token-efficient scripts in `scripts/`: `eb-health.sh`, `logs-recent.sh`, `eb-events.sh`
- Use if they fit the task, otherwise use custom bash commands directly.
- Create new scripts in `scripts/` if you notice recurring patterns.

## Use Case References

For specific AWS service workflows, see:
- **CloudWatch Logs**: [cloudwatch.md](cloudwatch.md) - Reading application logs, log streams, time-based filtering
- **Elastic Beanstalk**: [elasticbeanstalk.md](elasticbeanstalk.md) - Environment health, deployment failures, instance issues
- **IAM & Permissions**: [iam.md](iam.md) - Role checks, policy inspection, permission debugging
