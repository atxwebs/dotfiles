#!/bin/bash
set -euo pipefail

REPO=~/Code/dotfiles/home

# All paths are relative to ~
# Format: "path" or "path:patterns"
#   For files: just the path
#   For directories: "path:include1,include2:exclude" (includes, then exclude)
SYNC_ENTRIES=(
    # Files/globs
    ".bash*:*history*:*extras*"
    ".*rc"
    ".profile"
    ".gitconfig"
    ".config/starship.toml"
    ".config/Cursor/User/"{settings,keybindings}.json
    # Directories
    "bin:*.sh,*.js:*"
    ".claude/"{skills,rules,commands,mcp.json,agents,.skills}
    ".cursor/"{scripts,hooks.json}
    ".config/"{yazi,kitty}
)

rsync_output=""

for entry in "${SYNC_ENTRIES[@]}"; do
    IFS=':' read -ra parts <<< "$entry"
    path="${parts[0]}"
    source_path="$HOME/$path"
    
    # Check if it's a glob pattern (has * or {})
    if [[ "$path" == *"*"* ]] || [[ "$path" == *"{"* ]]; then
        # Use rsync's include/exclude for glob patterns
        dest_dir="$REPO/$(dirname "$path")"
        mkdir -p "$dest_dir"
        
        include_args=("--include=$path")
        exclude_args=()
        
        # Add exclusions if present
        if [ ${#parts[@]} -gt 1 ]; then
            for i in $(seq 1 $((${#parts[@]} - 1))); do
                if [ -n "${parts[$i]}" ]; then
                    exclude_args+=("--exclude=${parts[$i]}")
                fi
            done
        fi
        
        # Expand braces for include pattern
        if [[ "$path" == *"{"* ]]; then
            # Handle brace expansion - create separate includes
            include_args=()
            for expanded in $source_path; do
                rel_path="${expanded#$HOME/}"
                include_args+=("--include=$rel_path")
            done
        fi
        
        rsync_output+=$(rsync -av "${exclude_args[@]}" "${include_args[@]}" --exclude="*" \
            "$HOME/" "$REPO" 2>&1)
        rsync_output+=$'\n'
    elif [ -f "$source_path" ]; then
        # Single file
        dest_path="$REPO/$path"
        mkdir -p "$(dirname "$dest_path")"
        rsync_output+=$(rsync -av "$source_path" "$dest_path" 2>&1)
        rsync_output+=$'\n'
    elif [ -d "$source_path" ]; then
        # Directory sync
        dest_path="$REPO/$path"
        mkdir -p "$dest_path"
        
        include_patterns="${parts[1]:-}"
        exclude_pattern="${parts[2]:-*}"
        
        if [ -n "$include_patterns" ]; then
            include_args=()
            IFS=',' read -ra patterns <<< "$include_patterns"
            
            has_wildcard=false
            specific_patterns=()
            
            for pattern in "${patterns[@]}"; do
                if [ "$pattern" = "*" ]; then
                    has_wildcard=true
                else
                    specific_patterns+=("--include=$pattern")
                fi
            done
            
            include_args+=("${specific_patterns[@]}")
            
            if [ "$has_wildcard" = true ]; then
                include_args+=("--exclude=*.*" "--include=*")
            fi
            
            rsync_output+=$(rsync -av --delete --delete-excluded "${include_args[@]}" --exclude="$exclude_pattern" \
                "$source_path/" "$dest_path/" 2>&1)
        else
            rsync_output+=$(rsync -av --delete "$source_path/" "$dest_path/" 2>&1)
        fi
        rsync_output+=$'\n'
    else
        echo "Warning: $source_path does not exist, skipping" >&2
    fi
done

# Filter and display output once
echo "$rsync_output" | awk '/^sending incremental file list/{flag=1; next} 
     flag && /^(sent|total|building|file list|created directory)/{flag=0; next} 
     flag && /^\.\//{next} 
     flag && length > 0 {print}'
