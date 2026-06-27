Stage and commit changes.

**Default behavior:** Only stage files you modified during this conversation. Leave any other unstaged changes alone — the user may have uncommitted work they don't want included. If the user says "commit all" or similar, stage everything with `git add -A`.

Steps:
1. `git status` and `git diff` to identify changes you made vs pre-existing ones.
2. `git add` only the files you changed (skip if already staged correctly).
3. `git commit` with an action verb + specific change in 15-20 words max. No period, no "why", just "what".

Examples: "Implement the new invoice matching logic", "Fix negative invoice matching in createInvoice"
