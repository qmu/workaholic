#!/bin/sh -eu
# Find the project's CLAUDE.md (carries the ## Deploy / ## Verify sections).
# Usage: sh find-claude-md.sh
# Output: JSON with path if found, or {"found": false}

set -eu

for candidate in "./CLAUDE.md"; do
  if [ -f "$candidate" ]; then
    echo '{"found": true, "path": "'"$candidate"'"}'
    exit 0
  fi
done

echo '{"found": false}'
