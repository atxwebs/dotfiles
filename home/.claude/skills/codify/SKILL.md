---
name: codify
description: Read when the user asks to codify a session, capture learnings, improve skills, or cement recurring work into scripts.
---

# Codify a Session

## Critical reminder

Skills load into context. Be concise. Every word costs tokens.

## Two modes

**Update existing skill:** `/codify /lint` or `/codify /aws` — polish, add scripts, refine rules in an existing skill.

**Create new skill:** `/codify ~/.claude/skills/new-skill` — extract session learnings into a fresh skill at that path.

Most invocations update. New skills are rare.

## What `/codify` means

**Replay what you did in this session:**

1. Sequence of steps (commands, reads, branches)
2. Which steps are **deterministic** vs need **judgment**
3. What to cement as scripts vs what stays in SKILL.md
4. What to remove (superseded scripts, duplicated logic)

## Three levels of specificity

| Level             | Artifact                         | When                                                              |
| ----------------- | -------------------------------- | ----------------------------------------------------------------- |
| Text instructions | Prose in SKILL.md                | Judgment calls, tone, branching on context                        |
| Inline snippets   | 1-2 line code blocks in SKILL.md | Short commands, parameters vary per invocation                    |
| References        | `references/*.md`                | Long tables, env variants, notebooks — ~200+ lines or multi-topic |
| Scripts           | `scripts/*.sh` (or `.py`/`.js`)  | Stable logic, reused across sessions, complex pipelines           |

**Scripts:** start in Bash (terse, native shell access). Use `jq` inline for JSON—it keeps Bash clean and scales it further. Extract to `scripts/lib/*.jq` only when filters are bulky or reused across scripts. Migrate to `.js`/`.py` when logic outgrows Bash or you're inlining JS/Py inside it. Agent picks language. One bundle beats many ad-hoc calls; delete superseded wrappers.

**Snippets:** `gh pr list --state open --json number,title`, `jq -c '.items[]'`. Keep inline when the command is short or the user/args change each time.

**SKILL.md prose:** when to invoke scripts/snippets, NEVER rules, report format. Mutating target-skill scripts need `--dry-run` or explicit user OK — not a codify gate on every edit.

Detail: [workflow-decomposition](./references/workflow-decomposition.md)

## Script output format

When structured output helps the agent (not required when plain text is natural):

- **Single object** → one compact JSON object on stdout (`jq -c .` or `jq -n` builder). No pretty-print.
- **List of records** (items, comments, rows) → **JSONL**: one minified JSON object per line, no wrapping array.
- **Schema lives in the script** (header comment or `--help`). SKILL.md wires sample `jq` extracts only — do not duplicate field lists.

## Workflow

**Agile default:** low-risk skill polish (wording, wiring, snippets, read-only scripts) → assess and **execute in one turn**. No proposal essay.

**Pause first** only for: new skills, destructive/mutating scripts, large splits, or genuinely unclear scope.

### 1. Assess

**Session replay**

Same chat: prior tool calls and outputs are usually **still in context**. Start there.

Fallback when history is thin (summarized thread, past chat): search **session logs or transcripts** the user points at — format varies by tool. `rg` first, `jq` once you know the shape:

```bash
rg -n 'gh |curl |jq |scripts/' <session-log-or-transcript>
rg -n 'tool_use|command|Shell' <session-log-or-transcript>
```

Do not assume a fixed log path or schema.

**Replay checklist**

- Tool/command sequence you actually ran
- User corrections and preferences
- Implicit patterns (files always read, greps always run)

**Classify each step** → script candidate or skill rule?

**Inventory skills:**

```bash
head -n 3 ~/.claude/skills/*/SKILL.md
head -n 3 .claude/skills/*/SKILL.md   # project checkout, if any
```

Read full files only for skills you will change.

**Consolidation check:** Can new script replace N ad-hoc calls? Shared lib instead of copy-paste? Lighter list script vs full bundle?

**Split check:** ~200+ lines, multi-env/topic bloat, or user asks to slim → [skill-split](./references/skill-split.md). Single-topic checklists ~150 lines can stay whole.

**Graduation check:** One-liner → script → skill glue. Don't create a new skill when extending an existing one suffices. Detail: [workflow-decomposition](./references/workflow-decomposition.md).

### 2. Report (brief)

**Max ~8 bullets or one short paragraph.** User should not read a book.

Format: `skill → change` lines only. Example:

```
testing: post-publish verify snippet (mongo + jq + curl)
codify: agile execute, shorter report
skip: new script — ad-hoc jq was enough
```

Include test plan only for new/changed scripts (one line each).

**Wait for approval** only when pause triggers above apply. Otherwise go to step 3 immediately.

### 3. Execute

- Minimal edits; match existing skill style
- Add scripts + update SKILL script table
- Run script tests before marking done
- New skill only if user asked or nothing fits: read `~/.claude/skills-cursor/create-skill/SKILL.md`
- Rewrite skill **`description`** only if trigger scenarios changed (see below)
- Tell user what landed in **3–5 lines** — not a recap of the whole session

## Script testing (required)

Every new or changed script gets tested before the task is done. Inputs are usually **live** (IDs, URLs) — run against a real safe target, not saved fixtures.

**Read-only / idempotent:** run for real. Verify exit code and output shape (`jq -c` spot-check).

**Mutating:** add `--dry-run` — same reads and branching, no mutations; preview on stderr. Real run only with explicit user approval.

Detail: [script-testing](./references/script-testing.md)

## Skill layout

| Piece                    | Location                           |
| ------------------------ | ---------------------------------- |
| When + glue + rules      | `SKILL.md`                         |
| Deterministic automation | `scripts/`                         |
| Shared jq/helpers        | `scripts/lib/`                     |
| Long examples            | `references/*.md` (one level deep) |

Split pattern: [skill-split.md](./references/skill-split.md).

**Locations:** `~/.claude/skills/` (primary), `.claude/skills/` (project checkout).

### Skill `description` — WHEN only

The YAML `description` is the **trigger** — when to read, not what the skill does.

- ✅ "Read when the user pastes a Jira URL or asks about a ticket."
- ❌ "Parses Jira URLs and fetches issue metadata via API."

Slightly pushy phrasing helps under-triggering. After adding scripts, update WHEN only if **new trigger scenarios** exist — never list script names in `description`.

## Principles

- Scripts for repetition; skill for taste and branching
- Token efficiency: references over bloated SKILL.md
- One concern per script; compose in skill workflow
- Delete superseded scripts when merged
- Project-repo conventions → that repo's rules/docs; personal automation → `~/.claude/skills/`
- Never encode domain rules in `codify` — teach the split, apply in target skill
- **NEVER** pad markdown tables for column alignment — `| --- |` separators only. Fix existing files: `scripts/remove-table-padding.sh <dir-or-file>`.

## Scripts

| Script                            | Role                                                                |
| --------------------------------- | ------------------------------------------------------------------- |
| `scripts/remove-table-padding.sh` | Strip alignment padding from markdown tables (`--dry-run` optional) |
