#!/usr/bin/env bash
# Get PR review comments efficiently
# Usage: ~/.cursor/skills/gh/scripts/pr-comments.sh [PR_NUMBER] [--cursor-only] [REPO]
# Example: ~/.cursor/skills/gh/scripts/pr-comments.sh 1 --cursor-only
#          ~/.cursor/skills/gh/scripts/pr-comments.sh 1 "" OWNER/REPO

set -euo pipefail

PR_NUMBER="${1:-}"
FILTER_CURSOR="${2:-}"
REPO="${3:-}"

if [ -z "$PR_NUMBER" ]; then
  echo "Usage: $0 <PR_NUMBER> [--cursor-only] [REPO]"
  exit 1
fi

# Auto-detect repo from git remote if not provided
if [ -z "$REPO" ]; then
  if git rev-parse --git-dir >/dev/null 2>&1; then
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
    if [[ "$REMOTE_URL" =~ github.com[:/]([^/]+)/([^/]+)\.git ]]; then
      REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    else
      echo "Error: Could not detect repo from git remote. Please provide REPO argument."
      exit 1
    fi
  else
    echo "Error: Not in a git repo and REPO not provided."
    exit 1
  fi
fi

ENDPOINT="repos/$REPO/pulls/$PR_NUMBER/comments"

# Clean body: strip Cursor links, bug IDs, and normalize whitespace
CLEAN_BODY="(.body | gsub(\"<p><a[^>]*>.*?</a>.*?</p>\"; \"\") | gsub(\"<picture>.*?</picture>\"; \"\") | gsub(\"<!-- BUGBOT_BUG_ID:[^>]*-->\"; \"\") | gsub(\"&nbsp;\"; \" \") | gsub(\"\\\\s+\"; \" \") | trim)"

# Build jq expression based on whether we're filtering for Cursor bot
if [ "$FILTER_CURSOR" = "--cursor-only" ]; then
  JQ_EXPR="[.[] | select(.user.login == \"cursor[bot]\")] | .[] | {id, path, line, body: $CLEAN_BODY, created_at}"
else
  JQ_EXPR=".[] | {id, user: .user.login, path, line, body: $CLEAN_BODY, created_at}"
fi

# Output each comment as a single line (compact JSON) with essential fields only
# Strips Cursor links (Fix in Cursor/Web buttons) to save tokens
# Example: ~/.cursor/skills/gh/scripts/pr-comments.sh 1 --cursor-only | tail -n1
gh api "$ENDPOINT" --jq "$JQ_EXPR" | jq -c .
