# PR Comments

```bash
~/.claude/skills/gh/scripts/pr-comments.sh PR_NUMBER --cursor-only
~/.claude/skills/gh/scripts/pr-comments.sh PR_NUMBER --cursor-only | tail -n1 | jq .
```
Script auto-detects repo from git remote. Output: one JSON line per comment. `| grep pattern`, `| jq .` for pretty.
