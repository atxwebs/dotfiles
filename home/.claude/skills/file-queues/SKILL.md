---
name: file-queues
description: Read when managing JSONL file-based work queues across agents.
---

# File Queues

File-based queue system for managing work items across multiple agents.

## Usage

`QUEUES_ROOT` defaults to current directory if not set. Queue paths are relative to `QUEUES_ROOT`:

```bash
# Single item
~/.claude/skills/file-queues/scripts/queue.sh add prospects/US/Veterinary '{"name":"Dr. Smith"}'

# Multiple items as arguments
~/.claude/skills/file-queues/scripts/queue.sh add prospects/US/Veterinary '{"name":"Dr. A"}' '{"name":"Dr. B"}'

# Multiple items via stdin
echo '{"name":"Dr. A"}
{"name":"Dr. B"}' | ~/.claude/skills/file-queues/scripts/queue.sh add prospects/US/Veterinary

# Multiple items via heredoc
~/.claude/skills/file-queues/scripts/queue.sh add prospects/US/Veterinary <<EOF
{"name":"Dr. A"}
{"name":"Dr. B"}
EOF
```

## Commands

- `add <path> [json...]` - Add item(s) to queue (FIFO). Accepts multiple arguments or stdin.
- `next <path>` - Get and remove next item from queue
- `peek <path>` - View next item without removing it
- `count <path>` - Count items in queue
- `dump <path>` - Output all items in queue (cat the file)

## Path Structure

Queue paths are relative to `QUEUES_ROOT` and create nested directories:
- `prospects/US/Veterinary` → `inputs/queues/prospects/US/Veterinary.jsonl`
- `searches/AR/Dentistry` → `inputs/queues/searches/AR/Dentistry.jsonl`

## Data Format

Each queue is a JSONL file (one JSON object per line). Format is flexible - agents decide what fields to include.

## Concurrency

Uses `flock` for atomic operations when multiple agents access the same queue simultaneously.
