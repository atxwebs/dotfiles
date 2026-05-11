---
name: todos
description: Process pasted notes into .claude/local/TODO.md. Use when user pastes /todos followed by raw notes or tasks.
---

# Todos

When user pastes `/todos` + raw notes:

1. Read `.claude/local/TODO.md`
2. Merge new tasks with existing ones
3. Polish each task: retain all words, fill gaps only. Don't rewrite much
4. Translate Spanish to English
5. Organize into 3 categories:

## Categories

- **# TODO** – Tasks that are to be done in the current project
- **# Other** – Tasks that are for other related projects
- **# Backlog** – Aspirational, ideas, won't do soon

## Rules

- Sort within each category: easier tasks on top, more time consuming or unclear towards the bottom
- Keep existing tasks untouched
- Polish raw tasks minimally: fill gaps, fix typos, clarify phrasing
- Preserve user's wording; don't paraphrase
- Spanish → English
- Use `- [ ]` checkbox format
