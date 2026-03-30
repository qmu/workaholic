#!/bin/bash
# Clean up a trip worktree and its local branch after PR merge.
# Usage: bash cleanup-worktree.sh <trip-name>
# Output: JSON with cleanup status

set -euo pipefail

trip_name="${1:-}"

if [ -z "$trip_name" ]; then
  echo '{"error": "trip name is required"}' >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
branch="trip/${trip_name}"
worktree_path="${repo_root}/.worktrees/${trip_name}"

worktree_removed=false
branch_removed=false

# Remove worktree if it exists
if [ -d "$worktree_path" ]; then
  git worktree remove "$worktree_path" --force
  worktree_removed=true
fi

# Prune stale worktree entries
git worktree prune

# Delete local branch if it exists (safe delete)
if git show-ref --verify --quiet "refs/heads/${branch}"; then
  git branch -d "$branch" 2>/dev/null || git branch -D "$branch"
  branch_removed=true
fi

cat <<EOF
{"cleaned": true, "worktree_path": "$worktree_path", "branch": "$branch", "worktree_removed": $worktree_removed, "branch_removed": $branch_removed}
EOF
