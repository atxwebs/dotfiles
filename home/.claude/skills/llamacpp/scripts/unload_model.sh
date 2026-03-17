#!/bin/bash
set -e
# Unload a model via llama.cpp server API (router mode)

MODEL="${1:?Usage: unload_model.sh <model_name>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/llamacpp.sh" POST /models/unload "{\"model\": \"$MODEL\"}"
echo ""
