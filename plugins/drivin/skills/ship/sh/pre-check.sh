#!/bin/bash
# Pre-check: verify PR exists for a branch.
# Usage: bash pre-check.sh <branch-name>
# Output: JSON with pr_number, url, state, merged

set -euo pipefail

branch="${1:-}"

if [ -z "$branch" ]; then
  echo '{"error": "branch name is required"}' >&2
  exit 1
fi

pr_info=$(gh pr list --head "$branch" --state all --json number,url,state,mergedAt --jq '.[0]' 2>/dev/null || echo "")

if [ -z "$pr_info" ] || [ "$pr_info" = "null" ]; then
  echo '{"found": false, "branch": "'"$branch"'"}'
  exit 0
fi

number=$(echo "$pr_info" | jq -r '.number')
url=$(echo "$pr_info" | jq -r '.url')
state=$(echo "$pr_info" | jq -r '.state')
merged_at=$(echo "$pr_info" | jq -r '.mergedAt')

merged=false
if [ "$merged_at" != "null" ] && [ -n "$merged_at" ]; then
  merged=true
fi

cat <<EOF
{"found": true, "pr_number": $number, "url": "$url", "state": "$state", "merged": $merged}
EOF
