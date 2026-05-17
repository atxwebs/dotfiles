# Page Interaction

How to interact with page elements using pinchtab CLI. For crawling/fetching content, use [crawl.sh](../scripts/crawl.sh) instead.

## Core Workflow

1. Create a session: `export PINCHTAB_SESSION=$(pinchtab session create --agent-id myagent)`
2. Navigate: `pinchtab nav <url> --snap`
3. Use refs to click, fill, select
4. Re-snapshot after navigation or DOM changes

```bash
export PINCHTAB_SESSION=$(pinchtab session create --agent-id crawler)
pinchtab nav https://example.com/form --snap
# e1:textbox "Email"
# e2:textbox "Password"
# e3:button "Submit"

pinchtab fill e1 "user@example.com" && pinchtab fill e2 "pass123" && pinchtab click e3 --snap
```

## Command Chaining

Chain with `&&` when you don't need intermediate output. Run separately when you must read refs first.

## Interaction Commands

```bash
pinchtab snap -i                  # Interactive elements (get refs)
pinchtab snap -s "#sel"           # Scoped snapshot
pinchtab click e1                 # Click
pinchtab fill e1 "text"           # Set value directly
pinchtab type e1 "text"           # Keystroke events
pinchtab select e1 "option"       # Dropdown
pinchtab check e1                 # Toggle checkbox
pinchtab hover e1                 # Hover
pinchtab text                     # All page text
pinchtab text e1                  # Text from one element
pinchtab eval "js"                # Run JS (requires allowEvaluate)
pinchtab press Enter              # Key press
pinchtab scroll down              # Scroll page
pinchtab wait e1                  # Wait for element visible
pinchtab wait 3000                # Wait ms
pinchtab wait --load network-idle # Wait for page load
```

Use `--snap-diff` on `click`, `fill`, `select`, `back`, `forward`, `reload` to get only changed elements (token-efficient). Use `--snap` for full snapshot (first nav, major page change).

## Ref Lifecycle

Refs (`e0`, `e1`, etc.) are temporary — invalidated on navigation or DOM changes. **Always re-snapshot after clicking anything that changes the page.**

## Snap vs Snap-Diff

```bash
pinchtab snap                    # Full snapshot
pinchtab snap -i                 # Interactive elements only
pinchtab snap -d                 # Diff from last snapshot
pinchtab click e5 --snap-diff    # Action + only changed elements
```

Output format with `--snap-diff`:
```
# Page Title | URL | 57 nodes | +2 ~1 -0
e0:link "Home"
e5:button "Submit" [+]
e12:textbox val="updated" [~]
# removed: e99
```
`[+]` = added, `[~]` = changed, removed refs listed at end.

## Selectors

- Ref: `e5` — from snapshot (fastest)
- CSS: `#login`, `.btn` — `document.querySelector`
- Text: `text:Sign In` — visible text match
- Semantic: `find:login button` — natural language

Auto-detection: bare `eN` → ref, `#`/`.`/`[...]` → CSS, `//` → XPath.
