#!/bin/bash
# Lightpanda fetch wrapper with clean markdown output
# Usage: fetch.sh "URL" [additional lightpanda options]

if [ -z "$1" ]; then
    echo "Usage: fetch.sh \"URL\" [options]"
    exit 1
fi

URL="$1"
shift

# Fetch with default options, pass through additional args, cleanup output
# Note: lightpanda expects URL at the end
lightpanda fetch \
    --dump markdown \
    --wait_until networkidle \
    --wait_ms 5000 \
    "$@" \
    "$URL" 2>/dev/null | \
    # Remove log lines (start with $)
    grep -v '^\$' | \
    # Remove \r characters
    tr -d '\r' | \
    # Remove leading/trailing whitespace from each line
    sed 's/^[ \t]*//;s/[ \t]*$//' | \
    # Replace multiple newlines with double newline
    cat -s | \
    # Replace 2+ spaces with tab
    sed 's/  \+/\t/g'
