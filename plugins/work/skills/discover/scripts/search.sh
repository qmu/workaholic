#!/bin/sh -eu
# Search all tickets (archive, todo, icebox) by multiple keywords
# Usage: search.sh <keyword1> [keyword2] [keyword3] ...
# Output: List of matching ticket paths with match counts

set -eu

if [ $# -eq 0 ]; then
    echo "Usage: search.sh <keyword1> [keyword2] ..."
    exit 1
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

ARCHIVE_DIR="${ROOT}/.workaholic/tickets/archive"
TODO_DIR="${ROOT}/.workaholic/tickets/todo"
ICEBOX_DIR="${ROOT}/.workaholic/tickets/icebox"

# Collect all search directories that exist
SEARCH_DIRS=""
for dir in "$ARCHIVE_DIR" "$TODO_DIR" "$ICEBOX_DIR"; do
    [ -d "$dir" ] && SEARCH_DIRS="$SEARCH_DIRS $dir"
done

# Build grep pattern: keyword1|keyword2|keyword3
PATTERN=$(echo "$@" | tr ' ' '|')

# Search and count matches per file, sort by count descending
grep -rilE -m 10 "$PATTERN" $SEARCH_DIRS 2>/dev/null | while read -r file; do
    count=$(grep -ciE -m 10 "$PATTERN" "$file" 2>/dev/null || echo 0)
    echo "$count $file"
done | sort -rn | head -10
