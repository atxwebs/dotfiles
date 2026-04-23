---
name: lightpanda
description: Lightpanda headless browser for web automation and scraping. Use when fetching web pages, extracting content, or automating browser tasks
---

# Lightpanda Browser

Lightpanda is a headless browser for AI agents and automation. Ultra-fast, low memory footprint.

## Installation

Installed at `~/bin/lightpanda`.

## Scripts

### [fetch.sh](scripts/fetch.sh) - Fetch any URL

Fetches a URL and returns clean markdown output.

```bash
~/.claude/skills/lightpanda/scripts/fetch.sh "https://example.com"
~/.claude/skills/lightpanda/scripts/fetch.sh "https://example.com" --wait_ms 3000 --obey_robots
```

**Defaults:**
- `--dump markdown`
- `--wait_until networkidle`
- `--wait_ms 5000`

**Features:**
- Forwards additional args to `lightpanda`
- Output cleanup (whitespace, newlines, tabs)

### [search.sh](scripts/search.sh) - Search DuckDuckGo

Searches DuckDuckGo and returns only ### titles (clean organic results).

```bash
~/.claude/skills/lightpanda/scripts/search.sh "your search query"
```

**Features:**
- Auto-prepends DuckDuckGo URL
- Escapes query parameters
- Extracts only article titles (### headers)
- Removes ads, navigation, footers
- Supports forwarded args (e.g., `--wait_ms 3000`)

## Tips

- **DuckDuckGo > Google**: Google blocks automated requests with CAPTCHA. Always use `search.sh` or DuckDuckGo URLs.
- **Wait for networkidle**: Pages with dynamic content need `--wait_until networkidle`.
- **Markdown output**: Use `--dump markdown` for clean, token-efficient extraction.

## Direct Usage

For full control, use `lightpanda` directly:

```bash
# Fetch a webpage
lightpanda fetch --dump markdown --wait_until networkidle --wait_ms 5000 "https://example.com"

# Start CDP server for Puppeteer/Playwright
lightpanda serve --port 9222

# Start MCP server over stdio
lightpanda mcp
```

## Examples

```bash
# Fetch a news article
~/.claude/skills/lightpanda/scripts/fetch.sh "https://example.com/article"

# Fetch with custom options
~/.claude/skills/lightpanda/scripts/fetch.sh "https://example.com" --wait_ms 3000 --obey_robots

# Search for AI news
~/.claude/skills/lightpanda/scripts/search.sh "artificial intelligence news"

# Search with custom wait time
~/.claude/skills/lightpanda/scripts/search.sh "trip to japan" --wait_ms 3000

# Search DuckDuckGo (manual)
~/.claude/skills/lightpanda/scripts/fetch.sh "https://duckduckgo.com/?q=your+query"
```

## Output

Both scripts output clean, compact markdown with:
- Minimal whitespace
- No extra newlines
- Compressed indentation (tabs instead of multiple spaces)

This minimizes token usage for AI processing.
