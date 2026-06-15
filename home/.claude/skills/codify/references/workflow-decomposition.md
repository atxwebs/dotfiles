# Workflow decomposition

Example session (review triage):

| Step | Level | Artifact |
| --- | --- | --- |
| List pending items | Script | `list-candidates.sh` |
| Per-item stats / filters | Script (lib) | `lib/stats.jq` |
| Bot vs human signals | Script (lib) | `lib/classify.jq` |
| Bundle fetches | Script | `assess.sh` |
| Fetch raw diff | Snippet | `gh pr view $NUM` |
| Verdict / comment text | Text instructions | SKILL.md rules |
| Post / mutate remote | Script + approval | `--dry-run` + user OK |

## Graduation ladder

| Stage | Artifact | Signal |
| --- | --- | --- |
| 1 | Shell one-liner in chat | Same command twice |
| 2 | Inline snippet in SKILL.md | Third use, or parameters vary per run |
| 3 | `scripts/foo.sh` | Stable logic, reused across sessions |
| 4 | SKILL.md glue + script table | Agent should invoke without being told |

Prefer extending an existing skill over creating a new one.

## When to use each level

**Text instructions (prose in SKILL.md):**

- Heuristics with exceptions ("usually approve unless…")
- NEVER lists (tone, approval gates)
- Mapping script output → user-facing report
- Choosing lighter list script vs full bundle

**Inline snippets (1-2 line code blocks):**

- Short commands where args change each invocation
- `gh pr list --state open --json number,title`
- `jq -c '.items[]'`
- One-liners that don't warrant a script file

**Scripts (`scripts/*.sh` or `.py`):**

- Same calls every time with stable structured output
- Logic duplicated across sessions or ad-hoc blocks
- Classification rules that never need context (allowlists, path globs)
- Complex pipelines with error handling

## Consolidation

- Merge N fetch calls → one parallel bundle script
- Shared `lib/*.jq` over inline duplicate filters
- Keep lighter batch script if full bundle is too heavy for lists
- Remove thin wrappers superseded by `bundle | jq '.field'`

## Output shape

- One record → compact JSON object
- Many records → JSONL (one minified object per line)
- Plain prose/logs when structure adds no value
