#!/bin/sh
# Create timestamped topic branch
# Usage: create.sh [feature-name]
# Default feature: work
# Output: JSON with branch name
# Format: work-YYYYMMDD-HHMMSS-<feature>

set -eu

FEATURE="${1:-work}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BRANCH="work-${TIMESTAMP}-${FEATURE}"

git checkout -b "$BRANCH"

cat <<EOF
{
  "branch": "${BRANCH}"
}
EOF
