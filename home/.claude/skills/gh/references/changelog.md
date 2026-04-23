# Release Changelog

Get combined changelog text between a version tag and HEAD from any GitHub repo. Strips boilerplate (download links, platform lists).

```bash
# Get all release notes since a tag (raw markdown, newest first)
~/.claude/skills/gh/scripts/changelog.sh OWNER/REPO <since-tag>

# Example: check what changed in llama.cpp since our version
~/.claude/skills/gh/scripts/changelog.sh ggml-org/llama.cpp b8778
```

Output: markdown with `## tag (date)` headers and release notes body, separated by `---`. Pipe to a file for review: `> /tmp/changelog.md`.
