#!/bin/sh

# Cursor has a SQLite that grows and grows, it was 10GB. This prunes old conversations
# Strategy:
# 1. Delete composerData > 1 month old (has timestamps)
# 2. Delete orphaned checkpoints (not referenced by any bubble)
# 3. Keep only the most recent N conversation sessions
# 4. VACUUM and checkpoint WAL to reclaim space

DB=~/.config/Cursor/User/globalStorage/state.vscdb
KEEP_SESSIONS=${KEEP_SESSIONS:-100}  # Default: keep 100 most recent sessions

PRUNE_SESSIONS=false

echo "Starting Cursor DB pruning..."
echo "Database: $DB"
echo "Keeping $KEEP_SESSIONS most recent sessions"

# Get initial size
INITIAL_SIZE=$(ls -lh "$DB" | awk '{print $5}')
echo "Initial size: $INITIAL_SIZE"

# Step 1: Delete old composerData (has timestamps)
echo "Step 1: Deleting composerData older than 1 month..."
sqlite3 $DB "
DELETE FROM cursorDiskKV
WHERE key LIKE 'composerData:%'
  AND CAST(json_extract(value, '$.lastUpdatedAt') AS INTEGER) <= (strftime('%s','now','-1 month') * 1000);
"

if [ "$PRUNE_SESSIONS" = "true" ]; then
  # Step 2: Keep only most recent N conversation sessions
  # Note: SQLite doesn't have a natural "recent" order without timestamps
  # We'll keep sessions that have the most bubble entries (most active)
  echo "Step 2: Keeping only $KEEP_SESSIONS most active conversation sessions..."
  sqlite3 $DB "
  DELETE FROM cursorDiskKV
  WHERE key LIKE 'bubbleId:%'
    AND substr(key, instr(key, ':') + 1, 36) NOT IN (
      SELECT substr(key, instr(key, ':') + 1, 36) as session_id
      FROM cursorDiskKV
      WHERE key LIKE 'bubbleId:%'
      GROUP BY session_id
      ORDER BY COUNT(*) DESC
      LIMIT $KEEP_SESSIONS
    );
  "
fi

# Step 3: Delete orphaned checkpoints
echo "Step 3: Deleting orphaned checkpoints..."
sqlite3 $DB "
DELETE FROM cursorDiskKV
WHERE key LIKE 'checkpointId:%'
  AND substr(key, instr(key, ':') + 1, 36) NOT IN (
    SELECT DISTINCT json_extract(value, '$.checkpointId')
    FROM cursorDiskKV
    WHERE key LIKE 'bubbleId:%'
      AND json_extract(value, '$.checkpointId') IS NOT NULL
  );
"


# Step 4: VACUUM to reclaim space
echo "Step 4: Running VACUUM (this may take a while)..."
sqlite3 $DB "VACUUM;"

# Step 5: Checkpoint WAL to merge back into main DB
echo "Step 5: Checkpointing WAL file..."
sqlite3 $DB "PRAGMA wal_checkpoint(TRUNCATE);"

# Get final size
FINAL_SIZE=$(ls -lh "$DB" | awk '{print $5}')
echo "Final size: $FINAL_SIZE"
echo "Pruning complete!"
