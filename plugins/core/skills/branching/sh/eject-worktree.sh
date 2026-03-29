#!/bin/bash
# Eject a worktree back to a regular branch in the main working tree.
# Must be run from the main working tree, passing the worktree path as argument.
# Usage: bash eject-worktree.sh <worktree-path>
# Output: JSON with ejected status, branch, and main_repo path

set -euo pipefail

worktree_path="${1:-}"

if [ -z "$worktree_path" ]; then
  echo '{"error": "worktree path is required"}' >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"

# Resolve to absolute path
if [[ "$worktree_path" != /* ]]; then
  worktree_path="${repo_root}/${worktree_path}"
fi

# Verify the path is a worktree
if ! git worktree list --porcelain | grep -q "worktree ${worktree_path}"; then
  echo '{"error": "not a valid worktree", "path": "'"${worktree_path}"'"}' >&2
  exit 1
fi

# Extract branch from worktree
wt_branch=""
found_path=false
while IFS= read -r line; do
  if [ "$line" = "worktree ${worktree_path}" ]; then
    found_path=true
  elif $found_path && [[ "$line" =~ ^branch\ refs/heads/(.+)$ ]]; then
    wt_branch="${BASH_REMATCH[1]}"
    break
  elif [ -z "$line" ]; then
    found_path=false
  fi
done < <(git worktree list --porcelain)

if [ -z "$wt_branch" ]; then
  echo '{"error": "could not determine branch for worktree"}' >&2
  exit 1
fi

# Check main working tree is clean
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo '{"error": "main working tree has uncommitted changes, commit or stash first"}' >&2
  exit 1
fi

# Remove worktree first (frees the branch)
git worktree remove "${worktree_path}" --force

# Prune stale entries
git worktree prune

# Checkout the branch in the main working tree
git checkout "${wt_branch}"

echo '{"ejected": true, "branch": "'"${wt_branch}"'", "main_repo": "'"${repo_root}"'"}'
