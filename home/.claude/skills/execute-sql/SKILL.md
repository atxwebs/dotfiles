---
name: execute-sql
description: To read the DB, use mcp-postgres MCP tools
---
To read the DB, use `mcp-postgres` MCP tools (possibly off)

**Plan B - If MCP tools unavailable or timeout:**
- Use `~/.claude/skills/execute-sql/scripts/sql.sh "SELECT ..."` from this skill dir. Runs from project dir (or any subdir); finds .{claude,cursor}/mcp.json upward. Prefer this over what's below
- If arg ends with `.sql`, uses `psql -f` (e.g. for migration files).
- Or manually: `DATABASE_URI=$(grep -oP '"DATABASE_URI"\s*:\s*"\K[^"]*' .cursor/mcp.json | head -n1)` then `psql "$DATABASE_URI" -c "SELECT ..."`
- With the script or psql you can pipe to grep, tail, jq for further processing, better than the MCP in that regard.
- Most DATABASE_URI from mcp.json include the search_path in the options parameter. Keep it implicit.
