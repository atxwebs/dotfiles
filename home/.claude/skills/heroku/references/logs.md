# Heroku Logs

**NEVER** `--tail` (hangs). **`--app`** usually not needed (git remote).

## Fetch

```bash
heroku logs --num 200 --source app --process-type web
```

`--source app --process-type web` → only `app[web.1]` (~74% of noise dropped vs unfiltered).

Sources skipped: `heroku[router]` (health checks), `app[api]` (log session open).

## Grep patterns

```bash
heroku logs --num 200 --source app --process-type web | grep -iE '409|Conflict|Polling|Failed to getMe'
heroku logs --num 100 --source app --process-type web | grep -i -E '(ignore|Newer message exists|discarding)'
heroku logs --num 100 --source app --process-type web | grep -i error
heroku logs --num 1000 --source app --process-type web | grep /message
```

Time window: pipe to `grep '2025-11-05.*19:4[01]'`.

Project-specific patterns (message IDs, `bin/check-logs.js`): see repo `.cursor/commands/heroku_logs.md` if present.
