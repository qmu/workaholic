#!/bin/sh -eu
# Strip YAML frontmatter from a markdown file
# Usage: strip-frontmatter.sh <file>
# Outputs clean markdown body to stdout

set -eu

FILE="${1:-}"

if [ -z "$FILE" ]; then
    echo "Usage: strip-frontmatter.sh <file>" >&2
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "Error: File not found: $FILE" >&2
    exit 1
fi

# Remove frontmatter: delete from first --- to next --- (only if file starts with ---)
awk 'NR==1 && /^---$/ { in_fm=1; next } in_fm && /^---$/ { in_fm=0; next } in_fm { next } { print }' "$FILE"
