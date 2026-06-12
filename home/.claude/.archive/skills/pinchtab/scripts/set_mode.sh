#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: set_mode.sh <headed|headless>" >&2
  exit 1
fi

MODE="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Validate mode
case "$MODE" in
  headed)
    BODY='{"mode":"headed","headless":false}'
    ;;
  headless)
    BODY='{"mode":"headless","headless":true}'
    ;;
  *)
    echo "Invalid mode: $MODE (use headed or headless)" >&2
    exit 1
    ;;
esac

# Stop any existing instance
"$SCRIPT_DIR/api.sh" /profiles/default/stop POST >/dev/null 2>&1 || true
sleep 2

# Start instance with requested mode
"$SCRIPT_DIR/api.sh" /profiles/default/start POST "$BODY" >/dev/null

echo "Instance started in $MODE mode"
