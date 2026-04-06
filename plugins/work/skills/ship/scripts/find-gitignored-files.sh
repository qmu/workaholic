#!/bin/bash
# Discover gitignored files in a worktree that differ from the main repo root.
# Usage: bash find-gitignored-files.sh <worktree-path>
# Output: JSON with has_changes flag and file list
#
# Excludes reinstallable directories (node_modules, .venv, vendor/bundle, .cache, __pycache__).
# Each file entry includes: path (relative), status (new|modified), size.

set -euo pipefail

worktree_path="${1:-}"

if [ -z "$worktree_path" ]; then
  echo '{"error": "worktree path is required"}' >&2
  exit 1
fi

if [ ! -d "$worktree_path" ]; then
  echo '{"error": "worktree path does not exist", "path": "'"$worktree_path"'"}' >&2
  exit 1
fi

repo_root="$(git -C "$worktree_path" rev-parse --show-toplevel 2>/dev/null)"
main_root="$(git rev-parse --show-toplevel 2>/dev/null)"

# Get all gitignored files in the worktree, excluding reinstallable directories
ignored_files=$(git -C "$worktree_path" ls-files --others --ignored --exclude-standard 2>/dev/null | \
  grep -v -E '^(node_modules/|\.venv/|venv/|vendor/bundle/|\.cache/|__pycache__/|\.git/)' || true)

if [ -z "$ignored_files" ]; then
  echo '{"has_changes": false, "files": []}'
  exit 0
fi

files_json="["
first=true

while IFS= read -r rel_path; do
  wt_file="${worktree_path}/${rel_path}"
  main_file="${main_root}/${rel_path}"

  # Skip directories
  if [ -d "$wt_file" ]; then
    continue
  fi

  # Skip binary/large files (over 1MB)
  file_size=$(stat -c%s "$wt_file" 2>/dev/null || echo "0")
  if [ "$file_size" -gt 1048576 ]; then
    continue
  fi

  # Determine status
  if [ ! -f "$main_file" ]; then
    status="new"
  elif ! diff -q "$wt_file" "$main_file" >/dev/null 2>&1; then
    status="modified"
  else
    # Identical file, skip
    continue
  fi

  # Format size for display
  if [ "$file_size" -ge 1024 ]; then
    display_size="$((file_size / 1024))KB"
  else
    display_size="${file_size}B"
  fi

  if [ "$first" = true ]; then
    first=false
  else
    files_json="${files_json},"
  fi

  # Escape path for JSON
  escaped_path=$(echo "$rel_path" | sed 's/\\/\\\\/g; s/"/\\"/g')
  files_json="${files_json}{\"path\":\"${escaped_path}\",\"status\":\"${status}\",\"size\":\"${display_size}\"}"
done <<< "$ignored_files"

files_json="${files_json}]"

if [ "$first" = true ]; then
  echo '{"has_changes": false, "files": []}'
else
  echo "{\"has_changes\": true, \"files\": ${files_json}}"
fi
