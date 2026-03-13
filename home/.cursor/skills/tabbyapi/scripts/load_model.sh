#!/bin/bash
# Load a TabbyAPI model with optional parameters

MODEL_NAME="${1:-Qwen3.5-9B-exl3-5.00bpw}"
MAX_SEQ="${2:-32768}"
CACHE_SIZE="${3:-32768}"
CACHE_MODE="${4:-4,4}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

JSON_BODY="{
  \"model_name\": \"$MODEL_NAME\",
  \"max_seq_len\": $MAX_SEQ,
  \"cache_size\": $CACHE_SIZE,
  \"cache_mode\": \"$CACHE_MODE\"
}"

"$SCRIPT_DIR/tabbyapi.sh" POST /v1/model/load "$JSON_BODY"
echo ""
