#!/bin/sh
# Check if on main/master or topic branch
# Usage: check.sh
# Output: JSON with branch state

set -eu

CURRENT=$(git branch --show-current)

if [ "$CURRENT" = "main" ] || [ "$CURRENT" = "master" ]; then
  cat <<EOF
{
  "on_main": true,
  "branch": "$CURRENT"
}
EOF
else
  cat <<EOF
{
  "on_main": false,
  "branch": "$CURRENT"
}
EOF
fi
