#!/bin/bash
# Lightpanda DuckDuckGo search wrapper
# Usage: search.sh "search query" [additional lightpanda options]

if [ -z "$1" ]; then
    echo "Usage: search.sh \"search query\" [options]"
    exit 1
fi

# Escape the query for URL
QUERY=$(echo "$1" | sed 's/ /+/g' | sed 's/?/%3F/g' | sed 's/&/%26/g')
URL="https://duckduckgo.com/?q=${QUERY}"

# Shift query and pass remaining args to fetch.sh
shift

# Fetch and extract only organic search results (clean format)
~/.claude/skills/lightpanda/scripts/fetch.sh "$URL" "$@" | \
    # Extract just the numbered results with ### titles and their links
    grep -E '^(###|[0-9]+\.$)' | \
    # Join numbers with titles
    awk '
        /^[0-9]+\.$/ {num=$0; next}
        num != "" {print num " " $0; num=""}
    ' | \
    # Remove trailing empty lines
    sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
