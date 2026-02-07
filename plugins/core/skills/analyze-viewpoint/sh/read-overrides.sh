#!/bin/sh -eu
# Read user repo's root CLAUDE.md for viewpoint override directives
# Usage: read-overrides.sh
# Output: JSON with any custom viewpoint overrides found

set -eu

CLAUDE_MD="CLAUDE.md"

echo "=== OVERRIDES ==="

if [ ! -f "$CLAUDE_MD" ]; then
    echo '{"has_overrides": false, "viewpoints": []}'
    exit 0
fi

# Check for viewpoint-related directives in CLAUDE.md
# Look for lines containing "viewpoint" in any section
HAS_VIEWPOINT=$(grep -ci "viewpoint" "$CLAUDE_MD" 2>/dev/null || echo "0")

if [ "$HAS_VIEWPOINT" = "0" ]; then
    echo '{"has_overrides": false, "viewpoints": []}'
    exit 0
fi

# Extract viewpoint-related sections
echo '{"has_overrides": true, "content": "'
grep -i -A 5 "viewpoint" "$CLAUDE_MD" 2>/dev/null | sed 's/"/\\"/g' | tr '\n' ' '
echo '"}'
