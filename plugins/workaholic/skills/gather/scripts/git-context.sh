#!/bin/sh -eu
# Gather all context for documentation subagents
# Usage: gather.sh
# Output: JSON with branch, base_branch, repo_url, archived_tickets, git_log

set -eu

SCRIPT_DIR=$(dirname "$0")
BRANCH=$(git branch --show-current)
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# Base ref: the single resolver decides it (prefers origin/<default>, so it is immune
# to a local `main` a primary checkout has pinned stale, and needs no network). Do NOT
# swallow its failure — an empty base_branch would degrade `git log "${BASE_BRANCH}..HEAD"`
# below into `git log HEAD` (all history, silently), which is exactly the bug. Fail loud.
if ! BASE_BRANCH=$("${SCRIPT_DIR}/base-ref.sh"); then
    echo "git-context: could not resolve a base ref; refusing to emit an empty base_branch" >&2
    exit 1
fi
REPO_URL_RAW=$(git remote get-url origin 2>/dev/null || true)

# Transform SSH URL to HTTPS format
# git@github.com:owner/repo.git -> https://github.com/owner/repo
REPO_URL=$(echo "$REPO_URL_RAW" | \
  sed 's|^git@github\.com:|https://github.com/|' | \
  sed 's|\.git$||')

# List archived tickets for the branch (empty array if none)
ARCHIVE_DIR="${ROOT}/.workaholic/tickets/archive/${BRANCH}"
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
