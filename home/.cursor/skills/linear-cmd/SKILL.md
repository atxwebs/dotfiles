---
name: linear-cmd
description: Linear MCP Commands
disable-model-invocation: true
---
# Linear MCP Commands

Use MCP Linear tools to interact with Linear issues and projects.

## List Issues
- `mcp_linear_list_issues` - List issues with filters (assignee, team, state, project, etc.)
- Use `assignee: "me"` to get your issues

## Get Issue
- `mcp_linear_get_issue` - Get detailed issue info by ID

## Create Issue
- `mcp_linear_create_issue` - Create new issue
- **Required**: `title`, `team`
- **Always set**: `assignee: "me"`, `project` (UUID from list_projects)
- Optional: `description`, `state`, `priority`, `labels`, `dueDate`, etc.

## Update Issue
- `mcp_linear_update_issue` - Update existing issue by ID
- **Always set**: `assignee: "me"` when updating
- WARNING: `blocks`, `blockedBy`, `relatedTo` REPLACE all existing relations - include ALL you want

## Projects
- `mcp_linear_list_projects` - List projects
- `mcp_linear_get_project` - Get project by name/ID
- `mcp_linear_create_project` - Create project (requires `name`, `team`)

## Comments
- `mcp_linear_list_comments` - List comments for an issue
- `mcp_linear_create_comment` - Add comment to issue
