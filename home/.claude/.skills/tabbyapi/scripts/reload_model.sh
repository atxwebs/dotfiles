#!/bin/bash
# Reload TabbyAPI model (unload then load)

MODEL_NAME="${1:-Qwen3.5-9B-exl3-5.00bpw}"
MAX_SEQ="${2:-32768}"
CACHE_SIZE="${3:-32768}"
CACHE_MODE="${4:-4,4}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Unloading current model..."
"$SCRIPT_DIR/unload_model.sh" > /dev/null

sleep 2

echo "Loading $MODEL_NAME..."
"$SCRIPT_DIR/load_model.sh" "$MODEL_NAME" "$MAX_SEQ" "$CACHE_SIZE" "$CACHE_MODE"
