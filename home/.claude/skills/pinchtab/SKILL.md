---
name: pinchtab
description: Use to crawl websites without needing stealth mode (use camoufox-cli for anti-detect)
---

# PinchTab

Browser automation CLI. 12MB Go binary, uses real Chrome.

## Server

Install and run as a background service: `pinchtab daemon install && pinchtab daemon start`

## Crawl

```bash
~/.claude/skills/pinchtab/scripts/crawl.sh <url1> [url2] ...
```

Strips noise (scripts, styles, nav, ads, hidden elements), unwraps links inline, and returns clean text. Uses the default profile (persisted logins). Output saved to `PINCHTAB_CRAWL_OUTPUT_DIR` if set.

## Page Interaction

Read [references/interaction.md](references/interaction.md) when you need to click, fill forms, or interact with page elements.

## Key Concepts

- **Profiles** store cookies, sessions, local storage. Default profile at `~/.pinchtab/profiles/default/`.
- **Sessions** are CLI auth tokens for tab context. Created with `pinchtab session create --agent-id <id>`.
- Always create a session before browser commands: `export PINCHTAB_SESSION=$(pinchtab session create --agent-id myagent)`

## Reference

- [Interaction](references/interaction.md)
- [Snapshot Refs](references/snapshot-refs.md)
- [Commands](references/commands.md)
- [Profiles](references/profiles.md)
