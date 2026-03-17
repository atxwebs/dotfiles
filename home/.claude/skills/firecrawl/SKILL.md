---
name: firecrawl
description: Web scraping, search, and browser automation via Firecrawl CLI. Use for: scrape webpages, search the web, crawl sites, extract structured data, or automate browser interactions.
allowed-tools:
  - Bash(firecrawl *)
  - Bash(npx firecrawl *)
---

# Firecrawl CLI

Web scraping, search, and browser automation. Returns clean markdown optimized for LLM context windows.

Run `firecrawl --help` or `firecrawl <command> --help` for details.

## Prerequisites

Must be installed and authenticated. Check with `firecrawl --status`.

```
  🔥 firecrawl cli v1.8.0

  ● Authenticated via FIRECRAWL_API_KEY
  Concurrency: 0/100 jobs (parallel scrape limit)
  Credits: 500,000 remaining
```

- **Concurrency**: Max parallel jobs. Run parallel operations up to this limit.
- **Credits**: Remaining API credits. Each scrape/crawl consumes credits.

If not ready, see [rules/install.md](rules/install.md). For output handling guidelines, see [rules/security.md](rules/security.md).

## Workflow

Follow this escalation pattern:

1. **Search** - No specific URL yet. Find pages, answer questions, discover sources.
2. **Scrape** - Have a URL. Extract its content directly.
3. **Map + Scrape** - Large site or need a specific subpage. Use `map --search` to find the right URL, then scrape it.
4. **Crawl** - Need bulk content from an entire site section (e.g., all /docs/).
5. **Browser** - Scrape failed because content is behind interaction (pagination, modals, form submissions, multi-step navigation).

| Need                        | Command    | When                                                      |
| --------------------------- | ---------- | --------------------------------------------------------- |
| Find pages on a topic       | `search`   | No specific URL yet                                       |
| Get a page's content        | `scrape`   | Have a URL, page is static or JS-rendered                 |
| Find URLs within a site     | `map`      | Need to locate a specific subpage                         |
| Bulk extract a site section | `crawl`    | Need many pages (e.g., all /docs/)                        |
| AI-powered data extraction  | `agent`    | Need structured data from complex sites                   |
| Interact with a page        | `browser`  | Content requires clicks, form fills, pagination, or login |
| Download a site to files    | `download` | Save an entire site as local files                        |

## Reference Docs

Read these detailed guides when you need specific command help:

- **`references/search.md`** — Web search with full page extraction. Read when: searching for topics, finding articles, no URL yet.
- **`references/scrape.md`** — Extract markdown from URLs. Read when: have URL, need page content, scraping static/JS-rendered pages.
- **`references/map.md`** — Discover URLs on a site. Read when: need to find a specific subpage, listing URLs, map+scrape pattern.
- **`references/crawl.md`** — Bulk extract site sections. Read when: crawling many pages, extracting entire /docs/ sections.
- **`references/browser.md`** — Cloud browser automation. Read when: page needs clicks/form fills/login, scrape failed, pagination.
- **`references/agent.md`** — AI-powered structured extraction. Read when: need JSON output, complex multi-page data, pricing/products.

## Output & Organization

Unless the user specifies to return in context, write results to `.firecrawl/` with `-o`. Add `.firecrawl/` to `.gitignore`. Always quote URLs - shell interprets `?` and `&` as special characters.

```bash
firecrawl search "react hooks" -o .firecrawl/search-react-hooks.json --json
firecrawl scrape "<url>" -o .firecrawl/page.md
```

Naming conventions:

```
.firecrawl/search-{query}.json
.firecrawl/search-{query}-scraped.json
.firecrawl/{site}-{path}.md
```

Never read entire output files at once. Use `grep`, `head`, or incremental reads:

```bash
wc -l .firecrawl/file.md && head -50 .firecrawl/file.md
grep -n "keyword" .firecrawl/file.md
```

Single format outputs raw content. Multiple formats (e.g., `--format markdown,links`) output JSON.

## Working with Results

These patterns are useful when working with file-based output (`-o` flag) for complex tasks:

```bash
# Extract URLs from search
jq -r '.data.web[].url' .firecrawl/search.json

# Get titles and URLs
jq -r '.data.web[] | "\(.title): \(.url)"' .firecrawl/search.json
```

## Parallelization

Run independent operations in parallel. Check `firecrawl --status` for concurrency limit:

```bash
firecrawl scrape "<url-1>" -o .firecrawl/1.md &
firecrawl scrape "<url-2>" -o .firecrawl/2.md &
firecrawl scrape "<url-3>" -o .firecrawl/3.md &
wait
```

For browser, launch separate sessions for independent tasks and operate them in parallel via `--session <id>`.

## Credit Usage

```bash
firecrawl credit-usage
firecrawl credit-usage --json --pretty -o .firecrawl/credits.json
```
