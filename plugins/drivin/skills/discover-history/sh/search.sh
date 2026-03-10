#!/bin/sh -eu
# Search archived tickets by multiple keywords
# Usage: search.sh <keyword1> [keyword2] [keyword3] ...
# Output: List of matching ticket paths with match counts

set -eu

if [ $# -eq 0 ]; then
    echo "Usage: search.sh <keyword1> [keyword2] ..."
    exit 1
fi

ARCHIVE_DIR=".workaholic/tickets/archive"

# Build grep pattern: keyword1|keyword2|keyword3
PATTERN=$(echo "$@" | tr ' ' '|')

# Search and count matches per file, sort by count descending
grep -rilE -m 10 "$PATTERN" "$ARCHIVE_DIR" 2>/dev/null | while read -r file; do
    count=$(grep -ciE -m 10 "$PATTERN" "$file" 2>/dev/null || echo 0)
    echo "$count $file"
done | sort -rn | head -10
