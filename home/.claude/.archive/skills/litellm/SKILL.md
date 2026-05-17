---
name: litellm
description: LiteLLM proxy server for unified LLM API access. Use when making API calls to Alibaba models (Qwen, MiniMax, GLM) or when the user needs to test/configure LLM endpoints.
---

# LiteLLM Proxy

## Location & Setup

- **Installation**: `~/Applications/litellm/`
- **Virtual env**: `~/Applications/litellm/venv/`
- **Config**: `~/Applications/litellm/config.yaml`
- **Service**: systemd (`litellm.service`)
- **Port**: 58847
- **API Base**: `https://coding-intl.dashscope.aliyuncs.com/v1`

## Available Models

| Model Name | Provider | Capabilities |
|------------|----------|--------------|
| `qwen3.5-plus` | dashscope/qwen-plus | thinking, vision, function calling, JSON mode |
| `qwen3-coder-next` | dashscope/qwen-coder-plus | thinking, vision, function calling, JSON mode |
| `qwen3-coder-plus` | dashscope/qwen-coder-plus | thinking, vision, function calling, JSON mode |
| `minimax-m2.5` | minimax/minimax-m2 | function calling, JSON mode |
| `glm-5` | zhipuai/glm-4 | vision, function calling, JSON mode |

## Usage

### Test Connection

```bash
curl http://localhost:58847/health
curl http://localhost:58847/v1/models
```

### API Call Example

```bash
curl http://localhost:58847/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3.5-plus",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

### Service Management

```bash
# Check status
systemctl status litellm

# Restart after config changes (no sudo needed)
systemctl restart litellm

# View logs (tail -f style)
journalctl -u litellm -f

# Last N lines
journalctl -u litellm -n 100 --no-pager

# Manual run (for testing)
cd ~/Applications/litellm
./venv/bin/litellm --config config.yaml --port 58847
```

## Config Structure

Models are configured in `config.yaml` with:

```yaml
model_list:
  - model_name: <your-model-name>
    litellm_params:
      model: <provider>/<actual-model>
      api_base: https://coding-intl.dashscope.aliyuncs.com/v1
      api_key: os.environ/ALIBABA_CLOUD_API_KEY
      extra_params:
        enable_thinking: true  # For Qwen thinking models
    model_info:
      supports_function_calling: true
      supports_vision: true
      supports_json_mode: true
```

## Environment Variable

The service uses `ALIBABA_CLOUD_API_KEY` (set in systemd service file).

## Status

**Service is stopped and disabled.** Config is preserved at `~/Applications/litellm/config.yaml`.

To restart manually:
```bash
systemctl start litellm
# Or run directly:
cd ~/Applications/litellm && ./venv/bin/litellm --config config.yaml --port 58847
```

## Cursor IDE Integration (Not Active)

Previous attempt to use LiteLLM with Cursor via public URL (`http://home.rovetia.com:58847`) encountered issues with Cursor's SSRF blocking and path handling. Service is now stopped.
