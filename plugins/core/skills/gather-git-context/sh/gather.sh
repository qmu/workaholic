#!/bin/sh -eu
# Gather all context for documentation subagents
# Usage: gather.sh
# Output: JSON with branch, base_branch, repo_url, archived_tickets, git_log

set -eu

BRANCH=$(git branch --show-current)
BASE_BRANCH=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | sed 's/.*: //')
REPO_URL_RAW=$(git remote get-url origin)

# Transform SSH URL to HTTPS format
# git@github.com:owner/repo.git -> https://github.com/owner/repo
REPO_URL=$(echo "$REPO_URL_RAW" | \
  sed 's|^git@github\.com:|https://github.com/|' | \
  sed 's|\.git$||')

# List archived tickets for the branch (empty array if none)
ARCHIVE_DIR=".workaholic/tickets/archive/${BRANCH}"
if [ -d "$ARCHIVE_DIR" ]; then
    TICKETS=$(ls -1 "$ARCHIVE_DIR"/*.md 2>/dev/null | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')
else
    TICKETS=""
fi

# Get git log since base branch
GIT_LOG=$(git log "${BASE_BRANCH}..HEAD" --oneline 2>/dev/null | sed 's/"/\\"/g' | sed 's/$/\\n/' | tr -d '\n' | sed 's/\\n$//')

cat <<EOF
{
  "branch": "${BRANCH}",
  "base_branch": "${BASE_BRANCH}",
  "repo_url": "${REPO_URL}",
  "archived_tickets": [${TICKETS}],
  "git_log": "${GIT_LOG}"
}
EOF
