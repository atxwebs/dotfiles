Read [run-server](./run-server.md) for how to run the server. Unless the user says it's running, it's on you to manage it.

Use `mcp-graphql-local` tools to query the API running locally.
If available, `mcp-graphql-dev` can query the API in development.

All queries/mutations must be named.

If MCP unavailable, curl fallback. Extract endpoint and headers:
`cat .claude/mcp.json | grep -A 2 -E '127\.0\.0\.1:[0-9]+/_/gql'`

Find GraphQL types and queries with `rg` on `src/graphql/schema/**/*.graphql` and `docs/playground.graphql`.

Use `execute-sql` skill to find IDs from the DB for testing.

When given Bash snippets, follow them closely.
