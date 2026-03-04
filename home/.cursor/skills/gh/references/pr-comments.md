# PR Comments Review Flow

## Quick Reference

**Get Cursor bot comments only (recommended - auto-detects repo from git remote):**
```bash
~/.cursor/skills/gh/scripts/pr-comments.sh PR_NUMBER --cursor-only
```

**Get all PR comments (requires OWNER/REPO - replace placeholders):**
```bash
# Get OWNER/REPO from git remote first:
OWNER_REPO=$(git remote get-url origin | sed -E 's/.*github.com[:/]([^/]+)\/([^/]+)\.git/\1\/\2/')

# Then use in API call:
gh api repos/$OWNER_REPO/pulls/PR_NUMBER/comments --jq -c '.[]'
```

## Output Format

The script outputs each comment as a **single line** (compact JSON) with essential fields only, making it easy to filter:
- `| tail -n1` - Get the last comment
- `| head -n1` - Get the first comment
- `| grep "pattern"` - Filter by content
- `| grep '"id":COMMENT_ID'` - Find a specific comment by ID
- `| jq .` - Pretty-print a specific comment

Each line contains only essential fields: `id`, `path`, `line`, `body`, `created_at`, and `user` (for non-filtered output). This keeps output compact and token-efficient while remaining readable.

## Optimal Flow

1. **Use the helper script** - Auto-detects repo from git remote, filters efficiently:
   ```bash
   ~/.cursor/skills/gh/scripts/pr-comments.sh PR_NUMBER --cursor-only
   ```

2. **Get the last comment** - Useful for checking the most recent feedback:
   ```bash
   ~/.cursor/skills/gh/scripts/pr-comments.sh PR_NUMBER --cursor-only | tail -n1 | jq .
   ```

3. **Find a specific comment by ID** - Useful when referencing a comment from GitHub UI:
   ```bash
   ~/.cursor/skills/gh/scripts/pr-comments.sh PR_NUMBER --cursor-only | grep '"id":2784202718' | jq .
   ```

4. **Assess each comment** - Parse the JSON to review body, path, line, and other fields

## Required Scopes

- **Current**: `repo` (works for REST API `/pulls/{pull_number}/comments`)
- **For GraphQL**: May need `read:org` and `read:discussion` if querying user/org info
- **To refresh scopes**: `gh auth refresh --scopes repo,read:org,read:discussion`

## Script Location

[pr-comments.sh](./scripts/pr-comments.sh)
