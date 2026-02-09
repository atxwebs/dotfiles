#!/bin/bash
# Get latest GitHub Actions run status
set -euo pipefail
GIT_CONFIG_NOSYSTEM=1 gh run list --limit 1 --json conclusion,status,displayTitle,createdAt,databaseId --jq '.[] | "\(.status)|\(.conclusion)|\(.displayTitle)|\(.databaseId)"'
