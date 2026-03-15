#!/bin/bash
# Get logs for a GitHub Actions run
# Usage: logs.sh <run-id>
set -euo pipefail
[ $# -eq 1 ] || { echo "Usage: $0 <run-id>" >&2; exit 1; }
GIT_CONFIG_NOSYSTEM=1 gh run view "$1" --log
