#!/bin/bash
# Load a TabbyAPI model with optional parameters

MODEL_NAME="${1:-Qwen3.5-9B-exl3-5.00bpw}"
MAX_SEQ="${2:-32768}"
CACHE_SIZE="${3:-32768}"
CACHE_MODE="${4:-4,4}"

ADMIN_KEY=$(grep admin_key ~/Applications/tabbyAPI/api_tokens.yml | cut -d' ' -f2)
BASE_URL="http://127.0.0.1:5000"

curl -s -X POST -H "Authorization: Bearer $ADMIN_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model_name\": \"$MODEL_NAME\",
    \"max_seq_len\": $MAX_SEQ,
    \"cache_size\": $CACHE_SIZE,
    \"cache_mode\": \"$CACHE_MODE\"
  }" \
  $BASE_URL/v1/model/load

echo ""
