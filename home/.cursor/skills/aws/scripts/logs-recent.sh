#!/bin/bash
# Get recent CloudWatch logs with optional grep pattern
# Usage: logs-recent.sh <log-group> <minutes> [grep-pattern] [region]
set -euo pipefail
[ $# -ge 2 ] || { echo "Usage: $0 <log-group> <minutes> [grep-pattern] [region]" >&2; exit 1; }
LOG_GROUP="$1"
MINUTES="$2"
PATTERN="${3:-}"
REGION="${4:-${AWS_REGION:-us-east-1}}"
START_TIME=$(($(date +%s) - MINUTES * 60))000
if [ -n "$PATTERN" ]; then
  aws logs filter-log-events --log-group-name "$LOG_GROUP" --region "$REGION" --start-time "$START_TIME" --query 'events[*].message' --output text | grep -E "$PATTERN" | tail -50
else
  aws logs filter-log-events --log-group-name "$LOG_GROUP" --region "$REGION" --start-time "$START_TIME" --query 'events[*].message' --output text | tail -50
fi
