#!/bin/bash
# Copy gitignored files from a worktree to the main repo root.
# Usage: bash sync-gitignored-files.sh <worktree-path> <main-repo-root> '<files-json>'
# Output: JSON with sync status and copied file list
#
# <files-json> is a JSON array of relative paths, e.g.: '["path/to/.env","path/to/.local.md"]'

set -euo pipefail

worktree_path="${1:-}"
main_root="${2:-}"
files_json="${3:-}"

if [ -z "$worktree_path" ] || [ -z "$main_root" ] || [ -z "$files_json" ]; then
  echo '{"error": "usage: sync-gitignored-files.sh <worktree-path> <main-repo-root> <files-json>"}' >&2
  exit 1
fi

if [ ! -d "$worktree_path" ]; then
  echo '{"error": "worktree path does not exist"}' >&2
  exit 1
fi

# Parse file paths from JSON array using sed (no jq dependency)
# Handles: ["path1","path2"] -> path1\npath2
file_list=$(echo "$files_json" | sed 's/^\[//;s/\]$//;s/","/"\n"/g' | sed 's/^"//;s/"$//' | sed '/^$/d')

if [ -z "$file_list" ]; then
  echo '{"synced": true, "count": 0, "files": []}'
  exit 0
fi

synced_files="["
count=0
first=true
warnings=""

while IFS= read -r rel_path; do
  src="${worktree_path}/${rel_path}"
  dst="${main_root}/${rel_path}"

  if [ ! -f "$src" ]; then
    continue
  fi

  # Check for conflicts (main has a different version)
  if [ -f "$dst" ] && ! diff -q "$src" "$dst" >/dev/null 2>&1; then
    # Overwrite with worktree version (user chose to sync)
    :
  fi

  # Create parent directory if needed
  dst_dir=$(dirname "$dst")
  mkdir -p "$dst_dir"

  cp "$src" "$dst"
  count=$((count + 1))

  if [ "$first" = true ]; then
    first=false
  else
    synced_files="${synced_files},"
  fi

  escaped_path=$(echo "$rel_path" | sed 's/\\/\\\\/g; s/"/\\"/g')
  synced_files="${synced_files}\"${escaped_path}\""
done <<< "$file_list"

synced_files="${synced_files}]"

echo "{\"synced\": true, \"count\": ${count}, \"files\": ${synced_files}}"
