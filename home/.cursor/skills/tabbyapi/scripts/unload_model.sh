#!/bin/bash
# Unload the current TabbyAPI model

ADMIN_KEY=$(grep admin_key ~/Applications/tabbyAPI/api_tokens.yml | cut -d' ' -f2)
BASE_URL="http://127.0.0.1:5000"

curl -s -X POST -H "Authorization: Bearer $ADMIN_KEY" \
  $BASE_URL/v1/model/unload

echo "Model unloaded"
