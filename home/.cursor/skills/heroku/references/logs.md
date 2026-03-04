# Heroku Logs

## Basic Usage
```bash
heroku logs --num 100 | grep <pattern>
```

## Important Notes
- **NEVER use `--tail`** - it keeps connection open and hangs
- Use `--num N` to fetch last N lines (e.g., `--num 100`)
- The `--app` flag is not needed - Heroku CLI uses implicit app context

## Common Patterns
```bash
# Get logs around a specific time (filter with grep)
heroku logs --num 100 | grep "2025-11-05.*19:4[01]"

# Search for specific message IDs or user IDs
heroku logs --num 100 | grep -E "(121086|1679315655)"

# Find why bot didn't reply (look for "ignore", "Newer message exists", etc.)
heroku logs --num 100 | grep -i -E "(ignore|Newer message exists|discarding)"

# Check for errors around a timestamp
heroku logs --num 100 | grep -E "(2025-11-05.*19:3[89]|2025-11-05.*19:4[01])" | grep -i error
```
