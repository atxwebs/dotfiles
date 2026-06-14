# CloakBrowser Usage Reference

**What we do and why:** [stealth.md](./stealth.md) (source-linked).

This file: agent-browser CLI gotchas, batch patterns, CDP wiring. Scripts use `browser_lib.py` — don't copy stale args from below.

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

# CORRECT -- comma-join flags that DON'T contain internal commas
--args "--no-sandbox,--fingerprint=12345"
```

**Note**: `cssImagesEnabled=false` is redundant with `imagesEnabled=false` (which blocks all images including CSS backgrounds). Use only `imagesEnabled=false`.

## Stealth args

Use library defaults — do not hand-roll blink flags:

```bash
# Official integration pattern (comma-joined for agent-browser)
STEALTH_ARGS=$(python3 -c "from cloakbrowser.config import get_default_stealth_args; print(','.join(get_default_stealth_args()))")
export AGENT_BROWSER_EXECUTABLE_PATH="$CLOAK_BIN"
export AGENT_BROWSER_ARGS="$STEALTH_ARGS"
```

`browser_lib.daemon_args()` does this via `build_args()` plus a time-based `--fingerprint` override. On Linux, `--fingerprint-platform=windows` is expected — see [stealth.md](./stealth.md).

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

**Python helper pattern** — prefer `browser_lib.ensure_daemon()` + `connect_cdp()`. Legacy batch-only sketch:

```python
# Use daemon_args() from browser_lib — not hand-rolled blink flags
from browser_lib import daemon_args, CLOAK_BIN

def _cmd():
    return ["agent-browser", "--executable-path", CLOAK_BIN, "--args", daemon_args()]
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

Scripts use `browser_lib` — see `custom.py`, `crawl.py`, `ddg-search.py`.

### Setup

```bash
# browser_lib sets these via ensure_daemon() — get_default_stealth_args() per agent_browser.sh
~/.claude/skills/cloakbrowser/scripts/custom.py https://example.com
```

### Manual Pattern

```python
from browser_lib import ensure_daemon, connect_cdp, disconnect_cdp

ws_url = ensure_daemon("about:blank")
pw, browser, context, page = connect_cdp(ws_url)  # humanize on by default
page.goto("https://example.com")
print(page.title())
disconnect_cdp(pw, browser, page)
```

### Key Points

- **Daemon owns lifecycle** — Python connects/disconnects but daemon manages the browser process
- **Idle timeout preserved** — browser auto-shutdowns after `AGENT_BROWSER_IDLE_TIMEOUT_MS` of inactivity
- **One instance, two controllers** — agent-browser CLI and Python Playwright API work on the same browser
- **Stealth patches active** — C++ patches require `--fingerprint` and `--fingerprint-platform` args

### Limitations

- **Stealth patches** — C++ patches active over CDP automatically
- **humanize** — `browser_lib.connect_cdp()` applies `patch_browser()` by default ([README](https://github.com/CloakHQ/CloakBrowser#humanize))
- **Viewport** — only set when CDP reports none ([stealth.md](./stealth.md))

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
