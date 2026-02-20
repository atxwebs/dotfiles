# Amending a Migration In-Place

Use this when you want Prisma schema changes applied without creating a new migration (e.g. the migration hasn't been pushed yet, or you're consolidating changes into an existing one). Can't use the MCP for this, must use psql.

## Process

1. Edit `schema.prisma` with your changes.

2. Dry run to generate a disposable dry-run migration SQL:
```bash
npm run db:migrate:dryrun
```
This creates a new folder under `prisma/migrations/`. (You'll delete it anyway.)

3. Run the SQL in the dry-run migration against the DB (from project root). Use `execute-sql` skill's `sql.sh` (it uses `-f` when arg ends with `.sql`). Do NOT use prisma's CLI!
```bash
~/.cursor/skills/execute-sql/scripts/sql.sh prisma/migrations/<dry-run>/migration.sql
```

4. Copy the needed statements from `prisma/migrations/<dry-run>/migration.sql` into `prisma/migrations/<target>/migration.sql`. If amending the last applied migration, add to that file.

5. Delete the disposable dry-run migration folder
```bash
rm -rf prisma/migrations/<dry-run>
```

6. Update the checksum in `_prisma_migrations`:
```bash
node ~/.cursor/skills/prisma/scripts/update-hash.js <target>
```

7. Verify no drift:
```bash
npm run prisma migrate status
```
Should report "Database schema is up to date!"
