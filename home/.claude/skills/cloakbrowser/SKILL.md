---
name: cloakbrowser
description: Use to crawl websites with stealth Chromium (57 C++ fingerprint patches) via agent-browser CLI.
---

# CloakBrowser

Stealth Chromium with source-level anti-detect patches, driven by agent-browser CLI.

## Crawl

```bash
~/.claude/skills/cloakbrowser/scripts/crawl.py <url1> [url2] ...
```

Strips noise, unwraps links inline, returns clean text. Output saved to `CLOAKBROWSER_CRAWL_OUTPUT_DIR` if set.

## DDG Search

```bash
~/.claude/skills/cloakbrowser/scripts/ddg-search.py "your query"
```

Free, unlimited DuckDuckGo search. Saves JSONL to `$DDG_SEARCH_OUTPUT_DIR` (default `/tmp`).

## Key Concepts

- **CloakBrowser binary** — `~/.cloakbrowser/chromium-*/chrome` with 57 C++ fingerprint patches (canvas, WebGL, WebRTC, etc.)
- **agent-browser daemon** — auto-starts on first command, persists across CLI calls, auto-shutdowns after idle
- **Tab-per-call** — each invocation opens a tab, works, closes it. Daemon stays alive
- **Concurrency** — multiple calls share one browser instance (~600MB), each gets its own tab
- **RAM lifecycle** — 0MB idle → ~600MB active → 0MB after 5min idle

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `CLOAK_BIN` | `~/.cloakbrowser/chromium-*/chrome` | Override browser binary |
| `AGENT_BROWSER_IDLE_TIMEOUT_MS` | `300000` (5min) | Auto-shutdown daemon after N ms of inactivity |
| `CLOAKBROWSER_CRAWL_OUTPUT_DIR` | unset | Save crawl output files |
| `DDG_SEARCH_OUTPUT_DIR` | `/tmp` | Save DDG search results |

## References

See `references/usage.md` for detailed usage patterns, gotchas, and ad-hoc snippets.
