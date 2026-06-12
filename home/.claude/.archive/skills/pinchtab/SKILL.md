---
name: pinchtab
description: Browser automation for LLMs via PinchTab. Use when controlling a browser, automating form fills, or building web-scraping tools.
---

# Pinchtab

Browser control for AI agents. HTTP API + CLI. 12MB Go binary, token-efficient text extraction.

## Install from scratch

```bash
curl -fsSL https://pinchtab.com/install.sh | bash
```

Linux amd64: binary may be `pinchtab-linux-amd64` while CLI expects `x64`. Set:
```bash
export PINCHTAB_BINARY_PATH=~/.pinchtab/bin/0.7.6/pinchtab-linux-amd64
```

Chrome profile permission issues:
```bash
export BRIDGE_PROFILE=/tmp/pinchtab-profile
export BRIDGE_NO_RESTORE=true
```

## CLI (server must be running)

```bash
pinchtab                          # start server (port 9867)
pinchtab nav https://example.com   # navigate
pinchtab snap -i -c               # snapshot (interactive, compact)
pinchtab fill e12 "query"          # fill by ref
pinchtab click e16                 # click by ref
pinchtab press Enter               # press key
pinchtab text                      # extract page text
```

Refs (e0, e1, …) come from snapshot. Invalidated after navigate — snapshot again.

## Integration

`src/integrations/pinchtab.ts` — `pinchtab` object:

- `navigate(url)`, `snapshot(opts)`, `click(ref)`, `fill(ref, text)`, `press(key)`, `text()`
- `startServer()`, `stopServer()` — lifecycle (start skips if already up)
- `eval(expression)` — JS in page (e.g. `form.submit()` when click fails)

Env: `PINCHTAB_URL`, `PINCHTAB_BINARY_PATH`, `BRIDGE_PROFILE`

## Tools

`src/tools/browser/*.ts`: `browserNavigate`, `browserSnapshot`, `browserFill`, `browserClick`, `browserPress`, `browserText`, `browserEval`, `browserStartServer`, `browserStopServer`

Session: `src/sessions/browserSearch.ts` — search via form (DDG/Google).

## Shutdown (ensure browser is off at end)

Sessions must call `browserStopServer` when done. If pinchtab was started manually, kill it:

```bash
pkill -9 -f pinchtab
# verify: curl -s http://localhost:9867/health  (should fail)
```

## Caveats

- Google: click "Buscar con Google" can open image-upload UI; use `browserEval` + `form.submit()` fallback
- DuckDuckGo: Search button (e80) often disabled; use eval fallback
