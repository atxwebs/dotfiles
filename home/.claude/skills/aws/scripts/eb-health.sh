#!/bin/bash
# Get Elastic Beanstalk environment health
# Usage: eb-health.sh <app-name> <env-name> [region]
set -euo pipefail
[ $# -ge 2 ] || { echo "Usage: $0 <app-name> <env-name> [region]" >&2; exit 1; }
APP_NAME="$1"
ENV_NAME="$2"
REGION="${3:-${AWS_REGION:-us-east-1}}"
aws elasticbeanstalk describe-environments --application-name "$APP_NAME" --environment-names "$ENV_NAME" --region "$REGION" --query 'Environments[0].[Status,Health,HealthStatus,CNAME]' --output table
