---
name: learn
description: Read when the user asks if there's anything to learn from the conversation or to capture learnings
disable-model-invocation: true
---

# Learn from Conversation

## Critical Reminder

Skills are inserted into the agent's context window. **Always be extremely concise** to save tokens. Every word counts.

## Skill Locations

- **Primary**: `~/.cursor/skills/` (user home) - most skills are here
- **Secondary**: `.cursor/skills/` (project root) - rare, but check both locations

## Workflow

### Step 1: Assess (Do Not Modify Yet)

1. Review conversation history for:
 - Times the user didn't like something and requested changes
 - Patterns or preferences that should become automatic
 - Recurring corrections or clarifications

2. List existing skills (check both locations):
 - Get skill names/descriptions: `head -n 3 ~/.cursor/skills/*/SKILL.md`
 - If already in your context window, use that instead
 - **Do not read full skill files yet**

3. Identify candidates:
 - Which existing skills were involved in the conversation?
 - Would a new skill be needed? (New skills are **rare**)

### Step 2: Report to User

Present findings:
- Which existing skills should be updated (and why)
- If a new skill is needed, describe its purpose
- **Do not make changes yet**

### Step 3: Get Confirmation

Wait for user approval

### Step 4: Execute (After Confirmation)

**For existing skills:**
- Read only the skills that need updates
- Make minimal, targeted additions
- Preserve existing structure and style
- Avoid verbosity - add only essential information

**For new skills:**
- Follow the create-skill workflow or mimic other skills
- Keep it concise

## Principles

- **Minimal changes**: Extend existing skills slightly, don't rewrite them
- **Token efficiency**: Skills consume context - every addition must justify its cost
- **Selective reading**: Only read skills that clearly need updates
- **New skills are rare**: Most learnings fit into existing skills
