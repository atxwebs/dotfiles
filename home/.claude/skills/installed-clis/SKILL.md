---
name: installed-clis
description: Read when needing system CLI tools
---

Available CLI tools, use when suitable:

- fd (find replacement)
- rg (ripgrep)
- sd (sed replacement)
- parallel (job parallelization)
- tldr (tealdeer, simplified man pages)
- fzf (fuzzy finder)
- gh (github CLI, see gh skill)
- hf (Hugging Face CLI)
- aws (AWS CLI, see aws skill)
- gcloud (Google Cloud CLI, see gcloud skill)
- gws (Google Workspace CLI, see gws skill)
- yq (YAML processor)
- claude (Claude CLI)

Verify all listed tools: `~/.claude/skills/installed-clis/scripts/which-all.sh` (parses this file, runs `command -v` each).

## Working on JSON, CSV, TSV

- jq (JSON processor)
- mlr (miller, CSV/TSV processor)

This file is in `~/.claude/skills/installed-clis/` - take all paths as relative to it.
