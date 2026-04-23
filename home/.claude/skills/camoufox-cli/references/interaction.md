# Page Interaction

How to interact with page elements (click, fill forms, etc.) using camoufox-cli. For crawling/fetching content, use [crawl.sh](../scripts/crawl.sh) instead.

## Core Workflow

1. `camoufox-cli open <url>`
2. `camoufox-cli snapshot -i` (get element refs like `@e1`, `@e2`)
3. Use refs to click, fill, select
4. Re-snapshot after navigation or DOM changes
5. `camoufox-cli close` when done

```bash
camoufox-cli open https://example.com/form
camoufox-cli snapshot -i
# - textbox "Email" [ref=e1]
# - textbox "Password" [ref=e2]
# - button "Submit" [ref=e3]

camoufox-cli fill @e1 "user@example.com" && camoufox-cli fill @e2 "pass123" && camoufox-cli click @e3
camoufox-cli snapshot -i  # Check result
```

## Command Chaining

Chain commands with `&&` when you don't need intermediate output. Run separately when you need to parse snapshot refs first.

```bash
# Chain open + screenshot
camoufox-cli open https://example.com && camoufox-cli screenshot page.png

# Multiple interactions
camoufox-cli fill @e1 "text" && camoufox-cli click @e2
```

## Interaction Commands

```bash
camoufox-cli snapshot -i          # Interactive elements (get refs)
camoufox-cli snapshot -s "#sel"   # Scoped snapshot
camoufox-cli click @e1            # Click
camoufox-cli fill @e1 "text"      # Clear + type
camoufox-cli type @e1 "text"      # Append without clearing
camoufox-cli select @e1 "option"  # Dropdown
camoufox-cli check @e1            # Toggle checkbox
camoufox-cli hover @e1            # Hover
camoufox-cli text @e1             # Get text
camoufox-cli text body            # All page text
camoufox-cli eval "js"            # Run JS
camoufox-cli press Enter          # Key press
camoufox-cli wait @e1             # Wait for element
camoufox-cli wait 3000            # Wait ms
camoufox-cli wait --url "*/path"  # Wait for URL pattern
camoufox-cli close                # Close session
```

## Ref Lifecycle

Refs (`@e1`, `@e2`, etc.) are temporary — invalidated on navigation or DOM changes. **Always re-snapshot after clicking anything that changes the page.**

```bash
# CORRECT: re-snapshot after navigation
camoufox-cli click @e5
camoufox-cli snapshot -i
camoufox-cli click @e1  # Use new refs

# WRONG: using stale refs
camoufox-cli click @e5
camoufox-cli click @e3  # Stale ref!
```

### What Invalidates Refs

- Navigation (clicking links, form submissions, redirects)
- Dynamic content (dropdowns, modals, AJAX updates)
- Scrolling that triggers lazy loading
- Any DOM mutation that changes element order

## Session Management

Use named sessions for concurrent crawls. Always close when done to avoid leaked processes.

```bash
camoufox-cli --session agent1 open https://site-a.com
camoufox-cli --session agent1 close
camoufox-cli close --all  # Kill all sessions
```

If a previous session wasn't closed, run `camoufox-cli close` before starting.

## Global Flags

```
--session <name>       Named session
--headed               Show browser window
--timeout <seconds>    Daemon idle timeout (default: 1800)
--persistent [path]    Persistent profile
--proxy <url>          Proxy server
```
