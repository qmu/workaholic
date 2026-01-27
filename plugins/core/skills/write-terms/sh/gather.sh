#!/bin/sh -eu
# Gather context for terms updates
# Outputs branch info, tickets, existing terms, and diff

set -eu

BASE_BRANCH="${1:-main}"

# Get current branch
BRANCH=$(git branch --show-current)
echo "=== BRANCH ==="
echo "$BRANCH"
echo ""

# List archived tickets
ARCHIVE_DIR=".workaholic/tickets/archive/${BRANCH}"
echo "=== TICKETS ==="
if [ -d "$ARCHIVE_DIR" ]; then
    ls -1 "$ARCHIVE_DIR"/*.md 2>/dev/null || echo "No archived tickets"
else
    echo "No archived tickets"
fi
echo ""

# List existing terms
echo "=== TERMS ==="
find .workaholic/terms -name "*.md" -type f 2>/dev/null | sort || echo "No terms found"
echo ""

# Get diff against base
echo "=== DIFF ==="
git diff "${BASE_BRANCH}...HEAD" --stat 2>/dev/null || echo "No diff available"
echo ""

# Get current commit hash
echo "=== COMMIT ==="
git rev-parse --short HEAD
