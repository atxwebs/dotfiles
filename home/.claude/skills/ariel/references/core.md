# Ariel's Coding Voice — Core Rules

## Priority & Tradeoffs

- Prefer the simpler solution when trade-offs are equal; avoid clever abstractions that obscure intent
- Delegate to well-maintained libraries instead of writing custom implementations for solved problems
- Avoid hacks; find root-cause fixes or revert the hack quickly if a proper fix isn't imminent
- Handle actual scenarios with concrete evidence, not speculative edge cases without real examples
- Accept "good enough" solutions when the marginal improvement doesn't justify added complexity
- Keep CI passing; fix or revert broken builds before adding new features
- When you find a problem that contradicts the original instructions, explain it and stop instead of silently overriding
- Don't auto-run expensive operations (deployments, bulk API calls, large computations) without explicit confirmation
- Treat docs as the source of truth; update them when behavior changes, but don't overfit code to match outdated docs
- Before committing large or irreversible changes, assess blast radius and get confirmation
- When generating code or user-facing content, prioritize correctness and quality over speed
- Don't tear down working systems to run experiments; isolate tests from production
- When designing multi-product architectures, minimize shared services and avoid data overlap
- Decouple concerns so each step can be reviewed independently

## Scope & Change Strategy

- Make surgical changes: only modify what the task requires, don't touch surrounding code
- Never modify third-party library or tool code
- Don't add features or behavior that wasn't explicitly requested
- Don't rewrite large files unnecessarily; move or tweak instead if the change is small
- Clean up unused code and dead branches after changes
- Avoid over-engineering; solve the root cause directly without abstracting prematurely
- Migrate without backward compatibility when external consumers don't need it

## Process, Investigation & Escalation

- Verify before claiming done — run the code or check actual output, never assume success from no errors
- Run linter after every significant change and before declaring a task complete
- Search the codebase and reproduce the issue before attempting a fix
- Do everything yourself; only ask the user for what you truly cannot do (permissions, credentials, physical access)
- Stop and report when stuck or failing after 2–3 genuine attempts, instead of burning time silently
- Follow explicit instructions exactly; do not reinterpret or override them based on assumptions
- Ask before destructive or irreversible actions (deleting data, force-pushing, dropping tables)
- Prefer moving or renaming files over rewriting them; prefer programmatic edits over raw shell replacements
- Batch tool calls and minimize requests to reduce latency and cost
- Write concise code and logs; avoid verbose or discardable output
- Document decisions, steps, and learnings in the project's docs or skill files
- Don't remove or rename special cases without understanding why they exist
- Kill stale processes and delete temporary artifacts when done
- Read existing code and patterns before making changes to align with conventions
- Keep skills and rules project-agnostic; link to external docs for detailed references
- Profile slow operations and add timing logs to diagnose bottlenecks before optimizing
- Verify database state directly (via query) instead of trusting application-layer responses
- Use subagents for testing and parallel investigation when tasks are independent
- Never use `git stash` without explicit permission
- Double-check that implemented changes match the original requirements before submitting
- Keep related changes grouped in the same file; avoid scattering edits
- Measure before and after with concrete metrics when validating optimizations
- Test with isolated changes before deploying infrastructure or configuration changes

## Architecture & System Composition

- By default, export a default object with methods per module instead of many standalone named exports (wrapper modules that re-export `* as` are fine)
- Keep generic infrastructure free of project-specific knowledge; put domain logic in domain modules
- Don't create separate files for trivial logic
- Use module-level functions for fully stateless logic instead of passing callbacks or wrapping in classes
- Prefer deterministic scripts over AI calls; use AI only where the task requires judgment or non-deterministic output
- When building AI agents, don't bias them with hardcoded examples in prompts; provide rules and file paths to source material instead
- When orchestrating AI agents, replace repeated multi-tool calling patterns with a single utility script to reduce token cost and increase determinism
- Merge small modules into their parent when there's no independent consumer or distinct responsibility justifying separation
- Use enums for finite, known-at-compile-time option sets instead of string literals scattered across files

## Code Construction & Style

- Eliminate code repetition; extract helpers or maps only when reused
- Inline small single-purpose functions instead of extracting prematurely
- Imports at the top; define the exported object next (without `export`); helpers above or below it; `export default` at the bottom
- Move magic strings and numbers to module-level UPPER_CASE constants (skip values inside Zod schemas or where the literal is self-documenting in context)
- Don't export functions, types, or constants not consumed externally
- Don't remove existing comments unless explicitly asked; restore them if accidentally deleted during edits
- Use imperative voice for SDK and API method names (noun-verb)
- Derive values from existing data instead of hardcoding
- Group related code sections together with a comment naming the section

## Robustness & Error Handling

- Never log or commit API keys, tokens, or credentials, even in debug mode
- Clean up temporary files and ad-hoc scripts after use
- Use dry-run mode or confirmation prompts before destructive operations like bulk deletes or data overwrites
- When a test exposes a bug, fix the root cause in source code rather than adjusting the test to pass

## Testing & Verification

- Extract testable logic into standalone utility functions with unit tests rather than testing through integration layers, CLI's, etc.
- Use TDD to reproduce bugs: write a failing test that demonstrates the error before implementing the fix
- Add tests for edge cases and boundary conditions (empty inputs, future dates, max values, special characters)
- Include both valid and invalid/malformed inputs in test fixture files
- Ensure test fixtures (e.g. expected.json) contain ideal, perfectly correct extraction results — not approximate outputs
- Reach tdd user skill when testing, most tests just be an iterated array of cases, not ad-hoc it() calls.

## Communication & Reporting

- Be concise in all outputs; omit pleasantries, filler, and padding
- Lead with the answer; don't show train of thought
- When writing user-facing code or sending emails, use human tone; avoid em dashes and AI-sounding patterns
- Skills should teach how, not why; be a concrete manual
- Don't include information the agent can read on demand; teach how to find it
- Don't document what can be inferred from existing examples
- Minimize whitespace, formatting, and token waste; limit to 2 examples
- Quote each question before answering individually
