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

Free, unlimited DuckDuckGo search. Saves JSON to `$DDG_SEARCH_OUTPUT_DIR` (default `/tmp`).

## Direct agent-browser Usage

```bash
AB=~/.claude/skills/cloakbrowser/scripts/ab.sh
$AB open https://example.com
$AB snapshot -i
$AB eval "document.title"
$AB close
```

## Key Concepts

- **CloakBrowser binary** — `~/.cloakbrowser/chromium-*/chrome` with 57 C++ patches
- **agent-browser daemon** — auto-starts on first command, persists between commands
- **Idle timeout** — set `AGENT_BROWSER_IDLE_TIMEOUT_MS` (e.g. `300000` for 5min) for auto-shutdown
- **Concurrent crawls** — `agent-browser` is single-session; chain commands in one invocation

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `CLOAK_BIN` | `~/.cloakbrowser/chromium-*/chrome` | Override browser binary |
| `AGENT_BROWSER_IDLE_TIMEOUT_MS` | unset | Auto-shutdown daemon after N ms of inactivity |
| `CLOAKBROWSER_CRAWL_OUTPUT_DIR` | unset | Save crawl output files |
| `DDG_SEARCH_OUTPUT_DIR` | `/tmp` | Save DDG search results |
