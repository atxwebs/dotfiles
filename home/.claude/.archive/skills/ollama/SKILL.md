---
name: ollama
description: Read when working with Ollama
---

# Ollama

**Location:** `/usr/share/ollama` (system) or `~/.ollama` (user)

**Service:**
```bash
# Check status
systemctl status ollama

# Start/stop
sudo systemctl start ollama
sudo systemctl stop ollama

# View logs
journalctl -u ollama -f
```

**CLI:**
```bash
# List models
ollama list

# Pull model
ollama pull <model-name>

# Show model details
ollama show <model-name>

# Run model
ollama run <model-name>
```

## Templates

**Location:** `~/.claude/skills/ollama/assets/`

**Available templates:**
- `qwen-def-no-think-fixed-tools.modelfile` - Qwen template with thinking disabled by default, fixed tool call/response format

**Template features:**
- Thinking disabled by default (only enabled with explicit `think:true`)
- Fixed `<tool_call>` and `<tool_response>` XML wrappers for tool compatibility
- `/think` and `/no_think` suffix handling commented out

**Using templates:**
```bash
# Create model from template
ollama create <model-name> -f ~/.claude/skills/ollama/assets/qwen-def-no-think-fixed-tools.modelfile

# Modify existing model template
ollama show <model-name> > /tmp/model.tpl
# Edit template, then:
ollama create <model-name> -f /tmp/model.tpl
```

## Modelfile Format

Modelfiles use Go template syntax with special variables:
- `.Messages` - Conversation messages
- `.System` - System prompt
- `.Tools` - Available tools
- `.IsThinkSet` - Whether thinking flag is set
- `.Think` - Thinking enabled flag

**Template comments:** Use `{{/* comment */}}` syntax

## Notes

- Models stored in `/usr/share/ollama/.ollama/models/blobs/`
- Templates can be extracted with `ollama show <model-name>`
- Modelfile extension: `.modelfile`
