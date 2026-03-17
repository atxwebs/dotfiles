---
name: llamacpp
description: When working with llama.cpp (serve
---

# llama.cpp

**Location:** `~/Applications/llamacpp`

**Binaries (in PATH):** `llama-cli`, `llama-server` — wrappers in `~/.local/bin`, no env vars needed.

## Starting Server

**Manual start:**
```bash
llama-server --host 0.0.0.0 --port 58261 --models-dir ~/Applications/llamacpp/models
```

**Systemd service (auto-start on login):**
```bash
systemctl --user enable llamacpp-server.service
systemctl --user start llamacpp-server.service
systemctl --user status llamacpp-server.service
journalctl --user -u llamacpp-server.service -f
```

**Service file:** `~/.config/systemd/user/llamacpp-server.service`

**Verify:** `curl http://127.0.0.1:58261/health` → `{"status":"ok"}`

Server: `http://127.0.0.1:58261` (0.0.0.0 = reachable from LAN)

## Models

**Models dir:** `~/Applications/llamacpp/models` — put GGUF files here. Router mode auto-discovers and loads on demand.

**CLI (one-off inference):**
```bash
llama-cli -m ~/Applications/llamacpp/models/model.gguf -p "Hello"
```

## Scripts

**Location:** `~/.claude/skills/llamacpp/scripts/`

- `llamacpp.sh <method> <endpoint> [json_body]` — Base API script (no auth)
- `start_server.sh` — Enable + start service, verify health
- `build-llama-cpp.sh` — Rebuild with CUDA (sm_89)
- `ollama-to-llamacpp.sh <model:tag> [...]` — Extract GGUF + template from Ollama blobs
- `flush-and-start.js` — Kill all llama-server, free memory, restart
- `logs.js [N]` — Show last N lines of llamacpp-server journal (default 80)
- `hf-to-llamacpp.sh <owner/project> <quant>` — Download GGUF from HF, add to preset
- `chat.js -m MODEL -p PROMPT` — One-shot chat
- `chat-tools.js [MODEL]` — Tool-call test
- `chat-vision.js -m MODEL -p PROMPT -f IMAGE_PATH` — Vision (OCR, describe)
- `load_model.sh <model>` — Load model via API
- `unload_model.sh <model>` — Unload model via API

## API Endpoints

OpenAI-compatible. No authentication by default.

- Chat: `POST /v1/chat/completions`
- Models: `GET /v1/models`
- Load: `POST /v1/models/load` (router mode)
- Docs: `http://127.0.0.1:58261/docs`

## Rebuild

`~/.claude/skills/llamacpp/scripts/build-llama-cpp.sh`

## Ollama → llama.cpp

One command extracts GGUF, assigns templates, and updates the preset:
```bash
~/.claude/skills/llamacpp/scripts/ollama-to-llamacpp.sh \
  Qwen3.5-9B:UD-Q4_K_XL Qwen3-14B-NT:UD-IQ3_XXS qwen3-vl:8b-instruct \
  ministral-3-14b:IQ3_XS Qwen_Qwen3-14B:IQ3_XS
```

**Model–template linking:** `models/models.ini` preset maps each model to its template. Server uses `--models-preset` so templates apply automatically when a model is loaded.

**HF download:** `hf-to-llamacpp.sh unsloth/Qwen3.5-9B-GGUF IQ3_XXS` — downloads, adds to preset, infers template from repo name.

## Notes

- CUDA 12.6, RTX 4070 (sm_89)
- Router mode: models load on first request, `--models-max` limits concurrent
- Format: GGUF only
