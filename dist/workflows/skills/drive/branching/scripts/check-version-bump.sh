#!/bin/sh
# Check if a "Bump version" commit already exists in the current branch
# Usage: check-version-bump.sh
# Output: JSON with already_bumped state

set -eu

COUNT=$(git log main..HEAD --oneline --grep="Bump version" | wc -l | tr -d ' ')

if [ "$COUNT" -gt 0 ]; then
  cat <<EOF
{
  "already_bumped": true
}
EOF
else
  cat <<EOF
{
  "already_bumped": false
}
EOF
fi
