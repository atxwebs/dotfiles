#!/bin/bash
# Base TabbyAPI script - handles authentication and API calls
# Usage: tabbyapi.sh <method> <endpoint> [json_body]

METHOD="${1:-GET}"
ENDPOINT="$2"
JSON_BODY="$3"

# Read admin key (works for all endpoints)
KEY=$(grep admin_key ~/Applications/tabbyAPI/api_tokens.yml | cut -d' ' -f2)
BASE_URL="http://127.0.0.1:5000"

# Build curl command
if [ -n "$JSON_BODY" ]; then
  curl -s -X "$METHOD" \
    -H "Authorization: Bearer $KEY" \
    -H "Content-Type: application/json" \
    -d "$JSON_BODY" \
    "$BASE_URL$ENDPOINT"
else
  curl -s -X "$METHOD" \
    -H "Authorization: Bearer $KEY" \
    "$BASE_URL$ENDPOINT"
fi
