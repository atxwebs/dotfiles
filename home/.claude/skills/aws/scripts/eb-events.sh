#!/bin/bash
# Get recent Elastic Beanstalk environment events
# Usage: eb-events.sh <app-name> <env-name> [count] [region]
set -euo pipefail
[ $# -ge 2 ] || { echo "Usage: $0 <app-name> <env-name> [count] [region]" >&2; exit 1; }
APP_NAME="$1"
ENV_NAME="$2"
COUNT="${3:-10}"
REGION="${4:-${AWS_REGION:-us-east-1}}"
aws elasticbeanstalk describe-events --application-name "$APP_NAME" --environment-name "$ENV_NAME" --region "$REGION" --max-items "$COUNT" --query 'Events[*].[EventDate,Severity,Message]' --output table
