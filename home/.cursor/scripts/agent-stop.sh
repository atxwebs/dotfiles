#!/bin/bash
# Agent stop hook - runs agent:stop script from package.json if it exists

input=$(cat)
status=$(echo "$input" | jq -r '.status')
loop_count=$(echo "$input" | jq -r '.loop_count')

# Only run on first completion (not on aborted/error or follow-up loops)
if [ "$status" != "completed" ] || [ "$loop_count" != "0" ]; then
  exit 0
fi

workspace=$(echo "$input" | jq -r '.workspace_roots[0]')
script_file="$workspace/package.json"

# Check if package.json exists and has agent:stop script
if [ -f "$script_file" ]; then
  agent_stop=$(jq -r '.scripts["agent:stop"] // empty' "$script_file" 2>/dev/null)
  if [ -n "$agent_stop" ]; then
    cd "$workspace"
    output=$(npm run -s agent:stop 2>&1)
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
      # Use jq to properly construct the JSON
      jq -n --arg msg "$output" '{"followup_message": ("Automated review, address unless truly unrelated to your changes:\n" + $msg)}'
      exit 0
    fi
  fi
fi

exit 0
