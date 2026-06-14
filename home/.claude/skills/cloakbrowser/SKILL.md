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

Strips noise, unwraps links inline, returns clean text. Output saved to `CRAWL_OUTPUT_DIR` if set.

## DDG Search

```bash
~/.claude/skills/cloakbrowser/scripts/ddg-search.py "your query"
```

Free, unlimited DuckDuckGo search. Saves JSONL to `$DDG_SEARCH_OUTPUT_DIR` (default `/tmp`).

```bash
~/.claude/skills/cloakbrowser/scripts/ddg-search.py "your query"        # page 1
~/.claude/skills/cloakbrowser/scripts/ddg-search.py "your query" --page 2  # page 2
```

## Custom Exploration

Ad-hoc browser exploration with full Playwright API + humanize patches.

```bash
~/.claude/skills/cloakbrowser/scripts/custom.py <url>              # Open URL, print title + text
~/.claude/skills/cloakbrowser/scripts/custom.py <url> --eval <js>  # Run JS and print result
~/.claude/skills/cloakbrowser/scripts/custom.py <url> --snapshot   # Print accessibility snapshot
~/.claude/skills/cloakbrowser/scripts/custom.py <url> --html       # Print page HTML
```

See `references/usage.md` for the full Python CDP pattern.

## Key Concepts

- **CloakBrowser binary** — `~/.cloakbrowser/chromium-*/chrome` with 58 C++ fingerprint patches
- **Stealth** — `get_default_stealth_args()` + time-based fingerprint. READ [stealth](./references/stealth.md).
- **agent-browser daemon** — auto-starts on first command, persists across CLI calls, auto-shutdowns after idle
- **Tab-per-call** — each invocation opens a tab, works, closes it. Daemon stays alive
- **Concurrency** — multiple calls share one browser instance (~600MB), each gets its own tab
- **RAM lifecycle** — 0MB idle → ~600MB active → 0MB after 5min idle

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `CLOAK_BIN` | `~/.cloakbrowser/chromium-*/chrome` | Override browser binary |
| `AGENT_BROWSER_HEADED` | `0` | `1` = visible browser |
| `AGENT_BROWSER_IDLE_TIMEOUT_MS` | `180000` | Daemon idle shutdown |
| `CRAWL_OUTPUT_DIR` | unset | Save crawl output files |
| `DDG_SEARCH_OUTPUT_DIR` | `/tmp` | Save DDG search results |

## Notes

- **Stealth** — see [stealth.md](./references/stealth.md) (source-linked to CloakHQ README)
- **humanize** — on by default in `connect_cdp()` per [README](https://github.com/CloakHQ/CloakBrowser#humanize)
- **Challenges** — `wait_for_challenge()` for Turnstile
- **2Captcha / CapSolver** — Paid API fallbacks (~$3/1000 solves). Not integrated.

## References

- [usage](./references/usage.md) — CDP patterns, agent-browser gotchas, batching
- [stealth](./references/stealth.md) — anti-detection layers, Turnstile bypass, headed mode
