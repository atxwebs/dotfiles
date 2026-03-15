#!/bin/bash
# Run SQL via psql. Finds DATABASE_URI from .cursor/mcp.json (searches upward from CWD).
# Usage: sql.sh "SELECT * FROM schedules LIMIT 3"
#        sql.sh prisma/migrations/20260218162100/migration.sql
set -e
dir="$(pwd)"
while [ "$dir" != "/" ]; do
  if [ -f "$dir/.cursor/mcp.json" ]; then
    break
  fi
  dir="$(dirname "$dir")"
done
if [ ! -f "$dir/.cursor/mcp.json" ]; then
  echo "Error: .cursor/mcp.json not found" >&2
  exit 1
fi
DATABASE_URI=$(grep -oP '"DATABASE_URI"\s*:\s*"\K[^"]*' "$dir/.cursor/mcp.json" | head -n1)
if [ -z "$DATABASE_URI" ]; then
  echo "Error: DATABASE_URI not found in mcp.json" >&2
  exit 1
fi
if [[ "$1" == *.sql ]]; then
  exec psql "$DATABASE_URI" -f "$1"
else
  exec psql "$DATABASE_URI" -c "$1"
fi
