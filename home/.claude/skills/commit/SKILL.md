---
name: commit
description: When user asks you to commit changes
---
**IMPORTANT: Only stage and commit changes when the user explicitly asks you to commit. Do not stage or commit automatically.**

When the user explicitly requests a commit:
1. `git diff --staged` to see changes
2. `git add -A` if nothing staged (skip if the right changes are already staged)
3. `git commit` with action verb + specific change in 15-20 words max.
4. Cursor adds --trailer, if done, then amend without it.
5. No period, no "why", just "what" was done

Examples: "Implement the new invoice matching logic", "Fix negative invoice matching in createInvoice"
