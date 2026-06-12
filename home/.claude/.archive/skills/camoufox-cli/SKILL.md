---
name: camoufox-cli
author: Ariel Flesler
description: Read when you need to crawl a website with camoufox-cli.
---

# camoufox-cli

Anti-detect Firefox with C++-level fingerprint spoofing. Passes bot detection on sites that block Chromium automation.

## Crawl

```bash
~/.claude/skills/camoufox-cli/scripts/crawl.sh <url1> [url2] ...
```

Fetches one or more URLs, strips noise (scripts, styles, nav, ads, hidden elements), unwraps links inline, and returns clean text. Auto-closes browser on exit.

## DDG Search

```bash
~/.claude/skills/camoufox-cli/scripts/ddg-search.sh "your query"
```

Free, unlimited DuckDuckGo search. Saves JSON to `$DDG_SEARCH_OUTPUT_DIR` (default `/tmp`). Outputs formatted results to stdout.

## Page Interaction

If you need to click, fill forms, or interact with page elements, read [references/interaction.md](references/interaction.md).

## Global Flags

```
--session <name>       Named session
--timeout <seconds>    Daemon idle timeout (default: 1800)
--persistent [path]    Persistent profile
--proxy <url>          Proxy server
```

## Reference

- [Interaction](references/interaction.md)
- [Snapshot Refs](references/snapshot-refs.md)
- [Commands](references/commands.md)
