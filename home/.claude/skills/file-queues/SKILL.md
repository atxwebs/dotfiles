# File Queues

File-based queue system for managing work items across multiple agents.

## Usage

Set `QUEUES_ROOT` to your queue directory, then call the script:

```bash
QUEUES_ROOT=inputs/queues ~/.claude/skills/file-queues/scripts/queue.sh add prospects/US/Veterinary '{"name":"Dr. Smith","source":"https://example.com"}'
```

## Commands

- `add <path> <json>` - Add item to queue (FIFO)
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
