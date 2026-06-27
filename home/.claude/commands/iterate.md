Your job is to iteratively improve the files or whole project the user specified, following any extra instructions they give.

**Default: spawn a readonly review subagent** to audit the code and docs in scope. Do the review yourself only when the user explicitly asks (e.g. "don't spawn", "you review", "no subagent").

## Loop (one round unless the user asks to repeat)

### 0. Use what the project already has

Before step 1, run the project's normal quality gates if they exist:

- tests (`pytest`, `npm test`, …)
- lint / typecheck (`ruff`, `eslint`, `mypy`, …)
- build / CI scripts the repo already uses

If anything comes up, fix it first. Don't waste the subagent's time. Only if all is good, continue with step 1.

### 1. Spawn reviewer (default)

Launch a **readonly** subagent. Prompt it with:

- Absolute repo path and scope (files, branch, or "recent changes").
- User's extra focus, if any.
- **Max ~15 findings**: broken, outdated, inconsistent, inefficient, or unsafe — no style nitpicks.
- Per finding: **severity** (`fix now` / `minor` / `skip`) and **predictable?** — could existing tests, lint, types, or CI have caught this? (`yes` / `no` / `partial` + what's missing).
- **Ignore list** on round 2+: paste only the findings you rejected last time (not fixed ones — they're already gone).

Tell the subagent: do not spawn or suggest spawning more agents; report only.

**Main agent does the review** only when the user opts out of subagents.

### 2. Triage (main agent)

For each finding:

| Predictable? | Action |
|--------------|--------|
| **yes** — lint/tests/CI could catch it | Add or tighten the check **first** (rule, test, CI step), then fix the code. |
| **no** — logic, UX, docs drift, env | Fix directly. |
| **partial** | Fix now; optionally note a gap in test/lint coverage for later. |

Discard refactors that don't pay off. Keep good advice even when minor. Don't blindly follow suggestions, you are in charge, they just give you ideas.

### 2.5. Verify before fixing

Before applying any fix, verify the issue is real:

- **Code changes**: Write a failing test that demonstrates the bug, then fix it (TDD).
- **Code snippets without side effects**: Run them once to confirm they work as intended.
- **Documentation/commands**: Test the actual behavior (e.g., run the command, check the output).

Don't trust the subagent's analysis blindly. Verify first, fix second.

### 3. Apply fixes

- Batch edits in one turn when possible.
- Code + docs + tests together when the change is user-facing.
- Run the project test command before calling the round done.

### 4. Stop or repeat

**Stop** when what's left is nitpicks or already-documented tradeoffs.

**Repeat** only if the user asked for another `/iterate` or too keep going while meaningful & actionable items remain.

## Do not re-report (unless regressions)

The main agent should skip these when processing subagent results:

- Findings already fixed in the previous round (no need to re-report — they're gone).
- Findings explicitly rejected in the previous round (pass these to the subagent in the ignore list).
- Pure formatting / naming preferences with no bug or doc-truth impact.
- Large refactors the user or main agent already declined.
- "Add more agents" or "run another full audit" as the only suggestion.

## Subagent prompt template

```
Review [REPO_PATH] — scope: [FILES / branch / recent changes]. Read-only.

Find up to 15 issues: broken, outdated, inconsistent, inefficient, unsafe.
Per item: severity (fix now | minor | skip), predictable? (yes | no | partial + what tool), file/path.

Ignore these or similar to these: [rejected last round]

Do not spawn or recommend spawning more agents.
```

## Execution rules

- Work from repo root
- Commit only when the user asks
- Main agent implements fixes; subagent only reviews.

**TLDR:** Run existing tests/lint → spawn readonly reviewer (unless user says not to) → triage "could CI have caught this?" → fix → test → stop.
