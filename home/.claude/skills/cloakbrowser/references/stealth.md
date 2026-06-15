# Stealth

What we do, why, and upstream source for each choice.

## Source map

|What we do|Where|Upstream source|
|---|---|---|
|`get_default_stealth_args()` via `build_args()`|`daemon_args()`|[agent_browser.sh](https://github.com/CloakHQ/CloakBrowser/blob/main/examples/integrations/agent_browser.sh), [config.py `get_default_stealth_args`](https://github.com/CloakHQ/CloakBrowser/blob/main/cloakbrowser/config.py)|
|Time-based `--fingerprint` override|`daemon_args()`|[README: fixed seed for session persistence](https://github.com/CloakHQ/CloakBrowser/blob/main/README.md#fingerprint-management) — we use time bucket instead of random for daemon stability|
|`patch_browser()` on CDP connect|`connect_cdp()`|[README: `humanize=True`](https://github.com/CloakHQ/CloakBrowser/blob/main/README.md#humanize)|
|Don't block `font` in routes|`connect_cdp()`|[README: font setup on Linux](https://github.com/CloakHQ/CloakBrowser/blob/main/README.md#font-setup-on-linux)|
|Viewport only if CDP has none|`_ensure_viewport()`|[usage.md CDP limitations](usage.md#python-cdp-integration-daemon-first)|
|`wait_for_challenge()`|crawl/ddg-search|Turnstile — README passing tests|
|Font package check|`setup.sh`|[README: font setup](https://github.com/CloakHQ/CloakBrowser/blob/main/README.md#font-setup-on-linux)|

`agent_browser.sh` is the minimal official integration. README documents the full recommendations (`humanize`, persistent profiles, FPJS tuning) — we follow README where our agent-browser + CDP stack allows.

## Why always Windows (on Linux)?

Not "randomness restricted to Windows" — **OS family is fixed, identity varies inside it.**

The library picks one coherent platform profile per host OS ([README fingerprint management](https://github.com/CloakHQ/CloakBrowser/blob/main/README.md#fingerprint-management)):

|Host|`--fingerprint-platform`|Why|
|---|---|---|
|Linux|`windows`|Most common desktop Chrome fingerprint; avoids rare Linux+NVIDIA automation cluster|
|Windows|`windows`|Native|
|macOS|`macos`|Native — spoofing Windows on Mac causes font/GPU mismatches ([config.py](https://github.com/CloakHQ/CloakBrowser/blob/main/cloakbrowser/config.py))|

**What still varies per seed:** GPU renderer, screen dimensions, hardware concurrency, device memory, canvas/WebGL/audio noise — all derived from `--fingerprint` ([README](https://github.com/CloakHQ/CloakBrowser/blob/main/README.md#default-fingerprint)).

They don't randomize across macOS/Linux/Windows because mixed signals (Windows UA + Linux GPU fonts) are easier to detect than a consistent Windows desktop with a different seed.

## Our daemon args

```
--no-sandbox,--fingerprint=<time-bucket>,--fingerprint-platform=windows
```

Nothing else. Noise, screen, timezone — binary defaults from seed.

## humanize

`connect_cdp()` calls `patch_browser()` with `idle_between_actions=True` by default — equivalent to `launch(humanize=True)` ([README](https://github.com/CloakHQ/CloakBrowser/blob/main/README.md#humanize)).

## Viewport

Only set `DEFAULT_VIEWPORT` when CDP reports no viewport. Don't hand-set screen flags — seed handles coherence.

## Fonts

Never block font requests. Run `setup.sh` — warns if emoji font packages missing.

## State: ephemeral vs persistent profiles

Two separate concepts ([README `launch_persistent_context`](https://github.com/CloakHQ/CloakBrowser/blob/main/README.md#launch_persistent_context)):

||Fingerprint (`--fingerprint=seed`)|Profile (`userDataDir`)|
|---|---|---|
|What it is|Device identity signals (GPU, canvas, UA, screen…)|Cookies, localStorage, cache on disk|
|Persists|Per daemon launch (our time bucket)|Across browser restarts|
|Our crawls|Yes — one seed per ~10min daemon|**No** — we don't use `launch_persistent_context`|

**Not per-fingerprint automatically.** Profile folder is just a directory you choose. If you reuse `./profile` with a new fingerprint seed, old cookies from "device A" meet signals from "device B" — suspicious. Library pattern: one profile per stable identity, or ephemeral when you want no carryover.

**Our model:** no disk profile. Fresh browser context when daemon starts. Within one daemon session, tabs share the same context (cookies can accumulate across URLs until idle timeout). New daemon ≈ new fingerprint bucket + fresh context. For full isolation between targets, `agent-browser close` between runs.

Persistent profiles are for sites that challenge cookieless first visits — README warmup flow. Different architecture than our scripts; not wired.

## Advanced (not in our stack)

|Feature|README source|Why we skip|
|---|---|---|
|`launch(proxy=...)`|[FPJS troubleshooting](https://github.com/CloakHQ/CloakBrowser/blob/main/README.md#detected-by-fingerprintjs)|No proxy configured|
|`geoip=True`|[issue #197](https://github.com/CloakHQ/CloakBrowser/issues/197)|Needs `launch()` + proxy|
|`launch_persistent_context`|[README](https://github.com/CloakHQ/CloakBrowser/blob/main/README.md#launch_persistent_context)|Ephemeral crawls; agent-browser path|
|Widevine CDM|[README Widevine](https://github.com/CloakHQ/CloakBrowser/blob/main/README.md#widevine--drm)|Persistent profiles only|
|`--fingerprint-noise=false`|[FPJS troubleshooting](https://github.com/CloakHQ/CloakBrowser/blob/main/README.md#detected-by-fingerprintjs)|Site-specific, not baseline default|

## Daemon gotcha

`AGENT_BROWSER_ARGS` only on daemon start. `agent-browser close` to change.
