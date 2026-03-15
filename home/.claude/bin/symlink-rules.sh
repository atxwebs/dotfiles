#!/bin/bash

# Script to symlink rules from ~/.cursor/rules/ to current project's .cursor/rules/
# Usage: ~/.cursor/symlink-rules.sh
# Run from any project directory

PROJECT_ROOT="${PWD}"
LOCAL_RULES_DIR="${PROJECT_ROOT}/.cursor/rules"
GLOBAL_RULES_DIR="$HOME/.cursor/rules"
GITIGNORE="${PROJECT_ROOT}/.gitignore"

# Create local rules directory if it doesn't exist
if [ ! -d "$LOCAL_RULES_DIR" ]; then
  mkdir -p "$LOCAL_RULES_DIR"
  echo "Created directory: $LOCAL_RULES_DIR"
fi

if [ ! -d "$GLOBAL_RULES_DIR" ]; then
  echo "Error: Global rules directory '$GLOBAL_RULES_DIR' does not exist"
  exit 1
fi

# Symlink each rule file if it doesn't exist locally
SYMLINKED_COUNT=0
SKIPPED_COUNT=0

for file in "$GLOBAL_RULES_DIR"/*.mdc; do
  if [ -f "$file" ]; then
    filename=$(basename "$file")
    local_file="$LOCAL_RULES_DIR/$filename"
    gitignore_entry=".cursor/rules/$filename"
    
    if [ -f "$local_file" ] || [ -L "$local_file" ]; then
      echo "Skipped: $filename (already exists)"
      ((SKIPPED_COUNT++))
      
      # If it's a symlink, ensure it's in .gitignore
      if [ -L "$local_file" ]; then
        if [ -f "$GITIGNORE" ] && ! grep -q "^${gitignore_entry}$" "$GITIGNORE"; then
          echo "$gitignore_entry" >> "$GITIGNORE"
          echo "  Added to .gitignore"
        fi
      fi
    else
      ln -s "$file" "$local_file"
      echo "Symlinked: $filename"
      ((SYMLINKED_COUNT++))
      
      # Add symlinked file to .gitignore if not already present
      if [ -f "$GITIGNORE" ] && ! grep -q "^${gitignore_entry}$" "$GITIGNORE"; then
        echo "$gitignore_entry" >> "$GITIGNORE"
        echo "  Added to .gitignore"
      fi
    fi
  fi
done

echo ""
echo "Summary: $SYMLINKED_COUNT symlinked, $SKIPPED_COUNT skipped"
