#!/bin/sh -eu
# Pre-check: verify PR exists for a branch.
# Usage: sh pre-check.sh <branch-name>
# Output: JSON with pr_number, url, state, merged
#     or: {"found": false, "reason": "gh_unavailable", ...} when the `gh` CLI is absent
#
# "NO gh" AND "NO PR" ARE DIFFERENT ANSWERS, AND ONLY ONE IS SAFE TO PROCEED ON.
# The `gh pr list ... || echo ""` below used to swallow an exit 127 into the same empty
# string an unPR'd branch produces, so a ship flow read "this environment has no GitHub
# CLI" as "this branch has no pull request" -- confidently continuing on an answer its
# own tooling had failed to produce (`workaholic:implementation` / observability).
# The hourly runner meets this every tick: the Claude-Code-on-the-web container has no
# `gh` (observed 2026-07-31). So the absence is checked FIRST and reported by name.

set -eu

branch="${1:-}"

if [ -z "$branch" ]; then
  echo '{"error": "branch name is required"}' >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo '{"found": false, "reason": "gh_unavailable", "branch": "'"$branch"'", "detail": "the GitHub CLI is not installed here, so PR state could not be read -- this is NOT the same as the branch having no pull request"}'
  exit 0
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
