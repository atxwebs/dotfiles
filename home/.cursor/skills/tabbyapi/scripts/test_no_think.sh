#!/bin/bash
# Test if model is generating thinking tokens

API_KEY=$(grep api_key ~/Applications/tabbyAPI/api_tokens.yml | cut -d' ' -f2)
BASE_URL="http://127.0.0.1:5000"

RESPONSE=$(curl -s -X POST $BASE_URL/v1/chat/completions \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen3.5-9B-exl3-5.00bpw",
    "messages": [{"role": "user", "content": "What is 2+2? Answer briefly."}],
    "max_tokens": 100,
    "temperature": 0.7
  }')

CONTENT=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['choices'][0]['message']['content'])" 2>/dev/null)

echo "Response: $CONTENT"
echo ""

if echo "$CONTENT" | grep -q "<think>"; then
    echo "❌ FAILED: Model is generating <think> blocks!"
else
    echo "✅ SUCCESS: No <think> blocks detected!"
fi
