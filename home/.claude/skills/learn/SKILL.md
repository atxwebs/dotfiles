---
name: learn
description: Read when the user asks to learn from a conversation, capture learnings, improve skills, or cement recurring work into scripts.
---

# Learn from Conversation

## Critical reminder

Skills load into context. Be concise. Every word costs tokens.

## What `/learn` means

Do not only hunt for user complaints. **Replay what you did in this session:**

1. Sequence of steps (commands, reads, branches)
2. Which steps are **deterministic** vs need **judgment**
3. What to cement as scripts vs what stays in SKILL.md
4. What to remove (superseded scripts, duplicated logic)

Most learnings update an **existing** skill. New skills are rare.

## Deterministic → scripts | Judgment → SKILL.md

| Deterministic (script)         | Judgment (skill glue)              |
| ------------------------------ | ---------------------------------- |
| Stable API calls, fixed flags  | When to run which script           |
| Parse/merge into JSON          | Approve / skip / comment verdicts  |
| Filters, counts, bot detection | User-facing wording and tone rules |
| Read-only fetches              | Interpreting diff meaning          |
| Idempotent transforms          | Branching on ambiguous risk        |

**Scripts:** `scripts/*.sh` (or `.py`/`.js`), shared `scripts/lib/*.jq`. One bundle script beats many ad-hoc calls. Extract shared libs; delete superseded wrappers.

**SKILL.md:** when to invoke scripts, how to read output, NEVER rules, report format, explicit approval before mutations.

Detail: [workflow-decomposition](./references/workflow-decomposition.md)

## Script output format

When structured output helps the agent (not required when plain text is natural):

- **Single object** → one compact JSON object on stdout (`jq -c .` or `jq -n` builder). No pretty-print.
- **List of records** (items, comments, rows) → **JSONL**: one minified JSON object per line, no wrapping array.
- **Schema lives in the script** (header comment or `--help`). SKILL.md wires sample `jq` extracts only — do not duplicate field lists.

## Workflow

### 1. Assess (do not edit yet)

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

**Graduation check:** One-liner → script → skill glue. Don't create a new skill when extending an existing one suffices. Detail: [workflow-decomposition](./references/workflow-decomposition.md).

### 2. Report

- Skills to update (and why)
- New scripts: name, replaces what, sample invocation
- SKILL.md deltas: rules/wiring only (not re-documenting JSON fields)
- Artifacts to remove
- **Test plan** per new/changed script

Wait for user approval.

### 3. Execute (after approval)

- Minimal edits; match existing skill style
- Add scripts + update SKILL script table
- Run script tests before marking done
- New skill only if user asked or nothing fits: read `~/.claude/skills-cursor/create-skill/SKILL.md`
- Rewrite skill **`description`** only if trigger scenarios changed (see below)

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
- Never encode domain rules in `learn` — teach the split, apply in target skill
