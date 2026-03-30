#!/bin/sh -eu
# Gather ticket metadata for frontmatter in one call
# Usage: gather.sh
# Output: JSON with created_at, author, and filename_timestamp

set -eu

CREATED_AT=$(date -Iseconds)
AUTHOR=$(git config user.email)
FILENAME_TS=$(date +%Y%m%d%H%M%S)

cat <<EOF
{
  "created_at": "${CREATED_AT}",
  "author": "${AUTHOR}",
  "filename_timestamp": "${FILENAME_TS}"
}
EOF
