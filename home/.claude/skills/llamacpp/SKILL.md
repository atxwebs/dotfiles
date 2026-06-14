---
name: llamacpp
description: Read when working with llama.cpp server, local GGUF models, or Hugging Face downloads.
---

# llama.cpp

**Location:** `~/Applications/llamacpp`

**Binaries (in PATH):** `llama-cli`, `llama-server` — wrappers in `~/.local/bin`, no env vars needed.

## Server

**Systemd service (auto-start on login):**
```bash
systemctl --user status llamacpp-server.service
systemctl --user restart llamacpp-server.service
journalctl --user -u llamacpp-server.service -f
```

**Quick commands:**
```bash
~/.claude/skills/llamacpp/scripts/restart.sh        # Restart + verify health
~/.claude/skills/llamacpp/scripts/models.sh         # List all models (like ollama list)
~/.claude/skills/llamacpp/scripts/ps.sh             # Show loaded models (like ollama ps)
~/.claude/skills/llamacpp/scripts/remove-model.sh   # Remove a model by slug
```

**Server:** `http://127.0.0.1:58261` (0.0.0.0 = reachable from LAN)  
**Verify:** `curl http://127.0.0.1:58261/health` → `{"status":"ok"}`

**Router mode:** No models loaded on boot. Auto-loads on first API request, unloads after 5min idle.

## Models

**Models dir:** `~/Applications/llamacpp/models` — GGUF files here, auto-discovered in router mode.  
**Presets:** `models/models.ini` — chat templates and per-model settings auto-applied.

**CLI (one-off inference):**
```bash
llama-cli -m ~/Applications/llamacpp/models/model.gguf -p "Hello"
```

**Download models:**
```bash
~/.claude/skills/llamacpp/scripts/hf.py unsloth/Qwen3.5-9B-GGUF IQ3_XXS
~/.claude/skills/llamacpp/scripts/hf.py unsloth/Qwen3.5-9B-GGUF:Q4_K_XL  # quant in path
~/.claude/skills/llamacpp/scripts/hf.py unsloth/Qwen3.5-9B-GGUF IQ3_XXS CustomName:Tag  # custom name
```

## Scripts

**Location:** `~/.claude/skills/llamacpp/scripts/`

- `restart.sh` — Restart service via systemd, verify health
- `models.sh` — List all models (mimics `ollama list`)
- `ps.sh` — Show loaded models (mimics `ollama ps`)
- `remove-model.sh <slug>` — Remove model by name (deletes GGUF + preset entry)
- `logs.js [N]` — Show last N lines of server logs (default 80)
- `hf.py <owner/project> [quant] [custom_name]` — Download GGUF from HF (like hf_ollama, auto-cleans cache)
- `chat.js -m MODEL -p PROMPT` — One-shot chat
- `chat-tools.js [MODEL]` — Tool-call test
- `chat-vision.js -m MODEL -p PROMPT -f IMAGE_PATH` — Vision (OCR, describe)
- `llamacpp.js` — Core API utilities (used by other scripts)

## API Endpoints

OpenAI-compatible. Use with any OpenAI client: `base_url="http://127.0.0.1:58261/v1"`

- `GET /v1/models` — List models
- `POST /v1/chat/completions` — Chat (auto-loads model)
- `POST /models/load` — Manual load
- `POST /models/unload` — Manual unload
- `http://127.0.0.1:58261/docs` — API docs

## Notes

- CUDA 12.6, RTX 4070 (sm_89)
- Router mode: starts empty, loads on-demand, unloads after 5min idle
- `--models-max 1`: only 1 model in VRAM at a time (auto-evicts)
- Format: GGUF only

## Configuration

**Server flags** (`~/.config/systemd/user/llamacpp-server.service`):
```bash
--reasoning off    # Disable thinking/reasoning by default
```

Models use their embedded GGUF chat templates automatically. For models with thinking support (Qwen3, Qwen3.5), pass `"chat_template_kwargs":{"enable_thinking":false}` per-request to disable thinking.

**Cache locations:**
- `LLAMA_CACHE=~/Applications/llamacpp/.cache` - llama.cpp download cache (on disk, not tmpfs)
- `~/.cache/huggingface/hub` - HF download cache (auto-cleaned by `hf.py` after copying to models dir)

**Auto-cleanup:** `hf.py` removes HF cache files after successful download (saves ~6GB per model)
