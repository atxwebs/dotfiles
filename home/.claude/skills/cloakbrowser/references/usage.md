# CloakBrowser Usage Reference

Detailed patterns, gotchas, and snippets for using agent-browser with the CloakBrowser binary ad-hoc.

## Setup

```bash
# Install
~/.claude/skills/cloakbrowser/scripts/setup.sh

# Binary location
CLOAK_BIN=~/.cloakbrowser/chromium-*/chrome
```

## Basic Usage

```bash
# Simple open + eval
agent-browser --executable-path "$CLOAK_BIN" open https://example.com
agent-browser eval "document.title"
agent-browser close
```

## --args Comma Splitting Gotcha

**CRITICAL**: `agent-browser --args` splits on commas. This means values containing commas get split into separate args.

```bash
# WRONG -- gets split into 3 args, last two become URLs
--args "--blink-settings=imagesEnabled=false,cssImagesEnabled=false"

# CORRECT -- each flag is its own --args entry (no commas inside values)
--args "--disable-blink-features=AutomationControlled" --args "--no-first-run"

# CORRECT -- comma-join flags that DON'T contain internal commas
--args "--disable-blink-features=AutomationControlled,--no-first-run,--no-default-browser-check"

# CORRECT -- put --blink-settings in the same comma-joined list
--args "--disable-blink-features=AutomationControlled,--blink-settings=imagesEnabled=false"
```

**Note**: `cssImagesEnabled=false` is redundant with `imagesEnabled=false` (which blocks all images including CSS backgrounds). Use only `imagesEnabled=false`.

## Stealth Args (Recommended)

```bash
ARGS="--disable-blink-features=AutomationControlled,--no-first-run,--no-default-browser-check,--disable-infobars,--blink-settings=imagesEnabled=false"

agent-browser --executable-path "$CLOAK_BIN" --args "$ARGS" open https://example.com
```

## Daemon Persistence

The daemon **persists across CLI calls**. First command spawns it, all subsequent calls reuse it automatically.

```bash
# First call: spawns daemon (~600MB, ~2-3s)
agent-browser open https://example.com

# Subsequent calls: near-instant (reuses daemon)
agent-browser eval "document.title"
agent-browser snapshot -i
agent-browser click "#btn"

# Close daemon
agent-browser close

# Close all sessions (if multiple tabs)
agent-browser close --all
```

**Important**: `--args` is only applied on daemon startup. If daemon is already running, `--args` is ignored:
```
⚠ --args ignored: daemon already running. Use 'agent-browser close' first to restart with new options.
```

## Idle Timeout

```bash
# Set via env var (default 300000ms = 5min)
AGENT_BROWSER_IDLE_TIMEOUT_MS=300000 agent-browser open https://example.com

# Daemon auto-shutdowns after this many ms of inactivity
# RAM goes from ~600MB → 0MB automatically
```

## Batching

### batch --json (recommended for multi-step)

Pass JSON array of commands via stdin:

```bash
# Basic batch
echo '[["open","https://example.com"],["eval","document.title"],["click","#btn"]]' \
  | agent-browser --executable-path "$CLOAK_BIN" --args "$ARGS" batch --json
```

**Python helper pattern** (used in crawl.py and ddg-search.py):

```python
def _cmd():
    return [
        "agent-browser",
        "--executable-path", CLOAK_BIN,
        "--args", "--disable-blink-features=AutomationControlled,--no-first-run,--no-default-browser-check,--disable-infobars,--blink-settings=imagesEnabled=false",
    ]

def ab(*args, **kwargs):
    env = {**os.environ, "AGENT_BROWSER_IDLE_TIMEOUT_MS": "300000"}
    return subprocess.run(_cmd() + list(args), capture_output=True, text=True, env=env, **kwargs)

def ab_batch(*cmds, **kwargs):
    env = {**os.environ, "AGENT_BROWSER_IDLE_TIMEOUT_MS": "300000"}
    return subprocess.run(
        _cmd() + ["batch", "--json"],
        input=json.dumps([list(c) for c in cmds]),
        capture_output=True, text=True, env=env, **kwargs,
    )
```

### Batch Output Structure

```json
[
  {
    "command": ["tab", "new", "https://example.com"],
    "error": null,
    "result": {
      "label": null,
      "tabId": "t1",
      "total": 2,
      "url": "https://example.com"
    },
    "success": true
  },
  {
    "command": ["eval", "document.title"],
    "error": null,
    "result": {
      "origin": "https://example.com/",
      "result": "Example Domain"
    },
    "success": true
  }
]
```

