---
name: graphql
description: Read when modifying *.graphql files
---
**Scalars:** `NonEmptyString`, `Email`, `Phone`, `PositiveX`, `NonNegativeX`. Not plain String for emails/phones.

**Codegen:** Run `npm run gql:codegen` after edits. Needs local API. If server down, ask user.

**Rules:** No nullable when shouldn't be. Arrays: no nullable element types. Inputs wrapped in `input` type. Entity: `Node`, `id`, `createdAt`, `updatedAt`. Mutations: verb+noun. Queries: noun/plural.

**Endpoint:** `/_/gql`. Examples: `docs/playground.graphql`.
