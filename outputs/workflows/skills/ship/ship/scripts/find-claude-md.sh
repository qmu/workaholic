#!/bin/bash
# Find the project's CLAUDE.md (carries the ## Deploy / ## Verify sections).
# Usage: bash find-claude-md.sh
# Output: JSON with path if found, or {"found": false}

set -euo pipefail

for candidate in "./CLAUDE.md"; do
  if [ -f "$candidate" ]; then
    echo '{"found": true, "path": "'"$candidate"'"}'
    exit 0
  fi
done

echo '{"found": false}'
