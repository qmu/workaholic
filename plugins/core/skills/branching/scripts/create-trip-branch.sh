#!/bin/bash
# Create a trip branch without a worktree.
# Usage: bash create-trip-branch.sh <trip-name>
# Output: JSON with branch name and worktree flag

set -euo pipefail

trip_name="${1:-}"

if [ -z "$trip_name" ]; then
  echo '{"error": "trip name is required"}' >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo '{"error": "not inside a git repository"}' >&2
  exit 1
fi

branch="trip/${trip_name}"

if git show-ref --verify --quiet "refs/heads/${branch}"; then
  echo '{"error": "branch already exists", "branch": "'"${branch}"'"}' >&2
  exit 1
fi

git checkout -b "${branch}"

echo '{"branch": "'"${branch}"'", "worktree": false}'
