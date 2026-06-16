#!/bin/bash

# Backup Cursor projects folder (agent-transcripts only)
# Excludes: terminals/, agent-tools/, mcps/, mcp-cache.json (noise, not useful for fine-tuning)
# Uses -u to update existing archive safely (won't delete files no longer on disk)
OUT=$HOME/Backup/Cursor/cursor-projects.zip
cd ~/.cursor/projects

zip -ru -9 "$OUT" . -x "*/terminals/*" -x "*/agent-tools/*" -x "*/mcps/*" -x "*/mcp-cache.json"
echo "Cursor projects backup created at $OUT (agent-transcripts only)"

# Backup Claude Code projects folder (conversation transcripts)
OUT=$HOME/Backup/Cursor/claude-projects.zip
cd ~/.claude/projects && zip -ru -9 "$OUT" .
echo "Claude Code projects backup created at $OUT"

# Export historical SQL chat conversations (Jan 2024 - May 2025)
# Default: false (already exported once, historical data doesn't change)
BACKUP_SQL=${BACKUP_SQL:-false}

if [ "$BACKUP_SQL" = "false" ]; then
  echo "Skipping SQL chat export (historical archive, set BACKUP_SQL=true to re-export)"
  exit 0
fi

echo "Exporting historical Cursor chat conversations (2024-2025)..."

DB="$HOME/.config/Cursor/User/globalStorage/state.vscdb"
OUTPUT_DIR="/tmp/cursor-chats-historical"

# Clean and create output directory
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

if [ ! -f "$DB" ]; then
  echo "Error: Cursor database not found at $DB"
  exit 1
fi

# Export only meaningful composer sessions (skip empty/tiny ones)
sqlite3 -readonly "$DB" "
SELECT key, value FROM cursorDiskKV WHERE key LIKE 'composerData:%';
" | while IFS='|' read -r key value; do
  # Extract metadata using jq
  composer_id=$(echo "$value" | jq -r '.composerId // empty' 2>/dev/null)
  [ -z "$composer_id" ] && continue
  
  # Skip if no conversation array or empty conversation
  has_conv=$(echo "$value" | jq -r 'if .conversation and (.conversation | length) > 0 then "yes" else "no" end' 2>/dev/null)
  [ "$has_conv" = "no" ] && continue
  
  name=$(echo "$value" | jq -r '.name // empty' 2>/dev/null)
  created_at=$(echo "$value" | jq -r '.createdAt // 0' 2>/dev/null)
  updated_at=$(echo "$value" | jq -r '.lastUpdatedAt // 0' 2>/dev/null)
  
  # Calculate total text length across all conversation turns
  total_text=$(echo "$value" | jq -r '[.conversation[]? | .text // ""] | join(" ") | length' 2>/dev/null)
  
  # Skip sessions with <500 chars (tiny/meaningless)
  [ "$total_text" -lt 500 ] && continue
  
  # Extract first file path from ANY conversation turn
  first_file=$(echo "$value" | jq -r '
    [.conversation[]? | 
      (.context.fileSelections[]?.uri.path // empty),
      (.context.fileSelections[]?.uri.fsPath // empty),
      (.context.mentions.fileSelections[]?.uri.path // empty),
      (.context.mentions.folderSelections[]? // empty)
    ] | map(select(length > 0 and . != "Untitled-*" and . != "")) | .[0] // empty
  ' 2>/dev/null)
  
  # Determine project from file path or use "other"
  project="other"
  if [ -n "$first_file" ] && [[ "$first_file" != "Untitled"* ]]; then
    if [[ "$first_file" =~ /Code/([^/]+)/([^/]+) ]]; then
      project="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}"
    elif [[ "$first_file" =~ $HOME/Code/([^/]+) ]]; then
      project="${BASH_REMATCH[1]}"
    fi
  fi
  
  # Create project directory
  project_dir="$OUTPUT_DIR/$project"
  mkdir -p "$project_dir"
  
  # Sanitize session name for filename
  safe_name=$(echo "$name" | tr -cd '[:alnum:]_ -' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | head -c 50)
  [ -z "$safe_name" ] && safe_name="unnamed-session"
  
  # Create filename with timestamp for chronological sorting
  filename="${project_dir}/${updated_at:-0000000000000}_${composer_id}_${safe_name}.txt"
  
  # Write conversation with metadata
  {
    echo "=== Session: $composer_id ==="
    echo "Name: $name"
    echo "Project: $project"
    echo "File: $first_file"
    echo "Created: $(date -d "@$((created_at / 1000))" 2>/dev/null || echo "$created_at")"
    echo "Updated: $(date -d "@$((updated_at / 1000))" 2>/dev/null || echo "$updated_at")"
    echo ""
    echo "=== Conversation ==="
    
    # Extract and format conversation turns
    echo "$value" | jq -r '
      .conversation[]? |
      "\n--- \(if .type == 1 then "USER" else "AI" end) ---\n\(.text // "")"
    ' 2>/dev/null || echo "[Failed to parse JSON]"
  } > "$filename"
done

# Count exported sessions
session_count=$(find "$OUTPUT_DIR" -name "*.txt" | wc -l)
project_count=$(find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)
echo "Exported $session_count historical chat sessions (2024-2025) across $project_count projects to $OUTPUT_DIR"

# Create compressed archive
echo "Creating compressed archive..."
cd "$OUTPUT_DIR" && zip -ru -9 ~/Backup/Cursor/sql-chats.zip .
echo "Done! Historical archive created at $HOME/Backup/Cursor/sql-chats.zip"