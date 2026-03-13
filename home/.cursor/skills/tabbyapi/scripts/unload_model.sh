#!/bin/bash
# Unload the current TabbyAPI model

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/tabbyapi.sh" POST /v1/model/unload
echo ""
echo "Models unloaded"
