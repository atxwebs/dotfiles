#!/bin/bash
set -e
# Load a model via llama.cpp server API (router mode)

MODEL="${1:?Usage: load_model.sh <model_name_or_path>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/llamacpp.sh" POST /models/load "{\"model\": \"$MODEL\"}"
echo ""
