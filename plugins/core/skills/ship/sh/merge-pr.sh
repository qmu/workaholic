#!/bin/bash
# Merge a PR and sync local main branch.
# Usage: bash merge-pr.sh <pr-number>
# Output: JSON with merge status and commit hash

set -euo pipefail

pr_number="${1:-}"

if [ -z "$pr_number" ]; then
  echo '{"error": "PR number is required"}' >&2
  exit 1
fi

if ! gh pr merge "$pr_number" --merge; then
  echo '{"merged": false, "error": "merge failed"}' >&2
  exit 1
fi

git checkout main
git pull origin main

commit_hash=$(git rev-parse --short HEAD)

cat <<EOF
{"merged": true, "pr_number": $pr_number, "commit_hash": "$commit_hash"}
EOF
