#!/bin/bash
# Quick swap between Qwen3.5-9B and Qwen3-14B models

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$1" in
  "9b"|"9B")
    "$SCRIPT_DIR/reload_model.sh" "Qwen3.5-9B-exl3-5.00bpw" 32768 32768 "4,4"
    ;;
  "14b"|"14B")
    "$SCRIPT_DIR/reload_model.sh" "Qwen3-14B-exl3-4bpw" 16384 16384 "4,4"
    ;;
  *)
    echo "Usage: $0 [9b|14b]"
    exit 1
    ;;
esac

echo ""
echo "VRAM usage:"
nvidia-smi --query-gpu=memory.used,memory.free --format=csv,noheader,nounits
