Add a project to curated lists (awesome-\*, ecosystem pages, "tools using X" sections) by opening a PR on the list repo. The goal is genuine visibility through relevance — not volume.

## When to do this

- You built a tool and want it discoverable by the right audience
- Someone asks "where should I list my project?"
- You're preparing a launch or growing a project's reach
- `/publicize check` — check if any publicize PRs have updates or comments

## Core principles

1. **Fit first.** The project must genuinely belong in the section. If you have to squint, skip it.
2. **Existing sections only.** Never add a new category, heading, or section just to fit your project in. Only add entries to sections that already exist and already list similar projects.
3. **Read before writing.** Scan the list's structure, tone, and existing entries. Match the format exactly.
4. **One line.** Your diff should be a single entry added to an existing table or list. No restructuring, no reformatting, no "improvements" to surrounding content.
5. **No competitor promotion.** Don't list competing or alternative projects in your PR. Only your project.
6. **No AI signatures.** Never include "Generated with Claude/Copilot/Cursor" or similar attributions in PR bodies.
7. **No self-deprecation or hype.** The PR description should be factual and confident. No "just a small project" hedging, no "revolutionary" claims.
8. **Check for duplicates.** Before opening a PR, verify you haven't already opened one (search by author + state).
9. **Budget, don't cherry-pick.** When multiple targets are good fits, submit to all of them. Keep a daily budget of ~5 PRs to avoid looking like spam. Spread across days if you have more candidates.

## Target selection

