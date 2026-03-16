---
name: prisma
description: Read when modifying schema.prisma
---

# Prisma Rules


## Tech Stack
- Database: PostgreSQL running on RDS
- Prisma v2

## Naming Conventions
- Tables are named with TitleCase
- Columns are named with camelCase
- Tables are singular, e.g. "User" not "Users"
- **Never use GraphQL built-in type names as tables** (e.g., `Subscription`, `Query`, `Mutation`)

### By type
- Boolean: Start with `is`, `can`, `are` (e.g., `isActive`)
- Date: End with `At` (e.g., `createdAt`)
- Array: Use plural form (e.g., `users`)
- Enums: Use TitleCase (e.g., `OrganizationKind`)

## Standard Model Structure
- Every model has: `id`, `createdAt`, `updatedAt`
- User-owned entities have: `userId` and `user` relation
- Org-owned entities have: `orgId` and `org` relation

## Relations
- Foreign keys end with `Id` (e.g., `userId`, `stateId`)
- Relation fields omit the `Id` suffix (e.g., `user`, `state`)
- Use `@unique` where applicable
- Add `onDelete: Cascade` for dependent entities
- Do NOT use @relation `name` unless we have too, aka +1 relations to the same table

## Status Enums
- Status enums follow pattern: `EntityNameStatus` (e.g., `ProductStatus`, `ReceiptStatus`)
- Common status values: `Draft`, `Pending`, `Active`, `Archived`
- Use `@default()` for initial status

## Indexes
- Add indexes for: foreign keys, status fields, date fields, commonly filtered fields
- Don't create indexes for columns that are already `@unique` or `@id`

## Column order and grouping
Requires a new line after each group
1. id, createdAt, updatedAt, userId/user (if exists), orgId/org (if exists)
2. All non-relational columns
3. One group per relation: xId field first, then x relation field, blank line before next relation
4. All list relations (users[], payments[], etc.)
5. @@unique lines, then @@index lines come last

## Migrations

### Create and edit (dry run)
1. Edit `schema.prisma`
2. `npm run db:migrate:dryrun -- --name <descriptive_name>` — creates migration without applying (e.g. `--name webhook`, `--name add_patient_avatar`). Never create nameless migrations.
3. Edit project's `prisma/migrations/<name>/migration.sql` (backfill, fix quoted column names per sql skill)
4. **Ask user to confirm** before applying (migrations are hard to roll back)
5. `npm run db:migrate` — applies, generates client, enums, etc.

### Amending a migration in-place
This file is in `~/.claude/skills/prisma/`, take the next paths as relative to it
When consolidating changes into an existing migration (not pushed yet), see [amend-migration.md](./references/amend-migration.md).

## Helpers

Helpers in `src/model/prisma.ts` simplify common Prisma operations.

### Pagination

```typescript
// Convert GraphQL PageInput to Prisma args
const page = model.prisma.mapPageInput(input.page, defaultCount)

// Fetch paginated list with total
const result = await model.prisma.fetchWithTotal(
  db.patient, input.page, info, orderBy, where,
)
```

### Ordering

```typescript
// Convert GraphQL OrderInput[] to Prisma orderBy
const orderBy = model.prisma.mapOrderInput<Patient>(input.order, {
  Name: 'name',
  CreatedAt: 'createdAt',
})

// Common orders
model.prisma.orderAsc   // { orderBy: { id: 'asc' } }
model.prisma.orderDesc  // { orderBy: { id: 'desc' } }
```

### Relations

```typescript
// Connect/disconnect by ID
model.prisma.connect(id)         // { connect: { id } } or { disconnect: true } if null
model.prisma.set(ids)            // { set: ids.map(id => ({ id })) }
model.prisma.connectToSet(data)  // Converts connect to set
```

### Filters

```typescript
model.prisma.mapDateTimeFilter(input) // DateTimeFilter → Prisma.DateTimeFilter
model.prisma.mapIntFilter(input)      // IntFilter → Prisma.IntFilter
model.prisma.and(...filters)          // Combine with AND
model.prisma.or(...filters)           // Combine with OR
```

See `src/model/prisma.ts` for all helpers.
