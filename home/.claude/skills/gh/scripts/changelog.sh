#!/usr/bin/env bash
# Get combined changelog text between a version and HEAD
# Usage: changelog.sh OWNER/REPO <since-tag> [per_page]
# Example: ~/.claude/skills/gh/scripts/changelog.sh ggml-org/llama.cpp b8778
#          ~/.claude/skills/gh/scripts/changelog.sh ollama/ollama v0.5.0 20
# Output: raw markdown release notes, newest first, separated by dividers

set -euo pipefail

REPO="${1:-}"
SINCE="${2:-}"
PER_PAGE="${3:-50}"

if [ -z "$REPO" ] || [ -z "$SINCE" ]; then
  echo "Usage: $0 OWNER/REPO <since-tag> [per_page]" >&2
  exit 1
fi

ENDPOINT="repos/$REPO/releases?per_page=$PER_PAGE"
FOUND_SINCE=0
PAGE=1

# Fetch newest page first (reverse chronological), print as we go
while [ "$FOUND_SINCE" -eq 0 ]; do
  PAGE_DATA=$(gh api "${ENDPOINT}&page=$PAGE")

  if [ -z "$PAGE_DATA" ] || [ "$(echo "$PAGE_DATA" | jq 'length')" -eq 0 ]; then
    break
  fi

  for i in $(jq -r 'keys[]' <<< "$PAGE_DATA"); do
    TAG=$(jq -r ".[$i].tag_name" <<< "$PAGE_DATA")
    if [ "$TAG" = "$SINCE" ]; then
      FOUND_SINCE=1
      break
    fi
    DATE=$(jq -r ".[$i].published_at" <<< "$PAGE_DATA" | cut -dT -f1)
    BODY=$(jq -r ".[$i].body // empty" <<< "$PAGE_DATA")
    # Strip boilerplate: download links, platform lists
    BODY_CLEAN=$(echo "$BODY" | sed -n '/^\*\*\(macOS\|Linux\|Android\|Windows\|openEuler\|iOS\|WebGPU\|OpenCL\|SYCL\|Vulkan\|CUDA\|ROCm\|HIP\|Intel\|Apple\|KleidiAI\)/,/^[A-Z]/!p')
    BODY_CLEAN=$(echo "$BODY_CLEAN" | sed -e '/^<details.*>$/d' -e '/^<\/details>$/d')
    # Skip if body is just boilerplate
    BODY_CLEAN=$(echo "$BODY_CLEAN" | sed '/^$/N;/^\n$/d')
    if [ -n "$BODY_CLEAN" ]; then
      echo "## $TAG ($DATE)"
      echo ""
      echo "$BODY_CLEAN"
      echo ""
      echo "---"
      echo ""
    fi
  done

  PAGE=$((PAGE + 1))
done
