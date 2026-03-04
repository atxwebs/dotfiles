---
name: heroku
description: Read before using Heroku CLI
disable-model-invocation: true
---
# Heroku CLI Usage

## 🚨 CRITICAL RULE
**NEVER make Heroku changes via CLI without explicit user approval each time.** Only use for read-only debugging and information gathering.

## App Context
- The `--app` flag is not needed - Heroku CLI uses implicit app context from git remote or `heroku git:remote` configuration
- Always work from the project directory with Heroku git remote configured

## Use Case References

This file is in `~/.cursor/skills/heroku/` - take all paths as relative to it.

For specific Heroku workflows, see:
- **Logs**: [logs.md](./references/logs.md) - Reading application logs, filtering by time/pattern, debugging production issues
