#!/bin/sh
# Create timestamped topic branch
# Usage: create.sh [prefix]
# Default prefix: drive
# Output: JSON with branch name

set -eu

PREFIX="${1:-drive}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BRANCH="${PREFIX}-${TIMESTAMP}"

git checkout -b "$BRANCH"

cat <<EOF
{
  "branch": "${BRANCH}"
}
EOF
