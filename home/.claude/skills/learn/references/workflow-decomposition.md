# Workflow decomposition

Example session (review triage):

| Step                     | Deterministic? | Artifact               |
| ------------------------ | -------------- | ---------------------- |
| List pending items       | Yes            | `list-candidates.sh`   |
| Per-item stats / filters | Yes            | `lib/stats.jq`         |
| Bot vs human signals     | Yes            | `lib/classify.jq`      |
| Bundle fetches           | Yes            | `assess.sh`            |
| Fetch raw diff           | Yes (CLI)      | skill says when to run |
| Verdict / comment text   | No             | SKILL.md rules         |
| Post / mutate remote     | Mutating       | `--dry-run` + user OK  |

## Graduation ladder

| Stage | Artifact                     | Signal                                 |
| ----- | ---------------------------- | -------------------------------------- |
| 1     | Shell one-liner in chat      | Same command twice                     |
| 2     | `scripts/foo.sh`             | Third use, or flags easy to get wrong  |
| 3     | SKILL.md script table + glue | Agent should invoke without being told |

Prefer extending an existing skill over creating a new one.

## When to script

- Same calls every time with stable structured out
- Logic duplicated across sessions or ad-hoc blocks
- Classification rules that never need context (allowlists, path globs)

## When to keep in SKILL

- Heuristics with exceptions ("usually approve unless…")
- NEVER lists (tone, approval gates)
- Mapping script output → user-facing report
- Choosing lighter list script vs full bundle

## Consolidation

- Merge N fetch calls → one parallel bundle script
- Shared `lib/*.jq` over inline duplicate filters
- Keep lighter batch script if full bundle is too heavy for lists
- Remove thin wrappers superseded by `bundle | jq '.field'`

## Output shape

- One record → compact JSON object
- Many records → JSONL (one minified object per line)
- Plain prose/logs when structure adds no value
