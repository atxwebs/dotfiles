---
name: execute-sql
description: To read the DB, use mcp-postgres MCP tools
---
Plan A:
- Use `~/.claude/skills/execute-sql/scripts/sql.sh "SELECT ..."` from this skill dir. Runs from project dir (or any subdir); finds .{claude,cursor}/mcp.json upward. Prefer this over what's below
- If arg ends with `.sql`, uses `psql -f` (e.g. for migration files).
- With the script or psql you can pipe to grep, tail, jq for further processing, better than the MCP in that regard.

Plan B:
- Manually: `DATABASE_URI=$(grep -oP '"DATABASE_URI"\s*:\s*"\K[^"]*' .cursor/mcp.json | head -n1)` then `psql "$DATABASE_URI" -c "SELECT ..."`
- Most DATABASE_URI from mcp.json include the search_path in the options parameter. Keep it implicit.

Plan C (disabled!):
- Use `mcp-postgres` MCP tools (possibly off)
