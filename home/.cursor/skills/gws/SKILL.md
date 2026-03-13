---
name: gws
description: Use Google Workspace CLI for Drive, Gmail, Calendar, Sheets, Docs, Tasks. Read when working with Workspace data via CLI.
---
**Auth:** `GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE=~/.config/gws/credentials.json` (in ~/.bash_extras). Re-auth: `gws auth login`, export: `gws auth export --unmasked > ~/.config/gws/credentials.json`.

**Pattern:** `gws <service> <resource> [sub] <method> --params '{"k":"v"}'` (query/path) `--json '{...}'` (body). `--dry-run` to preview. Output: JSON.

**Introspect:** `gws schema drive.files.list` — shows request/response schema.

**Pagination:** `--page-all` for NDJSON stream. `--page-limit N`, `--page-delay MS`.

This file is in `~/.cursor/skills/gws/`. References:
- [drive](./references/drive.md) — files, search, upload
- [gmail](./references/gmail.md) — messages, labels, send
- [calendar](./references/calendar.md) — events, calendarList
- [sheets](./references/sheets.md) — spreadsheets, values
- [docs](./references/docs.md) — documents get/update
- [tasks](./references/tasks.md) — tasklists, tasks
- [slides](./references/slides.md) — presentations
- [chat](./references/chat.md) — spaces, messages (needs chat scope)
- [keep](./references/keep.md) — notes (needs keep scope)

See `gcloud` skill (~/.cursor/skills/gcloud/) for Google Cloud CLI, service accounts, APIs.