**Good targets:**
- Repos with 200+ stars (meaningful audience)
- Lists with a section that clearly matches your project's category
- Entries in the section that are similar in scope/maturity to your project
- Ecosystem hubs (e.g., the protocol's own repo listing tools that use it)

**Skip:**
- Lists where your project would be the smallest/least-starred entry by far
- Lists focused on a different domain (research papers when you're a CLI tool)
- Lists that are "reorganizing" or have broken structure
- Lists where you'd need to create a new section to fit
- Repos where you'd be promoting a competitor alongside your own project

## PR content rules

### The diff

- Add exactly one entry to an existing list/table
- Match the surrounding format (column order, link style, description length)
- Place the entry where it belongs — check the ordering convention first:
  - **Alphabetical** → insert at the correct letter position
  - **Categorized/grouped** → place next to the most related entry
  - **No visible order** → place after the entry most similar in scope or function, not blindly at the end
- Description should be one sentence: what it does + who it's for. No adjectives like "amazing", "powerful", "next-generation"

### PR title

- Factual: what you're adding and where
- Format: `Add <project> to <section name>`
- No hype words, no version numbers

### PR body

- One paragraph: what the project is, what it does, link to repo, install command
- No emojis unless the list's existing entries use them
- Keep it under 5 lines

## Search strategy

Derive search terms from the project's domain. Run multiple queries in parallel to cast a wide net:

- **Tool-specific:** `"awesome <tool>"` (e.g., `"awesome claude code"`, `"awesome cursor"`)
- **Category:** `"awesome <category>"` (e.g., `"awesome ai coding"`, `"awesome developer tools"`)
- **Ecosystem:** `"awesome <protocol>"` (e.g., `"awesome mcp"`, `"awesome scip"`)
- **Function:** `"awesome <function>"` (e.g., `"awesome code intelligence"`, `"awesome cli"`)

Filter results by stars (200+), then inspect each README for a relevant section before forking.

## Workflow

1. **Search** for candidate lists (see Search strategy above)
2. **Evaluate** each: star count, section fit, existing entries
3. **Check for existing PRs** from your account to the same repo — if found, skip this target (don't spam)
4. **Check CONTRIBUTING.md** if it exists — some repos have specific submission guidelines; if they say "open an issue instead", do that instead of a PR
5. **Verify not already listed** — search the README for your project name to avoid duplicates:

```bash
gh api repos/<owner>/<repo>/readme --jq '.content' | base64 --decode | grep -i "<project-name>"
```

If the API returns 404 (no README), skip this target.

6. **Read** the target section to understand format and tone
7. **Fork + clone** the repo (use `gh repo fork <owner>/<repo> --clone` or manual fork+clone)
8. **Add upstream remote** — `git remote add upstream https://github.com/<owner>/<repo>.git` (skip if `gh repo fork --clone` already created it)
9. **Sync fork** — `git fetch upstream && git merge upstream/<default-branch>` (use `main` or `master` depending on the repo)
10. **Create feature branch** — `git checkout -b add-<project>-to-<section>` (one branch per target, never edit main directly)
11. **Edit** — one line added to the right section
12. **Verify** the diff is minimal and matches surrounding entries
13. **Commit + push** — `git push origin <branch-name>` with a clean commit message
14. **Open PR** with a factual title and minimal body
15. **Track** the PR — create `tmp/` if needed, then log to `tmp/publicize-prs.md` (see Tracking section)
16. **Move on** — don't spam follow-up comments or close/reopen

## Tracking PRs

After opening a publicize PR, log it in `tmp/publicize-prs.md` in the source repo. This file must be gitignored.

**File location:** `<source-repo>/tmp/publicize-prs.md`

**Format:**

```markdown
# Publicize PRs

## Open

| Date | Target | PR | Status |
|------|--------|-----|--------|
| 2026-01-27 | awesome-claude-code-toolkit | [#588](https://github.com/rohitg00/awesome-claude-code-toolkit/pull/588) | Open |

## Merged

| Date | Target | PR | Merged |
|------|--------|-----|--------|
| 2026-01-20 | awesome-cursor-rules | [#42](https://github.com/awesome-cursor-rules/pull/42) | 2026-01-22 |

## Closed

| Date | Target | PR | Reason |
|------|--------|-----|--------|
| 2026-01-15 | awesome-devtools | [#123](https://github.com/awesome-devtools/pull/123) | Not a fit |
```

**When to update:**
- After opening a new PR → add to Open
- After PR merges → move to Merged with date
- After PR closes without merge → move to Closed with reason
- After receiving comments → check and respond (see Monitoring section)

**Gitignore:** The tracking file is local-only and must not be committed. Before creating it, verify `tmp/` is in the repo's `.gitignore`. If not, add it to `.git/info/exclude` instead.

## Monitoring PRs

Check for updates, comments, or review requests on open publicize PRs.

**Command:** `/publicize check`

**What to check:**
1. Read `tmp/publicize-prs.md` to get list of open PRs
2. For each open PR, check:
   - PR state (still open? merged? closed?)
   - New comments or review requests
   - CI status (if applicable)
3. Report findings to user
4. If comments request changes, summarize and ask user how to respond

**Snippet to check PR status and comments:**

```bash
# Get PR state, comments, and review requests
gh pr view <number> --repo <owner>/<repo> --json state,title,comments,reviews,reviewRequests
```

**Response guidelines:**
- If maintainer requests changes → summarize what they want, ask user for approval before making changes
- If maintainer asks questions → answer factually, no hype
- If PR is merged → move to Merged section in tracking file
- If PR is closed → move to Closed section with reason
- Don't respond to automated CI comments unless they indicate a real problem

## Snippets

### Search for candidate lists

```bash
gh search repos "awesome <category>" --limit 20 --json fullName,description,stargazersCount,isArchived,isFork --sort stars | jq '.[] | select(.isArchived == false and .isFork == false and .stargazersCount >= 200)'
```

### Check if a section exists

```bash
gh api repos/<owner>/<repo>/readme --jq '.content' | base64 --decode | grep -n -E -i "^#{2,}\s.*<keyword>"
```

### Check for existing PRs from your account

```bash
gh pr list --repo <owner>/<repo> --author @me --state all
```

### Verify your diff is clean

```bash
git diff upstream/<default-branch>
```

Replace `<default-branch>` with `main` or `master` depending on the repo.

## Red flags — stop and reconsider

If any of these apply, skip the target:

- The list's README is broken or says "under construction"
- CONTRIBUTING.md forbids self-promotion or has requirements you can't meet
- Your project is already listed (don't add a duplicate)
