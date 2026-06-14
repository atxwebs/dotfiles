#!/bin/bash
# File-based queue manager
# Usage: queue.sh <command> <queue-path> [data]
# Commands: add, peek, next, count
# Queue path is relative to $QUEUES_ROOT (e.g., prospects/US/Veterinary)

set -euo pipefail

CMD="${1:-}"
QUEUE_PATH="${2:-}"
DATA="${3:-}"

if [ -z "$QUEUES_ROOT" ]; then
  echo "Error: QUEUES_ROOT not set" >&2
  exit 1
fi

if [ -z "$CMD" ] || [ -z "$QUEUE_PATH" ]; then
  echo "Usage: queue.sh <add|peek|next|count> <queue-path> [data]"
  echo "Example: queue.sh add prospects/US/Veterinary '{\"name\":\"Dr Smith\"}'"
  exit 1
fi

QUEUE_DIR="$QUEUES_ROOT/$(dirname "$QUEUE_PATH")"
QUEUE_FILE="$QUEUES_ROOT/$QUEUE_PATH.jsonl"
LOCK_FILE="$QUEUE_FILE.lock"

mkdir -p "$QUEUE_DIR"

case "$CMD" in
  add)
    if [ -z "$DATA" ]; then
      echo "Error: add requires data argument"
      exit 1
    fi
    
    # Use flock for atomic append if available
    if command -v flock >/dev/null 2>&1; then
      (
        flock -x 200
        printf '%s\n' "$DATA" >> "$QUEUE_FILE"
      ) 200>"$LOCK_FILE"
    else
      printf '%s\n' "$DATA" >> "$QUEUE_FILE"
    fi
    ;;
    
  peek)
    if [ ! -f "$QUEUE_FILE" ] || [ ! -s "$QUEUE_FILE" ]; then
      exit 1
    fi
    head -n 1 "$QUEUE_FILE"
    ;;
    
  next)
    if [ ! -f "$QUEUE_FILE" ] || [ ! -s "$QUEUE_FILE" ]; then
      exit 1
    fi
    
    if command -v flock >/dev/null 2>&1; then
      (
        flock -x 200
        head -n 1 "$QUEUE_FILE"
        tail -n +2 "$QUEUE_FILE" > "$QUEUE_FILE.tmp"
        mv "$QUEUE_FILE.tmp" "$QUEUE_FILE"
      ) 200>"$LOCK_FILE"
    else
      head -n 1 "$QUEUE_FILE"
      tail -n +2 "$QUEUE_FILE" > "$QUEUE_FILE.tmp"
      mv "$QUEUE_FILE.tmp" "$QUEUE_FILE"
    fi
    ;;
    
  count)
    if [ ! -f "$QUEUE_FILE" ] || [ ! -s "$QUEUE_FILE" ]; then
      echo "0"
      exit 0
    fi
    wc -l < "$QUEUE_FILE" | tr -d ' '
    ;;
    
  dump)
    if [ ! -f "$QUEUE_FILE" ]; then
      exit 0
    fi
    cat "$QUEUE_FILE"
    ;;
    
  *)
    echo "Unknown command: $CMD"
    echo "Commands: add, peek, next, count, dump"
    exit 1
    ;;
esac
