---
name: exaai
description: AI-powered search for LLMs via Exa.ai API. Optimized for research with category and domain filtering.
---


# Exa.ai API

AI-powered search engine optimized for LLMs. Provides neural search with category filtering and domain restrictions.

## Usage

**Important**: Be mindful of API credits. Default limit is 10 results.

## Quick Start

```bash
# Basic search
~/.claude/skills/exaai/scripts/search "your query"

# Search with category filter
~/.claude/skills/exaai/scripts/search "query" --category "research paper"

# Search with domain restrictions
~/.claude/skills/exaai/scripts/search "query" --domains "pubmed.ncbi.nlm.nih.gov,mayoclinic.org"

# Combine options
~/.claude/skills/exaai/scripts/search "query" --category "news" --domains "reuters.com,bloomberg.com" --limit 5
```

## Output

Results are saved to `~/.exaai/search-{query}.json` with:
- Full page text (highlights up to 4000 chars)
- URLs, titles, and metadata
- Automatically cleaned whitespace

## Options

| Option | Description | Default |
|--------|-------------|---------|
| (positional) | Search query (required) | - |
| `--category` | Filter by category: "news", "research paper", "company", "webpage", etc. | auto |
| `--domains` | Comma-separated list of domains to include | all domains |
| `--limit` | Number of results | 10 |

## API Key

Set `EXA_AI_API_KEY` in your `~/.bash_extras`:

```bash
export EXA_AI_API_KEY='your-api-key-here'
```

---

*Efficiency first: Use category filters for higher quality results, domain restrictions for trusted sources.*
