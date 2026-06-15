# Splitting a bloated SKILL.md into references

Split on **structure**, not line count alone. Goal: **SKILL.md ~50–80 lines** — trigger, glue, routing; depth in `references/*.md` (one level deep).

**When to split**

|Signal|Action|
|---|---|
|User asks to slim|Split|
|**~200+ lines**|Should split|
|**~150–200 lines** + multiple envs/topics, notebook appendices, or duplicate tables|Should split|
|**~150 lines**, single cohesive checklist (naming rules, test style, one DB connection guide)|**Keep whole** — agents need it in one read|
|Under **150 lines**|Usually fine|

`aws` was **331 lines** with DVM/acceptance/prod variants — obvious. **`mongodb`** / **`postgresql`** at ~100 are single-topic — fine.

## What stays in SKILL.md

- YAML **`description`** (WHEN to read the skill)
- Trigger, principles, NEVER rules
- **Workflow** (numbered steps agents follow every time)
- **Routing table** — task/signal → which reference to **READ** (not summarize)
- Script names + one-line invocations only
- No env-specific tables, long examples, or append-only notes

## What moves to `references/`

|Slice|Filename pattern|Contents|
|---|---|---|
|Auth / credentials|`auth.md`|SSO, profiles, vault quirks, config stanzas|
|Generic recipes|`<topic>-recipes.md`|Reusable commands; no env tables|
|Mental model|`<topic>-<concept>.md`|Architecture, bucket/key model, routing to other refs|
|Env or variant|`<topic>-<env>.md`|One environment per file (dvm, acceptance, production)|
|Session learnings|`notebook.md`|Durable discoveries — **append here**, not SKILL.md|
|Errors|`troubleshooting.md`|Symptom → fix; link back to env refs|

**Rules**

- **One concern per file** — slice by env or topic, not arbitrary line chunks.
- **Cross-link** between refs; do not duplicate the routing table from SKILL.md inside every ref.
- **Do not nest** `references/references/`.
- Optional **hub ref** (e.g. `s3-published-sites.md`) when many env refs share one mental model.

## Wiring (required)

References are **not** auto-loaded. SKILL.md must:

1. List every ref under **References** with a one-line “when to read”.
2. Include a **routing table** (task → profile/env → ref) for the common fork.
3. Use **READ** / **read** explicitly — not “see” or “optional”.

Update **`description`** only if triggers change (e.g. “read `references/` for env detail”) — still WHEN-only, no file inventory.

## Execute

1. Read full SKILL.md; outline slices (table above).
2. Move prose verbatim where possible — **restructure, don’t rewrite** unless fixing errors.
3. Slim SKILL.md; verify every moved section has a link from the index.
4. Report: before/after line counts per file; no new scripts unless the split exposed a script candidate.

## Anti-patterns

- One giant `references/everything.md` — same token problem, harder to navigate.
- Duplicating the same table in SKILL.md and a reference.
- Putting **only** deep content in refs but leaving workflow buried there — workflow stays in SKILL.md.
- Splitting auth into a ref **without** a profile/env row in the routing table (agents skip the read).

## Example (aws skill)

`SKILL.md` 50 lines · `auth.md` · `s3-recipes.md` · `s3-published-sites.md` (hub) · `s3-dvm.md` · `s3-acceptance.md` · `s3-production.md` · `notebook.md` · `troubleshooting.md`
