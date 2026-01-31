#!/bin/bash
# Create timestamped topic branch
# Usage: create.sh <prefix>
# Example: create.sh drive

PREFIX="${1:-drive}"

# Validate prefix
case "$PREFIX" in
  drive|trip|feat|fix|refact) ;;
  *)
    echo "Error: prefix must be: drive, trip, feat, fix, or refact" >&2
    exit 1
    ;;
esac

# Generate branch name
BRANCH="${PREFIX}-$(date +%Y%m%d-%H%M%S)"

# Create and checkout branch
git checkout -b "$BRANCH"

# Output branch name
echo "$BRANCH"
