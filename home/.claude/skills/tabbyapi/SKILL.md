---
name: tabbyapi
description: Run and manage TabbyAPI server for local AI model inference. Use when starting TabbyAPI, downloading models, configuring the API, or working with local LLM inference.
---

# TabbyAPI

**Location:** `~/Applications/tabbyAPI`

**API Keys:** `~/Applications/tabbyAPI/api_tokens.yml` (auto-generated, not versioned)
- Read: `cat ~/Applications/tabbyAPI/api_tokens.yml`
- Regenerate: Delete `api_tokens.yml` and restart

## Starting Server

**Manual start:**
```bash
cd ~/Applications/tabbyAPI && ./start.sh
```

**Systemd service (auto-start on login):**

**CURRENT STATUS: DISABLED** (not auto-starting)

```bash
# Enable and start service (re-enable auto-start)
systemctl --user enable tabbyapi.service
systemctl --user start tabbyapi.service

# Check status
systemctl --user status tabbyapi.service

# View logs
journalctl --user -u tabbyapi.service -f

# Stop/restart
systemctl --user stop tabbyapi.service
systemctl --user restart tabbyapi.service

# Disable auto-start (if needed again)
systemctl --user disable tabbyapi.service
systemctl --user stop tabbyapi.service
```

**Service file:** `~/.config/systemd/user/tabbyapi.service`

Server: `http://127.0.0.1:5000`

## Downloading Models

```bash
cd ~/Applications/tabbyAPI
./start.sh download <model-repo> --revision <branch>
```

**Examples:**
- `./start.sh download turboderp/Qwen3.5-9B-exl3 --revision 5.00bpw`
- `./start.sh download turboderp/Qwen2.5-14B-Instruct-exl3 --revision 5.0bpw`

**BPW:** 4→5bpw significant improvement, 5→6bpw less so. Prefer 5bpw.

**VRAM (8GB GPU):**
- `Qwen3.5-9B-exl3-5.00bpw`: 32K context (~5.4GB)
- `Qwen3-14B-exl3-4bpw`: 16K context max (~7.7GB)

## Scripts

**Location:** `~/.claude/skills/tabbyapi/scripts/`

**Base script:**
- `tabbyapi.sh <method> <endpoint> [json_body]` - Base script that handles authentication and API calls. Always uses admin_key (works for all endpoints).

**Model management:**
- `load_model.sh [model] [max_seq] [cache_size] [cache_mode]` - Load model
- `unload_model.sh` - Unload current model
- `reload_model.sh [model] [max_seq] [cache_size] [cache_mode]` - Reload model (unload then load)
- `swap_model.sh [9b|14b]` - Swap between Qwen3.5-9B and Qwen3-14B

All scripts use Bearer token authentication via the base `tabbyapi.sh` script.

## Configuration

**Config:** `config.yml`

**Key settings:**
- `model.model_name`: Initial model to load (`null` = no auto-load, load on-demand)
- `model.inline_model_loading`: Enable loading models via API requests (`true` = on-demand)
- `model.max_seq_len`: Total sequence length (context + generation)
- `model.cache_size`: KV cache size (should match `max_seq_len`)
- `model.cache_mode`: KV cache quantization `"k_bits,v_bits"` (e.g., `"4,4"`)
- `model.prompt_template`: Template name (without `.jinja`)

**On-demand loading:** Set `model_name: null` and `inline_model_loading: true` to prevent auto-loading. Models load when requested via API.

**Templates:** `~/Applications/tabbyAPI/templates/*.jinja`
- `qwen_no_think.jinja` - Prevents thinking token generation

## API Endpoints

**Authentication:**
- Use Bearer token: `Authorization: Bearer <admin_key>` or `Authorization: Bearer <api_key>`
- Admin key works for all endpoints (admin + regular API)
- API key works for regular endpoints only
- Legacy headers: `X-Admin-Key` (admin endpoints only), `X-Api-Key` (regular endpoints)

**Endpoints:**
- Chat: `POST /v1/chat/completions`
- Models: `GET /v1/models`
- Load: `POST /v1/model/load` (requires `model_name` in JSON body)
- Unload: `POST /v1/model/unload`
- Docs: `http://127.0.0.1:5000/redoc`

## Context Length

`max_seq_len` = context + generation combined
- `max_seq_len=32768` + 16K context = up to 16K generation
- `cache_size` should match `max_seq_len`
- `cache_mode`: `"2,2"` < `"3,3"` < `"4,4"` < `"8,8"` (FP16)

## Notes

- Formats: EXL2, EXL3, GPTQ, FP16
- Backend: ExLlamaV2/V3 (auto-detected)
- Requires NVIDIA GPU with CUDA 12.x
- Venv auto-created in `venv/`
- Configured to run as systemd user service (auto-start on login)
- No auto-load: Models load on-demand via API (`model_name: null`, `inline_model_loading: true`)
