#!/bin/bash
# Find cloud.md in standard locations.
# Usage: bash find-cloud-md.sh
# Output: JSON with path if found, or {"found": false}

set -euo pipefail

for candidate in "./cloud.md" "./.workaholic/cloud.md"; do
  if [ -f "$candidate" ]; then
    echo '{"found": true, "path": "'"$candidate"'"}'
    exit 0
  fi
done

echo '{"found": false}'
