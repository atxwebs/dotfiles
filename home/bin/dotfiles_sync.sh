#!/bin/bash
set -euo pipefail

REPO=~/Code/dotfiles/home

# Unified sync entries: files/globs from ~/ or directories
# Format: "path" or "path:patterns"
# - If path starts with ~/, it's a directory (or specific file path)
# - Otherwise, it's a root file/glob from ~/
# Patterns format:
#   For root files: "glob:exclude1:exclude2:..." (exclusions)
#   For directories: "source:include1,include2:exclude" (includes, then exclude)
SYNC_ENTRIES=(
    # Root files/globs
    ".bash*:*history*:*extras*"
    ".*rc"
    ".profile"
    ".gitconfig"
    ".cursor/mcp.json"
    ".config/starship.toml"
    ".config/Cursor/User/"{settings,keybindings}.json
    # Directories
    "~/bin:*.sh,*.js:*"
    "~/.cursor/"{bin,skills,rules}
    "~/.config/"{yazi,kitty}
)

rsync_output=""
root_exclude_args=()
root_include_args=()

for entry in "${SYNC_ENTRIES[@]}"; do
    IFS=':' read -ra parts <<< "$entry"
    path="${parts[0]}"
    
    # Check if it's a directory (starts with ~/)
    if [[ "$path" =~ ^~ ]]; then
        # Directory sync
        source_expanded="${path/#\~/$HOME}"
        # Remove ~ prefix (handle both ~/path and ~path)
        dest_relative="${path#\~}"
        dest_relative="${dest_relative#/}"  # Remove leading / if present
        dest_path="$REPO/$dest_relative"
        
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
                "$source_expanded/" "$dest_path/" 2>&1)
        else
            rsync_output+=$(rsync -av --delete "$source_expanded/" "$dest_path/" 2>&1)
        fi
        rsync_output+=$'\n'
    else
        # Root file/glob - collect for single rsync
        if [ ${#parts[@]} -gt 1 ]; then
            # Has exclusions
            for i in $(seq 1 $((${#parts[@]} - 1))); do
                if [ -n "${parts[$i]}" ]; then
                    root_exclude_args+=("--exclude=${parts[$i]}")
                fi
            done
        fi
        root_include_args+=("--include=$path")
    fi
done

# Sync all root files in one rsync call
if [ ${#root_include_args[@]} -gt 0 ]; then
    rsync_output+=$(rsync -av --delete "${root_exclude_args[@]}" "${root_include_args[@]}" --exclude="*" ~/ "$REPO" 2>&1)
    rsync_output+=$'\n'
fi

# Filter and display output once
echo "$rsync_output" | awk '/^sending incremental file list/{flag=1; next} 
     flag && /^(sent|total|building|file list|created directory)/{flag=0; next} 
     flag && /^\.\//{next} 
     flag && length > 0 {print}'
