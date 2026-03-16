---
name: learn
description: Read when the user asks if there's anything to learn from the conversation or to capture learnings
---

# Learn from Conversation

## Critical Reminder

Skills are inserted into the agent's context window. Always be extremely concise to save tokens. Every word counts.

## Skill Locations

- Primary: `~/.claude/skills/` (user home) - most skills are here
- Secondary: `.claude/skills/` (project root) - rare, but check both locations

## Skill Structure (when creating/updating)

- Extra docs: `references/<file>.md` — link as `./references/<file>.md` (one level deep)
- Scripts: `scripts/` — link as `./scripts/<file>`
- Description: what + when, third person, slightly pushy (Claude undertriggers)
- Service-specific details → references; keep main SKILL tight
- Repeated helpers → scripts/

**When creating a NEW skill:** Read `~/.claude/skills-cursor/create-skill/SKILL.md` first. For updates/tweaks, mimic the existing skill.

**Reference skills by pattern** (read only what fits):
- CLI + references/*, concise: `~/.claude/skills/gws/SKILL.md`
- CLI + references/*, critical rules: `~/.claude/skills/aws/SKILL.md`
- General structure: `~/.claude/skills-cursor/create-skill/SKILL.md`

## Workflow

### Step 1: Assess (Do Not Modify Yet)

1. Review conversation history for:
 - Times the user didn't like something and requested changes
 - Patterns or preferences that should become automatic
 - Recurring corrections or clarifications
 - Implicit patterns you followed, like files you recurringly read, grep's you ran, etc.

The following only applies if told to learn in general. If the user asked to create a specific skill, just focus on that one.

2. List existing skills (check both locations):
 - Get skill names/descriptions: `head -n 3 ~/.claude/skills/*/SKILL.md`
 - If already in your context window, use that instead
 - Do not read full skill files yet

3. Identify candidates:
 - Which existing skills were involved in the conversation?
 - Would a new skill be needed? (New skills are rare)

### Step 2: Report to User

Present findings:
- Which existing skills should be updated (and why)
- If a new skill is needed, describe its purpose
- Do not make changes yet

### Step 3: Get Confirmation

Wait for user approval

### Step 4: Execute (After Confirmation)

For existing skills:
- Read only the skills that need updates
- Make minimal, targeted additions
- Preserve existing structure and style
- Avoid verbosity - add only essential information

For new skills:
- Read ~/.claude/skills-cursor/create-skill/SKILL.md
- Pick reference from table above; read that skill's SKILL.md + one references/* for pattern
- Description: brief, WHEN to read

## Principles

- Minimal changes: Extend existing skills slightly, don't rewrite them
- Token efficiency: Skills consume context - every addition must justify its cost
- Selective reading: Only read skills that clearly need updates
- New skills are rare: Most learnings fit into existing skills. Unless the user explicitly asks to create a new skill
