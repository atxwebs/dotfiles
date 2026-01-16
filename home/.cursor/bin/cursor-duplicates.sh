#!/bin/bash

# Script to match rules and commands in .cursor/ to those in ~/.cursor/. Run from any project directory
# Usage: ~/.cursor/cursor-duplicates.sh [--delete]

# Use current working directory (where script is called from)
PROJECT_ROOT="${PWD}"
LOCAL_RULES_DIR="${PROJECT_ROOT}/.cursor/rules"
GLOBAL_RULES_DIR="$HOME/.cursor/rules"
LOCAL_COMMANDS_DIR="${PROJECT_ROOT}/.cursor/commands"
GLOBAL_COMMANDS_DIR="$HOME/.cursor/commands"

HAS_MATCHES=false

# Function to find and display matching files
find_matches() {
  local local_dir="$1"
  local global_dir="$2"
  local type_name="$3"
  
  if [ ! -d "$local_dir" ] || [ ! -d "$global_dir" ]; then
    return 0
  fi
  
  local matching_files=()
  
  # Find matching files (support both .mdc and .md extensions)
  for ext in mdc md; do
    for file in "$local_dir"/*."$ext"; do
      # Skip if no matches found (glob didn't expand)
      [ ! -f "$file" ] && continue
      filename=$(basename "$file")
      if [ -f "$global_dir/$filename" ]; then
        matching_files+=("$filename")
      fi
    done
  done
  
  if [ ${#matching_files[@]} -gt 0 ]; then
    HAS_MATCHES=true
    echo "Matching $type_name found:"
    for file in "${matching_files[@]}"; do
      echo "  - $file"
    done
    
    # Delete if --delete flag is provided
    if [ "$DELETE_FLAG" == "true" ]; then
      echo ""
      echo "Deleting matching $type_name from local directory..."
      for file in "${matching_files[@]}"; do
        local_file="$local_dir/$file"
        if [ -f "$local_file" ]; then
          rm "$local_file"
          echo "  Deleted: $local_file"
        fi
      done
    fi
    echo ""
  fi
}

# Check for --delete flag
DELETE_FLAG="false"
if [ "$1" == "--delete" ]; then
  DELETE_FLAG="true"
fi

# Process rules
find_matches "$LOCAL_RULES_DIR" "$GLOBAL_RULES_DIR" "rules"

# Process commands
find_matches "$LOCAL_COMMANDS_DIR" "$GLOBAL_COMMANDS_DIR" "commands"

# Display summary
if [ "$HAS_MATCHES" == "false" ]; then
  echo "No matching files found between local and global directories."
  exit 0
fi

if [ "$DELETE_FLAG" == "false" ]; then
  echo "To delete these files, run: $0 --delete"
fi

if [ "$DELETE_FLAG" == "true" ]; then
  echo "Done."
fi
