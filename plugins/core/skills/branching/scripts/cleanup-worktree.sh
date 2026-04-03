#!/bin/bash
# Clean up a worktree and its local branch after PR merge.
# Usage: bash cleanup-worktree.sh <branch-name>
# Output: JSON with cleanup status

set -euo pipefail

branch_name="${1:-}"

if [ -z "$branch_name" ]; then
  echo '{"error": "branch name is required"}' >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
worktree_path="${repo_root}/.worktrees/${branch_name}"

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
if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
  git branch -d "$branch_name" 2>/dev/null || git branch -D "$branch_name"
  branch_removed=true
fi

cat <<EOF
{"cleaned": true, "worktree_path": "$worktree_path", "branch": "$branch_name", "worktree_removed": $worktree_removed, "branch_removed": $branch_removed}
EOF
