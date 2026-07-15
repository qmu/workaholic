#!/bin/sh -eu
# Commit and push generated release note(s) to the current branch, so they are
# included in the merge to main. Run AFTER workaholic:write-release-note has written the
# note file(s) under .workaholic/release-notes/ and BEFORE merge-pr.sh.
# Usage: bash commit-release-note.sh <branch>
# Output: JSON {committed, branch, pushed, push_error} or {committed:false, reason}
#
# The push is best-effort and NEVER fails this script, but its outcome is reported
# rather than swallowed: `pushed` is true/false and `push_error` carries a short,
# non-secret cause when it failed. A note committed but not pushed is a note the PR
# does not carry, so the caller must be able to see it. See lib/push-outcome.sh.

set -eu

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

# Refresh the .workaholic OKF bundle indexes (stages them) so the new note is
# reflected in the committed hierarchy (best-effort: never blocks the commit).
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/push-outcome.sh"
sh "${SCRIPT_DIR}/../../okf/scripts/refresh-index.sh" >/dev/null 2>&1 || true

git add "$notes_dir"
git commit -m "Add release notes for $branch" >/dev/null
# Non-fatal, but reported: a note committed and not pushed is a note the PR does
# not carry, and the caller cannot see that from `committed` alone.
push_and_report

echo '{"committed": true, "branch": "'"$branch"'", "pushed": '"$PUSH_OK"', "push_error": "'"$PUSH_ERROR"'"}'
