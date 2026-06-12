#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Installing PinchTab ==="
curl -fsSL https://pinchtab.com/install.sh | bash

echo ""
echo "=== Configuring PinchTab ==="
CONFIG="$HOME/.pinchtab/config.json"

# Configure PinchTab
jq '.security.allowEvaluate = true | .instanceDefaults.stealthLevel = "light" | .instanceDefaults.humanize = true | .multiInstance.strategy = "simple"' "$CONFIG" > /tmp/pt-config.json && mv /tmp/pt-config.json "$CONFIG"

echo "Config updated"

echo ""
echo "=== Installing daemon ==="
pinchtab daemon install
pinchtab daemon start

echo ""
echo "=== Verifying ==="
sleep 3
curl -sf http://localhost:9867/health && echo "Server: OK" || echo "Server: FAIL"
pinchtab --version

echo ""
echo "Setup complete. Scripts available at $SCRIPT_DIR/"
