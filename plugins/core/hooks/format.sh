#!/bin/bash
# PostToolUse hook: Format files after Write or Edit operations
# Reads tool input from stdin to get file_path

# Read JSON from stdin
INPUT=$(cat)

# Extract file_path from tool_input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# Exit if no file path or file doesn't exist
[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Format the file (fail silently if prettier not available)
npx prettier --write "$FILE_PATH" 2>/dev/null || true

exit 0
