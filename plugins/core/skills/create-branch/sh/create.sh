#!/bin/sh -eu
# Create timestamped topic branch
# Usage: create.sh <prefix>
# Example: create.sh feat

set -eu

PREFIX="$1"

if [ -z "$PREFIX" ]; then
    echo "Usage: create.sh <prefix>"
    echo "Prefixes: feat, fix, refact"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BRANCH="${PREFIX}-${TIMESTAMP}"

git checkout -b "$BRANCH"
echo "$BRANCH"