**Getting the tab ID** (common mistake — it's in `.result.tabId`, NOT `.data.tabId`):

```python
def _get_tab_id(results):
    return results[0].get("result", {}).get("tabId")
```

**Getting eval results** from batch:

```python
def _eval_result(r):
    """Extract eval result from batch output."""
    v = r.get("result", {})
    if isinstance(v, dict):
        v = v.get("result", "")
    # If it's a JSON-encoded string (from JS returning objects), decode it
    if isinstance(v, str) and len(v) > 2 and v[0] == '"' and v[-1] == '"':
        return v[1:-1].encode().decode("unicode_escape")
    return str(v) if v else ""

# For JS that returns an array (like DDG extraction):
eval_r = batch_out[cmd_idx].get("result", {})
if isinstance(eval_r, dict):
    eval_r = eval_r.get("result", "")
if isinstance(eval_r, str):
    results = json.loads(eval_r)  # decode JSON string
else:
    results = eval_r if isinstance(eval_r, list) else []
```

## Tab Management

### Tab-per-Call Pattern (Recommended)

Each script invocation opens a tab, works, closes it. Daemon stays alive.

```python
def crawl(url):
    r = ab_batch(
        ["tab", "new", url],
        ["wait", "--load", "networkidle", "--timeout", "30000"],
        ["eval", "document.title"],
        ["eval", "document.body.innerText"],
    )
    results = json.loads(r.stdout.strip())
    tab_id = results[0].get("result", {}).get("tabId")

    # ... do work with results ...

    # Always close our tab — daemon stays alive
    if tab_id:
        ab("tab", "close", tab_id)
```

**Benefits:**
- Sequential calls: ~600MB constant
- Concurrent calls: ~600MB constant (single browser, multiple tabs)
- Tabs are properly cleaned up
- Daemon handles idle shutdown automatically

**Don't use `agent-browser session`** for concurrency — it spawns a full new browser instance per session (~600MB each). Tabs share one instance.

### Tab Commands

```bash
# List tabs
agent-browser tab list
# → [t1] example.com - https://example.com/
# → [t2] about:blank

# Close specific tab
agent-browser tab close t1

# Open new tab
agent-browser tab new https://example.com

# Switch to tab (makes it active for eval/snapshot/etc)
agent-browser tab 1
```

**Note**: Chrome always has at least one tab open. When you close the last tab, it opens `about:blank`. This is normal and uses negligible RAM.

## Common Patterns

### Open, Wait, Eval

```bash
agent-browser open https://example.com
agent-browser wait --load networkidle --timeout 30000
agent-browser eval "document.querySelector('h1').textContent"
agent-browser close
```

### Snapshot (AI-friendly page structure)

```bash
# Interactive elements only
agent-browser snapshot -i

# Compact (remove empty structural elements)
agent-browser snapshot -c

# Scoped to selector
agent-browser snapshot -s "#main-content"
```

### Click + Type

```bash
agent-browser open https://example.com/form
agent-browser fill "#email" "user@example.com"
agent-browser fill "#password" "secret"
agent-browser click "#submit"
agent-browser wait 2000
agent-browser snapshot
```

### Network Route (block/modify requests)

```bash
# Block specific resource types
agent-browser network route "https://ads.example.com/*" --abort

# Block by resource type (csv)
agent-browser network route "*" --resource-type "image,stylesheet" --abort
```

### Screenshot

```bash
agent-browser open https://example.com
agent-browser wait --load networkidle
agent-browser screenshot /tmp/screenshot.png
agent-browser screenshot --full /tmp/full.png
```

### Get Content

```bash
agent-browser get text          # Page text
agent-browser get html          # Page HTML
agent-browser get title         # Page title
agent-browser get url           # Current URL
agent-browser get text "#main"  # Text of selector
```

## Python subprocess Patterns

### Simple one-shot call

```python
def ab_eval(js):
    env = {**os.environ, "AGENT_BROWSER_IDLE_TIMEOUT_MS": "300000"}
    return subprocess.run(
        _cmd() + ["eval", js],
        capture_output=True, text=True, env=env,
    ).stdout.strip()
```

### Multi-step with batch

```python
def fetch_page(url):
    r = ab_batch(
        ["tab", "new", url],
        ["wait", "--load", "networkidle", "--timeout", "15000"],
        ["eval", EXTRACT_JS],
    )
    results = json.loads(r.stdout.strip())
    tab_id = results[0]["result"]["tabId"]

    # Extract eval result (index 2 because: 0=tab new, 1=wait, 2=eval)
    eval_r = results[2].get("result", {})
    if isinstance(eval_r, dict):
        eval_r = eval_r.get("result", "")

    if tab_id:
        ab("tab", "close", tab_id)

    return eval_r
```

### Concurrent execution

```python
import concurrent.futures

urls = ["https://a.com", "https://b.com", "https://c.com"]
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
    futures = [executor.submit(fetch_page, url) for url in urls]
    results = [f.result() for f in futures]
# All share one browser instance, each gets its own tab
```

## Python CDP Integration (Daemon-First)

Connect Playwright to the agent-browser daemon for programmatic control while preserving the daemon lifecycle (idle timeout, RAM management).

### Setup

```bash
# Export these so agent-browser launches CloakBrowser with stealth patches
export AGENT_BROWSER_EXECUTABLE_PATH=~/.cloakbrowser/chromium-146.0.7680.177.5/chrome
export AGENT_BROWSER_ARGS="--no-sandbox,--fingerprint=12345,--fingerprint-platform=windows"
```

### Script Pattern

```bash
~/.claude/skills/cloakbrowser/scripts/custom.py <url>              # Open URL, print title + text
~/.claude/skills/cloakbrowser/scripts/custom.py <url> --eval <js>  # Run JS and print result
~/.claude/skills/cloakbrowser/scripts/custom.py <url> --snapshot   # Print accessibility snapshot
~/.claude/skills/cloakbrowser/scripts/custom.py <url> --html       # Print page HTML
```

### Manual Pattern

```python
import subprocess, os
from playwright.sync_api import sync_playwright

# Ensure daemon uses CloakBrowser
os.environ["AGENT_BROWSER_IDLE_TIMEOUT_MS"] = "300000"
os.environ["AGENT_BROWSER_EXECUTABLE_PATH"] = "~/.cloakbrowser/chromium-*/chrome"
os.environ["AGENT_BROWSER_ARGS"] = "--no-sandbox,--fingerprint=12345,--fingerprint-platform=windows"

# 1. Start daemon (first command spawns it)
subprocess.run(["agent-browser", "open", "https://example.com"], capture_output=True)

# 2. Get CDP WebSocket URL
ws_url = subprocess.run(["agent-browser", "get", "cdp-url"],
                       capture_output=True, text=True).stdout.strip()

# 3. Connect Playwright to daemon's browser
pw = sync_playwright().start()
browser = pw.chromium.connect_over_cdp(ws_url)
context = browser.contexts[0]
page = context.pages[0]

# 4. Use full Playwright API
page.goto("https://target-site.com")
print(page.title())

# 5. Apply humanize patches (optional)
from cloakbrowser.human import patch_browser, resolve_config
cfg = resolve_config("default")
patch_browser(browser, cfg)
# Now page.click(), page.type(), page.fill() use human-like behavior

# 6. Agent-browser can still operate independently
subprocess.run(["agent-browser", "snapshot"], capture_output=True)

# 7. Disconnect — daemon keeps browser alive, auto-shutdowns after idle
browser.close()
pw.stop()
```

### Key Points

- **Daemon owns lifecycle** — Python connects/disconnects but daemon manages the browser process
- **Idle timeout preserved** — browser auto-shutdowns after `AGENT_BROWSER_IDLE_TIMEOUT_MS` of inactivity
- **One instance, two controllers** — agent-browser CLI and Python Playwright API work on the same browser
- **Stealth patches active** — C++ patches require `--fingerprint` and `--fingerprint-platform` args

### Limitations

- **Stealth patches active** — All C++ fingerprint patches work automatically over CDP (GPU, screen, WebGL, canvas, etc.)
- **`humanize` available over CDP** — Use `from cloakbrowser.human import patch_browser, resolve_config; patch_browser(browser, resolve_config("default"))` after connecting. See example below.
- **Viewport may need manual set** — Headless CDP sometimes doesn't report viewport; set with `page.set_viewport_size({"width": 1280, "height": 720})` if humanize fails with "Viewport size not available"

## Gotchas Summary

| Issue | Cause | Fix |
|---|---|---|
| Stray tab with weird URL | `--args` splits on commas, value becomes URL | Don't put commas inside individual `--args` values |
| Tab never closes | `_get_tab_id` reads `.data.tabId` | Read `.result.tabId` instead |
| `--args` ignored warning | Daemon already running with different args | Use `agent-browser close` first, or accept existing daemon |
| DDG returns empty results | File cached from previous empty run | Delete cached file or add cache-busting logic |
| Multiple `--blink-settings` | Chrome only uses the last one | Combine in single value: `--blink-settings=key1=val1,key2=val2` |
| Batch eval returns `[]` | Result is a list, not a string | Check type: if list, use directly; if string, `json.loads()` |
| `agent-browser close` doesn't kill | Multiple sessions/daemons | Use `agent-browser close --all` or `pkill -9 -f "chrome"` |
