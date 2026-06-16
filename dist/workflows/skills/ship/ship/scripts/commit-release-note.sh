#!/bin/bash
# Commit and push generated release note(s) to the current branch, so they are
# included in the merge to main. Run AFTER core:write-release-note has written the
# note file(s) under .workaholic/release-notes/ and BEFORE merge-pr.sh.
# Usage: bash commit-release-note.sh <branch>
# Output: JSON {committed, branch} or {committed:false, reason}

set -euo pipefail

branch="${1:-}"

if [ -z "$branch" ]; then
  echo '{"error": "branch name is required"}' >&2
  exit 1
fi

notes_dir=".workaholic/release-notes"

tracked_changes=$(git status --porcelain -- "$notes_dir" 2>/dev/null || echo "")

if [ -z "$tracked_changes" ]; then
  echo '{"committed": false, "reason": "no_release_note_changes"}'
  exit 0
fi

git add "$notes_dir"
git commit -m "Add release notes for $branch" >/dev/null
git push >/dev/null 2>&1 || true

echo '{"committed": true, "branch": "'"$branch"'"}'
