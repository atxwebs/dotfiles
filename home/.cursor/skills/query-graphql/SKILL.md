---
name: query-graphql
description: How to query the GraphQL API
disable-model-invocation: true
---
Read skill `run-server` for how to run the server. Unless the user says it's running, it's on you to manage it.
Use `mcp-graphql-local` tools to query the API running locally.
If available, use `mcp-graphql-dev` can be used to query the API running in development.
All queries/mutations must be named.
If MCP unavailable, use curl as fallback. Extract endpoint and headers with: `cat .cursor/mcp.json | grep -A 2 -E '127\.0\.0\.1:[0-9]+/_/gql'`
Find GraphQL types & queries with `read-symbol` skill instructions.
You can use `execute-sql` skill to find data from the DB to test (most likely IDs)
When given Bash snippets, follow them closely.

This file is in `~/.cursor/skills/query-graphql/` - take all paths as relative to it. Related: [run-server](./run-server) - for running the server.