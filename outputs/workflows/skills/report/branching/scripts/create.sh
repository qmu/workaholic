#!/bin/sh
# Create timestamped topic branch
# Usage: create.sh
# Output: JSON with branch name
# Format: work-YYYYMMDD-HHMMSS

set -eu

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BRANCH="work-${TIMESTAMP}"

git checkout -b "$BRANCH"

cat <<EOF
{
  "branch": "${BRANCH}"
}
EOF
