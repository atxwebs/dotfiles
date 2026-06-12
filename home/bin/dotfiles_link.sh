#!/bin/bash
set -euo pipefail

DRY_RUN=true
if [[ "${1:-}" == "--execute" ]]; then
    DRY_RUN=false
else
    echo "=== DRY RUN (use --execute to apply changes) ==="
fi

REPO="$HOME/Code/dotfiles/home"

# All paths relative to ~, matching the old sync entries
PATHS=(
    ".bash_aliases"
    ".bash_cursor"
    ".bash_exports"
    ".bash_functions"
    ".bash_git"
    ".bash_login"
    ".bash_logout"
    ".bash_options"
    ".bash_pi"
    ".bash_profile"
    ".bash_prompt"
    ".bashrc"
    ".curlrc"
    ".gitconfig"
    ".keynavrc"
    ".nanorc"
    ".profile"
    ".ripgreprc"
    ".serverlessrc"
    ".xinputrc"
    ".config/starship.toml"
    ".config/Cursor/User/settings.json"
    ".config/Cursor/User/keybindings.json"
    ".claude/mcp.json"
    ".cursor/hooks.json"
    "bin/backup.sh"
    "bin/cursor-clear.sh"
    "bin/cursor-projects.sh"
    "bin/disable-keyboard.js"
    "bin/disable-keyboard.sh"
    "bin/dotfiles_link.sh"
    "bin/gc.sh"
    "bin/import-assets.sh"
    "bin/os-update.sh"
    "bin/prune-cursor-db.sh"
    "bin/recover_from_backup.sh"
    "bin/reorganize-by-dir.sh"
    "bin/restore-projects.sh"
    "bin/subs.js"
    "bin/telegram-wrapper.sh"
    "bin/toggle-mic.sh"
    "bin/trigger.sh"
    "bin/z.sh"
    ".claude/skills"
    ".claude/rules"
    ".claude/commands"
    ".claude/agents"
    ".cursor/scripts"
    ".config/yazi"
    ".config/kitty"
)

# Compare two files
files_equal() {
    cmp -s "$1" "$2"
}

# Compare two directories recursively
dirs_equal() {
    diff -rq "$1" "$2" > /dev/null 2>&1 || [[ $? -eq 1 ]]
}

# List differing files in directories
list_diff_files() {
    diff -rq "$1" "$2" 2>/dev/null | head -20 || true
}

# Create symlink from repo to home
do_symlink() {
    local src="$1"  # in repo
    local dst="$2"  # in ~

    if $DRY_RUN; then
        echo "[dry-run] ln -sf $src -> $dst"
        return
    fi

    ln -sf "$src" "$dst"
}

# Prompt user for confirmation (default: yes)
confirm() {
    local prompt="$1"
    local answer
    read -p "$prompt [Y/n] " answer
    [[ "$answer" =~ ^[Nn]$ ]] && return 1
    return 0
}

process_path() {
    local rel="$1"
    local src="$REPO/$rel"
    local dst="$HOME/$rel"

    if [[ ! -e "$src" ]]; then
        echo "SKIP (not in repo): $rel"
        return
    fi

    # 1. Already a symlink to repo
    if [[ -L "$dst" ]]; then
        local target
        target="$(readlink -f "$dst")"
        if [[ "$target" == "$(readlink -f "$src")" ]]; then
            echo "OK (already linked): $rel"
        else
            echo "LINKED ELSEWHERE: $rel -> $target"
        fi
        return
    fi

    # 2. Target doesn't exist
    if [[ ! -e "$dst" ]]; then
        echo "LINK (missing): $rel"
        mkdir -p "$(dirname "$dst")"
        do_symlink "$src" "$dst"
        return
    fi

    # 3. Both exist - file case
    if [[ -f "$src" && -f "$dst" ]]; then
        if files_equal "$src" "$dst"; then
            echo "LINK (equal): $rel"
            if ! $DRY_RUN; then
                rm "$dst"
                do_symlink "$src" "$dst"
            fi
        else
            if $DRY_RUN; then
                echo "DIFFER (would prompt): $rel"
            elif confirm "DIFFER: $rel — replace?"; then
                rm "$dst"
                do_symlink "$src" "$dst"
            else
                echo "SKIP: $rel"
            fi
        fi
        return
    fi

    # 4. Both exist - directory case
    if [[ -d "$src" && -d "$dst" ]]; then
        if dirs_equal "$src" "$dst"; then
            echo "LINK (dirs equal): $rel"
            if ! $DRY_RUN; then
                rm -rf "$dst"
                do_symlink "$src" "$dst"
            fi
        else
            echo "DIFFER: $rel"
            list_diff_files "$src" "$dst"
            if $DRY_RUN; then
                echo "(would prompt to replace directory)"
            elif confirm "Replace directory $rel?"; then
                rm -rf "$dst"
                do_symlink "$src" "$dst"
            else
                echo "SKIP: $rel"
            fi
        fi
        return
    fi

    echo "TYPE MISMATCH: $rel (src=$(file -b "$src" | cut -d, -f1), dst=$(file -b "$dst" | cut -d, -f1))"
}

echo ""
for p in "${PATHS[@]}"; do
    process_path "$p"
done
echo ""
echo "Done."
