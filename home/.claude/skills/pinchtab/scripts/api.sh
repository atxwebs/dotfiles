#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: api.sh <path> <method> [body_json]" >&2
  exit 1
fi

ENDPOINT="$1"
METHOD="$2"
BODY="${3:-}"

TOKEN=$(jq -r '.server.token' "$HOME/.pinchtab/config.json")

if [ -n "$BODY" ]; then
  curl -s -X "$METHOD" "http://localhost:9867${ENDPOINT}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$BODY"
else
  curl -s -X "$METHOD" "http://localhost:9867${ENDPOINT}" \
    -H "Authorization: Bearer ${TOKEN}"
fi
